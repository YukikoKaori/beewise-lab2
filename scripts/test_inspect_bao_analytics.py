"""Check native identity receipts fail closed on incomplete/interleaved logs."""
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location(
    "inspect_bao_analytics", Path(__file__).with_name("inspect-bao-analytics.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def log(identity=None, complete=True, event_name="search", params=None,
        include_upload_ack=False, app_id="com.beewise.beewise"):
    lines = [f"Uploading data. app: {app_id}", "batch {", "bundle {",
             f"app_id: {app_id}"]
    if identity is not None:
        lines += ["user_property {", "name: user_id(_id)",
                  "string_value: " + identity, "}"]
    lines += ["event {", f"name: {event_name}", "timestamp_millis: 123"]
    for key, value_type, value in (params or []):
        lines += ["param {", f"name: {key}", f"{value_type}: {value}", "}"]
    lines += ["}", "}", "}"]
    if not complete:
        lines.pop()
    rows = [f"11-01 12:00:00.000  100  101 D FA-SVC  : {line}" for line in lines]
    # Another process's identity must not contaminate this upload.
    rows.insert(5, "11-01 12:00:00.000  200  201 D FA-SVC  : string_value: foreign")
    if include_upload_ack:
        rows.append(
            "11-01 12:00:01.000  100  101 V FA-SVC  : Successful upload. Got network response. code, size: 204, 0"
        )
        # Upload ack on an unrelated thread/app must not be counted.
        rows.append(
            "11-01 12:00:02.000  200  201 V FA-SVC  : Successful upload. Got network response. code, size: 204, 0"
        )
    return "\n".join(rows)


class IdentityReceiptTest(unittest.TestCase):
    def test_complete_guest_has_no_identity(self):
        receipt = module.inspect(log())
        bundle, = receipt["businessEventUploadBundles"]
        self.assertEqual(bundle["userIdPropertyCount"], 0)
        self.assertEqual(bundle["userIdAliases"], [])
        self.assertEqual(bundle["events"][0]["name"], "search")
        self.assertEqual(receipt["unexpectedParameterKeys"], [])
        self.assertEqual(receipt["unsafeParameterValuesOmitted"], 0)

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

    def test_final_ai_events_and_safe_parameters_exported(self):
        receipt = module.inspect(
            log(
                event_name="ai_error",
                params=[
                    ("feature", "string_value", "tutor_need"),
                    ("kind", "string_value", "timeout"),
                    ("ga_event_origin(_o)", "string_value", "app"),
                    ("ga_screen_class(_sc)", "string_value", "MainActivity"),
                    ("ga_screen_id(_si)", "int_value", "-154764801810505901"),
                ],
                include_upload_ack=True,
            )
        )
        bundle, = receipt["businessEventUploadBundles"]
        event = bundle["events"][0]
        self.assertEqual(event["name"], "ai_error")
        self.assertEqual(event["parameters"], {"feature": "tutor_need", "kind": "timeout"})
        self.assertEqual(receipt["unexpectedParameterKeys"], [])
        self.assertEqual(receipt["successfulUploadCount"], 1)

    def test_unexpected_parameter_key_flagged_without_exporting_value(self):
        receipt = module.inspect(
            log(
                event_name="ai_request",
                params=[
                    ("feature", "string_value", "tutor_need"),
                    ("raw_email", "string_value", "parent@example.com"),
                ],
            )
        )
        bundle, = receipt["businessEventUploadBundles"]
        event = bundle["events"][0]
        self.assertEqual(event["parameters"], {"feature": "tutor_need"})
        self.assertEqual(event["unexpectedParameterKeys"], ["raw_email"])
        self.assertEqual(receipt["unexpectedParameterKeys"], ["raw_email"])
        self.assertNotIn("parent@example.com", str(receipt))

    def test_unsafe_allowlisted_parameter_value_omitted_safely(self):
        receipt = module.inspect(
            log(
                event_name="ai_result_accepted",
                params=[
                    ("feature", "string_value", "raw-user@secret.vn"),
                ],
            )
        )
        bundle, = receipt["businessEventUploadBundles"]
        self.assertEqual(bundle["events"][0]["parameters"], {})
        self.assertEqual(receipt["unsafeParameterValuesOmitted"], 1)
        self.assertNotIn("raw-user@secret.vn", str(receipt))

    def test_tutor_and_vietqr_business_events_recognized(self):
        for event_name, params in [
            ("tutor_application_submitted", []),
            ("tutor_application_resubmitted", []),
            ("connection_request_submitted", [("request_type", "string_value", "parent_connection")]),
            ("upload_report", [
                ("storage_backend", "string_value", "local_metadata"),
                ("file_size_kb", "int_value", "15"),
                ("result", "string_value", "success"),
            ]),
        ]:
            with self.subTest(event_name=event_name):
                receipt = module.inspect(log(event_name=event_name, params=params))
                bundle, = receipt["businessEventUploadBundles"]
                self.assertEqual(bundle["events"][0]["name"], event_name)

    def test_irregular_unexpected_key_name_is_hashed_instead_of_exported(self):
        receipt = module.inspect(
            log(
                event_name="ai_request",
                params=[
                    ("secret@email key", "string_value", "sensitive-val"),
                ],
            )
        )
        self.assertEqual(len(receipt["unexpectedParameterKeys"]), 1)
        self.assertTrue(receipt["unexpectedParameterKeys"][0].startswith("key-sha256:"))
        self.assertNotIn("secret@email", str(receipt))
        self.assertNotIn("sensitive-val", str(receipt))


if __name__ == "__main__":
    unittest.main()
