# Lesson: Repository Use Cache — Stale Element Reference

> **Ngày ghi nhận:** 2026-07-20  
> **Module:** OpenFile_FromProduction (ClickApplyWithFallback), Verify_ProductionPresettingDialog_AutoClose  
> **Session/HANDOFF liên quan:** `docs/HANDOFF.md` (Bug 1 — ĐÃ FIX)

---

## Trigger

Khi test PASS ở row 1 (hoặc lần chạy đầu) nhưng FAIL ở row 2+ với lỗi liên quan đến element "not visible", "not found", hoặc thuộc tính trả về giá trị cũ — dù UI hiển thị đúng.

## KHÔNG áp dụng khi

- Element thực sự không tồn tại trên UI (kiểm tra bằng Spy).
- Lỗi do RxPath generic match nhầm element khác — xem [generic-popup-path-collision.md](generic-popup-path-collision.md).
- Lỗi do RxPath hardcode `@caption` cụ thể — xem [openfile-dynamic-rxpath-lesson.md](openfile-dynamic-rxpath-lesson.md).
- Chỉ 1 row data và lỗi xảy ra ngay lần đầu.

## Triệu chứng

1. Test PASS row 1, FAIL row 2+ (hoặc PASS lần chạy đầu, FAIL lần chạy sau trong cùng session).
2. Lỗi: "Element is not visible" — dù Ranorex Spy thấy element hiển thị bình thường.
3. Tìm trực tiếp bằng `Host.Local.Find()` → element Visible=True, Rect có giá trị đúng. Nhưng qua repo accessor → Visible=False, Rect={0,0,0,0}.
4. Thuộc tính element qua repo accessor trả về giá trị từ lần chạy trước (stale data).
5. Dialog/form đã đóng rồi mở lại, nhưng repo vẫn trỏ đến instance cũ đã bị destroy.

## Nguyên nhân gốc

Repository folder có **Use Cache = True** (mặc định trong Ranorex). Khi folder cache element lần đầu tìm thấy, các lần truy cập sau dùng lại reference cũ mà không tìm lại. Nếu element bị destroy (dialog đóng) rồi tạo lại (dialog mở lại), repo vẫn trỏ đến object cũ đã chết.

**Ví dụ thực tế:** Folder `InspectionRegionSettings` (base path `/form[@name='Popup']`) có Use Cache = True. Lần 1: dialog mở → repo cache form instance A. Lần 2: dialog đóng rồi mở lại → form instance B mới được tạo. Nhưng repo vẫn trỏ đến instance A (đã chết) → `Visible=False`, `Rect={0,0,0,0}`.

## Cách xác minh

1. So sánh kết quả truy cập qua repo accessor vs tìm trực tiếp:
   ```csharp
   // Qua repo — có thể stale
   var viaRepo = repo.FolderName.ElementName;
   Report.Log(ReportLevel.Info, "DEBUG",
       string.Format("Repo: Visible={0}, Rect={1}", viaRepo.Visible, viaRepo.Element.ScreenRectangle));
   
   // Tìm trực tiếp — luôn fresh
   var direct = Host.Local.FindSingle<Ranorex.Form>("/form[@name='Popup']//button[@text='Apply']");
   Report.Log(ReportLevel.Info, "DEBUG",
       string.Format("Direct: Visible={0}, Rect={1}", direct.Visible, direct.Element.ScreenRectangle));
   ```
2. Nếu repo: Visible=False, Rect={0,0,0,0} nhưng direct: Visible=True, Rect có giá trị → **Use Cache stale**.
3. Kiểm tra Use Cache trong `.rxrep`: mở Ranorex Studio → Repository → chọn folder → panel Properties → trường `Use Cache`.

## Fix chuẩn

**Tắt Use Cache cho folder chứa dialog/popup tạm thời:**

1. Mở Ranorex Studio trên máy test.
2. Mở Repository (`Lynn_DPI_ATRepository.rxrep`).
3. Chọn folder bị ảnh hưởng (ví dụ `InspectionRegionSettings`).
4. Panel Properties → **Use Cache = False**.
5. Save → commit → sync về máy code.

**Lưu ý:** File `.rxrep` CHỈ sửa trên máy Ranorex. Claude Code KHÔNG sửa file này.

**Quy tắc: folder nào cần Use Cache = False?**
- Dialog/popup mở-đóng nhiều lần trong test (ví dụ dialog Production Presetting).
- Form tạm thời (modal dialog, popup notification).
- Bất kỳ folder nào có element bị destroy rồi tạo lại giữa các iteration.

**Folder nào giữ Use Cache = True?**
- Main window (tồn tại suốt test session).
- Control tĩnh không bị recreate.

## Anti-pattern

- **TUYỆT ĐỐI KHÔNG** giả định "element not visible" là do selector sai nếu chưa so sánh repo accessor vs tìm trực tiếp.
- **TUYỆT ĐỐI KHÔNG** tăng timeout khi root cause là stale reference — chờ bao lâu cũng không fix được object đã chết.
- **TUYỆT ĐỐI KHÔNG** để Use Cache = True cho folder chứa dialog/popup tạm thời.
- **LUÔN LUÔN** kiểm tra Use Cache của folder cha KHI gặp "element not visible" mà Spy thấy element hiển thị.

## Evidence

- HANDOFF master: `docs/HANDOFF.md` — Bug 1: "Repo cache element cha đã chết". Log DIAG xác nhận: direct find → Visible=True, Rect={998,849,120,32}; repo accessor → Visible=False, Rect={0,0,0,0}.
- Fix: Use Cache = False cho folder `InspectionRegionSettings` và `ShutdownDialog` (cả 2 dùng `form[@name='Popup']`).

## Xem thêm

- [generic-popup-path-collision.md](generic-popup-path-collision.md) — nếu Use Cache đã là False mà vẫn lỗi, kiểm tra path collision.
- HANDOFF.md quy tắc 7: "Element tìm thấy nhưng not visible → kiểm tra Use Cache của folder cha TRƯỚC khi nghĩ code."
