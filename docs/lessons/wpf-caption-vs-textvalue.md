# Lesson: WPF Caption trả về AutomationId thay vì text hiển thị

> **Ngày ghi nhận:** 2026-07-20  
> **Module:** OpenFile_FromProduction (ValidateTopModelName)  
> **Session/HANDOFF liên quan:** `docs/HANDOFF.md` (Bug 3 — ĐÃ FIX 2026-07-24)

---

## Trigger

Khi đọc text từ WPF element bằng `GetAttributeValueText("Caption")` hoặc `.Caption` và giá trị trả về KHÔNG khớp text hiển thị trên UI — thường trả về AutomationId hoặc internal name.

## KHÔNG áp dụng khi

- Element là Win32 control (dùng `TextValue` — xem [win32-edit-textvalue-input.md](win32-edit-textvalue-input.md)).
- Element là WinForms control (Caption thường hoạt động đúng).
- Giá trị đọc được khớp text hiển thị nhưng sai nội dung → vấn đề khác (data binding, stale cache).

## Triệu chứng

1. `GetAttributeValueText("Caption")` trả về string giống internal name / AutomationId (ví dụ: `topTextRecipeName`) thay vì text hiển thị (ví dụ: `KYE_Ver9_3_Job remake_1`).
2. Giá trị không đổi dù UI hiển thị text khác nhau — vì AutomationId là tĩnh.
3. Validation FAIL liên tục: `Expected contains 'ModelName', Actual = 'topTextRecipeName'`.
4. Poll loop chờ text thay đổi nhưng không bao giờ thấy giá trị mới (vì đọc sai attribute).

## Nguyên nhân gốc

WPF element có nhiều text-related attribute:

| Attribute | Ý nghĩa | Giá trị thường gặp |
|-----------|---------|-------------------|
| `Caption` | Label / identifier — WPF thường trả về **AutomationId** | `topTextRecipeName` (tĩnh) |
| `Text` | Text hiển thị chính | `KYE_Ver9_3_Job remake_1` (động) |
| `SelectionText` | Text đang được select | Giống `Text` nếu toàn bộ text được select |
| `WindowText` | Win32-level text | Có thể rỗng cho WPF element |

**Vấn đề:** WPF control override cách `Caption` hoạt động. Thay vì trả về text hiển thị (như Win32/WinForms), WPF trả về `AutomationProperties.AutomationId` — một giá trị tĩnh dùng cho UI Automation, không phải display text.

**Ví dụ thực tế:** `TopTextRecipeName` element trong Neptune:
- `Caption` → `topTextRecipeName` (AutomationId, tĩnh)
- `Text` → `KYE_Ver9_3_Job remake_1` (text thật, thay đổi theo recipe được load)

## Cách xác minh

1. Mở **Ranorex Spy** → navigate đến element.
2. Panel Properties → so sánh `Caption` vs `Text` vs `SelectionText`:
   - Nếu `Caption` ≠ text hiển thị trên UI → **đang đọc sai attribute**.
   - Nếu `Text` = text hiển thị → dùng `Text`.
3. Code debug:
   ```csharp
   var el = repo.CCIMainWindow.Area1.TopTextRecipeName.Element;
   Report.Log(ReportLevel.Info, "DEBUG",
       string.Format("Caption='{0}', Text='{1}', SelectionText='{2}'",
           el.GetAttributeValueText("Caption"),
           el.GetAttributeValueText("Text"),
           el.GetAttributeValueText("SelectionText")));
   ```
4. Xác nhận `Text` hoặc `SelectionText` khớp UI.

## Fix chuẩn

Dùng `GetAttributeValueText("Text")` với fallback `GetAttributeValueText("SelectionText")`:

```csharp
// ✅ ĐÚNG — đọc text hiển thị thực tế
var el = repo.CCIMainWindow.Area1.TopTextRecipeName.Element;
string actualText = el.GetAttributeValueText("Text");

// Fallback nếu Text rỗng
if (string.IsNullOrEmpty(actualText))
    actualText = el.GetAttributeValueText("SelectionText");
```

```csharp
// ❌ SAI — Caption trả về AutomationId cho WPF element
string actualText = el.GetAttributeValueText("Caption");
```

**Quy tắc khi đọc text từ WPF element:**
1. LUÔN dùng Ranorex Spy kiểm tra attribute nào chứa text thật TRƯỚC khi code.
2. Ưu tiên `Text` > `SelectionText` > `WindowText`. KHÔNG dùng `Caption` cho WPF.
3. Thêm fallback `SelectionText` trong trường hợp `Text` rỗng.

## Anti-pattern

- **TUYỆT ĐỐI KHÔNG** giả định `Caption` = text hiển thị cho WPF element. Luôn verify bằng Spy.
- **TUYỆT ĐỐI KHÔNG** tăng timeout khi validation fail do đọc sai attribute — chờ bao lâu cũng không fix sai attribute.
- **TUYỆT ĐỐI KHÔNG** dùng `.Caption` property trực tiếp cho WPF text element mà chưa verify bằng Spy.
- **LUÔN LUÔN** kiểm tra bằng Spy: `Caption` vs `Text` vs `SelectionText` — trước khi chọn attribute để đọc.

## Evidence

- HANDOFF master: `docs/HANDOFF.md` — Bug 3: "Caption trả về AUTOMATIONID, text thật nằm ở Text/SelectionText."
- Spy xác minh: Caption = `topTextRecipeName` (AutomationId, tĩnh), Text = `KYE_Ver9_3_Job remake_1` (text thật, động).
- Code hiện tại đã fix (`OpenFile_FromProduction.UserCode.cs` line ~180): dùng `GetAttributeValueText("Text")` với fallback `GetAttributeValueText("SelectionText")`.
- HANDOFF.md quy tắc 8: "Caption của WPF element có thể trả về automationid thay vì text hiển thị."

## Xem thêm

- [win32-edit-textvalue-input.md](win32-edit-textvalue-input.md) — tương tự nhưng cho Win32 Edit control (dùng `TextValue` thay vì keyboard).
- HANDOFF.md quy tắc 8: "Xác minh bằng Spy trước khi dùng GetAttributeValueText."
