"""PRM393 Final ARTEMIS executable E2E flows covering Final additions and updated routes."""

from __future__ import annotations

import os
import re

import pytest

from conftest import require


async def test_final_f01_discovery_search_filters_and_tutor_profile(run_flow):
    """FINAL-F01; Lab 2 Screens 01, 03, 04; Home -> /search -> filters -> /tutors/:id."""
    query = os.environ.get("BEEWISE_SEARCH_TERM", "Toán")
    tutor_name = os.environ.get("BEEWISE_TEST_TUTOR_NAME", "")
    observed = await run_flow(
        case_id="FINAL-F01",
        start=(
            "BeeWise is on /home with a real active catalog tutor matching the search "
            "and selected filter. This profile-inspection scenario does not allow empty recovery."
        ),
        steps=(
            f"From Trang chủ, open Tìm gia sư, enter {query!r}, and apply at least one visible "
            "filter chip/option (subject/mode/sort). Wait for real Firestore results to load. "
            "Read the displayed result count and open a real tutor card (preferring "
            f"{tutor_name!r} if configured), open its profile and verify subject/hourly fee "
            "and the Gửi yêu cầu kết nối action on the profile itself. Quote the actual fee "
            "value and CTA from that screen, not from the search card. Report any search or "
            "profile error even if other steps succeeded; never infer a missing observation."
        ),
        expected=(
            '{"screen":"Tìm gia sư","query":"configured term","filter_applied":true,'
            '"result_count":integer,"search_count_text":string,'
            '"state":"data|empty|error","error_observed":boolean,'
            '"profile_opened":boolean,"hourly_fee_visible":boolean,'
            '"connection_action_visible":boolean,"terminal_screen":"tutor_profile",'
            '"profile_hourly_fee_text":string,"profile_connection_cta_text":string,'
            '"profiles_fabricated":false}'
        ),
    )
    assert require(observed, "screen", str).lower() in {"tìm gia sư", "search"}
    assert require(observed, "query", str).strip().casefold() == query.strip().casefold()
    assert require(observed, "filter_applied", bool)
    count = require(observed, "result_count", int)
    assert require(observed, "error_observed", bool) is False
    assert require(observed, "state", str) == "data" and count > 0, (
        "FINAL-F01 requires a matching catalog tutor; empty recovery is not in scope."
    )
    assert require(observed, "search_count_text", str) == f"{count} gia sư phù hợp"
    assert require(observed, "profiles_fabricated", bool) is False
    assert require(observed, "profile_opened", bool)
    assert require(observed, "hourly_fee_visible", bool)
    assert require(observed, "connection_action_visible", bool)
    assert require(observed, "terminal_screen", str) == "tutor_profile"
    assert re.fullmatch(r"[0-9][0-9., ]*\s*đ/giờ", require(
        observed, "profile_hourly_fee_text", str
    ).strip()), "Expected the actual hourly fee from the profile."
    assert require(observed, "profile_connection_cta_text", str) == "Gửi yêu cầu kết nối"


@pytest.mark.manual_setup
async def test_final_f02a_ai_level2_confirm_and_edit_flow(run_flow):
    """FINAL-F02a; Final A1 / Lab 2 Screens 02 & 02c; /matching ConfirmTutorNeedScreen."""
    prompt = os.environ.get(
        "BEEWISE_FINAL_AI_PROMPT",
        "Tìm gia sư Toán lớp 9 ở Thủ Đức, học phí dưới 200k một giờ, học buổi tối.",
    )
    observed = await run_flow(
        case_id="FINAL-F02a",
        start=(
            "BeeWise is on /matching (Ghép gia sư bằng AI) with Firebase App Check token "
            "active and Remote Config ai_matching_enabled=true."
        ),
        steps=(
            f"Enter the synthetic learning need {prompt!r} into the requirement input and "
            "tap Phân tích nhu cầu bằng AI once. Wait for the AI parse to complete and verify "
            "the heading 'Gợi ý AI · Kiểm tra và chỉnh sửa' appears. Edit one field (for example, "
            "adjust 'Phí tối đa mỗi giờ (VND)' from 200000 to 220000 or change 'Hình thức'), "
            "and read the same field before and after the edit. Then tap 'Xác nhận và tìm gia sư' "
            "and wait for the post-submit UI. Quote the AI heading and the actual result heading "
            "or empty message. Report any AI, transport, Firestore or UI error observed; do not "
            "infer missing observations or fabricate tutor records."
        ),
        expected=(
            '{"ai_suggestion_header_visible":true,"ai_heading_text":string,"field_edited":true,'
            '"edited_field":string,"value_before_edit":string,"value_after_edit":string,'
            '"confirmed_search_submitted":true,"result_count":integer,'
            '"outcome":"results|empty|error","terminal_ui_text":string,'
            '"error_observed":boolean,"profiles_fabricated":false}'
        ),
    )
    assert require(observed, "ai_suggestion_header_visible", bool)
    assert require(observed, "ai_heading_text", str) == "Gợi ý AI · Kiểm tra và chỉnh sửa"
    assert require(observed, "field_edited", bool)
    assert require(observed, "edited_field", str) in {
        "Môn học", "Khối lớp", "Khu vực", "Lịch ưu tiên", "Hình thức",
        "Phí tối đa mỗi giờ (VND)",
    }
    before = require(observed, "value_before_edit", str).strip()
    after = require(observed, "value_after_edit", str).strip()
    assert before.casefold() != after.casefold(), "The same field must visibly change."
    assert require(observed, "confirmed_search_submitted", bool)
    assert require(observed, "error_observed", bool) is False
    count = require(observed, "result_count", int)
    outcome = require(observed, "outcome", str)
    terminal_text = require(observed, "terminal_ui_text", str)
    assert (
        (outcome == "results" and count > 0 and terminal_text == "Gia sư phù hợp")
        or (outcome == "empty" and count == 0
            and terminal_text == "Chưa có hồ sơ phù hợp với bộ lọc đã xác nhận.")
    ), "Expected post-submit results or the explicit empty UI, with a matching count."
    assert require(observed, "profiles_fabricated", bool) is False


@pytest.mark.manual_setup
async def test_final_f02b_ai_level2_offline_error_and_manual_fallback(run_flow):
    """FINAL-F02b; Final A1 failure recovery on ConfirmTutorNeedScreen."""
    observed = await run_flow(
        case_id="FINAL-F02b",
        start=(
            "Device connectivity is turned off (airplane mode / offline) and BeeWise is on "
            "/matching (Ghép gia sư bằng AI)."
        ),
        steps=(
            "Enter 'Tìm gia sư Vật lý lớp 11 ở Quận 3' and tap 'Phân tích nhu cầu bằng AI'. "
            "Verify a recoverable Vietnamese error message appears ('Chưa lấy được gợi ý AI. "
            "Thử lại hoặc tự điền bộ lọc.'), then tap 'Tự điền bộ lọc' to confirm the manual "
            "form ('Yêu cầu học tập') and manual search link ('Mở trang tìm kiếm gia sư') "
            "remain available."
        ),
        expected=(
            '{"ai_error_visible":true,"manual_form_header_visible":true,'
            '"manual_search_link_visible":true,"app_crashed":false}'
        ),
    )
    assert require(observed, "ai_error_visible", bool)
    assert require(observed, "manual_form_header_visible", bool)
    assert require(observed, "manual_search_link_visible", bool)
    assert require(observed, "app_crashed", bool) is False


@pytest.mark.manual_setup
async def test_final_f04_connection_request_and_chat_isolation(run_flow):
    """FINAL-F04; Lab 2 Screens 07 & 08; /tutors/:id -> /connection/:tutorId -> /chats/:chatId."""
    tutor_name = os.environ.get("BEEWISE_TEST_TUTOR_NAME")
    assert tutor_name, "Set BEEWISE_TEST_TUTOR_NAME to a real active catalog tutor."
    observed = await run_flow(
        case_id="FINAL-F04",
        start=(
            f"Signed in as a synthetic parent account on /tutors/:id for {tutor_name!r} "
            "(dedicated emulator or synthetic test fixture)."
        ),
        steps=(
            "Tap 'Gửi yêu cầu kết nối', fill synthetic non-personal goal, area and schedule, "
            "and submit once. Verify navigation to /chats/:chatId, send a harmless synthetic "
            "message ('Kiểm tra kết nối Final'), and confirm only this parent's conversation "
            "renders in Tin nhắn without leaking another parent's chat."
        ),
        expected=(
            '{"connection_submitted":true,"chat_opened":true,'
            '"sent_message_visible":true,"other_parent_leak":false}'
        ),
    )
    assert require(observed, "connection_submitted", bool)
    assert require(observed, "chat_opened", bool)
    assert require(observed, "sent_message_visible", bool)
    assert require(observed, "other_parent_leak", bool) is False


@pytest.mark.manual_setup
async def test_final_f07_vietqr_trust_boundary_and_official_schedule(run_flow):
    """FINAL-F07; Final VietQR /vietqr/:chatId -> invoice/QR/claim -> /schedule/:classId."""
    test_env = os.environ.get("BEEWISE_FINAL_TEST_ENV", "emulator")
    assert test_env in {"emulator", "production_safe_check"}
    if test_env == "production_safe_check":
        steps = (
            "In production_safe_check mode, open an existing synthetic offered/awaiting_transfer "
            "proposal at /vietqr/:chatId, verify the exact VND amount matches before confirming, "
            "and verify the dynamic VietQR image ('Mã QR VietQR của hóa đơn') renders alongside "
            "a server-generated BW... transfer reference. DO NOT send a bank transfer or claim "
            "a false transfer in production."
        )
        expected = (
            '{"environment":"production_safe_check","invoice_visible":true,'
            '"qr_visible":true,"paid_claim_without_staff_verify":false,'
            '"official_schedule_visible":false}'
        )
    else:
        steps = (
            "In Firebase Emulator mode, open /vietqr/:chatId with an offered synthetic proposal. "
            "Tap 'Xác nhận lớp' with the exact shown VND amount, verify dynamic VietQR renders "
            "('Mã QR VietQR của hóa đơn') and 'Nội dung chuyển khoản' starts with 'BW', then tap "
            "'Tôi đã chuyển khoản'. Verify 'Bạn đã báo chuyển khoản. Lịch học chỉ mở sau khi "
            "nhân viên kiểm tra khoản tiền thực nhận.' and confirm NO official schedule opens yet. "
            "Do not fabricate staff verification inside the Android client."
        )
        expected = (
            '{"environment":"emulator","invoice_visible":true,"qr_visible":true,'
            '"awaiting_verification_visible":true,'
            '"paid_claim_without_staff_verify":false,"official_schedule_visible":false}'
        )
    observed = await run_flow(
        case_id="FINAL-F07",
        start=f"Signed in as synthetic parent with an eligible VietQR proposal ({test_env}).",
        steps=steps,
        expected=expected,
    )
    assert observed.get("environment") == test_env
    assert require(observed, "invoice_visible", bool)
    assert require(observed, "qr_visible", bool)
    assert require(observed, "paid_claim_without_staff_verify", bool) is False
    assert require(observed, "official_schedule_visible", bool) is False
    if test_env == "emulator":
        assert require(observed, "awaiting_verification_visible", bool)


@pytest.mark.manual_setup
async def test_final_f08_tutor_cross_role_lifecycle_and_inbox(run_flow):
    """FINAL-F08; Final X1 & M2, T1–T8; /tutor/apply -> /tutor/pending -> /tutor/home & /tutor/notifications."""
    assert os.environ.get("BEEWISE_DEDICATED_TEST_PROJECT") == "1", (
        "Run cross-role lifecycle only on authorized emulator/production synthetic test fixtures "
        "with operator-entered disposable credentials outside model traces."
    )
    observed = await run_flow(
        case_id="FINAL-F08",
        start=(
            "Operator has entered disposable synthetic credentials on /tutor/apply (T1) or "
            "prepared the approved tutor session after Web Admin approval."
        ),
        steps=(
            "Submit synthetic T1 tutor fields without exposing credentials in output. Verify "
            "redirection to /tutor/pending (T2) showing 'Đang chờ duyệt' with parent bottom "
            "navigation absent. After Web Admin commits approval without reloading Android, verify "
            "T2 updates live to 'Đã được phê duyệt' with 'Vào trang gia sư', navigate to T3 "
            "(/tutor/home), and open T8 (/tutor/notifications) to confirm both the private approval "
            "notice and published general announcement are visible."
        ),
        expected=(
            '{"pending_visible":true,"parent_navigation_visible":false,'
            '"live_approved_without_reload":true,"workspace_cta_visible":true,'
            '"private_notice_visible":true}'
        ),
    )
    assert require(observed, "pending_visible", bool)
    assert require(observed, "parent_navigation_visible", bool) is False
    assert require(observed, "live_approved_without_reload", bool)
    assert require(observed, "workspace_cta_visible", bool)
    assert require(observed, "private_notice_visible", bool)


@pytest.mark.manual_setup
async def test_final_pdf_local_private_save_and_isolation(run_flow):
    """FINAL-PDF; Final I1 (supersedes legacy Base64 TC-11); local PDF + metadata + account B isolation."""
    tutor_name = os.environ.get("BEEWISE_TEST_TUTOR_NAME")
    assert tutor_name, "Set BEEWISE_TEST_TUTOR_NAME to an authorized active catalog tutor."
    observed = await run_flow(
        case_id="FINAL-PDF",
        start=f"Signed in as synthetic parent A viewing {tutor_name!r} in Final Firestore mode.",
        steps=(
            "Export the tutor PDF summary, tap 'Lưu PDF trên thiết bị', wait for 'Đã lưu PDF trên "
            "thiết bị. Firestore đã xác nhận thông tin báo cáo.', verify 'Mở PDF trên thiết bị' and "
            "'Chia sẻ PDF' actions appear, open 'Báo cáo đã lưu' on Profile to confirm Parent A's "
            "entry is listed, then sign out and sign in as Parent B to confirm Parent A's history "
            "is not exposed to Parent B. Do not export paths, UIDs, or PDF contents."
        ),
        expected=(
            '{"local_pdf_saved":true,"metadata_confirmed":true,'
            '"open_and_share_visible":true,"parent_a_history_listed":true,'
            '"parent_b_isolated":true}'
        ),
    )
    assert require(observed, "local_pdf_saved", bool)
    assert require(observed, "metadata_confirmed", bool)
    assert require(observed, "open_and_share_visible", bool)
    assert require(observed, "parent_a_history_listed", bool)
    assert require(observed, "parent_b_isolated", bool)
