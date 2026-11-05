"""Offline checks for the exact amended admission and reserve limits."""

import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools/artemis-deepseek"))

from balance_gate import check_balance
from policy import require_live_authorization, validate_completion_admission


class CompletionPolicyTest(unittest.TestCase):
    def test_only_new_failures_count_and_tc03_goes_first(self):
        approved = json.loads((Path(__file__).resolve().parents[1] /
                              "tools/artemis-deepseek/execution-policy.json").read_text(encoding="utf-8"))
        approved.pop("live_hold_reason", None)
        with patch("policy.Path.read_text", return_value=json.dumps(approved)):
            req = approved.get("approved_inference_requests", 240)
            policy = require_live_authorization(req, 690_000_000)
            with self.assertRaises(ValueError):
                require_live_authorization(req + 1, 690_000_000)
        rows = ([("TC-03", "FAILED")] * 4 + [("TC-03", "ACCEPTED")] * 3
                + [("TC-01", "ACCEPTED")] * 3 + [("TC-04", "ACCEPTED")] * 3 + [("TC-04", "FAILED")]
                + [("TC-05", "ACCEPTED")] * 3 + [("TC-05", "FAILED")]
                + [("TC-06", "ACCEPTED")] * 3 + [("TC-08", "ACCEPTED")] * 3
                + [("TC-09", "ACCEPTED")] * 3 + [("TC-09", "FAILED")]
                + [("TC-16", "FAILED")]
                + [("TC-20", "ACCEPTED")] * 3 + [("TC-20", "FAILED")]
                + [("TC-22", "FAILED")] * 2)
        validate_completion_admission(rows, "TC-22", policy)
        validate_completion_admission(rows + [("TC-22", "FAILED")], "TC-22", policy)
        with self.assertRaisesRegex(ValueError, "case failure cap"):
            validate_completion_admission(rows + [("TC-22", "FAILED")] * policy.get("additional_failures_per_case", 2), "TC-22", policy)
        validate_completion_admission(rows + [("TC-22", "ACCEPTED")], "TC-16", policy)
        with self.assertRaisesRegex(ValueError, "global cap"):
            validate_completion_admission(rows + [("TC-06", "ACCEPTED")] * (policy.get("maximum_admitted", 42) - len(rows) + 1), "TC-22", policy)

    def test_balance_floor_is_exact_and_no_sensitive_value_is_exported(self):
        with tempfile.TemporaryDirectory() as directory, patch("balance_gate.dotenv_values",
                return_value={"DEEPSEEK_API_KEY": "offline-credential"}), patch("balance_gate.httpx.Client") as client:
            response = client.return_value.__enter__.return_value.get.return_value
            response.status_code = 200
            for index, balance in enumerate(("0.8822333", "0.8822332")):
                receipt = Path(directory) / f"{index}.json"
                response.json.return_value = {"is_available": True,
                    "balance_infos": [{"currency": "USD", "total_balance": balance}]}
                if index == 0:
                    check_balance(Path("ignored"), 882_233_300, receipt)
                else:
                    with self.assertRaises(ValueError):
                        check_balance(Path("ignored"), 882_233_300, receipt)
                payload = json.loads(receipt.read_text())
                self.assertNotIn("total_balance", payload)
                self.assertNotIn("offline-credential", receipt.read_text())
                self.assertEqual(payload["inference_requests"], 0)


if __name__ == "__main__":
    unittest.main()
