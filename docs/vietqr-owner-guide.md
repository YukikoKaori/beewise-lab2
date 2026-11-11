# VietQR BeeWise: cấu hình và kiểm tra không chuyển tiền

1. Vào [Firestore Console của beewise-lab-3](https://console.firebase.google.com/project/beewise-lab-3/firestore), chọn database `(default)` → **Data**. Nếu chưa có `settings`, tạo collection `settings` và document ID `paymentRecipient`. Nếu đã có document, kiểm tra giá trị hiện tại trước khi sửa. Chỉ người vận hành có quyền Firebase mới chỉnh được; Web Admin không có quyền ghi cấu hình này.
2. Lấy mã BIN VietQR **6 chữ số** từ ngân hàng nhận hoặc đối chiếu mã ngân hàng thụ hưởng trong [tài liệu kỹ thuật NAPAS](https://developer.napas.com.vn/files/assets/files/Techspec_NapasCore_v1.2.pdf). Xác nhận ngân hàng hỗ trợ VietQR. Lấy số tài khoản và tên chủ tài khoản trực tiếp từ ứng dụng ngân hàng hoặc sao kê của chủ tài khoản. Dùng số tài khoản nhận tiền, không dùng số thẻ.
3. Nhập đủ bốn trường kiểu **string**. Giữ nguyên số 0 đầu, bỏ dấu cách/dấu gạch trong số tài khoản. Ví dụ dưới đây là dữ liệu giả để minh họa kiểu dữ liệu; không lưu vào production hoặc dùng để chuyển tiền.

   ```json
   {
     "bankBin": "000000",
     "accountNumber": "DEMO000000",
     "accountHolder": "TAI KHOAN GIA KHONG CHUYEN TIEN",
     "instructions": ""
   }
   ```

   `accountNumber`: 3–19 ký tự chữ/số. `accountHolder`: 2–100 ký tự. `instructions`: tối đa 300 ký tự; để chuỗi rỗng nếu không dùng. Kiểm tra bốn trường rồi bấm **Save**. Hóa đơn chụp lại thông tin người nhận tại lúc phát hành; sửa cấu hình không sửa hóa đơn đã có.
4. Khi Web Admin đã hoạt động và Rules tương ứng đã được xác minh, đăng nhập bằng Google của staff/admin được chỉ định. Mở trang thanh toán, chọn **Phát hành đề xuất lớp** cho một chat Final test đủ điều kiện. Đọc/đối chiếu thông tin người nhận trên hóa đơn test; không dùng chat của khách thật. Chỉ phát hành trên production nếu qb đã duyệt dữ liệu test riêng; nếu chưa, dùng Firebase Emulator. Ví dụ tổng tiền **12.345 ₫** giúp phát hiện lỗi nhập hoặc định dạng.
5. Trên Android, mở chat test, kiểm tra tổng tiền rồi xác nhận đề xuất lớp để hiện QR. Dùng app ngân hàng quét QR trên máy khác. Đối chiếu ngân hàng, số tài khoản, tên người nhận nếu ngân hàng hiển thị, số tiền và nội dung/mã tham chiếu với hóa đơn. Dữ liệu giả có thể bị app ngân hàng từ chối; trường hợp đó chỉ kiểm tra cấu trúc QR bằng trình giải mã, không ghi nhận là quét ngân hàng thành công.
6. Dừng ở màn xem trước, thoát khỏi app ngân hàng trước nút chuyển tiền/xác nhận/OTP. Không bấm **đã chuyển khoản** trong BeeWise. Staff có thể hủy hóa đơn test chưa xác minh nếu trạng thái cho phép; với dữ liệu emulator, bỏ phiên test theo quy trình của môi trường đó.
7. Về sau, chỉ xác minh khi sao kê tài khoản nhận có giao dịch ghi có thật. Đối chiếu số tiền, mã tham chiếu, BIN và số tài khoản; nhập mã giao dịch duy nhất từ sao kê. QR hợp lệ, thao tác quét hoặc lời báo đã chuyển đều không chứng minh tiền đã về. Chỉ xác minh thành công mới mở lịch học chính thức.
