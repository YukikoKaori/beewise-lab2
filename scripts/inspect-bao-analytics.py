"""Project complete, private multi-process FA-SVC logs into an aliased receipt.

Never writes native payloads, app instance IDs, credentials or raw user IDs.
An absent _id is meaningful only in a complete upload bundle for this package.
Usage: python scripts/inspect-bao-analytics.py PRIVATE_LOG PUBLIC_JSON
"""
import datetime
import hashlib
import json
from pathlib import Path
import re
import sys

PACKAGE = "com.beewise.beewise"
BUSINESS_EVENTS = {
    "login",
    "sign_up",
    "logout",
    "tutor_application_submitted",
    "tutor_application_resubmitted",
    "search",
    "view_tutor",
    "view_detail",
    "ai_request",
    "ai_result_accepted",
    "ai_error",
    "ai_match_success",
    "ai_match_no_results",
    "connection_request_submitted",
    "chat_message_sent",
    "trial_response",
    "class_adjustment_requested",
    "class_revision_confirmed",
    "payment_verification_requested",
    "begin_checkout",
    "payment_status_checked",
    "export_report",
    "upload_report",
}
SAFE_PARAMETERS = {
    "method",
    "account_type",
    "subject_count",
    "file_size_kb",
    "has_subject",
    "has_grade",
    "has_location",
    "result_count",
    "request_type",
    "query_length",
    "filter_count",
    "sort_mode",
    "outcome",
    "entry_source",
    "feature",
    "kind",
    "detail_type",
    "message_type",
    "sender_role",
    "response",
    "storage_backend",
    "result",
    "payment_provider",
    "reused_link",
}
SYSTEM_PARAMETERS = {
    "ga_event_origin(_o)",
    "firebase_event_origin(_o)",
    "_o",
    "ga_screen_class(_sc)",
    "firebase_screen_class(_sc)",
    "_sc",
    "ga_screen_id(_si)",
    "firebase_screen_id(_si)",
    "_si",
    "ga_screen(_sn)",
    "firebase_screen(_sn)",
    "_sn",
    "ga_previous_screen(_psr)",
    "firebase_previous_screen(_psr)",
    "_psr",
    "ga_previous_class(_pc)",
    "firebase_previous_class(_pc)",
    "_pc",
    "ga_previous_id(_pi)",
    "firebase_previous_id(_pi)",
    "_pi",
    "ga_session_id(_sid)",
    "_sid",
    "ga_session_number(_sno)",
    "_sno",
    "session_engaged(_se)",
    "_se",
    "engagement_time_msec(_et)",
    "_et",
    "ga_debug(_dbg)",
    "_dbg",
    "ga_realtime(_r)",
    "_r",
    "ga_conversion(_c)",
    "_c",
    "ga_error(_err)",
    "_err",
    "ga_error_value(_ev)",
    "_ev",
    "ga_error_length(_el)",
    "_el",
    "ga_ignore_referrer(_ir)",
    "_ir",
}
SAFE_VALUE_PATTERN = re.compile(r"[a-z_]{1,24}|\d{1,9}")
SAFE_KEY_NAME_PATTERN = re.compile(r"[A-Za-z0-9_().-]{1,48}")
ROW = re.compile(r"^(\d\d-\d\d \d\d:\d\d:\d\d\.\d+)\s+(\d+)\s+(\d+)\s+\w\s+FA-SVC\s*:\s?(.*)$")


def safe_key_label(key):
    """Return a bounded parameter key name or a hash alias if irregularly formatted."""
    if SAFE_KEY_NAME_PATTERN.fullmatch(key):
        return key
    return "key-sha256:" + hashlib.sha256(key.encode()).hexdigest()[:16]


def children(lines, name):
    """Return complete direct or nested protobuf-text blocks of one type."""
    index = 0
    while index < len(lines):
        if lines[index].strip() != name + " {":
            index += 1
            continue
        end, depth = index + 1, 1
        while end < len(lines) and depth:
            depth += lines[end].count("{") - lines[end].count("}")
            end += 1
        if depth:
            raise ValueError("Incomplete native block; absence is not proof")
        yield lines[index + 1:end - 1]
        index = end


def scalar(lines, key):
    values = [line.strip().split(": ", 1)[1] for line in lines
              if line.strip().startswith(key + ": ")]
    return values[0] if len(values) == 1 else None


def inspect(source):
    rows = [match.groups() for line in source.splitlines()
            if (match := ROW.match(line))]
    bundles, acknowledgements, incomplete = [], [], 0
    unexpected_keys = set()
    unsafe_values_omitted = 0
    successful_uploads = 0
    active_package_upload_threads = set()
    for index, (stamp, pid, tid, message) in enumerate(rows):
        if message.startswith("User property removed: user_id(_id)"):
            acknowledgements.append({"nativeLogTime": stamp, "servicePid": pid})
        if message.startswith("Successful upload.") and (pid, tid) in active_package_upload_threads:
            successful_uploads += 1
            active_package_upload_threads.discard((pid, tid))
        if not message.startswith("Uploading data.") or PACKAGE not in message:
            continue
        active_package_upload_threads.add((pid, tid))
        payload, depth, started, complete = [], 0, False, False
        for _, next_pid, next_tid, text in rows[index + 1:]:
            if (next_pid, next_tid) != (pid, tid):
                continue
            if not started:
                if text.strip() != "batch {":
                    break
                started = True
            payload.append(text)
            depth += text.count("{") - text.count("}")
            if depth == 0:
                complete = True
                break
        if not complete:
            incomplete += 1
            continue
        for bundle in children(payload, "bundle"):
            # Scalar values occur at many nesting levels; only bundle header
            # fields precede its first user_property/event block.
            header = bundle[:next((i for i, x in enumerate(bundle)
                                   if x.strip().endswith("{")), len(bundle))]
            if scalar(header, "app_id") != PACKAGE:
                continue
            identities = [prop for prop in children(bundle, "user_property")
                          if scalar(prop, "name") in ("user_id(_id)", "_id", "user_id")]
            identity_aliases = []
            for prop in identities:
                value = scalar(prop, "string_value")
                if value is not None:
                    identity_aliases.append(value if re.fullmatch(
                        r"uid-sha256:[a-f0-9]{16}", value) else
                        "uid-sha256:" + hashlib.sha256(
                            value.encode()).hexdigest()[:16])
            events = []
            for event in children(bundle, "event"):
                name = scalar(event[:next((i for i, x in enumerate(event)
                                          if x.strip().endswith("{")), len(event))], "name")
                if name not in BUSINESS_EVENTS:
                    continue
                parameters = {}
                event_unexpected = []
                for parameter in children(event, "param"):
                    key = scalar(parameter, "name")
                    if key is None:
                        continue
                    if key in SAFE_PARAMETERS:
                        value = scalar(parameter, "string_value") or scalar(parameter, "int_value")
                        # Approved event categories/numbers only; unknown or
                        # identity-like values are omitted rather than exported.
                        if value is not None:
                            if SAFE_VALUE_PATTERN.fullmatch(value):
                                parameters[key] = value
                            else:
                                unsafe_values_omitted += 1
                    elif key not in SYSTEM_PARAMETERS:
                        label = safe_key_label(key)
                        unexpected_keys.add(label)
                        if label not in event_unexpected:
                            event_unexpected.append(label)
                event_entry = {
                    "name": name,
                    "timestampMillis": scalar(event, "timestamp_millis"),
                    "parameters": parameters,
                }
                if event_unexpected:
                    event_entry["unexpectedParameterKeys"] = sorted(event_unexpected)
                events.append(event_entry)
            if events:
                bundles.append({"nativeUploadLogTime": stamp, "servicePid": pid,
                                "completeBundle": True, "userIdPropertyCount": len(identities),
                                "userIdAliases": identity_aliases, "events": events})
    return {
        "recordedAtUtc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "privateLogSha256": hashlib.sha256(source.encode()).hexdigest(),
        "package": PACKAGE,
        "nativeUserIdRemovalAcknowledgements": acknowledgements,
        "incompleteUploadsIgnored": incomplete,
        "successfulUploadCount": successful_uploads,
        "unexpectedParameterKeys": sorted(unexpected_keys),
        "unsafeParameterValuesOmitted": unsafe_values_omitted,
        "businessEventUploadBundles": bundles,
        "rawIdentityOrPayloadExported": False,
        "limitation": "Native SDK upload payload evidence; DebugView/backend receipt must be correlated separately. An app instance ID is not a Firebase Auth user ID.",
    }


if __name__ == "__main__":
    private_log, output = map(Path, sys.argv[1:3])
    receipt = inspect(private_log.read_text(encoding="utf-8", errors="replace"))
    receipt["privateLogSha256"] = hashlib.sha256(private_log.read_bytes()).hexdigest()
    output.write_bytes((json.dumps(receipt, indent=2) + "\n").encode())
    print(json.dumps({
        "completeBusinessBundles": len(receipt["businessEventUploadBundles"]),
        "removalAcknowledgements": len(receipt["nativeUserIdRemovalAcknowledgements"]),
        "incompleteUploadsIgnored": receipt["incompleteUploadsIgnored"],
        "successfulUploadCount": receipt["successfulUploadCount"],
        "unexpectedParameterKeys": receipt["unexpectedParameterKeys"],
        "unsafeParameterValuesOmitted": receipt["unsafeParameterValuesOmitted"],
    }))
