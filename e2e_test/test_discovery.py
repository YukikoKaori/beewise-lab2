"""Independent discovery and Lab 2 flow checks driven by ARTEMIS."""

from __future__ import annotations

import os

from conftest import require


async def test_tc01_guest_home_reports_real_visible_state(run_flow):
    """TC-01; Home; clean install, signed out, Firebase project configured."""
    observed = await run_flow(
        case_id="TC-01",
        start="BeeWise is installed and signed out on Home.",
        steps=(
            "Open BeeWise. Read the Home title, visible top-level destinations, "
            "any Firebase setup/error notice, and the number of tutor cards. "
            "Confirm whether every visible tutor card came from a visible real "
            "Firestore result; report no fabricated profile claims."
        ),
        expected=(
            '{"screen":"Home","tabs":["Trang chủ","Tìm gia sư","Ghép AI",'
            '"Tin nhắn","Tài khoản"],"tutor_card_count":integer,'
            '"firebase_notice_visible":boolean,"profiles_fabricated":false}'
        ),
    )
    assert require(observed, "screen", str).lower() == "home"
    tabs = require(observed, "tabs", list)
    assert {"Trang chủ", "Tìm gia sư", "Ghép AI", "Tin nhắn", "Tài khoản"}.issubset(
        set(tabs)
    )
    assert require(observed, "tutor_card_count", int) >= 0
    assert require(observed, "profiles_fabricated", bool) is False


async def test_tc02_search_returns_visible_catalog_state(run_flow):
    """TC-02; Search; Firebase is configured with the real tutor catalog."""
    query = os.environ.get("BEEWISE_SEARCH_TERM", "Toán")
    observed = await run_flow(
        case_id="TC-02",
        start="BeeWise is signed out on Home and Firebase has an active tutor catalog.",
        steps=(
            f"Open Tìm gia sư, search for {query!r}, and report the visible result "
            "count, the tutor names shown in the results, and whether a loading, empty, "
            "or error message is visible. Also inspect the ARTEMIS-captured Android "
            "Logcat for the Firebase Analytics search event and report its exact "
            "event name and result_count parameter. Do not infer off-screen records."
        ),
        expected=(
            '{"screen":"Tìm gia sư","query":"configured term",'
            '"result_count":integer,"visible_tutor_names":[string],'
            '"state":"data|empty|error|loading",'
            '"analytics_event_name":"search","analytics_result_count":integer}'
        ),
    )
    assert require(observed, "screen", str).lower() in {"tìm gia sư", "search"}
    assert require(observed, "result_count", int) >= 0
    assert require(observed, "query", str) == query
    names = require(observed, "visible_tutor_names", list)
    assert bool(names) == (observed["result_count"] > 0)
    assert observed.get("state") in {"data", "empty", "error", "loading"}
    assert require(observed, "analytics_event_name", str) == "search"
    assert require(observed, "analytics_result_count", int) == observed["result_count"]


async def test_tc03_search_no_match_shows_recoverable_empty_state(run_flow):
    """TC-03; Search error path; configured query has no catalog matches."""
    query = os.environ.get("BEEWISE_NO_RESULT_TERM", "zz-no-tutor-match-393-2026")
    observed = await run_flow(
        case_id="TC-03",
        start="BeeWise is on Tìm gia sư with Firebase available and the test term has no match.",
        steps=(
            f"Search for {query!r}. Wait for completion. Verify the empty-state "
            "message and a retry or clear-search recovery action; report both."
        ),
        expected=(
            '{"result_count":0,"empty_state_visible":true,'
            '"recovery_action_visible":true,"message":string}'
        ),
    )
    assert require(observed, "result_count", int) == 0
    assert require(observed, "empty_state_visible", bool)
    assert require(observed, "recovery_action_visible", bool)
    assert require(observed, "message", str).strip()


async def test_tc04_tutor_detail_matches_selected_real_tutor(run_flow):
    """TC-04; Tutor detail; the configured active tutor is visible in search."""
    tutor_name = os.environ.get("BEEWISE_TEST_TUTOR_NAME")
    assert tutor_name, "Set BEEWISE_TEST_TUTOR_NAME to a real active Firebase tutor."
    observed = await run_flow(
        case_id="TC-04",
        start="BeeWise is signed out on Tìm gia sư; the named active tutor is in the real catalog.",
        steps=(
            f"Find and open the tutor named {tutor_name!r}. Verify the profile "
            "name exactly, visible subject and fee details, and the connection "
            "action. Report only values visible on the screen."
        ),
        expected=(
            '{"screen":"Tutor profile","tutor_name":"configured exact name",'
            '"subjects":[string],"hourly_fee_visible":true,'
            '"connection_action_visible":true}'
        ),
    )
    assert require(observed, "screen", str).lower() in {"tutor profile", "hồ sơ gia sư"}
    assert require(observed, "tutor_name", str) == tutor_name
    assert require(observed, "subjects", list)
    assert require(observed, "hourly_fee_visible", bool)
    assert require(observed, "connection_action_visible", bool)


async def test_tc05_ai_match_uses_active_catalog_and_offers_manual_fallback(run_flow):
    """TC-05; AI matching; Firebase AI Logic and active tutor records are enabled."""
    observed = await run_flow(
        case_id="TC-05",
        start="BeeWise is signed out on Ghép AI; Firebase AI Logic and real tutor data are available.",
        steps=(
            "Describe a non-identifying need: grade 8 algebra, online twice a "
            "week, budget 250000 VND per hour. Submit once. Report the visible "
            "result names/count, whether an error or no-match state appeared, "
            "and whether manual search recovery is visible. Do not invent a match."
        ),
        expected=(
            '{"result_count":integer,"visible_tutor_names":[string],'
            '"state":"results|empty|error","manual_search_recovery_visible":boolean}'
        ),
    )
    count = require(observed, "result_count", int)
    names = require(observed, "visible_tutor_names", list)
    assert len(names) == count
    assert observed.get("state") in {"results", "empty", "error"}
    if count == 0:
        assert require(observed, "manual_search_recovery_visible", bool)


async def test_tc06_connection_gate_preserves_tutor_after_auth_navigation(run_flow):
    """TC-06; Discover/connect flow; signed out with a real tutor selected."""
    tutor_name = os.environ.get("BEEWISE_TEST_TUTOR_NAME")
    assert tutor_name, "Set BEEWISE_TEST_TUTOR_NAME to a real active Firebase tutor."
    observed = await run_flow(
        case_id="TC-06",
        start="BeeWise is signed out on the profile of the named real tutor.",
        steps=(
            "Tap the connection action. Verify the authentication gate opens. "
            "Open registration and then return to login without submitting any "
            "personal data. Verify the pending tutor context is still the same "
            "named tutor and no connection request was created."
        ),
        expected=(
            '{"authentication_gate_visible":true,"login_screen_visible":true,'
            '"pending_tutor_name":"configured exact name",'
            '"connection_request_created":false}'
        ),
    )
    assert require(observed, "authentication_gate_visible", bool)
    assert require(observed, "login_screen_visible", bool)
    assert require(observed, "pending_tutor_name", str) == tutor_name
    assert require(observed, "connection_request_created", bool) is False
