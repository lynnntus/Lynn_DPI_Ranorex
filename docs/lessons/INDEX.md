# Lessons Learned — Index

> Tra cứu theo triệu chứng để tìm lesson phù hợp.  
> Cập nhật: 2026-08-16

---

## Tra cứu nhanh theo triệu chứng

| Triệu chứng | Lesson | File |
|-------------|--------|------|
| `WaitForNotExists` hết timeout dù dialog đã đóng trên UI | Generic Popup Path Collision | [generic-popup-path-collision.md](generic-popup-path-collision.md) |
| `Exists()` trả True cho element đã biến mất | Generic Popup Path Collision | [generic-popup-path-collision.md](generic-popup-path-collision.md) |
| Spy thấy nhiều element match cùng RxPath `/form[@name='Popup']` | Generic Popup Path Collision | [generic-popup-path-collision.md](generic-popup-path-collision.md) |
| Ô File name chỉ chứa "v" hoặc "a" thay vì full path | Win32 Edit TextValue Input | [win32-edit-textvalue-input.md](win32-edit-textvalue-input.md) |
| `Ctrl+A` / `Ctrl+V` gõ literal character trong File Dialog | Win32 Edit TextValue Input | [win32-edit-textvalue-input.md](win32-edit-textvalue-input.md) |
| `SetAttributeValue("WindowText")` lỗi "not supported" | Win32 Edit TextValue Input | [win32-edit-textvalue-input.md](win32-edit-textvalue-input.md) |
| Dialog vẫn mở sau 3-5 giây dù click Apply/Open thành công | Dialog Close Polling Timeout | [dialog-close-polling-timeout.md](dialog-close-polling-timeout.md) |
| App hiện "Please Wait" / loading sau click button | Dialog Close Polling Timeout | [dialog-close-polling-timeout.md](dialog-close-polling-timeout.md) |
| Test FAIL intermittent — lúc PASS lúc FAIL cùng data | Dialog Close Polling Timeout | [dialog-close-polling-timeout.md](dialog-close-polling-timeout.md) |
| Repository item hardcode `@caption` cụ thể, chỉ match 1 giá trị | Dynamic RxPath for Hardcoded Selectors | [openfile-dynamic-rxpath-lesson.md](openfile-dynamic-rxpath-lesson.md) |
| `SomeText.Exists()` = False dù UI hiển thị text khác | Dynamic RxPath for Hardcoded Selectors | [openfile-dynamic-rxpath-lesson.md](openfile-dynamic-rxpath-lesson.md) |
| `Ctrl+A` bị WPF ComboBox intercept | WPF ComboBox Input | [../../.claude/lessons/login-retry-lesson.md](../../.claude/lessons/login-retry-lesson.md) (R1) |
| Clear field WPF ComboBox không hoạt động | WPF ComboBox Input | [../../.claude/lessons/login-retry-lesson.md](../../.claude/lessons/login-retry-lesson.md) (R1) |
| Sửa hàm nhưng không có effect — method không được gọi | Call Chain Verification | [../../.claude/lessons/login-retry-lesson.md](../../.claude/lessons/login-retry-lesson.md) (R2) |
| `Init()` không ngăn recording steps chạy | Init() Limitations | [../../.claude/lessons/login-retry-lesson.md](../../.claude/lessons/login-retry-lesson.md) (R3) |
| Test PASS row 1, FAIL row 2+ — element "not visible" dù UI hiển thị | Use Cache Stale Element | [repo-use-cache-stale-element.md](repo-use-cache-stale-element.md) |
| Repo accessor: Visible=False, Rect={0,0,0,0} — Direct find: Visible=True | Use Cache Stale Element | [repo-use-cache-stale-element.md](repo-use-cache-stale-element.md) |
| Dialog đóng rồi mở lại nhưng repo vẫn trỏ element cũ | Use Cache Stale Element | [repo-use-cache-stale-element.md](repo-use-cache-stale-element.md) |
| Polling `.Exists()` / `WaitForNotExists` loop hết timeout dù dialog đã đóng thật | Use Cache Stale Element | [repo-use-cache-stale-element.md](repo-use-cache-stale-element.md) |
| `WaitForNotExists` throw sớm hơn timeout parameter (~30s thay vì 90s) | WaitForNotExists Repo Timeout Limit | [waitfornotexists-repo-timeout-limit.md](waitfornotexists-repo-timeout-limit.md) |
| `WaitForNotExists` throw dù element đã biến mất (DIAG confirm 0 match) | WaitForNotExists Repo Timeout Limit | [waitfornotexists-repo-timeout-limit.md](waitfornotexists-repo-timeout-limit.md) |
| RxPath có `/form[...]/form[...]` — hai form nối nhau | RxPath Nested Form Invalid | [rxpath-nested-form-invalid.md](rxpath-nested-form-invalid.md) |
| Element tìm thấy chậm (~30s fallback) dù UI hiển thị ngay | RxPath Nested Form Invalid | [rxpath-nested-form-invalid.md](rxpath-nested-form-invalid.md) |
| Ranorex auto-generated Robust path chứa form lồng form | RxPath Nested Form Invalid | [rxpath-nested-form-invalid.md](rxpath-nested-form-invalid.md) |
| `Caption` trả về AutomationId thay vì text hiển thị | WPF Caption vs Text | [wpf-caption-vs-textvalue.md](wpf-caption-vs-textvalue.md) |
| `GetAttributeValueText("Caption")` trả giá trị tĩnh, không đổi dù UI thay đổi | WPF Caption vs Text | [wpf-caption-vs-textvalue.md](wpf-caption-vs-textvalue.md) |
| Validation FAIL: actual = internal name (ví dụ `topTextRecipeName`) | WPF Caption vs Text | [wpf-caption-vs-textvalue.md](wpf-caption-vs-textvalue.md) |

---

## Phân loại theo category

### Repository / UI Element
- [generic-popup-path-collision.md](generic-popup-path-collision.md) — RxPath generic match nhiều element
- [openfile-dynamic-rxpath-lesson.md](openfile-dynamic-rxpath-lesson.md) — Selector hardcode `@caption`
- [repo-use-cache-stale-element.md](repo-use-cache-stale-element.md) — Use Cache = True gây stale reference cho dialog/popup
- [rxpath-nested-form-invalid.md](rxpath-nested-form-invalid.md) — Form lồng form trong RxPath (dialog là top-level)

### Input / Keyboard
- [win32-edit-textvalue-input.md](win32-edit-textvalue-input.md) — Win32 Edit control: dùng `TextValue`
- `.claude/lessons/login-retry-lesson.md` (R1) — WPF ComboBox: dùng `{Home}{Shift+End}{Delete}`

### Timing / Wait
- [dialog-close-polling-timeout.md](dialog-close-polling-timeout.md) — Polling thay fixed wait cho dialog close
- [waitfornotexists-repo-timeout-limit.md](waitfornotexists-repo-timeout-limit.md) — WaitForNotExists bị giới hạn bởi repo search timeout

### Attribute / Property
- [wpf-caption-vs-textvalue.md](wpf-caption-vs-textvalue.md) — WPF Caption trả AutomationId, dùng Text/SelectionText

### Ranorex Framework
- `.claude/lessons/login-retry-lesson.md` (R2) — Kiểm tra call chain trước khi sửa hàm
- `.claude/lessons/login-retry-lesson.md` (R3) — `Init()` không thể skip recording steps

---

## Thứ tự đọc khi debug

1. **Element không tìm thấy / tìm thấy sai** → xem category "Repository / UI Element"
2. **Input text sai / không hoạt động** → xem category "Input / Keyboard"
3. **Test intermittent / timeout** → xem category "Timing / Wait"
4. **Code không có effect** → xem category "Ranorex Framework"
