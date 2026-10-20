# User Personas

## Phạm vi và độ tin cậy

Chị Lan tiếp tục là persona chính của BeeWise. Ba persona hỗ trợ mở rộng các bối cảnh tìm kiếm và kết nối của phụ huynh trong những luồng hiện có; họ không bổ sung vai trò gia sư hay tư vấn viên vào phạm vi thiết kế.

- **Thông tin sản phẩm trong repo:** BeeWise là ứng dụng Android giúp phụ huynh tìm gia sư bằng tìm kiếm thủ công hoặc AI, gửi yêu cầu kết nối, trao đổi trong nhóm ba bên với gia sư và tư vấn viên, rồi đi qua bước học thử, xác nhận lớp, thanh toán và xem lịch chính thức.
- **Thông tin người dùng:** Tên và tuổi là ví dụ. Bối cảnh gia đình, công việc, thói quen, mục tiêu, khó khăn và nhu cầu accessibility của cả bốn persona đều là **giả định thiết kế**, chưa được kiểm chứng bằng phỏng vấn, khảo sát hay dữ liệu sử dụng. Không xem các giả định này là kết quả nghiên cứu.
- **Nhu cầu accessibility:** Đây là các điều kiện cần thiết kế và kiểm chứng, không phải bằng chứng về tình trạng sức khỏe của người dùng. Persona Hạnh nêu một tình huống hỗ trợ phóng to văn bản như giả thuyết tiếp cận.
- **Hình ảnh:** Cả bốn chân dung dưới đây được tạo bằng AI để minh họa persona; không phải ảnh người dùng thật hay minh chứng nghiên cứu.

## Problem Statement

Phụ huynh tìm gia sư cho con cần xem năng lực, học phí và lịch học trong cùng một quy trình rõ ràng để so sánh lựa chọn và kết nối có hỗ trợ mà không phải tự thu thập thông tin qua nhiều cuộc trò chuyện rời rạc.

## Measurable Success Criterion

**Mục tiêu kiểm thử đề xuất, chưa phải kết quả đo:** Ít nhất 4/5 phụ huynh tham gia kiểm thử, bắt đầu ở trạng thái khách, có thể tìm hồ sơ phù hợp, xem học phí và lịch học, rồi gửi yêu cầu kết nối trong tối đa 5 phút mà không cần trợ giúp hoặc gặp lỗi nghiêm trọng.

## 1. Chị Lan — Persona chính

<img src="../assets/personas/lan.png" alt="Ảnh minh họa AI cho persona Chị Lan" width="220">

- **Tuổi và vai trò:** 38 tuổi (nhóm tuổi minh họa 35–40); nhân viên văn phòng, phụ huynh đang tìm gia sư cho con chuẩn bị thi vào lớp 10.
- **Bối cảnh hằng ngày:** Theo mô tả persona hiện có, chị tìm gia sư Toán sau giờ làm, thường vào buổi tối. Bối cảnh và thói quen thiết bị là giả định cần kiểm chứng.
- **Mục tiêu:** Tìm gia sư có kinh nghiệm ôn thi, học phí hợp lý, lịch phù hợp và thông tin năng lực rõ ràng.
- **Khó khăn:** Khó xác minh năng lực; phải hỏi riêng về học phí và lịch; khó so sánh mức độ phù hợp giữa các hồ sơ.
- **Thói quen thiết bị:** Giả định chị dùng điện thoại Android trong các phiên ngắn buổi tối; hiện tìm qua Facebook hoặc người quen rồi so sánh bằng tin nhắn.
- **Nhu cầu accessibility:** Nội dung chia đoạn dễ quét, chữ có thể phóng to, tương phản rõ, trạng thái không chỉ phân biệt bằng màu và nút chính dễ chạm.
- **JTBD:** “Khi con gặp khó khăn với môn Toán trước kỳ thi tuyển sinh, tôi muốn nhanh chóng tìm và đánh giá gia sư phù hợp để con được hỗ trợ học tập có định hướng.”
- **Kết quả mong đợi:** Chọn được hồ sơ phù hợp, gửi yêu cầu và biết bước tiếp theo là trao đổi trong nhóm chat ba bên.
- **Luồng liên quan:** Flow 01 — tìm thủ công và kết nối; có thể chuyển sang Flow 02 nếu chưa tìm được gia sư phù hợp.

## 2. Anh Minh — Phụ huynh cần định hướng tìm kiếm

<img src="../assets/personas/minh.png" alt="Ảnh minh họa AI cho persona Anh Minh" width="220">

- **Tuổi và vai trò:** 42 tuổi (nhóm tuổi minh họa 40–45); kỹ sư và phụ huynh có con học lớp 7.
- **Bối cảnh hằng ngày:** Lịch làm việc dày; muốn tìm hỗ trợ Toán đều đặn nhưng chưa biết mô tả chính xác nhu cầu của con bằng các bộ lọc.
- **Mục tiêu:** Nhanh chóng hiểu loại gia sư nào phù hợp, xem lý do đề xuất và chọn lịch học có thể duy trì.
- **Khó khăn:** Ít thời gian đọc nhiều hồ sơ; không chắc nên bắt đầu bằng môn học, trình độ hay lịch rảnh nào.
- **Thói quen thiết bị:** Giả định anh dùng Android, kiểm tra ứng dụng trong giờ nghỉ và có thể nhập nhu cầu bằng ngôn ngữ tự nhiên hoặc nhập liệu bằng giọng nói của thiết bị.
- **Nhu cầu accessibility:** Trường nhập liệu có nhãn rõ; hướng dẫn dễ hiểu; thông báo lỗi có cách thử lại; nội dung đã nhập không bị mất khi chuyển bước.
- **Kết quả mong đợi:** Thu hẹp lựa chọn bằng AI, hiểu vì sao gia sư được gợi ý, rồi mở hồ sơ hoặc chuyển sang tìm thủ công.
- **Luồng liên quan:** Flow 02 — AI Tutor Matching; khách có một lượt xử lý thành công miễn phí, lượt tiếp theo cần đăng nhập; AI lỗi không làm mất lượt miễn phí và có thể thử lại hoặc chuyển sang Flow 01.

## 3. Chị Mai — Phụ huynh cân đối chi phí và lịch học

<img src="../assets/personas/mai.png" alt="Ảnh minh họa AI cho persona Chị Mai" width="220">

- **Tuổi và vai trò:** 35 tuổi (nhóm tuổi minh họa 30–35); nhân viên kinh doanh và phụ huynh có con học lớp 6.
- **Bối cảnh hằng ngày:** Muốn tìm lớp tiếng Anh trực tuyến có thể học ngoài giờ; cần cân đối học phí với chi tiêu gia đình.
- **Mục tiêu:** So sánh học phí, hình thức dạy và lịch trước khi gửi yêu cầu kết nối.
- **Khó khăn:** Lo thông tin giá hoặc điều kiện học chỉ được nói sau nhiều lần nhắn tin; khó phân biệt học phí, lịch dự kiến và bước học thử.
- **Thói quen thiết bị:** Giả định chị dùng điện thoại Android tầm trung và dữ liệu di động; thường xem ứng dụng trong giờ nghỉ, ưu tiên danh sách và bộ lọc rõ.
- **Nhu cầu accessibility:** Trang tải gọn; nhãn bộ lọc dễ đọc; trạng thái được ghi bằng chữ hoặc biểu tượng thay vì chỉ dùng màu; thông tin chi phí hiển thị trực tiếp.
- **Kết quả mong đợi:** Xác định gia sư có hình thức và mức phí phù hợp trước khi đăng nhập và gửi yêu cầu.
- **Luồng liên quan:** Flow 01 — lọc và so sánh hồ sơ, sau đó yêu cầu kết nối; nếu tiếp tục, Flow 03 làm rõ học thử và thông tin lớp trước khi thanh toán.

## 4. Chị Hạnh — Phụ huynh cần theo dõi từng bước rõ ràng

<img src="../assets/personas/hanh.png" alt="Ảnh minh họa AI cho persona Chị Hạnh" width="220">

- **Tuổi và vai trò:** 52 tuổi (nhóm tuổi minh họa 50–55); phụ huynh có con học lớp 9.
- **Bối cảnh hằng ngày:** Quan tâm không chỉ đến việc chọn gia sư mà còn muốn biết rõ điều gì xảy ra sau buổi học thử, trước khi đồng ý với lớp chính thức.
- **Mục tiêu:** Kiểm tra môn học, học phí và lịch dự kiến; yêu cầu điều chỉnh nếu cần; chỉ thanh toán sau khi xác nhận lớp và biết lịch chính thức sẽ xuất hiện khi nào.
- **Khó khăn:** Nhiều bước và nhiều người cùng trao đổi có thể làm nhầm lẫn trạng thái lớp, thời điểm thanh toán hoặc lịch học.
- **Thói quen thiết bị:** Giả định chị dùng điện thoại Android, đọc tin nhắn và thông báo trong ngày; persona này dùng cỡ chữ hệ thống lớn như một tình huống accessibility cần kiểm chứng.
- **Nhu cầu accessibility:** Hỗ trợ phóng to chữ và TalkBack; nút đủ lớn; thông tin trạng thái có nhãn văn bản; nội dung không bị cắt khi tăng cỡ chữ.
- **Kết quả mong đợi:** Hiểu và hoàn tất tuần tự các bước học thử → xác nhận lớp → thanh toán → lịch chính thức; có thể yêu cầu sửa lớp hoặc thử lại khi thanh toán lỗi.
- **Luồng liên quan:** Flow 01 hoặc Flow 02 dẫn đến nhóm chat, sau đó Flow 03 — xác nhận lớp trước thanh toán; lịch chính thức chỉ xuất hiện sau khi thanh toán thành công.
