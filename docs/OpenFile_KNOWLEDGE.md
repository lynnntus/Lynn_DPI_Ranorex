# OpenFile Module — Knowledge Base

> Cập nhật: 2026-06-06 (session chốt — ValidateModelName implemented, Repository issue phát hiện)
> Mục đích: Lưu lại các fact đã chứng minh trong quá trình debug OpenFile module, tránh mất context giữa các session.

---

## 1. Current Status (chốt session 2026-06-06)

**PASS:**
- Open Recipe dialog mở thành công qua `LeftMenuOpenToogleButton` → `MenuOpenRecipe`.
- `MenuOpenRecipe` polling wait hoạt động (max 50s, poll 400ms).
- `RecipeFilePath` nhập vào `Text1148` thành công bằng `TextValue`.
- File được mở thực tế trong Neptune application.
- `ValidateModelName()` đã implement trong `OpenFile.UserCode.cs` — dùng `Validate.AreEqual`.
- CSV đã có cột `ModelName`, data binding hoạt động.
- Validation lấy actual từ `SomeText.Element.Parent.Caption` (ANCESTOR_L1), so sánh với `this.ModelName`.
- Với recipe `Lynn_Stacking_Underfill` — validation PASS.

**Known Issue đã xử lý:**
- Bước 6 (verify dialog closed sau click Open) gây false failure — đã loại bỏ tạm thời.

**Known Issue MỚI (CHƯA xử lý) — Repository Hardcode:**
- Repository item `CCIMainWindow.SomeText` hardcode `@caption='Lynn_Stacking_Underfill'` trong RxPath.
- Khi đổi TestData sang model khác (ví dụ `Lynn_Array_BadMark`), `SomeText.Exists()` = False → validation fail.
- Root cause: Repository selector, KHÔNG phải logic validation.
- Xem handover: `docs/HANDOVER_OpenFile_RepositoryIssue.md`

**Next Goal:**
- Phân tích và re-spy Repository selector — loại bỏ dependency vào giá trị model cụ thể.
- Làm cho selector hoạt động với mọi ModelName trong CSV.

---

## 1a. Problem ban đầu (đã RESOLVED)

- ~~Bug hiện tại nằm ở **bước nhập `RecipeFilePath` vào ô File name** (`Text1148`).~~
- ~~Test case chưa PASS vì chưa nhập và open được file recipe thành công.~~
- Warning: `RecipeFilePath`, `ExpectedFileName` chưa được bind CSV trong `.rxtst` — đang dùng default value.
- Default path: `C:\Kohyoung\Job\Lynn_20260516_Stacking\Lynn_Stacking_Underfill.kyjob`

---

## 2. Facts đã chứng minh

### Select Recipe File dialog

- Dialog đã mở được qua menu click: `LeftMenuOpenToogleButton` → `MenuOpenRecipe`.
- Regression "Element is not visible" cho `MenuOpenRecipe` đã fix bằng polling wait `WaitForMenuOpenRecipeClickable()` (max 50s, poll 400ms). **Đã test thực tế — PASS.**
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
- Code hiện tại đã có verify field text trước khi click Open.

### Bước 6 verify dialog closed — gây false failure (đã loại bỏ)

- Verify dialog closed sau click Open gây false failure vì dialog đóng ngay nhưng Neptune cần thời gian load.
- Đã loại bỏ tạm thời — thay bằng `Delay(2000)` + `Report.Info`.
- Sẽ thêm lại validation sau khi xác định timing đúng hoặc thay bằng ModelName validation.

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

- ~~**Chưa có cách ổn định để set/input full `RecipeFilePath` vào `Text1148` Win32 Edit control.**~~ → **RESOLVED** bằng `TextValue`.
- Các approach đã thử và fail:
  1. Clipboard + Ctrl+V → gõ literal "v"
  2. Ctrl+A để select all → gõ literal "a"
  3. SetAttributeValue("WindowText") → "The operation is not supported"
- **Approach PASS**: `repo.SelectRecipeFile.Text1148.TextValue = recipeFilePath`
- Chỉ được click Open **sau khi verify** field text chứa đúng full path hoặc `ExpectedFileName`.

---

## 5. Next Action

- Bug nhập path đã RESOLVED. Xem **Section 7: Lesson Learned**.
- Flow OpenFile đã test thực tế — file mở được trong Neptune.
- ~~**Next**: Implement ModelName validation~~ → **DONE** (session 2026-06-06).
- **Next**: Re-spy Repository selector để loại bỏ hardcode `@caption='Lynn_Stacking_Underfill'`.
  - Xem handover: `docs/HANDOVER_OpenFile_RepositoryIssue.md`
  - Mục tiêu: selector hoạt động với mọi ModelName — hỗ trợ multi-recipe testing.
- **Lesson Learn**: Xem `docs/lessons/openfile-dynamic-rxpath-lesson.md` — tổng hợp kinh nghiệm dynamic RxPath, investigation flow, anti-patterns, checklist.

---

## 6. Rules going forward

### KHÔNG dùng lại

- Ctrl+A / Ctrl+V / clipboard approach trên Text1148.
- `SetAttributeValue("WindowText", ...)` trên Text1148.
- `Report.Success` ngay sau click Open mà không verify.
- KHÔNG sửa `ValidateModelName()` logic — đã hoạt động đúng.

### BẮT BUỘC

- Verify field text **trước khi** click Open.
- Verify **không có popup** "file does not exist".
- Chỉ sửa `*.UserCode.cs`.
- Không commit/push khi chưa được yêu cầu.
- Repository issue phải giải quyết trong Ranorex Studio (re-spy), KHÔNG sửa `.rxrep` bằng tay.

> Note: Verify dialog closed đã thay bằng ModelName validation (Validate.AreEqual).

---

## 7. Lesson Learned — File name input

### Bug ban đầu
Không nhập được full `RecipeFilePath` vào ô File name của `Select Recipe File` dialog.

### Evidence đã chứng minh

- `Select Recipe File` dialog đã mở được.
- Spy xác nhận `Text1148` là Win32 Edit control:
  - Class = Edit
  - ControlId = 1148
  - AccessibleName = File name:
  - AccessibleRole = Text
  - Focusable = True
- Ctrl+A/Ctrl+V hoặc clipboard approach fail — field chỉ nhận literal `v` hoặc `av`.
- `SetAttributeValue("WindowText", path)` fail với lỗi: `The operation is not supported`.
- **`TextValue = recipeFilePath` hoạt động.**
- Report chứng minh:
  - `Field text sau set TextValue = C:\Kohyoung\Job\Lynn_20260516_Stacking\Lynn_Stacking_Underfill.kyjob`
  - `Path set dung`

### Kết luận

- Bug nhập path vào File name đã được **RESOLVED** bằng `TextValue`.
- **KHÔNG quay lại** các hướng đã fail:
  - Ctrl+A/Ctrl+V
  - Clipboard paste
  - `SetAttributeValue("WindowText")`
- **Rule mới**: Với Win32 Edit control trong Ranorex, ưu tiên dùng adapter property `TextValue` trước khi thử keyboard hoặc Win32 message.

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
| `CCIMainWindow.SomeText` | `//text[@caption='Lynn_Stacking_Underfill']/text[@caption='']` | **HARDCODED** — cần re-spy |

---

## 8. ModelName Validation — Facts (session 2026-06-06)

### Investigation Results

- `SomeText` (CHILD element) — `Caption = ''`, `Text = null`, tất cả attribute khác null.
- `SomeText.Element.Parent` (ANCESTOR_L1) — `Caption = 'Lynn_Stacking_Underfill'`, `Text = 'Lynn_Stacking_Underfill'`.
- **Kết luận**: Actual Model Name nằm ở ANCESTOR_L1 (parent của SomeText), attribute `Caption`.

### Implementation

- Method `ValidateModelName()` trong `OpenFile.UserCode.cs`.
- Đọc actual: `repo.CCIMainWindow.SomeText.Element.Parent` → `Caption` (fallback `Text`).
- Expected: `this.ModelName` (từ CSV/default).
- Validation: `Validate.AreEqual(actual, expected)` — chuẩn Ranorex, hiển thị đúng trong report.
- Screenshot tự động trước validation nếu phát hiện mismatch.

### Call Chain

```
ITestModule.Run()
  └─ OpenRecipeFileByPath()
       └─ Buoc 7:
            SomeTextInfo.Exists(30s)
            InvestigateModelNameElement()   ← phase 1 investigation logs (giữ tạm)
            ValidateModelName()             ← validation chính thức
```

### Repository Hardcode Issue

- RxPath của `SomeText` và `SomeIndicator` chứa `@caption='Lynn_Stacking_Underfill'`.
- Chỉ match khi recipe có model name = `Lynn_Stacking_Underfill`.
- Với recipe khác → `SomeText.Exists()` = False → validation fail trước khi đến logic so sánh.
- **Đây KHÔNG phải lỗi validation** — root cause nằm ở Repository selector.
- Cần re-spy trong Ranorex Studio để tạo dynamic selector.
