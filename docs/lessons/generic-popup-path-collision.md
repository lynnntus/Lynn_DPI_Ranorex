# Lesson: Generic Popup Path Collision

> **Ngày ghi nhận:** 2026-07-19  
> **Module:** Verify_ProductionPresettingDialog_AutoClose  
> **Session/HANDOFF liên quan:** `docs/HANDOFF_Verify_ProductionPresettingDialog_20260719.md`

---

## Trigger

Khi `WaitForNotExists()` hoặc `Exists()` trả kết quả SAI — element đã biến mất trên UI nhưng API vẫn báo tồn tại (hoặc ngược lại).

## KHÔNG áp dụng khi

- Element thực sự chưa biến mất (app chưa xử lý xong).
- Lỗi do timeout quá ngắn — xem [dialog-close-polling-timeout.md](dialog-close-polling-timeout.md).
- Lỗi do Use Cache = True cache element cũ — xem HANDOFF.md Bug 1.

## Triệu chứng

1. `WaitForNotExists(timeout)` hết timeout dù UI cho thấy dialog đã đóng.
2. Hoặc `Exists()` trả `True` dù dialog đã đóng trên màn hình.
3. Ranorex Report log: element vẫn found sau khi dialog đóng.
4. Spy kiểm tra: có NHIỀU element match cùng RxPath (ví dụ `/form[@name='Popup']` match 2+ form khác nhau).

## Nguyên nhân gốc

RxPath của parent form quá generic — chỉ dùng `@name` mà không có `@title` hoặc attribute phân biệt. Kết quả:

1. Dialog A đóng → element biến mất.
2. Nhưng panel/form B trên màn hình cũng match cùng RxPath `/form[@name='Popup']`.
3. `WaitForNotExists` tìm thấy form B → trả kết quả "vẫn tồn tại" → test FAIL giả.

**Ví dụ thực tế:** `/form[@name='Popup']` match cả dialog "Production Presetting" lẫn panel khác trên màn hình Production. Sau khi dialog đóng, `SelfInfo.WaitForNotExists` vẫn tìm thấy panel kia → báo dialog chưa đóng.

## Cách xác minh

1. Mở Ranorex Spy, navigate đến RxPath đang dùng.
2. Kiểm tra số lượng element match — nếu > 1, đây là root cause.
3. Hoặc trong UserCode, đếm element:
   ```csharp
   var list = Host.Local.Find<Ranorex.Form>("/form[@name='Popup']");
   Report.Log(ReportLevel.Info, "DEBUG",
       string.Format("So luong form match: {0}", list.Count));
   ```
4. Nếu sau khi dialog đóng mà count > 0 → path collision.

## Fix chuẩn

**Đổi verification target từ parent form (generic) sang child element duy nhất:**

```csharp
// ❌ SAI — parent path generic, match nhiều form
repo.InspectionRegionSettings.SelfInfo.WaitForNotExists(timeout);

// ✅ ĐÚNG — child element (Apply button) chỉ tồn tại trong dialog đúng
repo.InspectionRegionSettings.BtnApplyProductionPresettingInfo.WaitForNotExists(timeout);
```

**Nguyên tắc chọn child element:**
1. Chỉ tồn tại khi dialog mở (biến mất khi dialog đóng).
2. Không trùng với element nào khác trên màn hình.
3. Ưu tiên button hoặc control có `@text` cụ thể.

## Anti-pattern

- **TUYỆT ĐỐI KHÔNG** dùng `SelfInfo.WaitForNotExists` khi base path của folder chứa `@name` generic (như `Popup`, `Dialog`, `Window`) mà không có thêm `@title` hoặc attribute phân biệt.
- **TUYỆT ĐỐI KHÔNG** tăng timeout để "chờ thêm" khi root cause là path collision — timeout bao lâu cũng sẽ fail.
- **LUÔN LUÔN** kiểm tra số lượng element match bằng Spy hoặc `Host.Local.Find` trước khi kết luận "element chưa biến mất".

## Evidence

- HANDOFF: `docs/HANDOFF_Verify_ProductionPresettingDialog_20260719.md` — section "Root cause" và "Giai phap da implement".
- HANDOFF master: `docs/HANDOFF.md` — Bug 2 (Path lồng form), section Repository.
- Code fix: `Verify_ProductionPresettingDialog_AutoClose.UserCode.cs` line 71, 138.

## Xem thêm

- [openfile-dynamic-rxpath-lesson.md](openfile-dynamic-rxpath-lesson.md) — trường hợp khác: selector hardcode `@caption` cụ thể (chỉ match 1 giá trị). Lesson này nói về `@name` generic (match nhiều element).
