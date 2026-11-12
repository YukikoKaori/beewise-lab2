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


class Wave2CompletionPolicyTests(unittest.TestCase):
    def setUp(self) -> None:
        self.proposal_file = ROOT / "evidence/final/artemis/completion-wave2/budget-proposal.json"
        self.approval_file = ROOT / "evidence/final/artemis/completion-wave2/owner-approval.json"
        proposed = self.proposal_file.read_bytes().replace(b"\r\n", b"\n")
        self.digest = hashlib.sha256(proposed).hexdigest()
        self.proposal = json.loads(proposed)
        self.approval = json.loads(self.approval_file.read_text(encoding="utf-8"))

    def test_wave2_proposal_and_approval_match_contract(self) -> None:
        proposal, approval, digest = check_completion_approval(
            self.approval_file, self.proposal_file
        )
        self.assertEqual(digest, self.digest)
        self.assertEqual(
            proposal["cases"],
            ["FINAL-F02a", "FINAL-F01", "FINAL-F02b", "TC-27", "TC-NATIVE-01"],
        )
        self.assertEqual(proposal["max_admissions"], 15)
        self.assertEqual(proposal["repetitions_per_case"], 3)
        self.assertEqual(proposal["max_inference_requests"], 240)
        self.assertEqual(proposal["max_conservative_nanodollars"], 500_000_000)
        self.assertEqual(proposal["minimum_nexora_reserve_nanodollars"], 0)
        self.assertEqual(proposal["flash_max_turns"], 18)
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
            proposal_file=self.proposal_file,
        )
        self.assertEqual(returned["flash_max_turns"], 18)

    def test_wave2_cross_proposal_or_turn_over_cap_fails_closed(self) -> None:
        ref = f"{self.approval['owner_approval_ref']}:{self.digest}"
        future = (datetime.now(UTC) + timedelta(hours=1)).isoformat()
        req = self.proposal["max_inference_requests"]
        cap = self.proposal["max_conservative_nanodollars"]
        # Cannot reuse Wave 1 decision against Wave 2 proposal or vice versa.
        with self.assertRaises(ValueError):
            check_completion_authorization(
                ROOT / "evidence/final/artemis/completion-batch/owner-approval.json",
                (req, cap, future, ref, 0),
                proposal_file=self.proposal_file,
            )
        # Rejects flash_max_turns > 20 or conservative cost > $0.500.
        with tempfile.TemporaryDirectory() as tmp:
            tmp_prop = Path(tmp) / "over-turn-proposal.json"
            bad_prop = {**self.proposal, "flash_max_turns": 21}
            raw = json.dumps(bad_prop).encode("utf-8")
            bad_digest = hashlib.sha256(raw).hexdigest()
            tmp_prop.write_bytes(raw)
            tmp_app = Path(tmp) / "over-turn-approval.json"
            tmp_app.write_text(
                json.dumps({**self.approval, "proposal_sha256": bad_digest}),
                encoding="utf-8",
            )
            with self.assertRaises(ValueError):
                check_completion_authorization(
                    tmp_app,
                    (req, cap, future, f"{self.approval['owner_approval_ref']}:{bad_digest}", 0),
                    proposal_file=tmp_prop,
                )


class CodexHandoffCheckpointTests(unittest.TestCase):
    def test_wave2_summary_and_codex_checkpoint_invariants(self) -> None:
        batch_summary = json.loads(
            (ROOT / "evidence/final/artemis/completion-wave2/batch-summary.json").read_text(
                encoding="utf-8"
            )
        )
        self.assertEqual(batch_summary["status"], "COMPLETED_15_OF_15_ADMISSIONS")
        self.assertEqual(batch_summary["executed_admissions"], 15)
        self.assertEqual(batch_summary["accepted_passes"], 11)
        self.assertEqual(len(batch_summary["admissions"]), 15)

        checkpoint_path = ROOT / "evidence/final/artemis/codex-handoff-checkpoint.json"
        checkpoint_text = checkpoint_path.read_text(encoding="utf-8")
        self.assertNotIn("sk-", checkpoint_text)
        checkpoint = json.loads(checkpoint_text)

        self.assertEqual(checkpoint["status"], "PAUSED_CLEAN_AFTER_WAVE_2_TC_NATIVE_01")
        self.assertEqual(checkpoint["activeSessionAndDeviceState"]["activeSessionsInAnyLedger"], 0)
        self.assertEqual(
            checkpoint["activeSessionAndDeviceState"]["unreviewedSessionsInAnyLedger"], 0
        )
        self.assertEqual(
            checkpoint["cumulativeUsageAndBudget"]["rebuiltPr31ApkCombined"]["admittedRuns"], 18
        )
        self.assertEqual(
            checkpoint["cumulativeUsageAndBudget"]["rebuiltPr31ApkCombined"]["acceptedPasses"], 11
        )
        self.assertEqual(
            checkpoint["cumulativeUsageAndBudget"]["allFinalBatchesCombined"]["admittedRuns"], 27
        )
        self.assertEqual(
            checkpoint["cumulativeUsageAndBudget"]["allFinalBatchesCombined"]["acceptedPasses"], 15
        )
        self.assertFalse(checkpoint["artemisHostAndProviderConfig"]["credentialsIncluded"])

        # Every tracked artifact referenced in completed runs must exist cleanly without pre-ui XML.
        all_runs = (
            checkpoint["completedRuns"]["gate3b"]
            + checkpoint["completedRuns"]["wave1"]
            + checkpoint["completedRuns"]["wave2"]
        )
        self.assertEqual(len(all_runs), 27)
        for run in all_runs:
            for key in (
                "evidenceDir",
                "manifest",
                "independentReviewReceipt",
                "runReceipt",
                "actionsJson",
                "finalReportJson",
                "junitXml",
            ):
                rel = run.get(key)
                if rel:
                    self.assertTrue((ROOT / rel).exists(), f"Missing {rel}")
            for extra in run.get("screenshots", []) + run.get("additionalEvidenceFiles", []):
                self.assertNotIn("pre-ui", extra)
                self.assertTrue((ROOT / extra).exists(), f"Missing {extra}")

        # No raw pre-ui UIAutomator XML dumps or leaked API keys under completion-wave2.
        wave2_dir = ROOT / "evidence/final/artemis/completion-wave2"
        self.assertEqual(list(wave2_dir.rglob("*pre-ui*")), [])
        for file_path in wave2_dir.rglob("*"):
            if file_path.is_file() and file_path.suffix in {".json", ".md", ".xml"}:
                self.assertNotIn("sk-", file_path.read_text(encoding="utf-8", errors="ignore"))


if __name__ == "__main__":
    unittest.main()
