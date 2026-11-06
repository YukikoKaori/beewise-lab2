# Đề Xuất Phê Duyệt Ngân Sách Bổ Sung: Phiên Thăm Dò ARTEMIS 16 Phút Duy Nhất (TC-25)

## 1. Bối cảnh & Lý do đề xuất

Theo yêu cầu Rubric PRM393 Lab 3 (*PRM393_Lab3_Preparation_Guide_v5_ToiUu.pdf*, tr. 23) và chỉ thị Final Corrective:
- Hạng mục thăm dò tự chủ (TC-25) yêu cầu **một phiên duy nhất, liên tục kéo dài từ 15–30 phút (900–1800 giây)**.
- Hai phiên chạy trước đó đạt tổng cộng 846.14 giây (~14.1 phút), nhưng mỗi phiên riêng lẻ dừng ở 379s và 467s nên cần chạy **1 phiên mới duy nhất** đạt chuẩn >= 900s (mục tiêu 960s ~ 16 phút).
- Hai phiên trước đã tiêu thụ 34 requests (\$0.1068 USD) trong trần 50 requests (\$0.12 USD), chỉ còn lại 16 requests (\$0.0132 USD) — không đủ an toàn cho một phiên 16 phút độc lập (~26–30 turns).

---

## 2. Thông số hạn mức bổ sung chi tiết

| Mục | Giá trị |
| :--- | :--- |
| **Số lượt suy luận lũy kế tối đa** | **95 requests** (Bảo đảm hoàn tất phiên 16 phút độc lập) |
| **Chi phí bảo thủ lũy kế tối đa** | **\$0.310000 USD** (310,000,000 nanodollars) |
| **Số phiên thăm dò được phép chạy** | Đúng **1 phiên duy nhất** (Target 960s, dải hợp lệ 900–1800s) |
| **Số dư tài khoản DeepSeek hiện tại** | **\$0.86 USD** (đã xác thực qua live API `api.deepseek.com/user/balance`) |
| **Số dư dự kiến sau khi chạy xong** | **~\$0.76 USD** (hoặc ~\$0.77 USD theo chi phí thực tế) |
| **Hạn mức dự phòng bất khả xâm phạm cho Nexora** | **Tối thiểu \$0.50 USD** (Dư biên độ an toàn **\$0.26 USD**) |
| **Thời hạn phê duyệt** | 24 giờ (hết hạn lúc 2026-11-07T05:30:00Z) |

---

## 3. Điều kiện dừng & Rào chắn kỹ thuật

1. **Điều kiện hoàn thành thành công**:
   - Phiên thăm dò đạt thời lượng thực tế từ 900 đến 1800 giây (mục tiêu ~960 giây, ~16 phút) và trả về kết quả JSON hợp lệ.
2. **Cổng bảo vệ tài chính**:
   - Dừng ngay lập tức nếu vượt quá 32 lượt gọi bổ sung hoặc chạm mức trần \$0.11 USD bổ sung.
3. **Cấm tuyệt đối**:
   - Tuyệt đối không fallback sang Gemini (`ARTEMIS_DEEPSEEK_ONLY=1`).
   - Không tự ý chuyển model, không retry ẩn.
   - Không ghi đè hay xóa bỏ evidence của 2 phiên lịch sử trước đó.
