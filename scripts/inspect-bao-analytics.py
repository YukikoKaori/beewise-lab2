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
    "login", "logout", "search", "view_tutor", "ai_match_no_results",
    "sign_up", "export_report",
}
SAFE_PARAMETERS = {
    "method", "account_type", "subject_count", "file_size_kb", "has_subject",
    "has_grade", "has_location", "result_count", "request_type",
    "query_length", "filter_count", "sort_mode", "outcome", "entry_source",
}
ROW = re.compile(r"^(\d\d-\d\d \d\d:\d\d:\d\d\.\d+)\s+(\d+)\s+(\d+)\s+\w\s+FA-SVC\s*:\s?(.*)$")


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
    for index, (stamp, pid, tid, message) in enumerate(rows):
        if message.startswith("User property removed: user_id(_id)"):
            acknowledgements.append({"nativeLogTime": stamp, "servicePid": pid})
        if not message.startswith("Uploading data.") or PACKAGE not in message:
            continue
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
                for parameter in children(event, "param"):
                    key = scalar(parameter, "name")
                    if key in SAFE_PARAMETERS:
                        value = scalar(parameter, "string_value") or scalar(parameter, "int_value")
                        # Approved event categories/numbers only; unknown or
                        # identity-like values are omitted rather than exported.
                        if value is not None and re.fullmatch(r"[a-z_]{1,24}|\d{1,9}", value):
                            parameters[key] = value
                events.append({"name": name, "timestampMillis": scalar(event, "timestamp_millis"),
                               "parameters": parameters})
            if events:
                bundles.append({"nativeUploadLogTime": stamp, "servicePid": pid,
                                "completeBundle": True, "userIdPropertyCount": len(identities),
                                "userIdAliases": identity_aliases, "events": events})
    return {"recordedAtUtc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "privateLogSha256": hashlib.sha256(source.encode()).hexdigest(),
            "package": PACKAGE, "nativeUserIdRemovalAcknowledgements": acknowledgements,
            "incompleteUploadsIgnored": incomplete, "businessEventUploadBundles": bundles,
            "rawIdentityOrPayloadExported": False,
            "limitation": "Native SDK upload payload evidence; DebugView/backend receipt must be correlated separately. An app instance ID is not a Firebase Auth user ID."}


if __name__ == "__main__":
    private_log, output = map(Path, sys.argv[1:3])
    receipt = inspect(private_log.read_text(encoding="utf-8", errors="replace"))
    receipt["privateLogSha256"] = hashlib.sha256(private_log.read_bytes()).hexdigest()
    output.write_bytes((json.dumps(receipt, indent=2) + "\n").encode())
    print(json.dumps({"completeBusinessBundles": len(receipt["businessEventUploadBundles"]),
                      "removalAcknowledgements": len(receipt["nativeUserIdRemovalAcknowledgements"]),
                      "incompleteUploadsIgnored": receipt["incompleteUploadsIgnored"]}))
