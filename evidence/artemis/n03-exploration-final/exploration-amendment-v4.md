# Đề Xuất Phê Duyệt Ngân Sách Bổ Sung V4: Hoàn Tất Phiên Thăm Dò ARTEMIS 16 Phút Độc Lập (TC-25)

## 1. Bối cảnh & Nguyên nhân Root Cause của phiên trước

- Phiên chạy vừa qua đã chứng minh độ ổn định xuất sắc của bản vá kết nối: **chạy hoàn hảo liên tục 26 bước tự chủ trong 760.88 giây (~12.7 phút)** qua các màn hình Home, Search, Tutor Profile, Empty Login Error Validation, Messages, AI Matching UI.
- Không hề xảy ra lỗi socket disconnect như trước đây nhờ cơ chế `max_keepalive_connections=0`.
- Nguyên nhân phiên dừng ở 760.88s: Ở bước 25, công thức trần đặt chỗ (*reservation bound*) của transport tính toán chi phí dự phòng bảo thủ cho lượt gọi tiếp theo là 18.15M nanodollars (do tích lũy lịch sử 43KB text + 5 ảnh + 2048 output tokens), trong khi trần ngân sách \$0.31 USD chỉ còn lại 15.19M nanodollars. Do đó, ledger tự động kích hoạt bảo vệ fail-closed không gửi request.
- Để phiên đạt chuẩn Rubric (>= 900 giây, tức >= 15 phút continuous exploration), phiên cần chạy thêm khoảng 23–24 bước với turn pacing 34s (tổng thời gian ~930–960 giây).

---

## 2. Thông số hạn mức đề xuất chi tiết (V4)

| Mục | Giá trị |
| :--- | :--- |
| **Số lượt suy luận bổ sung tối đa** | **28 requests** (Nâng trần lũy kế từ 95 lên **115 requests**) |
| **Chi phí bảo thủ bổ sung tối đa** | **\$0.110000 USD** (Nâng trần chi phí lũy kế từ \$0.31 lên **\$0.420000 USD** / 420,000,000 nanodollars) |
| **Số phiên thăm dò được phép chạy** | Đúng **1 phiên duy nhất** (Target 930–960s, dải hợp lệ Rubric 900–1800s) |
| **Số dư tài khoản DeepSeek hiện tại** | **\$0.84 USD** (đã xác thực qua live API `api.deepseek.com/user/balance`) |
| **Chi phí thực tế dự kiến của phiên 16 phút** | **~\$0.096 USD** (~24 turns x \$0.004) |
| **Số dư thực tế dự kiến sau khi chạy xong** | **~\$0.74 USD** |
| **Hạn mức dự phòng bất khả xâm phạm cho Nexora** | **Tối thiểu \$0.50 USD** (Dư biên độ an toàn **\$0.24 USD**) |
| **Thời hạn phê duyệt** | 24 giờ (hết hạn lúc 2026-11-07T06:30:00Z) |

---

## 3. Điều kiện dừng & Rào chắn kỹ thuật

1. **Điều kiện hoàn thành thành công**:
   - Phiên thăm dò đạt thời lượng thực tế từ 900 đến 1800 giây (mục tiêu ~930–960 giây, ~16 phút) và trả về kết quả JSON hợp lệ với JUnit PASS.
2. **Cổng bảo vệ tài chính**:
   - Dừng ngay lập tức nếu chạm trần 115 requests hoặc vượt trần \$0.42 USD.
3. **Cấm tuyệt đối**:
   - Tuyệt đối không fallback sang Gemini (`ARTEMIS_DEEPSEEK_ONLY=1`).
   - Không tự ý chuyển model, không retry ẩn.
   - Bảo lưu toàn bộ 87 attempts lịch sử và evidence các phiên trước mà không ghi đè.
