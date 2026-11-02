"""Offline regression checks for ARTEMIS report normalization; no device/API calls."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "e2e_test"))

from conftest import _decode_observation, _trace_has_rate_limit, require  # noqa: E402


NAVIGATION = ["Trang chủ", "Tìm gia sư", "Ghép AI", "Tin nhắn", "Tài khoản"]
TC01_EXPECTED = {
    "screen": "Home",
    "tabs": NAVIGATION,
    "firebase_notice_visible": False,
    "tutor_card_count": 0,
    "profiles_fabricated": False,
}
TC09_EXPECTED = {
    "visible_destinations": NAVIGATION,
    "overflow_seen": False,
    "crash_dialog_seen": False,
}


def check_tc01_report_shapes() -> None:
    reports = [
        "Home title: BeeWise. Visible top-level destinations: "
        "Trang chủ, Tìm gia sư, Ghép AI, Tin nhắn, Tài khoản. "
        "Firebase setup/error notice: none. Number of tutor cards: 0. "
        "Confirmed no fabricated profile claims (0 tutor cards present).",
        {
            "home_title": "BeeWise",
            "visible_top_level_destinations": NAVIGATION,
            "firebase_notice": None,
            "number_of_tutor_cards": 0,
            "verified_firestore_result_confirmation": (
                "No tutor cards are displayed; zero fabricated profile claims."
            ),
        },
        {
            "app_bar_ title": "BeeWise",
            "top_level_destinations": NAVIGATION,
            "firebase_setup_or_error_notice": None,
            "number_of_tutor_cards": 0,
            "profiles_fabricated": False,
        },
        "The BeeWise app is open on the Home screen.\\n"
        '- App-bar title: "BeeWise"\\n'
        "- Visible top-level destinations: Trang chủ, Tìm gia sư, Ghép AI, "
        "Tin nhắn, Tài khoản\\n"
        '- Firebase setup/error notice: None (shows "Chưa có gia sư phù hợp")\\n'
        "- Number of tutor cards: 0\\n"
        "- Firestore results / fabricated profile claims: 0 visible tutor cards, "
        "hence no fabricated profile claims.",
    ]
    for report in reports:
        assert _decode_observation(report) == TC01_EXPECTED

    invalid_reports = [
        {"app_bar_title": "BeeWise", "top_level_destinations": NAVIGATION,
         "number_of_tutor_cards": 0, "real_firestore_confirmation": True},
        {"app_bar_title": "BeeWise", "top_level_destinations": NAVIGATION,
         "firebase_notice": None, "number_of_tutor_cards": 1,
         "fabricated_profile_claims": True},
        {"app_bar_title": "BeeWise", "top_level_destinations": NAVIGATION,
         "firebase_notice": None, "number_of_tutor_cards": 0},
        {"home_title": "BeeWise", "tabs": NAVIGATION, "firebase_notice": None,
         "number_of_tutor_cards": 0, "real_firestore_confirmation": True},
        {"home_title": "BeeWise", "tabs": NAVIGATION, "firebase_notice": None,
         "number_of_tutor_cards": 0, "real_firestore_confirmation": True,
         "profiles_fabricated": True},
        {"home_title": "BeeWise", "tabs": NAVIGATION, "firebase_notice": None,
         "number_of_tutor_cards": 0, "profiles_fabricated": False,
         "fabrication_check": "Fabricated profiles are present."},
        {"home_title": "BeeWise", "tabs": NAVIGATION, "firebase_notice": None,
         "number_of_tutor_cards": False, "profiles_fabricated": False},
    ]
    for report in invalid_reports:
        try:
            _decode_observation(report)
        except AssertionError:
            continue
        raise AssertionError(f"Unsafe TC-01 report was accepted: {report!r}")


def check_tc09_report_shapes() -> None:
    reports = [
        {
            "destinations": [
                {"name": name, "title_visible": True,
                 "overflow_seen": False, "crash_dialog_seen": False}
                for name in NAVIGATION
            ]
        },
    ]
    for report in reports:
        assert _decode_observation(report) == TC09_EXPECTED

    issue_report = {
        "destinations": [
            {"name": name, "title_visible": True,
             "overflow_seen": name == NAVIGATION[0],
             "crash_dialog_seen": False}
            for name in NAVIGATION
        ]
    }
    normalized = _decode_observation(issue_report)
    assert normalized["overflow_seen"] is True
    assert normalized["crash_dialog_seen"] is False

    incomplete_reports = [
        {"destinations": NAVIGATION},
        {"destinations": NAVIGATION, "overflow": False},
        {"destinations": [{"name": NAVIGATION[0], "title_visible": True}]},
        {"destinations": [
            {"name": name, "title_visible": True,
             "overflow_seen": False, "crash_dialog_seen": False}
            for name in NAVIGATION[::-1]
        ]},
        {"destinations": [
            {"name": name, "title_visible": True,
             "overflow_seen": False, "crash_dialog_seen": False}
            for name in [NAVIGATION[0], *NAVIGATION]
        ]},
        {"destinations": [
            {"name": name, "title_visible": True,
             "overflow_seen": False, "crash_dialog_seen": False}
            for name in [*NAVIGATION[:-1], NAVIGATION[0]]
        ]},
        {"destinations": [
            {"name": name, "title_visible": name != NAVIGATION[1],
             "overflow_seen": False, "crash_dialog_seen": False}
            for name in NAVIGATION
        ]},
        {"destinations": [
            {"name": name, "title_visible": True,
             "overflow_seen": False, "crash_dialog_seen": False}
            for name in NAVIGATION
        ][:4]},
        {"destinations": [
            {"name": name, "title_visible": True,
             "overflow_seen": False}
            for name in NAVIGATION
        ]},
        {"destinations": NAVIGATION, "overflow": False, "crash": False},
    ]
    for report in incomplete_reports:
        try:
            _decode_observation(report)
        except AssertionError:
            continue
        raise AssertionError(f"Incomplete TC-09 report was accepted: {report!r}")


def check_strict_integer_types() -> None:
    assert require({"count": 3}, "count", int) == 3
    for invalid in (True, False, 3.0, "3", None):
        try:
            require({"count": invalid}, "count", int)
        except AssertionError:
            continue
        raise AssertionError(f"Invalid integer observation was accepted: {invalid!r}")


def check_structured_quota_detection() -> None:
    assert _trace_has_rate_limit({"steps": [{"generic_tools": [{
        "type": "llm_call", "status": "retrying",
        "payload": {"error": "ClientError: 429 Too Many Requests; RESOURCE_EXHAUSTED"},
    }]}]})
    assert _trace_has_rate_limit({"error": {"code": 429, "message": "quota exceeded"}})
    for trace in (
        {"error": {"status": 429, "message": "Too Many Requests"}},
        {"error": {"code": "429", "message": "rate limit exceeded"}},
        {"result": {"error": {"status": "429"}}},
        {"exception": {"response": {"status_code": "429"}}},
        {"error": {"status": "RESOURCE_EXHAUSTED"}},
        {"exception": "Gemini quota exceeded for metric generate_content"},
    ):
        assert _trace_has_rate_limit(trace), trace
    false_positives = [
        {"prompt": "No 429 or rate limit occurred during the previous run."},
        {"prompt": "429"},
        {"narrative": "The report mentions RESOURCE_EXHAUSTED as an example only."},
        {"steps": [{"action_taken": {"args": {"text": "quota exceeded in an old log"}}}]},
        {"error": "No 429 or rate limit occurred."},
        {"error": "No 429 occurred; previous rate limit has cleared."},
        {"error": {"status": 500, "message": "server error"}},
    ]
    for trace in false_positives:
        assert not _trace_has_rate_limit(trace), trace

    # The runner must only stop when a parsed trace has structured quota evidence.
    assert _trace_has_rate_limit({"error": {"status": 429}})
    assert not _trace_has_rate_limit({"error": "No 429 occurred."})


if __name__ == "__main__":
    check_tc01_report_shapes()
    check_tc09_report_shapes()
    check_strict_integer_types()
    check_structured_quota_detection()
    print("PASS: TC-01/TC-09, integer types and structured quota guards.")
