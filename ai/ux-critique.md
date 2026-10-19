# BeeWise — UX Critique (Lab 2)

> Nguồn: quan sát 12 màn hình Initial UI và 5 bộ Before/After do nhóm tạo trong Google Stitch. Ảnh và prompt thực tế cần được bổ sung vào các đường dẫn bên dưới.

## Tổng hợp findings

| ID | Screen | Severity | Decision ban đầu | Trạng thái xác minh After |
|---|---|---|---|---|
| UX-01 | 01 Home | Medium | Modify | Chưa đánh giá |
| UX-02 | 01 Home | High | Modify | Chưa đánh giá |
| UX-03 | 02 Manual Tutor Search | Medium | Modify | Chưa đánh giá |
| UX-04 | 03 AI Tutor Matching | High | Modify | Chưa đánh giá |
| UX-05 | 12 Official Schedule | Medium | Modify | Chưa đánh giá |

## Chi tiết từng finding

### UX-01 — Banner AI quá nhiều thông tin

- **Screen:** 01 Home
- **Severity:** Medium
- **Observation:** Banner AI chứa nhiều nhãn, thông điệp và CTA khiến hành động chính chưa nổi bật.
- **User impact:** Phụ huynh mất thời gian xác định thao tác tìm gia sư.
- **Decision on initial design:** Modify
- **Proposed solution:** Rút gọn nội dung banner, giữ một CTA chính rõ ràng.
- **Acceptance criteria:** Home: banner gọn, CTA chính dễ nhận biết.
- **Prompt thực tế:** [`UX-01.txt`](prompts/UX-01.txt)

**Before:**
![UX-01 Before](../assets/ux-critique/UX-01/before.png)

**After:**
![UX-01 After](../assets/ux-critique/UX-01/after.png)

- **Đánh giá After:** [ ] Đạt  [ ] Cần sửa tiếp  [ ] Từ chối
- **Evidence-based notes:** TODO — ghi nhận xét dựa trên ảnh After thật.

### UX-02 — CTA không phù hợp quy trình nghiệp vụ

- **Screen:** 01 Home
- **Severity:** High
- **Observation:** Nút “Đặt lịch thử” xuất hiện trên card gia sư, trong khi quy trình BeeWise yêu cầu gửi yêu cầu kết nối và trao đổi với tư vấn viên trước khi học thử.
- **User impact:** Người dùng có thể hiểu nhầm có thể tự đặt lịch học thử ngay.
- **Decision on initial design:** Modify
- **Proposed solution:** Đổi CTA thành “Yêu cầu kết nối”, yêu cầu đăng nhập nếu là guest, sau đó vào nhóm chat 3 bên.
- **Acceptance criteria:** Không còn CTA đặt lịch thử trực tiếp từ Home.
- **Prompt thực tế:** [`UX-02.txt`](prompts/UX-02.txt)

**Before:**
![UX-02 Before](../assets/ux-critique/UX-02/before.png)

**After:**
![UX-02 After](../assets/ux-critique/UX-02/after.png)

- **Đánh giá After:** [ ] Đạt  [ ] Cần sửa tiếp  [ ] Từ chối
- **Evidence-based notes:** TODO — ghi nhận xét dựa trên ảnh After thật.

### UX-03 — Bộ lọc và sắp xếp chưa rõ ràng

- **Screen:** 02 Manual Tutor Search
- **Severity:** Medium
- **Observation:** Khu vực lọc/sắp xếp dày đặc; một số nhãn bị cắt, thao tác đặt lại khó nhận biết.
- **User impact:** Khó biết tiêu chí nào đang áp dụng và cách chỉnh sửa.
- **Decision on initial design:** Modify
- **Proposed solution:** Phân biệt rõ Bộ lọc và Sắp xếp; chip lọc có thể xóa, có Xóa tất cả.
- **Acceptance criteria:** Nhãn đầy đủ; xóa từng bộ lọc hoặc tất cả; sắp xếp dễ nhận biết.
- **Prompt thực tế:** [`UX-03.txt`](prompts/UX-03.txt)

**Before:**
![UX-03 Before](../assets/ux-critique/UX-03/before.png)

**After:**
![UX-03 After](../assets/ux-critique/UX-03/after.png)

- **Đánh giá After:** [ ] Đạt  [ ] Cần sửa tiếp  [ ] Từ chối
- **Evidence-based notes:** TODO — ghi nhận xét dựa trên ảnh After thật.

### UX-04 — AI Search rườm rà và chưa trình bày Top 3

- **Screen:** 03 AI Tutor Matching
- **Severity:** High
- **Observation:** Khối BeeBot AI chiếm diện tích; timeline phân tích dài; kết quả tập trung một gia sư, các lựa chọn khác chưa có lý do đề xuất đầy đủ.
- **User impact:** Phụ huynh phải cuộn nhiều và khó so sánh gia sư.
- **Decision on initial design:** Modify
- **Proposed solution:** Bỏ khối BeeBot giới thiệu, rút gọn loading, hiển thị Top 3 gia sư với lý do riêng; bỏ tỷ lệ khớp chưa xác minh.
- **Acceptance criteria:** Top 3 card có thông tin so sánh, lý do cá nhân hóa; không có tuyên bố độ chính xác chưa xác minh.
- **Prompt thực tế:** [`UX-04.txt`](prompts/UX-04.txt)

**Before:**
![UX-04 Before](../assets/ux-critique/UX-04/before.png)

**After:**
![UX-04 After](../assets/ux-critique/UX-04/after.png)

- **Đánh giá After:** [ ] Đạt  [ ] Cần sửa tiếp  [ ] Từ chối
- **Evidence-based notes:** TODO — ghi nhận xét dựa trên ảnh After thật.

### UX-05 — Thông tin đầu màn hình lịch học quá rườm rà

- **Screen:** 12 Official Schedule
- **Severity:** Medium
- **Observation:** Thông báo thanh toán thành công, trạng thái kích hoạt, mã giao dịch và giải thích đồng bộ bị lặp, đẩy lịch học xuống dưới.
- **User impact:** Phụ huynh phải cuộn mới thấy lịch hằng tuần.
- **Decision on initial design:** Modify
- **Proposed solution:** Rút gọn thông báo thành công thành một dòng, đưa gia sư và lịch học lên trước.
- **Acceptance criteria:** Lịch Thứ Ba/Thứ Sáu và gia sư được ưu tiên trên màn hình.
- **Prompt thực tế:** [`UX-05.txt`](prompts/UX-05.txt)

**Before:**
![UX-05 Before](../assets/ux-critique/UX-05/before.png)

**After:**
![UX-05 After](../assets/ux-critique/UX-05/after.png)

- **Đánh giá After:** [ ] Đạt  [ ] Cần sửa tiếp  [ ] Từ chối
- **Evidence-based notes:** TODO — ghi nhận xét dựa trên ảnh After thật.
