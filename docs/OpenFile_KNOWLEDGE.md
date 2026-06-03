# OpenFile Module — Knowledge Base

> Cập nhật: 2026-06-03
> Mục đích: Lưu lại các fact đã chứng minh trong quá trình debug OpenFile module, tránh mất context giữa các session.

---

## 1. Current Problem

- OpenFile module đã mở được **Select Recipe File** dialog thành công.
- Bug hiện tại nằm ở **bước nhập `RecipeFilePath` vào ô File name** (`Text1148`).
- Test case chưa PASS vì chưa nhập và open được file recipe thành công.
- Warning: `RecipeFilePath`, `ExpectedFileName` chưa được bind CSV trong `.rxtst` — đang dùng default value.
- Default path: `C:\Kohyoung\Job\Lynn_20260516_Stacking\Lynn_Stacking_Underfill.kyjob`

---

## 2. Facts đã chứng minh

### Select Recipe File dialog

- Dialog đã mở được qua menu click: `LeftMenuOpenToogleButton` → `MenuOpenRecipe`.
- Regression "Element is not visible" cho `MenuOpenRecipe` đã fix bằng polling wait `WaitForMenuOpenRecipeClickable()` (max 50s, poll 400ms). Build PASS nhưng **chưa test thực tế**. Chưa commit.
- Dialog title: `Select Recipe File` (Windows Open Dialog).

### Text1148 — ô File name

- Spy xác nhận thuộc tính:
  - **Class**: Edit
  - **ControlId**: 1148
  - **AccessibleName**: File name:
  - **AccessibleRole**: Text
  - **Focusable/Focused**: True
- Nằm bên trong **ComboBox** (controlid=1148):
  - Repository refpath: `/form[@title='Select Recipe File']/combobox[@controlid='1148']/text[@controlid='1148']`
  - Robust path: `/form[@title='Select Recipe File']/?/?/text[@controlid='1148']`

### Keyboard input KHÔNG hoạt động trên Text1148

- `element.PressKeys("{Control down}{a}{Control up}")` → gõ literal "a", không phải Ctrl+A.
- `Keyboard.Press("{LControlKey down}v{LControlKey up}")` → gõ literal "v", không phải Ctrl+V.
- Spy xác nhận: `NativeWindow windowtext = 'v'` sau khi chạy Ctrl+V.
- `Keyboard.DefaultKeyPressTime = 20ms` (set trong OpenFile.cs:103) — có thể là nguyên nhân modifier keys fail.

### SetAttributeValue KHÔNG hoạt động trên Text1148

- `SetAttributeValue("WindowText", path)` → lỗi `The operation is not supported`.
- `SetAttributeValue("Text", path)` → chưa có bằng chứng hoạt động (chưa test được do regression trước đó chặn).

### Report false PASS (đã fix)

- Code cũ click Open rồi ngay `Report.Success` — không verify dialog đóng.
- Code hiện tại đã có verify: kiểm tra dialog đóng (Bước 6), throw nếu còn mở.

---

## 3. Giả thuyết đã loại bỏ

| Giả thuyết | Bằng chứng loại bỏ |
|---|---|
| Ctrl+O vẫn còn active trong code | Grep: 0 active match, chỉ 2 dòng commented out (OpenFile.cs:116-117) |
| MenuOpenRecipe là root cause chính | Đã fix regression, dialog mở được. Các report trước cũng mở được dialog |
| Text1148 là static label / wrong control | Spy xác nhận: Class=Edit, AccessibleRole=Text, Focusable=True |
| SetAttributeValue("WindowText") là giải pháp đúng | Lỗi "The operation is not supported" khi chạy |
| Binary cũ / source-binary mismatch | Timestamp 6/2, đã rebuild cả Debug + Release |

---

## 4. Current Blocker

- **Chưa có cách ổn định để set/input full `RecipeFilePath` vào `Text1148` Win32 Edit control.**
- Các approach đã thử và fail:
  1. Clipboard + Ctrl+V → gõ literal "v"
  2. Ctrl+A để select all → gõ literal "a"
  3. SetAttributeValue("WindowText") → "The operation is not supported"
- Chỉ được click Open **sau khi verify** field text chứa đúng full path hoặc `ExpectedFileName`.

---

## 5. Next Action

Đánh giá và chọn 1 trong các hướng xử lý (theo thứ tự ưu tiên):

| # | Approach | Mô tả | Rủi ro |
|---|---|---|---|
| 1 | `TextValue = path` | Set property trực tiếp qua Ranorex adapter | Có thể read-only |
| 2 | `PressKeys(fullPath)` | Gõ từng ký tự path trực tiếp, không modifier keys | Ký tự đặc biệt (`\`, `:`) có thể bị interpret sai |
| 3 | `Keyboard.Press(fullPath)` | Gõ global từng ký tự | Cần focus đúng element, ký tự đặc biệt |
| 4 | `WM_SETTEXT` (P/Invoke) | Gửi Win32 message trực tiếp đến control handle | Cần P/Invoke, phức tạp hơn |

Lưu ý cho approach 2 và 3:
- Ranorex `PressKeys` interpret `{}` và modifier keys — path chứa `\` cần escape.
- Cần clear field trước khi gõ (triple-click hoặc Home+Shift+End để select all).

---

## 6. Rules going forward

### KHÔNG dùng lại

- Ctrl+A / Ctrl+V / clipboard approach trên Text1148.
- `SetAttributeValue("WindowText", ...)` trên Text1148.
- `Report.Success` ngay sau click Open mà không verify.

### BẮT BUỘC

- Verify field text **trước khi** click Open.
- Verify dialog **đã đóng** sau khi click Open.
- Verify **không có popup** "file does not exist".
- Chỉ sửa `*.UserCode.cs`.
- Không commit/push khi chưa được yêu cầu.

---

## Files liên quan

| File | Vai trò | Được sửa? |
|---|---|---|
| `OpenFile.UserCode.cs` | Custom logic — file chính đang debug | CÓ |
| `OpenFile.cs` | Auto-generated, gọi `Init()` → `OpenRecipeFileByPath()` → `SomeIndicator.WaitForExists(30000)` | KHÔNG |
| `OpenFile.rxrec` | Recording definition, module variables | KHÔNG |
| `Lynn_DPI_ATRepository.cs/.rxrep` | RxPath selector cho UI elements | KHÔNG |
| `TestData/OpenFileData.csv` | Data source cho RecipeFilePath, ExpectedFileName | KHÔNG (cấu hình binding trong Ranorex Studio) |

## Repository items quan trọng

| Item | RxPath | Dùng để |
|---|---|---|
| `SelectRecipeFile.Text1148` | `?/?/text[@controlid='1148']` | File name field (Win32 Edit trong ComboBox) |
| `ButtonOpen` | `/form[@title='Select Recipe File']/button[@text='&Open']` | Nút Open |
| `CCIMainWindow.SomeIndicator` | `indicator[1]` | Chỉ báo file load (active step trong OpenFile.cs:145-146) |
| `CCIMainWindow.LeftMenuOpenToogleButton` | (xem repository) | Nút mở menu sidebar |
| `CCIMainWindow.MenuOpenRecipe` | `button[@text='Open Recipe']` | Mục Open Recipe trong menu |
