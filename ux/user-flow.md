# User Flows

## Flow 1 - Tìm gia sư thủ công và yêu cầu kết nối

**Luồng chính:** Guest → Home → Search → Tutor Profile → Login → Connection Request → Group Chat.

**Alternate path:** Phụ huynh không tìm được gia sư phù hợp → điều chỉnh bộ lọc hoặc chuyển sang AI Matching.

**Error/Recovery:** Đăng nhập thất bại → hiển thị lỗi → nhập lại → tiếp tục yêu cầu kết nối, không mất hồ sơ gia sư đã chọn.

## Flow 2 - Tìm gia sư bằng AI (Free Trial)

**Luồng chính:** Guest → AI Matching → Free Trial → AI Results → Tutor Profile. Lần thứ hai yêu cầu đăng nhập.

**Alternate path:** Người dùng không hài lòng với kết quả AI → xem hồ sơ khác hoặc chuyển sang tìm kiếm thủ công.

**Error/Recovery:** AI không tìm được gia sư phù hợp hoặc xử lý thất bại → thông báo rõ nguyên nhân → cho điều chỉnh nhu cầu và thử lại. Nên quy định lượt AI chỉ bị trừ khi yêu cầu xử lý thành công.

## Flow 3 - Quy trình kết nối đến lịch học chính thức

**Luồng chính:** Group Chat → Học thử → Xác nhận thông tin lớp → Thanh toán → Xếp lịch chính thức.

### Các bước theo hình

- Bắt đầu trong Group Chat 3 bên: phụ huynh, gia sư và tư vấn viên.
- Tư vấn viên gửi widget Học thử; các bên trao đổi và thống nhất.
- Học thử hoàn tất; các bên trao đổi kết quả và nhu cầu tiếp tục.
- Tư vấn viên gửi widget Xác nhận lớp, gồm thông tin môn học, học phí và lịch dự kiến.
- Nếu thông tin lớp đã được xác nhận, hệ thống tự động gửi widget Thanh toán để phụ huynh thanh toán.
- Khi thanh toán thành công, hệ thống gửi widget Xếp lịch. Lịch học chính thức được xác lập và phụ huynh có thể xem lịch học.

**Alternate path - thông tin lớp chưa được xác nhận:** Chưa → yêu cầu điều chỉnh → tư vấn viên cập nhật và gửi lại widget.

**Error/Recovery - thanh toán thất bại:** Không thành công → báo lỗi → thử lại.

**Lưu ý theo hình:** Sơ đồ không vẽ rõ đường quay lại bước xác nhận thông tin sau khi widget được gửi lại, cũng không chỉ rõ đường đi tiếp sau “Thử lại”. Vì vậy, tài liệu chỉ ghi các nhánh được thể hiện và không thêm bước tiếp theo.
