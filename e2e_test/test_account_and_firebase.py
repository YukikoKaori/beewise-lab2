"""Account, native-device and Firebase demo-area ARTEMIS checks."""

from __future__ import annotations

import os

import pytest

from conftest import require


async def test_tc07_google_sign_in_native_picker_and_return(run_flow):
    """TC-07; authentication; dedicated test account is available in Google picker."""
    email = os.environ.get("BEEWISE_TEST_ACCOUNT_EMAIL")
    assert email, "Set BEEWISE_TEST_ACCOUNT_EMAIL for the dedicated test account."
    observed = await run_flow(
        case_id="TC-07",
        start="BeeWise is signed out on Login; the dedicated test Google account is available.",
        steps=(
            "Tap Continue with Google. Select the dedicated test account whose "
            f"address is {email!r} in the native account picker. Confirm the "
            "app returns to its signed-in Home state. Do not select any other account."
        ),
        expected=(
            '{"native_account_picker_seen":true,"selected_test_account":true,'
            '"signed_in_home_visible":true,"error_message_visible":false}'
        ),
    )
    assert require(observed, "native_account_picker_seen", bool)
    assert require(observed, "selected_test_account", bool)
    assert require(observed, "signed_in_home_visible", bool)
    assert require(observed, "error_message_visible", bool) is False


async def test_tc08_registration_validation_does_not_create_account(run_flow):
    """TC-08; registration validation; signed out, do not submit real personal data."""
    observed = await run_flow(
        case_id="TC-08",
        start="BeeWise is signed out on Register with all fields blank.",
        steps=(
            "Tap the create-account action while leaving all fields blank and "
            "required consent unchecked. Verify required-field or consent errors "
            "are visible and registration does not succeed. Do not enter or submit data."
        ),
        expected=(
            '{"register_screen_visible":true,"validation_errors_visible":true,'
            '"registration_succeeded":false}'
        ),
    )
    assert require(observed, "register_screen_visible", bool)
    assert require(observed, "validation_errors_visible", bool)
    assert require(observed, "registration_succeeded", bool) is False


async def test_tc09_all_top_level_destinations_are_reachable(run_flow):
    """TC-09; primary navigation; signed-out app on Home."""
    observed = await run_flow(
        case_id="TC-09",
        start="BeeWise is signed out on Home with the bottom navigation visible.",
        steps=(
            "Open each bottom destination in order: Trang chủ, Tìm gia sư, Ghép "
            "AI, Tin nhắn, Tài khoản. Report each destination only after its "
            "screen title is visible; also report whether any overflow or crash appeared."
        ),
        expected=(
            '{"visible_destinations":[string],"overflow_seen":false,'
            '"crash_dialog_seen":false}'
        ),
    )
    destinations = require(observed, "visible_destinations", list)
    assert set(destinations) >= {"Trang chủ", "Tìm gia sư", "Ghép AI", "Tin nhắn", "Tài khoản"}
    assert require(observed, "overflow_seen", bool) is False
    assert require(observed, "crash_dialog_seen", bool) is False


@pytest.mark.manual_setup
async def test_tc10_notification_permission_and_message_open(run_flow):
    """TC-10; native FCM interaction; operator has sent a test push to this device."""
    message = os.environ.get("BEEWISE_TEST_PUSH_TITLE", "BeeWise test notification")
    observed = await run_flow(
        case_id="TC-10",
        start=(
            "BeeWise is installed on Android 13+; a Firebase test push with title "
            f"{message!r} was sent to this device's FCM token."
        ),
        steps=(
            "If Android notification permission is requested, allow it. Receive "
            "the configured test message while BeeWise is foregrounded, then "
            "open the in-app notification center. Verify the exact title appears "
            "and opens its safe destination."
        ),
        expected=(
            '{"native_permission_prompt_seen":boolean,"push_title_visible":true,'
            '"notification_center_entry_visible":true,"opened_destination":string}'
        ),
    )
    assert require(observed, "native_permission_prompt_seen", bool) in {True, False}
    assert require(observed, "push_title_visible", bool)
    assert require(observed, "notification_center_entry_visible", bool)
    assert require(observed, "opened_destination", str).startswith("/")


@pytest.mark.manual_setup
async def test_tc14_background_notification_is_listed(run_flow):
    """TC-14; background FCM state; a distinct test push has been sent."""
    message = os.environ.get("BEEWISE_TEST_PUSH_BACKGROUND_TITLE", "BeeWise background test")
    observed = await run_flow(
        case_id="TC-14",
        start=(
            "BeeWise is signed in. A Firebase test push with title "
            f"{message!r} has been sent while the app was in the background."
        ),
        steps=(
            "Bring BeeWise to the foreground after the test notification arrived. "
            "Open the in-app notification center and verify the exact test title "
            "and one relevant destination are present."
        ),
        expected=(
            '{"push_title":"configured title","notification_center_entry_visible":true,'
            '"opened_destination":string}'
        ),
    )
    assert require(observed, "push_title", str) == message
    assert require(observed, "notification_center_entry_visible", bool)
    assert require(observed, "opened_destination", str).startswith("/")


@pytest.mark.manual_setup
async def test_tc15_terminated_notification_reopens_route(run_flow):
    """TC-15; terminated FCM state; a distinct test push has been sent."""
    message = os.environ.get("BEEWISE_TEST_PUSH_TERMINATED_TITLE", "BeeWise terminated test")
    observed = await run_flow(
        case_id="TC-15",
        start=(
            "BeeWise is signed in, then removed from the foreground without "
            "force-stopping. A Firebase test push "
            f"with title {message!r} has been sent to the device."
        ),
        steps=(
            "Tap the test notification from Android's notification shade. Verify "
            "BeeWise cold-starts, the exact notification title is listed in the "
            "notification center, and the safe destination from its route opens."
        ),
        expected=(
            '{"push_title":"configured title","cold_start_completed":true,'
            '"notification_center_entry_visible":true,"opened_destination":string}'
        ),
    )
    assert require(observed, "push_title", str) == message
    assert require(observed, "cold_start_completed", bool)
    assert require(observed, "notification_center_entry_visible", bool)
    assert require(observed, "opened_destination", str).startswith("/")


async def test_tc11_pdf_export_upload_progress_and_private_path(run_flow):
    """TC-11; file export/upload; signed in and viewing a real active tutor."""
    tutor_name = os.environ.get("BEEWISE_TEST_TUTOR_NAME")
    assert tutor_name, "Set BEEWISE_TEST_TUTOR_NAME to a real active Firebase tutor."
    observed = await run_flow(
        case_id="TC-11",
        start="BeeWise is signed in on the real tutor profile with Cloud Storage enabled.",
        steps=(
            f"On the profile for {tutor_name!r}, export the tutor summary PDF and "
            "upload it. Wait for completion. Report the visible tutor name, "
            "whether progress reached completion, the storage path, and whether "
            "a download URL is displayed. Do not fabricate a URL."
        ),
        expected=(
            '{"tutor_name":"configured exact name","progress_complete":true,'
            '"storage_path":"reports/<own-uid>/<pdf-file>","download_url_visible":true}'
        ),
    )
    assert require(observed, "tutor_name", str) == tutor_name
    assert require(observed, "progress_complete", bool)
    assert require(observed, "storage_path", str).startswith("reports/")
    assert observed["storage_path"].lower().endswith(".pdf")
    assert require(observed, "download_url_visible", bool)


async def test_tc12_remote_config_and_crashlytics_demo_area(run_flow):
    """TC-12; profile Firebase demo area; Firebase features are enabled."""
    observed = await run_flow(
        case_id="TC-12",
        start="BeeWise is signed in on Tài khoản with Remote Config and Crashlytics enabled.",
        steps=(
            "Read the two visible Remote Config values that affect app behavior "
            "and locate the Crashlytics non-fatal and deliberate fatal-test "
            "actions. Do not trigger either action in this inspection case. "
            "Report labels and current values."
        ),
        expected=(
            '{"visible_remote_config_values":{"ai_result_limit":integer,'
            '"ai_matching_enabled":boolean},"crashlytics_nonfatal_action_visible":true,'
            '"fatal_test_action_visible":true}'
        ),
    )
    values = require(observed, "visible_remote_config_values", dict)
    assert isinstance(values.get("ai_result_limit"), int)
    assert isinstance(values.get("ai_matching_enabled"), bool)
    assert require(observed, "crashlytics_nonfatal_action_visible", bool)
    assert require(observed, "fatal_test_action_visible", bool)


async def test_tc13_sign_out_clears_local_account_and_returns_to_guest(run_flow):
    """TC-13; sign-out; signed in with the dedicated test account on Profile."""
    observed = await run_flow(
        case_id="TC-13",
        start="BeeWise is signed in with the dedicated test account on Tài khoản.",
        steps=(
            "Tap sign out and wait for completion. Verify the account is signed "
            "out, private chats are no longer shown, and the guest Home state "
            "appears without a crash or stale account details."
        ),
        expected=(
            '{"signed_out":true,"guest_home_visible":true,'
            '"private_chats_visible":false,"stale_account_details_visible":false}'
        ),
    )
    assert require(observed, "signed_out", bool)
    assert require(observed, "guest_home_visible", bool)
    assert require(observed, "private_chats_visible", bool) is False
    assert require(observed, "stale_account_details_visible", bool) is False


async def test_tc16_cancel_google_picker_shows_recoverable_error(run_flow):
    """TC-16; auth error path/native interaction; signed out with Google configured."""
    observed = await run_flow(
        case_id="TC-16",
        start="BeeWise is signed out on Login with Google Sign-In enabled.",
        steps=(
            "Tap Continue with Google, then cancel the native account picker. "
            "Verify a clear cancellation message appears, the app remains usable, "
            "and no account is signed in."
        ),
        expected=(
            '{"native_picker_seen":true,"cancel_message_visible":true,'
            '"signed_in":false,"app_usable":true}'
        ),
    )
    assert require(observed, "native_picker_seen", bool)
    assert require(observed, "cancel_message_visible", bool)
    assert require(observed, "signed_in", bool) is False
    assert require(observed, "app_usable", bool)


async def test_tc17_deliberate_crash_is_reported_and_app_recovers(run_flow):
    """TC-17; Crashlytics fatal test; each run must explicitly relaunch the app."""
    observed = await run_flow(
        case_id="TC-17",
        start="BeeWise is signed in on Tài khoản and Crashlytics is configured.",
        steps=(
            "Tap the clearly labeled Crashlytics test-crash action once. Confirm "
            "BeeWise terminates, then relaunch it. Verify the app opens again "
            "without a crash loop and report the resulting screen."
        ),
        expected=(
            '{"test_crash_action_tapped":true,"app_terminated":true,'
            '"relaunch_succeeded":true,"screen_after_relaunch":string}'
        ),
    )
    assert require(observed, "test_crash_action_tapped", bool)
    assert require(observed, "app_terminated", bool)
    assert require(observed, "relaunch_succeeded", bool)
    assert require(observed, "screen_after_relaunch", str).strip()


@pytest.mark.manual_setup
async def test_tc26_tutor_registration_waits_for_staff_review(run_flow):
    """TC-26; project-added tutor flow; creates an isolated disposable account."""
    assert os.environ.get("BEEWISE_DEDICATED_TEST_PROJECT") == "1", (
        "Authorize only a dedicated test project and have the operator enter "
        "disposable credentials directly on the device, outside model traces."
    )
    observed = await run_flow(
        case_id="TC-26",
        start="Operator has opened the tutor form and entered disposable test credentials directly on the device.",
        steps=(
            "Do not read, repeat, record or change the credential fields. Enter name Lab3 Tutor Test, "
            "phone 0900000000, qualification Bachelor of Mathematics, subjects Toán, "
            "grades Lớp 8, introduction I have experience teaching secondary school "
            "mathematics, fee 300000, area Hà Nội, availability weekday evenings, "
            "select online teaching and consent, then submit. Verify the account is "
            "on the pending-review page, the message says it is not visible to parents, "
            "and parent bottom navigation is absent. Sign out at the end. Do not include "
            "the email or password in your final JSON."
        ),
        expected=(
            '{"pending_review_visible":true,'
            '"not_visible_to_parents_message":true,'
            '"parent_navigation_visible":false,"signed_out_after_test":true}'
        ),
    )
    assert require(observed, "pending_review_visible", bool)
    assert require(observed, "not_visible_to_parents_message", bool)
    assert require(observed, "parent_navigation_visible", bool) is False
    assert require(observed, "signed_out_after_test", bool)
