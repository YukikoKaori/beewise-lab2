# BeeWise — Phân tích UX (Lab 2)

Phạm vi sản phẩm: ứng dụng giúp phụ huynh tìm gia sư phù hợp, xem thông tin rõ ràng và đi qua quy trình kết nối có tư vấn viên BeeWise hỗ trợ.

## Tài liệu UX

- [Problem statement](ux/problem-statement.md)
- [User personas — 1 primary, 3 supporting](ux/persona.md)
- [Sitemap — 12 màn hình](ux/sitemap.md)
- [User flows — 3 luồng](ux/user-flow.md)

## AI design và minh chứng

- [AI Design Log](ai/ai-design-log.md)
- [UX Critique — 5 findings](ai/ux-critique.md)
- [Hướng dẫn minh chứng](ai/EVIDENCE-GUIDE.md)
- [AI Iteration 01 — Home & Business Flow](ai/iterations/iteration-01.md)
- [AI Iteration 02 — Tutor Discovery](ai/iterations/iteration-02.md)
- [AI Iteration 03 — Official Schedule](ai/iterations/iteration-03.md)

## Google Stitch

- [Mở project BeeWise_Lab2](https://stitch.withgoogle.com/projects/11519656942239142615)
- Trong project có thẻ prototype **“Prototype : BeeWise Tutoring Platform Flow”**. Hiện không có URL prototype riêng cho bản Stitch.

## Figma

- [Mở file BeeWise-Design](https://www.figma.com/design/gqbuTDuZYOyKyP8LsUwobC/BeeWise-Design?node-id=2-3&t=XLL8PoLbIdyZCOIC-1)
- File gồm 6 page:

| Page | Nội dung |
| --- | --- |
| 1. User Flow | Sơ đồ IA/sitemap; 3 flow có happy path, alternate path và error/recovery; bảng ánh xạ flow ↔ màn hình |
| 2. Wireframe | 12 màn low-fi (grayscale) cùng bố cục với Final UI |
| 3. Final UI | 12 màn chính (01 Home → 12 Official Schedule); 9 màn trạng thái loading/empty/error và dialog overlay; 4 màn kiểm tra ở 412dp |
| 4. Design System | Variables (Primitives → Color → Spacing & Radius), 11 text style, 3 effect style elevation, bảng contrast WCAG |
| 5. Components | Icons (Heroicons + logo Google), Button, IconButton, Chip, Badge, Avatar, Rating, TextField, SearchBar, AppBar, BottomNav, OnboardingStepper, InfoRow, TutorCard, Alert, Dialog, Loading, EmptyState, ErrorState, ChatBubble; logo và minh họa mascot BeeWise; bảng component → widget Flutter |
| 6. Prototype | 3 flow starting point; Back, bottom navigation, dialog overlay, chuyển cảnh loading → kết quả và nhánh lỗi → phục hồi |

## Trạng thái persona

`ux/persona.md` giữ Chị Lan làm persona chính và bổ sung ba persona hỗ trợ trong phạm vi phụ huynh của các luồng hiện có. Đặc điểm người dùng và nhu cầu accessibility là giả định thiết kế; repository không có nghiên cứu người dùng để xác nhận chúng.
