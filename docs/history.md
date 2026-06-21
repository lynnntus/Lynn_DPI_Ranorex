# Change History

## 2026-06-21

### ~PM — Implement OpenFile_FromProduction + Fix typo OpenFile
- **Modified**: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/OpenFile_FromProduction.UserCode.cs` — Implement toàn bộ logic: Enable check, click BtnOpenFileFromProduction, dialog handling (TextValue), ValidateTopModelName (poll TopTextRecipeName), try/finally + CleanupDialog
- **Modified**: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/OpenFile.UserCode.cs` — Fix typo dòng 112: `BtnOpenInDialogialog` → `BtnOpenInDialog` (lỗi tồn tại từ trước, chặn build)
- **Modified**: `docs/chat.md` — Thêm entry 2026-06-21
- **Modified**: `docs/history.md` — Thêm entry 2026-06-21

## 2026-06-08

### ~23:30 — Audit CLAUDE.md + Tạo Final Handover DynamicRxPath
- **Modified**: `CLAUDE.md` — Viết lại hoàn toàn (73 → 176 dòng): thêm Project Overview, Commands, Known Gotchas, Do Not, cải thiện File Safety và Coding Conventions
- **Created**: `docs/HANDOVER_DynamicRxPath_FinalStatus.md` — Handover cuối cùng cho topic DynamicRxPath: Confirmed Findings, Rejected Hypotheses, Implementation Status, Timing Investigation Status, Open Issues, Next Actions, Lessons Learned
- **Modified**: `docs/history.md` — Thêm entry session 2026-06-08 (audit + handover)
- **Modified**: `docs/chat.md` — Thêm entry session 2026-06-08 (audit + handover)

### ~21:50 — Tạo Lesson Learn: Dynamic RxPath
- **Created**: `docs/lessons/openfile-dynamic-rxpath-lesson.md` — Bài học xử lý Repository hard-code selector, investigation flow, wait/validate pattern, anti-patterns, checklist
- **Modified**: `CLAUDE.md` — Thêm reference đến lesson mới trong mục "Bài học"
- **Modified**: `docs/history.md` — Thêm entry session 2026-06-08
- **Modified**: `docs/chat.md` — Thêm entry session 2026-06-08
- **Modified**: `docs/OpenFile_KNOWLEDGE.md` — Thêm reference đến lesson trong Section 5

## 2026-06-06

### ~20:30 — Tạo Session Handover: DynamicRxPath & Timing Investigation
- **Created**: `docs/HANDOVER_DynamicRxPath_TimingInvestigation.md` — Handover đầy đủ cho session tiếp theo

### ~19:50 — ValidateModelName: chuyển sang dynamic RxPath, bỏ dependency repo.SomeText
- **Modified**: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/OpenFile.UserCode.cs`
  - `ValidateModelName()`: viết lại hoàn toàn — dùng `Host.Local.FindSingle<Ranorex.Text>()` với dynamic RxPath
  - RxPath: `/form[@title='CCIMainWindow']//text[@caption='{ModelName}']` (ModelName từ CSV runtime)
  - Bỏ toàn bộ dependency vào `repo.CCIMainWindow.SomeText` / `SomeTextInfo`
  - Wait 30s cho element, Report.Success nếu found, screenshot + throw nếu không
  - Buoc 7: đơn giản hóa — bỏ `SomeTextInfo.Exists(30000)`, bỏ gọi `InvestigateModelNameElement()`
  - Build: PASS (Debug x86)
  - Chưa commit/push

### ~session — Chốt session: ValidateModelName implemented, Repository issue phát hiện

**Code changes (session trước, build PASS):**
- **Modified**: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/OpenFile.UserCode.cs`
  - Thêm method `ValidateModelName()` — dùng `Validate.AreEqual(actual, expected)`
  - Đọc actual Model Name từ `SomeText.Element.Parent.Caption` (ANCESTOR_L1)
  - Fallback sang attribute `Text` nếu `Caption` rỗng
  - Screenshot tự động trước validation khi phát hiện mismatch
  - Thêm gọi `ValidateModelName()` cuối Buoc 7 trong `OpenRecipeFileByPath()`
  - Investigation code (`InvestigateModelNameElement()`, helpers) giữ nguyên tạm thời
  - Build: PASS (Debug x86)

**Knowledge issue phát hiện:**
- Repository item `SomeText` / `SomeIndicator` hardcode `@caption='Lynn_Stacking_Underfill'` trong RxPath
- Selector chỉ match 1 model name cụ thể — khi đổi sang model khác, `Exists()` = False
- Root cause: Repository selector, KHÔNG phải logic validation

**Documentation updates:**
- **Modified**: `docs/OpenFile_KNOWLEDGE.md` — Section 1 (status), Section 5 (next action), Section 6 (rules), thêm Section 8 (ModelName Validation facts)
- **Modified**: `docs/history.md` — Thêm entry session 2026-06-06
- **Modified**: `docs/chat.md` — Thêm entry session 2026-06-06
- **Created**: `docs/HANDOVER_OpenFile_RepositoryIssue.md` — Handover cho session re-spy Repository

## 2026-06-03

### ~16:30 - Tạo file BAT đồng bộ cho Máy A
- **Created**: `push_macA.bat` — Script commit/push code từ máy A lên Git
- **Created**: `sync_macA.bat` — Script pull/sync code mới nhất về máy A
- Dựa trên logic của `push_macB.bat` / `sync_macB.bat` (file cũ dành cho máy B)
- Điều chỉnh: path `F:\RanorexProjects\Lynn_DPI_AT`, giữ HTTPS remote, thêm hiển thị branch/status, thêm stash option trong sync

### ~15:00 - Chốt session — Update KNOWLEDGE + Tạo handover ModelName validation
- **Modified**: `docs/OpenFile_KNOWLEDGE.md`
  - Section 1: Cập nhật Current Status — các PASS đã xác nhận, Known Issue, Next Goal
  - Section 2: MenuOpenRecipe đánh dấu đã test thực tế PASS
  - Section 2: Thêm mục "Bước 6 verify dialog closed — gây false failure (đã loại bỏ)"
  - Section 5: Next Action cập nhật — hướng sang ModelName validation
  - Section 6: Rules cập nhật — bỏ "Verify dialog đã đóng" khỏi BẮT BUỘC
- **Created**: `docs/HANDOVER_OpenFile_ModelNameValidation.md` — Session starter cho ModelName validation

### ~14:45 - Bỏ false failure Bước 6 verify dialog closed
- **Modified**: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/OpenFile.UserCode.cs`
  - Bỏ: verify dialog closed, đọc field sau Open, throw exception, Escape cleanup
  - Thay bằng: `Delay(2000)` + `Report.Info` để tránh false failure
  - Build: PASS (Debug x86)
  - Chưa commit.

### ~14:30 - Cập nhật OpenFile_KNOWLEDGE.md — Lesson Learned
- **Modified**: `docs/OpenFile_KNOWLEDGE.md`
  - Section 4: Current Blocker đánh dấu RESOLVED
  - Section 5: Next Action cập nhật — chuyển sang test thực tế + bind CSV
  - Section 7: Thêm mới — Lesson Learned: File name input (evidence, kết luận, rule mới)

### ~14:00 - OpenFile: thay approach nhập path — TextValue thay SetAttributeValue
- **Modified**: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/OpenFile.UserCode.cs`
  - Method: `EnterPathIntoFileNameField()`
  - Thay `SetAttributeValue("WindowText")` + fallback `SetAttributeValue("Text")` bằng `TextValue = path`
  - Giữ nguyên: Focus + Click Text1148, đọc lại field verify, throw nếu không khớp
  - Giữ nguyên: Buoc 5 (Click Open), Buoc 6 (verify dialog đóng)
  - Build: PASS (Debug x86)
  - Chưa test thực tế. Chưa commit.

### ~09:30 - Tạo OpenFile Knowledge Base + Session Handover
- **Created**: `docs/OpenFile_KNOWLEDGE.md` — Lưu toàn bộ facts đã chứng minh, giả thuyết đã loại bỏ, current blocker, và rules cho debug OpenFile module
- **Created**: `docs/HANDOVER_OpenFile_20260603.md` — Session starter cho session tiếp theo

### ~09:00 - Fix regression: MenuOpenRecipe "Element is not visible"
- **Modified**: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/OpenFile.UserCode.cs`
  - Root cause: Code mới bỏ warm-up, click MenuOpenRecipe quá sớm sau LeftMenuOpenToogleButton (chỉ 500ms)
  - Fix: Thêm `WaitForMenuOpenRecipeClickable()` polling wait (max 50s, poll 400ms)
  - Fix: Kiểm tra Exists + Visible + Enabled trước khi click
  - Fix: EnsureVisible() khi element sẵn sàng
  - Fix: Screenshot + Error log nếu timeout
  - Build: PASS (Debug x86)

## 2026-06-02

### ~09:30 - Fix OpenFile: paste path + verification
- **Modified**: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/OpenFile.UserCode.cs`
  - Root cause: `element.PressKeys("{Control down}{a/v}{Control up}")` gõ literal "av" thay vì Ctrl+A/Ctrl+V (DefaultKeyPressTime=20ms quá nhanh)
  - Root cause: Report.Success ngay sau Click Open, không verify dialog đã đóng
  - Fix: Thay bằng R1 pattern (`{Home}{Shift+End}{Delete}`) + global `Keyboard.Press` cho Ctrl+V
  - Fix: Thêm `ReadFileNameField()` verify nội dung field sau paste
  - Fix: Thêm Buoc 6 verify dialog đã đóng, throw nếu còn mở
  - Fix: Thêm retry 1 lần nếu paste lần đầu fail
  - Fix: Log `RecipeFilePath` giá trị thực tế trong `Init()` để debug binding

## 2026-05-26

### ~23:00 - Project Cleanup
- **Deleted**: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/LoginRetry.cs.bak` — File backup cũ, không còn cần (git history đã lưu)

### ~16:00 - Hoàn thành Ranorex Research Knowledge Base (files 05-08)
- **Created**: `docs/ranorex-research/05_Stable_Automation_Strategy_For_DPI.md` — Chiến lược automation ổn định: object vs coordinate, wait strategy, login/logout flow, PopupWatcher, module design, DPI-specific
- **Created**: `docs/ranorex-research/06_Debug_And_Troubleshooting_Checklist.md` — 8 checklists debug: test fail, object not found, timeout, login fail, app chưa load, binding, recording conflict, manual vs automation
- **Created**: `docs/ranorex-research/07_Current_Project_Risks.md` — 8 risks assessment: 2 HIGH (caching, login conflict), 4 MEDIUM (coordinates, Recording1, CSV, binding), 2 LOW (delays, absolute path)
- **Created**: `docs/ranorex-research/08_Research_Findings_And_Recommendations.md` — Executive summary, 10 rules, roadmap ngắn/trung/dài hạn

### ~14:00 - Bắt đầu Ranorex Research Knowledge Base (files 01-04)
- **Created**: `docs/ranorex-research/01_Ranorex_Overview.md` — Tổng quan Ranorex, kiến trúc, flow thực thi
- **Created**: `docs/ranorex-research/02_Project_Structure_Analysis.md` — Phân tích cấu trúc project
- **Created**: `docs/ranorex-research/03_UserCode_Best_Practices.md` — Best practices viết UserCode
- **Created**: `docs/ranorex-research/04_Repository_Best_Practices.md` — Best practices quản lý Repository

## 2026-05-21

### 17:40 - Viết lại CLAUDE.md hoàn chỉnh bằng tiếng Việt
- **Modified**: `CLAUDE.md` — Viết lại toàn bộ nội dung bằng tiếng Việt, bao gồm: tổng quan project, cấu trúc thư mục, cách dùng Excel, quy tắc sửa code, chi tiết từng recording module, UI repository, cấu hình, và lưu ý phát triển

### 17:27 - Project Initialization
- **Created**: `CLAUDE.md` — Project guidance for Claude Code
- **Created**: `docs/chat.md` — Chat history log
- **Created**: `docs/history.md` — Change history log
- **Created**: `docs/plan.md` — Project plan
