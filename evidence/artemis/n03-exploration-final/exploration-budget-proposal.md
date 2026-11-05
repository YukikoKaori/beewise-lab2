# ĐỀ XUẤT NGÂN SÁCH & KẾ HOẠCH KIỂM THỬ KHÁM PHÁ (N-03 EXPLORATION & NATIVE PERMISSION) — TU CHỈNH LẦN 2

**Ngày đề xuất**: 2026-11-06 (UTC+7)  
**Phạm vi**: 1 phiên kiểm thử khám phá duy nhất (Single 20-minute Exploratory Session) tích hợp Tương tác Android Native Permission Dialog.

---

## 1. Thông số kỹ thuật & Nhà cung cấp
* **Provider**: DeepSeek Official API (`https://api.deepseek.com`).
* **Model**: `deepseek-flash` (non-thinking, non-streaming, max output 2,048 tokens).
* **Execution Engine**: `FlashRunner` (single-model reactive loop đã được chứng minh ổn định qua 30/30 lượt regression).
* **Gemini Fallback**: **TUYỆT ĐỐI BẰNG KHÔNG (ZERO)**. Cơ chế cô lập `ARTEMIS_DEEPSEEK_ONLY=1` lập tức ném lỗi `ValueError` nếu bất kỳ module nào cố gắng gọi Google Gemini.
* **Thời lượng mục tiêu**: **20 phút** (được đo đạc bằng đồng hồ đơn điệu `time.monotonic()`, bảo đảm nằm trong khung 15–30 phút theo yêu cầu của Rubric Preparation Guide v5 Trang 23).
* **Hạn mức phong bì (Transcript Envelope)**: 131,072 bytes (128 KB) để hỗ trợ 25–35 turns khám phá sâu mà không bị ngắt quãng bởi guardrail cục bộ.

---

## 2. Dự toán Ngân sách & Hạn mức Trần (Hard Ceilings)
Dựa trên dữ liệu thực tế từ phiên chạy thử nghiệm (17 requests, $0.05018 USD):
* **Số lượt suy luận kỳ vọng (Expected Inferences)**: 35 – 45 requests lũy kế toàn bộ phiên.
* **Hạn mức trần cứng (Hard Request Ceiling)**: **Tối đa 50 HTTP inference requests**.
* **Hạn mức chi phí trần cứng (Hard Cost Ceiling)**: **Tối đa $0.12 USD** (Conservative Estimate).
* **Cam kết bảo lưu quỹ Nexora**: Số dư tài khoản DeepSeek hiện tại là **$0.90 USD**. Việc tiêu tối đa $0.12 USD lũy kế sẽ để lại **ít nhất $0.78 USD** (vượt xa yêu cầu duy trì tối thiểu **$0.50 reserve cho Nexora**).
* **Không nạp thêm tiền (No Auto-Top-Up)**.

---

## 3. Kế hoạch Tương tác Android Native Permission
1. **Trước khi bắt đầu**:
   * Chạy lệnh native ADB để thu hồi quyền:
     `adb shell pm revoke com.beewise.beewise android.permission.POST_NOTIFICATIONS`
   * Xóa cờ quyền người dùng:
     `adb shell pm clear-permission-flags com.beewise.beewise android.permission.POST_NOTIFICATIONS user-set user-fixed`
   * Khởi động BeeWise: Hệ điều hành Android sẽ tự động bật hộp thoại quyền hệ thống thật của `com.google.android.permissioncontroller` ("Allow BeeWise to send you notifications?").
2. **Trong phiên chạy (Turn 1–2)**:
   * ARTEMIS quan sát thấy hộp thoại OS Native Permission và thực hiện hành động bấm "Allow" (hoặc "Don't allow").
   * Thu thập ảnh chụp trước/sau và xác minh trạng thái quyền bằng `dumpsys package`.
   * Thỏa mãn 100% tiêu chí **"một tương tác Android gốc"** của Rubric.
3. **Các lượt chạy tiếp theo (Turn 3–35)**:
   * ARTEMIS tự chủ khám phá toàn bộ ứng dụng: Trang chủ, Tìm kiếm gia sư, Chi tiết gia sư, Giao diện Ghép AI (không gọi API bên ngoài), Đăng nhập/Validation, Tin nhắn, Khu vực demo Firebase (Remote Config, Notification, Crashlytics demo), và 1 nhánh lỗi/recovery.
   * Pacing nhịp nhàng 25-30 giây giữa các turn để phiên chạy đạt trọn vẹn ~16–20 phút thực tế với JSON kết quả cấu trúc đầy đủ.

---

## 4. Chính sách Dừng khẩn cấp (Failure & Stop Policy)
* Dừng ngay lập tức nếu số request chạm mốc 50 hoặc chi phí chạm mốc $0.12 USD.
* Dừng ngay nếu phát hiện ANR hệ thống không tự hồi phục hoặc mất kết nối thiết bị.
* Không có vòng lặp vô hạn hay thử lại ngầm.
