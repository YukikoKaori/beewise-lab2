"""Offline assertion regressions: the real scenario functions receive synthetic reports."""

import pytest

import test_final_flows as flows


F01 = {
    "screen": "Tìm gia sư",
    "query": "Toán",
    "filter_applied": True,
    "result_count": 1,
    "search_count_text": "1 gia sư phù hợp",
    "state": "data",
    "error_observed": False,
    "profiles_fabricated": False,
    "profile_opened": True,
    "hourly_fee_visible": True,
    "connection_action_visible": True,
    "terminal_screen": "tutor_profile",
    "profile_hourly_fee_text": "150.000đ/giờ",
    "profile_connection_cta_text": "Gửi yêu cầu kết nối",
}

F02A = {
    "ai_suggestion_header_visible": True,
    "ai_heading_text": "Gợi ý AI · Kiểm tra và chỉnh sửa",
    "field_edited": True,
    "edited_field": "Hình thức",
    "value_before_edit": "Trực tuyến",
    "value_after_edit": "Trực tiếp",
    "confirmed_search_submitted": True,
    "result_count": 1,
    "outcome": "results",
    "terminal_ui_text": "Gia sư phù hợp",
    "error_observed": False,
    "profiles_fabricated": False,
}


@pytest.mark.parametrize("changes,missing,passes", [
    pytest.param({}, (), True, id="profile-with-fee-and-cta"),
    pytest.param({"profile_opened": False}, (), False, id="profile-not-opened"),
    pytest.param({"state": "error"}, (), False, id="search-error"),
    pytest.param({"result_count": 0}, (), False, id="zero-count-without-recovery"),
    pytest.param({"state": "empty", "result_count": 0, "empty_recovery_verified": True},
                 (), False, id="empty-recovery-outside-scenario"),
    pytest.param({}, ("profile_hourly_fee_text",), False, id="missing-fee-evidence"),
    pytest.param({"connection_action_visible": False}, (), False, id="cta-not-visible"),
    pytest.param({"terminal_screen": "search"}, (), False, id="still-on-search"),
    pytest.param({"result_count": True}, (), False, id="boolean-count"),
    pytest.param({"result_count": 2}, (), False, id="visible-count-mismatch"),
    pytest.param({"error_observed": True}, (), False, id="error-despite-data"),
])
async def test_discovery_assertions(changes, missing, passes, monkeypatch):
    monkeypatch.setenv("BEEWISE_SEARCH_TERM", "Toán")
    async def report(**scenario):
        assert scenario["case_id"] == "FINAL-F01"
        return {k: v for k, v in (F01 | changes).items() if k not in missing}

    scenario = flows.test_final_f01_discovery_search_filters_and_tutor_profile
    if passes:
        await scenario(report)
    else:
        with pytest.raises(AssertionError):
            await scenario(report)


@pytest.mark.parametrize("changes,missing,passes", [
    pytest.param({}, (), True, id="confirmed-results"),
    pytest.param({"outcome": "empty", "result_count": 0, "terminal_ui_text":
                  "Chưa có hồ sơ phù hợp với bộ lọc đã xác nhận."},
                 (), True, id="confirmed-empty"),
    pytest.param({"outcome": "error"}, (), False, id="search-error"),
    pytest.param({}, ("ai_suggestion_header_visible",), False, id="missing-header"),
    pytest.param({"value_after_edit": " Trực tuyến "}, (), False, id="unchanged-field"),
    pytest.param({}, ("value_after_edit",), False, id="missing-post-edit-value"),
    pytest.param({"field_edited": False}, (), False, id="edit-not-observed"),
    pytest.param({"confirmed_search_submitted": False}, (), False, id="not-submitted"),
    pytest.param({"outcome": "empty", "result_count": 0}, (), False, id="wrong-empty-ui"),
    pytest.param({"result_count": 0}, (), False, id="results-count-mismatch"),
    pytest.param({"error_observed": True}, (), False, id="error-despite-results"),
])
async def test_ai_confirmation_assertions(changes, missing, passes):
    async def report(**scenario):
        assert scenario["case_id"] == "FINAL-F02a"
        return {k: v for k, v in (F02A | changes).items() if k not in missing}

    scenario = flows.test_final_f02a_ai_level2_confirm_and_edit_flow
    if passes:
        await scenario(report)
    else:
        with pytest.raises(AssertionError):
            await scenario(report)
