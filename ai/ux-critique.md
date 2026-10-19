# BeeWise — UX Critique (Lab 2)

Nguồn đánh giá: ảnh Before/After trong repository và màn hình After đã đối chiếu trên Google Stitch. Quyết định bên dưới phản ánh bằng chứng hiện có; trường hợp thiếu ảnh chứng minh được ghi rõ là **Modify further**.

## Tổng hợp findings

| ID | Screen | Severity | Quyết định ban đầu | Quyết định After | Kết quả đối chiếu |
|---|---|---|---|---|---|
| UX-01 | 01 Home | Medium | Modify | **Modify further** | CTA rõ, nhưng banner vẫn cao và còn nhiều thành phần. |
| UX-02 | 01 Home | High | Modify | **Accept** | Hai card gia sư hiển thị CTA “Yêu cầu kết nối”. |
| UX-03 | 03 Manual Tutor Search | Medium | Modify | **Accept** | Bộ lọc, sắp xếp, chip và thao tác xóa được phân biệt rõ. |
| UX-04 | 02 AI Tutor Matching | High | Modify | **Modify further** | Canvas có đủ Top 3; ảnh After lưu trong repo chỉ thấy gia sư hạng 1. |
| UX-05 | 12 Official Schedule | Medium | Modify | **Accept** | Trạng thái gọn, gia sư và lịch Thứ Ba/Thứ Sáu được ưu tiên. |

## Chi tiết từng finding

### UX-01 — Banner AI quá nhiều thông tin

- **Screen:** 01 Home
- **Severity:** Medium
- **Observation:** Banner AI ban đầu có ưu đãi, thời gian ghép, tiêu đề, mô tả, số liệu hài lòng, mascot và CTA.
- **User impact:** Phụ huynh mất thời gian xác định thao tác tìm gia sư.
- **Decision on initial design:** Modify
- **Proposed solution:** Rút gọn banner và giữ một CTA chính rõ ràng.
- **Acceptance criteria:** Banner gọn; CTA chính dễ nhận biết.
- **Prompt thực tế:** [UX-01.txt](prompts/UX-01.txt)

**Before:**

![UX-01 Before](../assets/ux-critique/UX-01/before.png)

**After:**

![UX-01 After](../assets/ux-critique/UX-01/after.png)

- **Evaluation:** Nút “Thử ghép AI ngay” dễ nhận biết và số liệu hài lòng không còn. Tuy vậy, banner vẫn chiếm nhiều chiều cao và giữ hai nhãn, tiêu đề, mô tả hai dòng cùng hình minh họa.
- **Decision after:** **Modify further**
- **Evidence-based note:** Tiêu chí về CTA đạt; tiêu chí banner gọn chưa đạt. Prompt tiếp theo nên bỏ bớt nhãn và rút phần giải thích xuống một câu.

### UX-02 — CTA không phù hợp quy trình nghiệp vụ

- **Screen:** 01 Home
- **Severity:** High
- **Observation:** Nút “Đặt lịch thử” xuất hiện trên card gia sư, trong khi quy trình BeeWise yêu cầu yêu cầu kết nối và trao đổi với tư vấn viên trước buổi học thử.
- **User impact:** Người dùng có thể hiểu nhầm rằng họ tự đặt buổi học thử ngay từ card.
- **Decision on initial design:** Modify
- **Proposed solution:** Đổi CTA thành “Yêu cầu kết nối”; yêu cầu đăng nhập khi cần, sau đó tiếp tục luồng nhóm chat ba bên.
- **Acceptance criteria:** Không còn CTA đặt lịch thử trực tiếp từ Home.
- **Prompt thực tế:** [UX-02.txt](prompts/UX-02.txt)

**Before:**

![UX-02 Before](../assets/ux-critique/UX-02/before.png)

**After:**

![UX-02 After](../assets/ux-critique/UX-02/after.png)

- **Evaluation:** Cả hai card gia sư trong ảnh After dùng nút “Yêu cầu kết nối”; không còn CTA đặt lịch thử trực tiếp.
- **Decision after:** **Accept**
- **Evidence-based note:** Ảnh xác minh được CTA trên danh sách; màn hình này không chứng minh bước đăng nhập hoặc nhóm chat phía sau.

### UX-03 — Bộ lọc và sắp xếp chưa rõ ràng

- **Screen:** 03 Manual Tutor Search
- **Severity:** Medium
- **Observation:** Khu vực lọc/sắp xếp dày đặc; một số nhãn bị cắt, thao tác đặt lại khó nhận biết.
- **User impact:** Khó biết tiêu chí nào đang áp dụng và cách chỉnh sửa.
- **Decision on initial design:** Modify
- **Proposed solution:** Phân biệt rõ Bộ lọc và Sắp xếp; chip lọc có thể xóa; cung cấp “Xóa tất cả”.
- **Acceptance criteria:** Nhãn rõ ràng; có thể xóa từng bộ lọc hoặc tất cả; sắp xếp dễ nhận biết.
- **Prompt thực tế:** [UX-03.txt](prompts/UX-03.txt)

**Before:**

![UX-03 Before](../assets/ux-critique/UX-03/before.png)

**After:**

![UX-03 After](../assets/ux-critique/UX-03/after.png)

- **Evaluation:** Ảnh After cho thấy nút “Bộ lọc” có số lượng, điều khiển “Sắp xếp: Phù hợp nhất”, chip có nút bỏ chọn và “Xóa tất cả”. Canvas Stitch cũng hiển thị các nhãn bộ lọc đầy đủ.
- **Decision after:** **Accept**
- **Evidence-based note:** Ảnh tĩnh không mở bottom sheet sắp xếp; tiêu chí chính về nhận biết và chỉnh bộ lọc được đáp ứng.

### UX-04 — AI Search rườm rà và chưa trình bày Top 3

- **Screen:** 02 AI Tutor Matching
- **Severity:** High
- **Observation:** Khối giới thiệu BeeBot và timeline phân tích dài chiếm chỗ; kết quả ban đầu ưu tiên một gia sư và có tỷ lệ khớp chưa được chứng minh.
- **User impact:** Phụ huynh phải cuộn nhiều và khó so sánh gia sư.
- **Decision on initial design:** Modify
- **Proposed solution:** Rút gọn phần tìm kiếm và hiển thị ba gia sư với lý do gợi ý riêng; bỏ tỷ lệ khớp chưa xác minh.
- **Acceptance criteria:** Có đúng ba thẻ gia sư đầy đủ thông tin, lý do cá nhân hóa và hành động; không có tuyên bố độ chính xác chưa xác minh.
- **Prompt thực tế:** [UX-04.txt](prompts/UX-04.txt)

**Before:**

![UX-04 Before](../assets/ux-critique/UX-04/before.png)

**After:**

![UX-04 After](../assets/ux-critique/UX-04/after.png)

- **Evaluation:** Canvas Stitch hiển thị ba thẻ hạng 1–3, mỗi thẻ có thông tin gia sư, lý do gợi ý và các hành động; không thấy tỷ lệ khớp kiểu 98% hoặc 96,4%. Tuy nhiên, ảnh After trong repository bị cắt và chỉ cho thấy thẻ hạng 1.
- **Decision after:** **Modify further**
- **Evidence-based note:** Nội dung thiết kế đã được kiểm tra trên canvas; bằng chứng lưu trong repository chưa đủ để người đọc xác minh ba thẻ. Thay ảnh After bằng ảnh rộng hơn trước khi nộp.

### UX-05 — Thông tin đầu màn hình lịch học quá rườm rà

- **Screen:** 12 Official Schedule
- **Severity:** Medium
- **Observation:** Thông báo thanh toán, trạng thái kích hoạt, mã giao dịch và giải thích đồng bộ bị lặp, đẩy lịch học xuống dưới.
- **User impact:** Phụ huynh phải cuộn mới thấy lịch hằng tuần.
- **Decision on initial design:** Modify
- **Proposed solution:** Rút gọn thông báo thành công và đưa gia sư cùng lịch học lên trước.
- **Acceptance criteria:** Gia sư và lịch Thứ Ba/Thứ Sáu được ưu tiên, kèm giờ và hình thức học khi có dữ liệu.
- **Prompt thực tế:** [UX-05.txt](prompts/UX-05.txt)

**Before:**

![UX-05 Before](../assets/ux-critique/UX-05/before.png)

**After:**

![UX-05 After](../assets/ux-critique/UX-05/after.png)

- **Evaluation:** Ảnh After đặt trạng thái thành công trong một hàng gọn; tên lớp, gia sư và hai buổi Thứ Ba/Thứ Sáu lúc 19:30–21:30 xuất hiện ngay bên dưới. Hình thức học tại nhà cũng được ghi cho cả hai buổi.
- **Decision after:** **Accept**
- **Evidence-based note:** Thông tin lịch chính đã dễ thấy hơn và không còn phần xác nhận thanh toán dài ở đầu màn hình.

## Kết luận

Ba finding được **Accept** (UX-02, UX-03, UX-05); hai finding cần làm tiếp (UX-01, UX-04). UX-01 cần tinh gọn thiết kế; UX-04 cần ảnh minh chứng đầy đủ hơn. Không có finding nào bị **Reject**.

Repository hiện không kèm rubric PRM323 Lab 2 chính thức; phần đánh giá này bám checklist và hướng dẫn minh chứng đang có trong repository.
