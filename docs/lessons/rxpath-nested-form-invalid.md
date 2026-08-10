# Lesson: RxPath Nested Form — Form lồng Form không hợp lệ

> **Ngày ghi nhận:** 2026-07-20  
> **Module:** OpenFile_FromProduction (BtnApplyProductionPresetting)  
> **Session/HANDOFF liên quan:** `docs/HANDOFF.md` (Bug 2 — ĐÃ FIX)

---

## Trigger

Khi RxPath của một repository item chứa 2+ segment `/form[...]` nối tiếp nhau (form lồng form) — và element không tìm thấy hoặc tìm thấy chậm bất thường (~30s fallback).

## KHÔNG áp dụng khi

- RxPath chỉ có 1 `/form[...]` segment (path bình thường).
- Element không tìm thấy do Use Cache stale — xem [repo-use-cache-stale-element.md](repo-use-cache-stale-element.md).
- Element không tìm thấy do generic path collision — xem [generic-popup-path-collision.md](generic-popup-path-collision.md).

## Triệu chứng

1. Repository item có Robust path hoặc Absolute path chứa pattern: `/form[@processname='...']/form[@name='...']//...` — hai `/form` nối nhau.
2. Element tìm thấy chậm (~30 giây) vì Ranorex fallback qua nhiều path trước khi match.
3. Hoặc element không tìm thấy vì path structure không phản ánh đúng UI hierarchy.
4. Ranorex Spy cho thấy: dialog/popup là cửa sổ độc lập, KHÔNG phải child của main window.

## Nguyên nhân gốc

Dialog/popup trong Windows là cửa sổ top-level độc lập. Chúng KHÔNG nằm bên trong main window theo hierarchy. Khi Ranorex record, đôi khi auto-generate Robust path bao gồm cả process form cha:

```
/form[@processname='KohyoungGUI']/form[@name='Popup']//button[@text='Apply']
```

Path này ngụ ý `form[@name='Popup']` là child của `form[@processname='KohyoungGUI']` — **SAI**. Popup là cửa sổ riêng, cùng process nhưng không phải child element.

**Ví dụ thực tế:** `BtnApplyProductionPresetting` từng có Robust path `/form[@processname='KohyoungGUI']/form[@name='Popup']//button[...]`. Ranorex không tìm thấy qua path chính, phải fallback (~30s mỗi lần).

## Cách xác minh

1. Mở `.rxrep` trong Ranorex Studio → chọn item nghi vấn.
2. Kiểm tra Robust path và Absolute path — tìm pattern `/form[...]/form[...]`.
3. Mở Ranorex Spy → navigate đến element thực tế → xác nhận hierarchy:
   - Nếu popup/dialog là top-level window (không có parent form) → path lồng form là SAI.
4. Kiểm tra thời gian tìm element: nếu mất ~30s (timeout + fallback) → có thể path chính không match.

## Fix chuẩn

**Sửa trong Ranorex Studio (trên máy test, KHÔNG sửa bằng Claude Code):**

1. Mở Repository → chọn item bị lỗi.
2. Sửa path structure — popup/dialog là cửa sổ độc lập:
   ```
   ❌ SAI (form lồng form):
   Item     : //button[@text='Apply']
   Robust   : /form[@processname='KohyoungGUI']/form[@name='Popup']//button[@text='Apply']
   
   ✅ ĐÚNG (popup là top-level):
   Item     : .//button[@text='Apply']
   Robust   : /form[@name='Popup' and @title='Production Presetting']//button[@text='Apply']
   Absolute : /form[@name='Popup' and @title='Production Presetting']//button[@text='Apply']
   ```
3. Thêm `@title` phân biệt nếu có nhiều form cùng `@name='Popup'`.
4. Save → commit → sync về máy code.

**Nguyên tắc:**
- Dialog/popup LUÔN là path bắt đầu từ `/form[...]` — không bao giờ là child của form khác.
- Nếu app có nhiều popup cùng `@name`, PHẢI thêm `@title` hoặc attribute phân biệt.

## Anti-pattern

- **TUYỆT ĐỐI KHÔNG** để 2+ segment `/form[...]` nối tiếp nhau trong RxPath cho dialog/popup.
- **TUYỆT ĐỐI KHÔNG** tin Ranorex auto-generated Robust path mà không kiểm tra — Ranorex đôi khi sinh path lồng form.
- **TUYỆT ĐỐI KHÔNG** bỏ `@title` khỏi basepath khi app có nhiều popup cùng `@name='Popup'`.
- **LUÔN LUÔN** kiểm tra Robust path và Absolute path sau khi record item mới — đặc biệt cho dialog/popup.

## Evidence

- HANDOFF master: `docs/HANDOFF.md` — Bug 2: "Path lồng form trong form". Robust path cũ: `/form[@processname='KohyoungGUI']/form[@name='Popup']//button[...]`. Đã sửa: `/form[@name='Popup' and @title='Production Presetting']//button[@text='Apply']`.
- Repository hiện tại: 2 folder dùng `form[@name='Popup']` — `InspectionRegionSettings` (`@title='Production Presetting'`) và `ShutdownDialog` (`@title='Inspection Region Settings'`). `@title` là phần phân biệt duy nhất.

## Xem thêm

- [generic-popup-path-collision.md](generic-popup-path-collision.md) — trường hợp khác: path không lồng form nhưng `@name` generic match nhiều element.
- HANDOFF.md quy tắc 9: "Không lồng form trong form. Form Popup là cửa sổ độc lập."
