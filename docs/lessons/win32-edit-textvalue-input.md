# Lesson: Win32 Edit Control — Dùng TextValue thay vì Keyboard

> **Ngày ghi nhận:** 2026-06-02 → 2026-06-03 (debug qua 2 session)  
> **Module:** OpenFile, OpenFile_FromProduction  
> **Session/HANDOFF liên quan:** `docs/HANDOVER_OpenFile_20260602.md`, `docs/HANDOVER_OpenFile_20260603.md`, `docs/OpenFile_KNOWLEDGE.md`

---

## Trigger

Khi nhập text vào ô input trong Windows File Dialog (ví dụ ô "File name" trong Select Recipe File dialog) mà text kết quả bị sai — chỉ có 1-2 ký tự thay vì full path.

## KHÔNG áp dụng khi

- Control là WPF ComboBox — xem `.claude/lessons/login-retry-lesson.md` (R1: dùng `{Home}{Shift+End}{Delete}`).
- Control nhận keyboard input bình thường (test thử `PressKeys("abc")` ra đúng "abc").
- Lỗi do data binding chưa cấu hình (variable = default value, không phải giá trị từ CSV).

## Triệu chứng

1. Sau khi gửi `Ctrl+A` + `Ctrl+V` hoặc `PressKeys(path)`, ô File name chỉ chứa "v", "a", hoặc vài ký tự rời rạc.
2. Ranorex Spy xác nhận: `NativeWindow windowtext = 'v'` (literal "v" thay vì paste content).
3. Click Open → popup "file does not exist" vì path sai.
4. Control có `controlid='1148'`, class `Edit`, nằm trong ComboBox của Windows File Dialog.

## Nguyên nhân gốc

Win32 Edit control (controlid=1148) trong Windows File Dialog KHÔNG xử lý modifier key combinations:

1. `{Control down}{a}{Control up}` → control nhận literal "a", bỏ qua Control modifier.
2. `Keyboard.Press("{LControlKey down}v{LControlKey up}")` → control nhận literal "v".
3. `SetAttributeValue("WindowText", path)` → lỗi "The operation is not supported".

Nguyên nhân kỹ thuật: Windows File Dialog dùng native Win32 Edit control với message loop riêng. Ranorex gửi WM_KEYDOWN/WM_CHAR nhưng modifier state không được áp dụng đúng ở control level (khác với WPF control xử lý input ở framework level).

## Cách xác minh

1. Mở Ranorex Spy, navigate đến ô input.
2. Kiểm tra thuộc tính: nếu thấy `Class: Edit`, `ControlId: 1148`, `AccessibleRole: Text` → đây là Win32 Edit control.
3. Thử `element.PressKeys("test123")` — nếu text xuất hiện đúng "test123", control nhận keyboard bình thường. Nếu text sai → confirm Win32 Edit issue.
4. Kiểm tra `element.TextValue` có accessible không (đọc thử giá trị hiện tại).

## Fix chuẩn

**Dùng property `TextValue` để set text trực tiếp:**

```csharp
// ❌ SAI — keyboard shortcuts không hoạt động trên Win32 Edit
element.PressKeys("{Control down}{a}{Control up}");
element.PressKeys("{Control down}{v}{Control up}");

// ❌ SAI — SetAttributeValue không hỗ trợ
element.SetAttributeValue("WindowText", path);

// ✅ ĐÚNG — TextValue set text trực tiếp qua Win32 API
var textField = repo.SelectRecipeFile.Text1148;
textField.TextValue = path;
```

**Verify sau khi set:**

```csharp
string actual = textField.TextValue;
if (!string.Equals(actual, path, StringComparison.OrdinalIgnoreCase))
{
    Report.Log(ReportLevel.Failure, "OpenFile",
        string.Format("Text field khong khop. Expected='{0}', Actual='{1}'", path, actual));
    throw new Exception("Nhap path that bai.");
}
```

## Anti-pattern

- **TUYỆT ĐỐI KHÔNG** dùng `PressKeys` với modifier keys (`Ctrl+A`, `Ctrl+V`, `Ctrl+C`) trên Win32 Edit control trong Windows File Dialog.
- **TUYỆT ĐỐI KHÔNG** dùng `SetAttributeValue("WindowText", ...)` — không được hỗ trợ trên control này.
- **TUYỆT ĐỐI KHÔNG** nhầm lẫn với WPF ComboBox — WPF dùng `{Home}{Shift+End}{Delete}` + `PressKeys`, Win32 Edit dùng `TextValue`.
- **LUÔN LUÔN** verify text sau khi set bằng `TextValue` — đọc lại và so sánh.

## Evidence

- HANDOVER 2026-06-02: `docs/HANDOVER_OpenFile_20260602.md` — investigation 5 giả thuyết đều loại bỏ, xác nhận keyboard fail.
- HANDOVER 2026-06-03: `docs/HANDOVER_OpenFile_20260603.md` — tìm ra `TextValue` là solution duy nhất.
- Knowledge base: `docs/OpenFile_KNOWLEDGE.md` — section "Text1148 — ô File name", xác nhận `TextValue` hoạt động.
- Code thực tế: `OpenFile.UserCode.cs` method `EnterPathIntoFileNameField()`, `OpenFile_FromProduction.UserCode.cs` method `EnterPathIntoFileNameField()`.

## Xem thêm

- `.claude/lessons/login-retry-lesson.md` (R1) — WPF ComboBox: khác control type, khác fix (`{Home}{Shift+End}{Delete}` thay vì `TextValue`).
