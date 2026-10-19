# BeeWise — AI Design Log

## Project

- **Tool:** Google Stitch
- **Project:** [BeeWise_Lab2](https://stitch.withgoogle.com/projects/11519656942239142615)

## Initial generation

Ba prompt tạo ban đầu được lưu riêng; đây là prompt tạo màn hình, không tính là các vòng UX refinement.

| Batch | Prompt đã chạy | Ảnh đầu ra |
|---|---|---|
| 01 | [initial-batch-01.txt](prompts/initial-batch-01.txt) | [screen1.png](../assets/initial%20screen/screen1.png), [screen2.png](../assets/initial%20screen/screen2.png), [screen3.png](../assets/initial%20screen/screen3.png), [screen4.png](../assets/initial%20screen/screen4.png) |
| 02 | [initial-batch-02.txt](prompts/initial-batch-02.txt) | [screen5.png](../assets/initial%20screen/screen5.png), [screen6.png](../assets/initial%20screen/screen6.png), [screen7.png](../assets/initial%20screen/screen7.png), [screen8.png](../assets/initial%20screen/screen8.png) |
| 03 | [initial-batch-03.txt](prompts/initial-batch-03.txt) | [screen9.png](../assets/initial%20screen/screen9.png), [screen10.png](../assets/initial%20screen/screen10.png), [screen11.png](../assets/initial%20screen/screen11.png), [screen12.png](../assets/initial%20screen/screen12.png) |

**Lưu ý về mã màn hình:** Prompt Batch 01 ghi Manual Tutor Search là màn 02 và AI Tutor Matching là màn 03. Sitemap, prompt Batch 03 và các finding trong báo cáo dùng thứ tự 02 AI Tutor Matching, 03 Manual Tutor Search. Các prompt được giữ nguyên như đã chạy; báo cáo dùng tên màn hình để tránh nhầm.

## Refinement history

Năm prompt refinement thực tế được chạy riêng theo thứ tự UX-01 → UX-02 → UX-03 → UX-04 → UX-05. Ba file iteration bên dưới là nhóm trình bày theo checklist; chúng không khẳng định mỗi file tương ứng một lần gửi prompt.

| Nhóm báo cáo | Phạm vi | Prompt thực tế | Ảnh và kết quả |
|---|---|---|---|
| [01 — Home & Business Flow](iterations/iteration-01.md) | UX-01, UX-02 | [UX-01](prompts/UX-01.txt), [UX-02](prompts/UX-02.txt) | Before/After trong file; UX-01 và UX-02 Accept |
| [02 — Tutor Discovery](iterations/iteration-02.md) | UX-03, UX-04 | [UX-03](prompts/UX-03.txt), [UX-04](prompts/UX-04.txt) | Before/After trong file; UX-03 và UX-04 Accept |
| [03 — Official Schedule](iterations/iteration-03.md) | UX-05 | [UX-05](prompts/UX-05.txt) | Before/After trong file; UX-05 Accept |

## Evidence and limits

- Năm cặp ảnh Before/After nằm tại [assets/ux-critique](../assets/ux-critique/).
- UX-01 được chấp nhận với CTA rõ ràng; các nhãn phụ và hình minh họa còn lại đóng vai trò thông tin hỗ trợ.
- Với UX-04, ảnh After trong repository cho thấy phần đầu và canvas Stitch tại project link xác nhận đủ ba thẻ hạng 1–3. Bộ bằng chứng hiện tại được chấp nhận.
- Prototype có thẻ **“Prototype : BeeWise Tutoring Platform Flow”** trong project Stitch. Không có URL prototype riêng hoặc Figma URL được lưu trong repository.
- Repository không kèm rubric PRM323 Lab 2 chính thức; đánh giá hiện dùng checklist và hướng dẫn minh chứng nội bộ.

## Integrity note

- Prompt files lưu prompt đã chạy; không thay thế prompt gốc bằng đề xuất mới.
- Cả năm findings đều được **Accept** theo đối chiếu hiện tại; ghi chú nêu rõ phạm vi ảnh và chi tiết thị giác còn lại.
