# AI Iteration 01 — Home & Business Flow

## Objective

Giảm nhiễu thông tin trên Home và sửa CTA cho đúng quy trình kết nối.

## Scope and execution order

- **Tool:** Google Stitch
- **Prompt sequence:** UX-01 → UX-02; hai prompt được gửi riêng, theo thứ tự lịch sử Agent Log.
- **Original screens:** Banner AI ở Home (UX-01) và CTA trên card gia sư ở Home (UX-02), theo ảnh Before.

### UX-01 — Home AI banner

**Actual prompt:** [UX-01.txt](../prompts/UX-01.txt)

**Before:**

![UX-01 Before](../../assets/ux-critique/UX-01/before.png)

**After:**

![UX-01 After](../../assets/ux-critique/UX-01/after.png)

**Evaluation:** CTA “Thử ghép AI ngay” nổi bật hơn, chức năng ghép gia sư bằng AI và quyền lợi dùng thử dễ hiểu; số liệu hài lòng không còn. Banner vẫn giữ hai nhãn, tiêu đề, mô tả hai dòng và hình minh họa. Các chi tiết này được chấp nhận như thông tin hỗ trợ, dù mức độ tinh gọn còn dư địa cải thiện.

**Final decision:** **Accept**

### UX-02 — Tutor card CTA

**Actual prompt:** [UX-02.txt](../prompts/UX-02.txt)

**Before:**

![UX-02 Before](../../assets/ux-critique/UX-02/before.png)

**After:**

![UX-02 After](../../assets/ux-critique/UX-02/after.png)

**Evaluation:** Hai card trong ảnh After đều dùng “Yêu cầu kết nối” thay vì “Đặt lịch thử”, phù hợp với quy trình có tư vấn viên.

**Final decision:** **Accept**

## Reflection

- **What improved:** CTA kết nối đã đổi đúng hành động nghiệp vụ; CTA AI dễ nhận biết hơn.
- **Evidence scope (non-blocking):** Banner UX-01 vẫn có các chi tiết hỗ trợ; ảnh UX-02 chứng minh CTA trên card, không bao phủ các bước đăng nhập/nhóm chat phía sau. Những giới hạn này không chặn quyết định theo tiêu chí của hai finding.
- **Next action:** Chấp nhận hai finding theo phạm vi minh chứng hiện có; không yêu cầu thêm prompt hoặc ảnh để hoàn tất báo cáo.

> Đây là nhóm báo cáo của hai prompt refinement riêng, không khẳng định chúng được gửi trong cùng một lần chạy.
