# Kích thước frame Figma — BeeWise

**Nguồn:** [BeeWise-Design trên Figma](https://www.figma.com/design/gqbuTDuZYOyKyP8LsUwobC/BeeWise-Design?node-id=2-3&t=XLL8PoLbIdyZCOIC-1), page **3. Final UI**.

Các số dưới đây là kích thước frame hiển thị trong inspector của Figma, ghi theo đơn vị canvas `px`. Đây là kích thước thiết kế nguồn; không tự động coi chiều cao frame là chiều cao viewport của điện thoại. Nhiều frame cao hơn viewport vì nội dung cần cuộn.

| ID | Frame | Rộng | Cao |
|---|---|---:|---:|
| 01 | Home | 402 px | 874 px |
| 02 | AI Tutor Matching | 360 px | 872 px |
| 03 | Manual Tutor Search | 360 px | 1,263 px |
| 04 | Tutor Profile | 360 px | 1,159 px |
| 05 | Login | 360 px | 882 px |
| 06 | Register | 360 px | 916 px |
| 07 | Connection Request | 360 px | 1,059 px |
| 08 | Group Chat | 360 px | 911 px |
| 09 | Trial Lesson Detail | 360 px | 911 px |
| 10 | Class Confirmation | 360 px | 957 px |
| 11 | Payment | 360 px | 1,163 px |
| 12 | Official Schedule | 360 px | 913 px |

Trong inspector, AI Tutor Matching có chiều rộng `Fixed (360 px)` và chiều cao `Hug (872 px)`. Official Schedule có chiều rộng `Fixed (360 px)`, chiều cao `Hug (913 px)` và `Min height: 800 px`. Các frame khác được ghi lại theo kích thước tổng thể quan sát được trong Figma.

## Đối chiếu yêu cầu nền tảng

- Yêu cầu thiết kế của bài là Android mobile-first, khung cơ sở `360dp` và cần cân nhắc `412dp`.
- 11 frame trong bảng rộng 360 px; Home rộng 402 px. Vì vậy Home hiện chưa khớp chính xác với khung cơ sở 360dp và cần được chuẩn hóa trong Figma trước khi bàn giao triển khai.
- Page Final UI có các frame responsive được đặt tên 412dp. Kích thước cụ thể của các biến thể đó chưa được đo và không được suy ra từ tên frame.
- Chiều cao các frame khác nhau; khi triển khai cần giữ nội dung cuộn được và kiểm tra ở viewport Android thực tế. Không thu nhỏ hoặc cắt nội dung để ép mọi màn hình về `360 × 800`.

## Phạm vi ảnh minh chứng trong repository

- `assets/initial screen/` chứa 12 ảnh kết quả ban đầu từ Google Stitch theo ba batch.
- `assets/ux-critique/` chứa ảnh Before/After cho năm UX findings.
- Ảnh giao diện Figma do người dùng cung cấp được lưu tại [assets/figma-screens](../assets/figma-screens/README.md), gồm 12 màn hình chính và một trạng thái kết quả AI.
- Ảnh Home có kích thước raster 804 × 2400 px, còn inspector Figma hiện ghi frame 402 × 874 px. Ghi chú này được giữ rõ trong index; 11 ảnh màn hình chính còn lại khớp kích thước frame ở tỉ lệ raster 2×. Trạng thái AI Results là ảnh bổ sung và chưa đo frame riêng.
- Dùng [file Figma](https://www.figma.com/design/gqbuTDuZYOyKyP8LsUwobC/BeeWise-Design?node-id=2-3&t=XLL8PoLbIdyZCOIC-1) để xem thiết kế hiện tại và kích thước frame nguồn.
