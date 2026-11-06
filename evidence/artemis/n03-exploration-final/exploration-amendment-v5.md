# Đề Xuất Phê Duyệt Ngân Sách Bổ Sung V5: Hoàn Tất Chốt Báo Cáo Phiên Thăm Dò ARTEMIS 16 Phút Độc Lập (TC-25)

## 1. Bối cảnh & Cải tiến kỹ thuật chốt báo cáo

- Phiên chạy V4 đã chứng minh trọn vẹn khả năng tự chủ liên tục kéo dài **1018.74 giây (~17 phút)** — hoàn toàn vượt ngưỡng tối thiểu 900 giây (15 phút) của Rubric.
- Tuy nhiên, do logic `is_final` của ARTEMIS Flash ban đầu chỉ kiểm tra `turns == limit (35)`, công cụ chỉ chuyển sang `report_only_tools` ở turn 35. Vì vậy, agent tiếp tục thực hiện hành động thăm dò và chạm ngưỡng 115 requests trước khi kịp gửi lệnh `report_task_status`.
- **Cải tiến kỹ thuật đã áp dụng**:
  - Đã vá logic `is_final` trong `runner.py`:
    `is_final = (limit is not None and turns == limit) or (min_seconds > 0 and ledger.elapsed_seconds() >= min_seconds)`
  - Ngay khi thời gian thực tế đạt 910 giây (khoảng turn 23–24), `is_final` được kích hoạt lập tức, giới hạn danh sách công cụ thành duy nhất `report_task_status`.
  - Agent bắt buộc phải tổng kết kết quả JSON và hoàn thành phiên thành công với status `completed`.

---

## 2. Thông số hạn mức đề xuất chi tiết (V5)

| Mục | Giá trị |
| :--- | :--- |
| **Số lượt suy luận bổ sung tối đa** | **27 requests** (Nâng trần lũy kế từ 115 lên **142 requests**) |
| **Chi phí bảo thủ bổ sung tối đa** | **\$0.070000 USD** (Nâng trần chi phí lũy kế từ \$0.42 lên **\$0.490000 USD** / 490,000,000 nanodollars) |
| **Số phiên thăm dò được phép chạy** | Đúng **1 phiên duy nhất** (Target 920–950s, dải hợp lệ Rubric 900–1800s) |
| **Số dư tài khoản DeepSeek hiện tại** | **\$0.80 USD** (đã xác thực qua live API `api.deepseek.com/user/balance`) |
| **Chi phí thực tế dự kiến của phiên 16 phút** | **~\$0.08–\$0.09 USD** (~23 turns x \$0.0038) |
| **Số dư thực tế dự kiến sau khi chạy xong** | **~\$0.71–\$0.72 USD** |
| **Hạn mức dự phòng bất khả xâm phạm cho Nexora** | **Tối thiểu \$0.50 USD** (Dư biên độ an toàn **\$0.21 USD**) |
| **Thời hạn phê duyệt** | 24 giờ (hết hạn lúc 2026-11-07T11:00:00Z) |

---

## 3. Điều kiện dừng & Rào chắn kỹ thuật

1. **Điều kiện hoàn thành thành công**:
   - Phiên thăm dò đạt thời lượng thực tế từ 900 đến 1800 giây (mục tiêu ~920–950 giây, ~15.5–16 phút), gọi `report_task_status` trả về kết quả JSON hợp lệ và pytest PASS.
2. **Cổng bảo vệ tài chính**:
   - Dừng ngay lập tức nếu chạm trần 142 requests hoặc vượt trần \$0.49 USD.
3. **Cấm tuyệt đối**:
   - Tuyệt đối không fallback sang Gemini (`ARTEMIS_DEEPSEEK_ONLY=1`).
   - Không tự ý chuyển model, không retry ẩn.
   - Bảo lưu toàn bộ 115 attempts lịch sử và evidence các phiên trước mà không ghi đè.
