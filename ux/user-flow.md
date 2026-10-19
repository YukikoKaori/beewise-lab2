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

PDF không nêu alternate path hoặc error/recovery path cho Flow 3.