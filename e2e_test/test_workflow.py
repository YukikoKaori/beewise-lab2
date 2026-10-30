"""Parent request, group chat and consultant-mediated onboarding scenarios."""

from __future__ import annotations

import os

from conftest import require


async def test_tc18_submit_connection_request_creates_chat(run_flow):
    """TC-18; signed-in parent submits the Lab 2 connection request."""
    tutor_name = os.environ.get("BEEWISE_TEST_TUTOR_NAME")
    assert tutor_name, "Set BEEWISE_TEST_TUTOR_NAME to a real active Firebase tutor."
    observed = await run_flow(
        case_id="TC-18",
        start=f"Signed in on the connection form for real tutor {tutor_name!r}; Firestore is available.",
        steps=(
            "Fill the visible learning goal, area and schedule with designated "
            "non-personal test values, then submit once. Wait for the app to "
            "confirm success and open the newly created group chat. Verify the "
            "tutor context, the system request message and that no duplicate "
            "chat was shown. Do not submit private contact data."
        ),
        expected=(
            '{"request_submitted":true,"group_chat_visible":true,'
            '"system_request_message_visible":true,"tutor_name":"configured exact name"}'
        ),
    )
    assert require(observed, "request_submitted", bool)
    assert require(observed, "group_chat_visible", bool)
    assert require(observed, "system_request_message_visible", bool)
    assert require(observed, "tutor_name", str) == tutor_name


async def test_tc19_parent_message_appears_in_consultant_chat(run_flow):
    """TC-19; parent sends text to a real consultant-onboarded chat."""
    observed = await run_flow(
        case_id="TC-19",
        start="Signed in on a staging group chat whose consultant participant is present.",
        steps=(
            "Send the harmless message 'Kiểm tra tin nhắn Lab 3'. Wait for it "
            "to appear once in the chat. Verify it is labeled as a parent text "
            "message and any consultant/tutor messages have distinct role labels."
        ),
        expected=(
            '{"sent_message_visible":true,"sender_role":"parent",'
            '"message_kind":"text","participant_roles":[string]}'
        ),
    )
    assert require(observed, "sent_message_visible", bool)
    assert require(observed, "sender_role", str).lower() == "parent"
    assert require(observed, "message_kind", str).lower() == "text"
    assert require(observed, "participant_roles", list)


async def test_tc20_accept_consultant_trial_proposal(run_flow):
    """TC-20; parent accepts a real consultant-authored trial proposal."""
    observed = await run_flow(
        case_id="TC-20",
        start="Signed in on a staging group chat with a pending consultant-authored trial proposal.",
        steps=(
            "Open the pending trial proposal, review its visible date and time, "
            "and accept it. Verify the response confirmation appears in the chat "
            "and the app did not create an invoice or mark payment as complete."
        ),
        expected=(
            '{"trial_proposal_visible":true,"accepted_response_visible":true,'
            '"invoice_status":"none|pending","payment_verified":false}'
        ),
    )
    assert require(observed, "trial_proposal_visible", bool)
    assert require(observed, "accepted_response_visible", bool)
    assert observed.get("invoice_status") in {"none", "pending"}
    assert require(observed, "payment_verified", bool) is False


async def test_tc21_request_alternate_trial_time(run_flow):
    """TC-21; alternate branch of the real consultant trial proposal."""
    observed = await run_flow(
        case_id="TC-21",
        start="Signed in on a staging group chat with a pending trial proposal and alternate-time response enabled.",
        steps=(
            "Choose the alternate-time action and enter the designated "
            "non-personal test time 'Thứ bảy 09:00'. Submit it. Verify the "
            "alternate-time response is visible and the proposal remains "
            "awaiting consultant handling."
        ),
        expected=(
            '{"alternate_time_response_visible":true,"submitted_time":"Thứ bảy 09:00",'
            '"consultant_follow_up_pending":true}'
        ),
    )
    assert require(observed, "alternate_time_response_visible", bool)
    assert require(observed, "submitted_time", str) == "Thứ bảy 09:00"
    assert require(observed, "consultant_follow_up_pending", bool)


async def test_tc22_request_class_revision_adjustment(run_flow):
    """TC-22; adjustment branch of a real consultant-authored class revision."""
    observed = await run_flow(
        case_id="TC-22",
        start="Signed in on a staging group chat with a pending class revision.",
        steps=(
            "Open the class revision, choose request changes and enter the "
            "non-personal reason 'Xin đổi khung giờ học'. Submit. Verify the "
            "parent response is visible and no payment or official schedule is created."
        ),
        expected=(
            '{"class_revision_visible":true,"adjustment_response_visible":true,'
            '"payment_created_by_client":false,"official_schedule_visible":false}'
        ),
    )
    assert require(observed, "class_revision_visible", bool)
    assert require(observed, "adjustment_response_visible", bool)
    assert require(observed, "payment_created_by_client", bool) is False
    assert require(observed, "official_schedule_visible", bool) is False


async def test_tc23_confirm_class_revision_waits_for_backend_invoice(run_flow):
    """TC-23; accept a consultant revision, with invoice issuance server-owned."""
    observed = await run_flow(
        case_id="TC-23",
        start="Signed in on a staging group chat with a pending class revision and no invoice.",
        steps=(
            "Review the class details and confirm the revision. Verify the "
            "confirmation is recorded, but the client does not create an invoice, "
            "claim payment is verified or show an official schedule before the "
            "trusted backend posts those records."
        ),
        expected=(
            '{"class_confirmation_visible":true,"invoice_status":"none|pending",'
            '"payment_verified":false,"official_schedule_visible":false}'
        ),
    )
    assert require(observed, "class_confirmation_visible", bool)
    assert observed.get("invoice_status") in {"none", "pending"}
    assert require(observed, "payment_verified", bool) is False
    assert require(observed, "official_schedule_visible", bool) is False


async def test_tc24_payment_and_schedule_are_not_fabricated(run_flow):
    """TC-24; trust-boundary error path; account has no server-issued invoice/class."""
    observed = await run_flow(
        case_id="TC-24",
        start="Signed in to the staging Firebase project; this test account has no invoice or verified class.",
        steps=(
            "Open the payment and schedule areas from the visible app flow. "
            "Verify no payment is shown as successful and no official schedule "
            "is exposed without a server-issued invoice and verified payment. "
            "Report any blocked/error message and its recovery."
        ),
        expected=(
            '{"paid_claim_visible":false,"official_schedule_visible":false,'
            '"trust_boundary_message_visible":boolean,"recovery_visible":boolean}'
        ),
    )
    assert require(observed, "paid_claim_visible", bool) is False
    assert require(observed, "official_schedule_visible", bool) is False
    assert require(observed, "trust_boundary_message_visible", bool)
    assert require(observed, "recovery_visible", bool)
