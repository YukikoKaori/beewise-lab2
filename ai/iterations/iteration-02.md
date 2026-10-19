# AI Iteration 02 — Tutor Discovery

## Objective

Làm rõ bộ lọc/sắp xếp và giúp phụ huynh so sánh gia sư từ kết quả AI.

## Scope and execution order

- **Tool:** Google Stitch
- **Prompt sequence:** UX-03 → UX-04; hai prompt được gửi riêng, theo thứ tự lịch sử Agent Log.
- **Original screens:** Manual Tutor Search (UX-03) và AI Tutor Matching (UX-04), theo ảnh Before.

### UX-03 — Manual Tutor Search filters

**Actual prompt:** [UX-03.txt](../prompts/UX-03.txt)

**Before:**

![UX-03 Before](../../assets/ux-critique/UX-03/before.png)

**After:**

![UX-03 After](../../assets/ux-critique/UX-03/after.png)

**Evaluation:** Ảnh After cho thấy “Bộ lọc” có badge số lượng, “Sắp xếp: Phù hợp nhất”, chip có nút bỏ chọn và “Xóa tất cả”. Canvas Stitch hiển thị nhãn bộ lọc đầy đủ.

**Final decision:** **Accept**

### UX-04 — AI Top 3 recommendations

**Actual prompt:** [UX-04.txt](../prompts/UX-04.txt)

**Before:**

![UX-04 Before](../../assets/ux-critique/UX-04/before.png)

**After:**

![UX-04 After](../../assets/ux-critique/UX-04/after.png)

**Evaluation:** Canvas Stitch cho thấy đủ ba thẻ xếp hạng, lý do gợi ý cá nhân hóa và hành động xem hồ sơ/yêu cầu kết nối; không thấy phần trăm khớp chưa xác minh. File ảnh After trong repository chỉ hiển thị thẻ hạng 1 nên chưa đủ bằng chứng cho người đọc.

**Final decision:** **Modify further** — bổ sung ảnh After rộng hơn để thể hiện cả ba thẻ. Quyết định này đóng khoảng trống minh chứng trong repository; phần thiết kế ba thẻ đã được xác minh trên canvas Stitch.

## Reflection

- **What improved:** Bộ điều khiển tìm kiếm và lọc/sắp xếp rõ hơn; canvas AI có ba gia sư với lý do và hành động riêng.
- **What remains unresolved:** Ảnh UX-04 After lưu trong repository bị cắt; ảnh UX-03 tĩnh không cho thấy bottom sheet sắp xếp đang mở.
- **Next action:** Thay ảnh UX-04 bằng ảnh đủ rộng và, nếu cần chứng minh lựa chọn sắp xếp, bổ sung ảnh trạng thái bottom sheet.

> Đây là nhóm báo cáo của hai prompt refinement riêng, không khẳng định chúng được gửi trong cùng một lần chạy.
