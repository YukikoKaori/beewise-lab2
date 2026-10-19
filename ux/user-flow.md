# User Flows

## Flow 01 - Manual Tutor Search & Connection

![Flow 1 - Tìm gia sư thủ công và yêu cầu kết nối](../assets/user-flow/Flow1.png)

**Luồng chính:** Guest → Home → Manual Tutor Search → Tutor Profile → Login/Register (nếu chưa đăng nhập) → Connection Request → Group Chat.

**Alternate path:** Phụ huynh không tìm được gia sư phù hợp → điều chỉnh bộ lọc hoặc chuyển sang AI Matching.

**Error/Recovery:** Đăng nhập thất bại → hiển thị lỗi → nhập lại → tiếp tục yêu cầu kết nối, không mất hồ sơ gia sư đã chọn.

## Flow 02 - AI Tutor Matching (Free Trial)

![Flow 2 - Tìm gia sư bằng AI](../assets/user-flow/Flow%202.png)

**Luồng chính:** Guest → Home → AI Tutor Matching → Free Trial → AI Results → Tutor Profile.

- Guest có 1 lượt AI xử lý thành công miễn phí; lần sử dụng tiếp theo yêu cầu đăng nhập.
- AI xử lý thất bại không trừ lượt miễn phí.

**Alternate path:** Người dùng không hài lòng với kết quả AI → xem hồ sơ khác hoặc chuyển sang tìm kiếm thủ công.

**Error/Recovery:** AI không tìm được gia sư phù hợp hoặc xử lý thất bại → thông báo rõ nguyên nhân → cho điều chỉnh nhu cầu và thử lại.

## Flow 03 - Class Onboarding

![Flow 3 - Quy trình kết nối đến lịch học chính thức](../assets/user-flow/Flow%203.png)

**Luồng chính:** Group Chat → Trial Lesson Detail → Class Confirmation → Payment → Official Schedule.

### Các bước theo hình

- Bắt đầu trong Group Chat 3 bên: phụ huynh, gia sư và tư vấn viên.
- Tư vấn viên gửi đề xuất học thử; các bên trao đổi và thống nhất.
- Học thử hoàn tất; các bên trao đổi kết quả và nhu cầu tiếp tục.
- Tư vấn viên gửi xác nhận lớp, gồm thông tin môn học, học phí và lịch dự kiến.
- Khi thông tin lớp được xác nhận, hệ thống gửi thông tin thanh toán.
- Khi thanh toán thành công, hệ thống gửi lịch học chính thức để phụ huynh xem.

**Alternate path - không tiếp tục sau buổi học thử:** Không hài lòng với kết quả học thử → trao đổi thêm với gia sư hoặc tư vấn viên → kết thúc quy trình hoặc tìm gia sư khác.

**Alternate path - yêu cầu điều chỉnh lớp:** Phụ huynh yêu cầu điều chỉnh thông tin môn học, học phí hoặc lịch học → tư vấn viên cập nhật và gửi lại xác nhận lớp → quay lại bước xác nhận thông tin lớp.

**Error/Recovery - thanh toán thất bại:** Hiển thị thông báo lỗi → phụ huynh kiểm tra và thử lại hoặc chọn phương thức khác → quay lại bước thanh toán.
