# Screen List - BeeWise Android Mobile App

- **Project:** BeeWise - Android Tutoring Marketplace
- **Primary Persona:** Chị Lan - 38 tuổi, phụ huynh tìm gia sư Toán ôn thi vào lớp 10 cho con.
- **Platform:** Android Mobile (360dp, hỗ trợ 412dp)
- **Total:** 12 màn hình
- **Design Tool:** [Google Stitch — BeeWise_Lab2](https://stitch.withgoogle.com/projects/11519656942239142615)
- **Prototype:** Card “Prototype : BeeWise Tutoring Platform Flow” inside the Stitch project; no standalone URL is recorded.

## Kích thước frame Figma

Yêu cầu nền tảng là khung cơ sở Android `360dp`, hỗ trợ kiểm tra ở `412dp`. Trong page Final UI của Figma, 11 màn hình có chiều rộng frame 360 px; riêng Home rộng 402 px. Chiều cao frame thay đổi theo nội dung và không đồng nghĩa với chiều cao viewport cố định. Xem [bảng kích thước và ghi chú đối chiếu](../design/figma-screen-sizes.md). Home cần được chuẩn hóa về khung 360dp hoặc được giải thích rõ trước khi handoff.

## Batch 01 - Tutor Discovery & AI Matching

| ID | Screen Name | Mô tả |
|---|---|---|
| 01 | Home | Trang chủ cho phép khách khám phá gia sư, tìm kiếm thủ công hoặc bắt đầu AI Matching. |
| 02 | AI Tutor Matching | Nhập nhu cầu học tập bằng ngôn ngữ tự nhiên, AI phân tích và đề xuất gia sư phù hợp. Guest có 1 lượt AI xử lý thành công miễn phí. |
| 03 | Manual Tutor Search | Tìm kiếm gia sư theo môn học, lớp, học phí, địa điểm, hình thức dạy; lọc và sắp xếp kết quả. |
| 04 | Tutor Profile | Xem hồ sơ gia sư, chuyên môn, kinh nghiệm, học phí, lịch rảnh, đánh giá và gửi yêu cầu kết nối. |

## Batch 02 - Authentication & Connection

| ID | Screen Name | Mô tả |
|---|---|---|
| 05 | Login | Đăng nhập bằng tài khoản hoặc Google; hỗ trợ thông báo lỗi và quay lại yêu cầu kết nối đang thực hiện. |
| 06 | Register | Tạo tài khoản phụ huynh, nhập thông tin cơ bản và tiếp tục quy trình kết nối sau đăng ký. |
| 07 | Connection Request | Xác nhận thông tin gia sư và yêu cầu kết nối trước khi tạo nhóm trò chuyện. |
| 08 | Group Chat | Nhóm chat gồm 3 bên: phụ huynh, gia sư và tư vấn viên BeeWise; trao đổi về học thử và thông tin lớp. |

## Batch 03 - Class Onboarding & Payment

| ID | Screen Name | Mô tả |
|---|---|---|
| 09 | Trial Lesson Detail | Hiển thị đề xuất buổi học thử do tư vấn viên gửi; phụ huynh xác nhận hoặc đề xuất thời gian khác. |
| 10 | Class Confirmation | Xem và xác nhận thông tin lớp học chính thức hoặc yêu cầu tư vấn viên điều chỉnh. |
| 11 | Payment | Hiển thị thông tin thanh toán do hệ thống gửi sau khi lớp được xác nhận; hỗ trợ trạng thái thanh toán. |
| 12 | Official Schedule | Hiển thị lịch học chính thức sau khi thanh toán thành công, gồm thời gian, gia sư và thông tin buổi học. |
