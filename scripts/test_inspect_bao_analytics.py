"""Check native identity receipts fail closed on incomplete/interleaved logs."""
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location(
    "inspect_bao_analytics", Path(__file__).with_name("inspect-bao-analytics.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def log(identity=None, complete=True):
    lines = ["Uploading data. app: com.beewise.beewise", "batch {", "bundle {",
             "app_id: com.beewise.beewise"]
    if identity is not None:
        lines += ["user_property {", "name: user_id(_id)",
                  "string_value: " + identity, "}"]
    lines += ["event {", "name: search", "timestamp_millis: 123", "}", "}", "}"]
    if not complete:
        lines.pop()
    rows = [f"11-01 12:00:00.000  100  101 D FA-SVC  : {line}" for line in lines]
    # Another process's identity must not contaminate this upload.
    rows.insert(5, "11-01 12:00:00.000  200  201 D FA-SVC  : string_value: foreign")
    return "\n".join(rows)


class IdentityReceiptTest(unittest.TestCase):
    def test_complete_guest_has_no_identity(self):
        receipt = module.inspect(log())
        bundle, = receipt["businessEventUploadBundles"]
        self.assertEqual(bundle["userIdPropertyCount"], 0)
        self.assertEqual(bundle["userIdAliases"], [])
        self.assertEqual(bundle["events"][0]["name"], "search")

    def test_identity_is_aliased(self):
        receipt = module.inspect(log("synthetic-a"))
        bundle, = receipt["businessEventUploadBundles"]
        self.assertEqual(bundle["userIdPropertyCount"], 1)
        self.assertEqual(len(bundle["userIdAliases"]), 1)
        self.assertNotIn("synthetic-a", str(receipt))
        self.assertNotIn("foreign", str(receipt))

    def test_incomplete_guest_is_not_clear_evidence(self):
        receipt = module.inspect(log(complete=False))
        self.assertEqual(receipt["businessEventUploadBundles"], [])
        self.assertEqual(receipt["incompleteUploadsIgnored"], 1)

    def test_capture_time_alias_is_preserved(self):
        receipt = module.inspect(log("uid-sha256:0123456789abcdef"))
        bundle, = receipt["businessEventUploadBundles"]
        self.assertEqual(bundle["userIdAliases"], ["uid-sha256:0123456789abcdef"])


if __name__ == "__main__":
    unittest.main()
