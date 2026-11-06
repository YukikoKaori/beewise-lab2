# Đề Xuất Phê Duyệt Ngân Sách Bổ Sung V6: Hoàn Tất Phiên Thăm Dò ARTEMIS 16 Phút Độc Lập (TC-25)

## 1. Bối cảnh & Phân tích nguyên nhân toán học

- Ở phiên V4, hệ thống đã chạy xuất sắc **1018.74 giây (~17 phút)** liên tục.
- Ở phiên V5 vừa qua, hệ thống đã chạy hoàn toàn ổn định qua 21 turns trong **724.20 giây (~12 phút)** với tốc độ trung bình 34.4s/turn trước khi chạm trần chi phí cục bộ.
- **Nguyên nhân cốt lõi**: Cơ chế đặt chỗ (*reservation*) bảo thủ của transport tính toán chi phí dự phòng trước mỗi lượt gọi (khoảng 16M nanodollars), khiến trần ngân sách \$0.49 USD của SQLite ledger dừng lại khi tích lũy tổng chi phí lịch sử đạt ngưỡng.
- **Giải pháp tối ưu hóa toán học**:
  - Tăng nhẹ turn pacing lên **38s/turn** để mỗi bước quan sát sâu hơn, giảm tổng số bước cần gọi xuống chỉ còn **21–22 turns** để đạt mốc 910 giây (~15.5 phút).
  - Kết hợp với bản vá `is_final` trong `runner.py`: Ngay tại turn 22 (khi thời gian thực tế chạm 910s), hệ thống tự động khóa danh sách tool về duy nhất `report_task_status`, buộc agent chốt báo cáo JSON và kết thúc phiên với trạng thái `completed`.
  - Cần nâng trần lũy kế lên **168 requests** và **\$0.58 USD** (580M nanodollars) để cung cấp đủ headroom cho 22 lượt gọi và khoản đệm đặt chỗ.

---

## 2. Thông số hạn mức đề xuất chi tiết (V6)

| Mục | Giá trị |
| :--- | :--- |
| **Số lượt suy luận bổ sung tối đa** | **26 requests** (Nâng trần lũy kế từ 142 lên **168 requests**) |
| **Chi phí bảo thủ bổ sung tối đa** | **\$0.090000 USD** (Nâng trần chi phí lũy kế từ \$0.49 lên **\$0.580000 USD** / 580,000,000 nanodollars) |
| **Số phiên thăm dò được phép chạy** | Đúng **1 phiên duy nhất** (Target 925–950s, dải hợp lệ Rubric 900–1800s) |
| **Số dư tài khoản DeepSeek hiện tại** | **\$0.78 USD** (đã xác thực qua live API `api.deepseek.com/user/balance`) |
| **Chi phí thực tế dự kiến của phiên 16 phút** | **~\$0.086 USD** (~22 turns x \$0.0039) |
| **Số dư thực tế dự kiến sau khi chạy xong** | **~\$0.69 USD** |
| **Hạn mức dự phòng bất khả xâm phạm cho Nexora** | **Tối thiểu \$0.50 USD** (Dư biên độ an toàn **\$0.19 USD**) |
| **Thời hạn phê duyệt** | 24 giờ (hết hạn lúc 2026-11-07T11:30:00Z) |

---

## 3. Điều kiện dừng & Rào chắn kỹ thuật

1. **Điều kiện hoàn thành thành công**:
   - Phiên thăm dò đạt thời lượng thực tế từ 900 đến 1800 giây (mục tiêu ~925–950 giây, ~15.5 phút), gọi `report_task_status` trả về kết quả JSON hợp lệ và pytest PASS.
2. **Cổng bảo vệ tài chính**:
   - Dừng ngay lập tức nếu chạm trần 168 requests hoặc vượt trần \$0.58 USD.
3. **Cấm tuyệt đối**:
   - Tuyệt đối không fallback sang Gemini (`ARTEMIS_DEEPSEEK_ONLY=1`).
   - Không tự ý chuyển model, không retry ẩn.
   - Bảo lưu toàn bộ 136 attempts lịch sử và evidence các phiên trước mà không ghi đè.
