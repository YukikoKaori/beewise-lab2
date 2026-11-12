"""Offline checks for PRM393 Final ARTEMIS budget and approval gating."""

from __future__ import annotations

import hashlib
import json
import sys
import tempfile
import unittest
from datetime import UTC, datetime, timedelta
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools/artemis-deepseek"))

from completion_once import check_completion_approval  # noqa: E402
from final_once import check_final_approval, verify_installed_apk  # noqa: E402
from host import check_completion_authorization, check_final_authorization  # noqa: E402


class FinalArtemisPolicyTests(unittest.TestCase):
    def setUp(self) -> None:
        self.proposal_file = ROOT / "evidence/final/artemis/budget-proposal.json"
        self.approval_file = ROOT / "evidence/final/artemis/owner-approval.json"
        proposed = self.proposal_file.read_bytes().replace(b"\r\n", b"\n")
        self.digest = hashlib.sha256(proposed).hexdigest()
        self.proposal = json.loads(proposed)
        self.approval = json.loads(self.approval_file.read_text(encoding="utf-8"))

    def test_current_proposal_and_owner_approval_match_contract(self) -> None:
        proposal, approval, digest = check_final_approval(
            self.approval_file, self.proposal_file
        )
        self.assertEqual(digest, self.digest)
        self.assertEqual(proposal["max_admissions"], 9)
        self.assertEqual(proposal["retry_admissions"], 0)
        self.assertEqual(proposal["max_inference_requests"], 60)
        self.assertEqual(proposal["max_conservative_nanodollars"], 200_000_000)
        self.assertEqual(proposal["minimum_nexora_reserve_nanodollars"], 500_000_000)
        expires = (datetime.now(UTC) + timedelta(hours=1)).isoformat()
        ref = f"{approval['owner_approval_ref']}:{digest}"
        check_final_authorization(
            self.approval_file,
            (
                proposal["max_inference_requests"],
                proposal["max_conservative_nanodollars"],
                expires,
                ref,
                0,
            ),
        )

    def test_tampered_or_expired_or_blocked_budget_fails_closed(self) -> None:
        ref = f"{self.approval['owner_approval_ref']}:{self.digest}"
        future = (datetime.now(UTC) + timedelta(hours=1)).isoformat()
        past = (datetime.now(UTC) - timedelta(minutes=1)).isoformat()
        # Blocked ledger
        with self.assertRaises(ValueError):
            check_final_authorization(
                self.approval_file, (60, 200_000_000, future, ref, 1)
            )
        # Expired ledger
        with self.assertRaises(ValueError):
            check_final_authorization(
                self.approval_file, (60, 200_000_000, past, ref, 0)
            )
        # Mismatched request count
        with self.assertRaises(ValueError):
            check_final_authorization(
                self.approval_file, (61, 200_000_000, future, ref, 0)
            )
        # Wrong approval hash
        with tempfile.TemporaryDirectory() as tmp:
            bad = Path(tmp) / "bad-approval.json"
            bad.write_text(
                json.dumps({**self.approval, "proposal_sha256": "0" * 64}),
                encoding="utf-8",
            )
            with self.assertRaises(ValueError):
                check_final_authorization(bad, (60, 200_000_000, future, ref, 0))

    def test_verify_installed_apk_fails_on_hash_mismatch(self) -> None:
        expected = self.proposal["target_apk_sha256"]

        def fake_adb(cmd, **kwargs):
            if cmd[-2:] == ["path", "com.beewise.beewise"]:
                return SimpleNamespace(stdout="package:/data/app/~~abc/base.apk\n")
            if cmd[-2] == "sha256sum":
                return SimpleNamespace(stdout=f"{expected}  /data/app/~~abc/base.apk\n")
            raise AssertionError(cmd)

        with patch("final_once.subprocess.run", side_effect=fake_adb):
            self.assertEqual(verify_installed_apk("offline-device", expected), expected)

        with patch(
            "final_once.subprocess.run",
            side_effect=[
                SimpleNamespace(stdout="package:/data/app/~~abc/base.apk\n"),
                SimpleNamespace(stdout="f" * 64 + "  /data/app/~~abc/base.apk\n"),
            ],
        ), self.assertRaisesRegex(ValueError, "Installed APK SHA-256 mismatch"):
            verify_installed_apk("offline-device", expected)


class CompletionBatchPolicyTests(unittest.TestCase):
    def setUp(self) -> None:
        self.proposal_file = ROOT / "evidence/final/artemis/completion-batch/budget-proposal.json"
        self.approval_file = ROOT / "evidence/final/artemis/completion-batch/owner-approval.json"
        proposed = self.proposal_file.read_bytes().replace(b"\r\n", b"\n")
        self.digest = hashlib.sha256(proposed).hexdigest()
        self.proposal = json.loads(proposed)
        self.approval = json.loads(self.approval_file.read_text(encoding="utf-8"))

    def test_completion_proposal_and_approval_match_contract(self) -> None:
        proposal, approval, digest = check_completion_approval(
            self.approval_file, self.proposal_file
        )
        self.assertEqual(digest, self.digest)
        self.assertEqual(proposal["cases"], ["FINAL-F01", "FINAL-F02a"])
        self.assertEqual(proposal["max_admissions"], 6)
        self.assertEqual(proposal["repetitions_per_case"], 3)
        self.assertEqual(proposal["retry_admissions"], 0)
        self.assertEqual(proposal["max_inference_requests"], 54)
        self.assertEqual(proposal["max_conservative_nanodollars"], 150_000_000)
        self.assertEqual(proposal["minimum_nexora_reserve_nanodollars"], 500_000_000)
        self.assertEqual(proposal["flash_max_turns"], 12)
        expires = (datetime.now(UTC) + timedelta(hours=1)).isoformat()
        ref = f"{approval['owner_approval_ref']}:{digest}"
        returned = check_completion_authorization(
            self.approval_file,
            (
                proposal["max_inference_requests"],
                proposal["max_conservative_nanodollars"],
                expires,
                ref,
                0,
            ),
        )
        self.assertEqual(returned["flash_max_turns"], 12)

    def test_completion_tampered_or_expired_or_blocked_fails_closed(self) -> None:
        ref = f"{self.approval['owner_approval_ref']}:{self.digest}"
        future = (datetime.now(UTC) + timedelta(hours=1)).isoformat()
        past = (datetime.now(UTC) - timedelta(minutes=1)).isoformat()
        req = self.proposal["max_inference_requests"]
        cap = self.proposal["max_conservative_nanodollars"]
        with self.assertRaises(ValueError):
            check_completion_authorization(self.approval_file, (req, cap, future, ref, 1))
        with self.assertRaises(ValueError):
            check_completion_authorization(self.approval_file, (req, cap, past, ref, 0))
        with self.assertRaises(ValueError):
            check_completion_authorization(self.approval_file, (req + 1, cap, future, ref, 0))
        with tempfile.TemporaryDirectory() as tmp:
            bad = Path(tmp) / "bad-approval.json"
            bad.write_text(
                json.dumps({**self.approval, "decision": "WRONG_DECISION"}),
                encoding="utf-8",
            )
            with self.assertRaises(ValueError):
                check_completion_authorization(bad, (req, cap, future, ref, 0))


if __name__ == "__main__":
    unittest.main()
