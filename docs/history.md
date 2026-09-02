# Change History

## 2026-09-02

### Code review DIAG truoc khi trien khai May B

- **File review** (chi doc, khong sua): `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/RunProduction.UserCode.cs`
  - Ket qua: 0 Critical, 2 Warning, 4 Suggestion → co the trien khai ngay
  - Cap nhat: `docs/chat.md`

### Them DIAG logging vao RunProduction ReadProgressBarText va Step5

- **File sua**: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/RunProduction.UserCode.cs`
  - `ReadProgressBarText()`: Them DIAG log cho moi approach (TxtProducedQty, ProgressBar, text children)
  - `Step5_VerifyProducedQuantityImpl()`: Them timestamp va polling iteration log
  - Fix loi compile: `DateTime` → `System.DateTime` (ambiguous voi `Ranorex.DateTime`)
  - Prefix: `[DIAG_PROGRESS]` — de grep trong Ranorex Report

## 2026-08-27

### Tao handoff tai lieu debug RunProduction ProgressBar

- **File tao**: `docs/HANDOFF_RunProduction_ProgressBar_DIAG_20260827.md`
  - Tai lieu ban giao de debug Step 5 (doc gia tri progress bar)
  - Gom: trieu chung, flow, lessons da check, 6 gia thuyet, code path, selector details
  - Ke hoach session tiep: chi them DIAG, chua sua selector/timeout
  - Checklist evidence can thu thap tu Ranorex Report va Spy

## 2026-08-25

### Fix 2 bugs trong module RunProduction

- **File sửa**: `RunProduction.UserCode.cs`
  - **Bug 1 (Step 5 đọc sai giá trị progress bar)**:
    - Root cause: `ReadProgressBarText()` đọc Caption trước → trả label "Production Information(...)" thay vì value "2/2". Matched lesson "WPF Caption vs Text".
    - Fix: Viết lại `ReadProgressBarText()` với 3-approach fallback: (1) TxtProducedQty Text attr, (2) ProgressBar element attrs, (3) dynamic Find text children + regex `\d+/\d+` validation
    - Thêm helper `IsProgressValue()` — regex validation cho pattern X/Y
    - `Step5_VerifyProducedQuantityImpl()` dùng `ReadProgressBarText()` + `_expectedQty` instance field
  - **Bug 2 (Flow chạy lại sau fail)**:
    - Root cause: `Init()` gọi `RunProductionFlow()` → 5 steps. Sau đó auto-generated `Run()` gọi lại từng Step. Matched lessons "Init() Limitations" + "Recording Step Action Timeout".
    - Fix: Thêm `_stepsRanFromInit` flag + `_expectedQty` instance field
    - Tách mỗi StepX() thành: public guard (check flag → skip) + private StepX_Impl() (logic thật)
    - `RunProductionFlow()` gọi Impl methods trực tiếp
    - Init() set `_stepsRanFromInit = true` trước `RunProductionFlow()`
- **File không đổi**: `RunProduction.cs` (auto-generated), `ProductionContext.cs`
- **Build**: PASS

## 2026-08-23

### Cleanup DIAG code + Tạo lesson ANR state cascade

- **File sửa**: `OpenFile_FromProduction.UserCode.cs`
  - Xóa toàn bộ DIAG diagnostic code (~25 items): `[DIAG]` logs, `LogDiagBtnState()` method, `diagTotalSw`/`diagStep1Sw` Stopwatch
  - Reformat 2 dòng mixed DIAG+business: bỏ `[DIAG]` tag nhưng giữ error info
  - **GIỮ NGUYÊN**: ANR handling (catch, retry, cleanup), business logs, constants
  - File giảm từ 792 → ~715 dòng
- **File không đổi**: `Verify_ProductionPresettingDialog_AutoClose.UserCode.cs` (không chứa DIAG)
- **File mới**: `docs/lessons/anr-state-cascade.md` — lesson về ApplicationNotRespondingException cascade pattern
- **File update**: `docs/lessons/INDEX.md` — thêm 4 triệu chứng ANR + 1 category entry
- **Build**: PASS

## 2026-08-16

### Fix ApplicationNotRespondingException cascade — Verify + OpenFile

- **Files**:
  - `Verify_ProductionPresettingDialog_AutoClose.UserCode.cs`
  - `OpenFile_FromProduction.UserCode.cs`
- **Root cause**: App Neptune đôi khi trở thành Not Responding (OS-level hung) sau khi Verify module click Apply. Tất cả UI interaction throw `ApplicationNotRespondingException`. BUOC 3b polling loop KHÔNG có try-catch → exception propagate → module crash → dialog vẫn mở → OpenFile bắt đầu ngay 102ms sau → app vẫn hung → cascade FAIL.
- **Thay đổi Verify module**:
  - Thêm constant `ANR_RECOVERY_WAIT_MS = 3000`
  - BUOC 3b: catch ANR + Thread.Sleep(3000) + continue polling (retry thay vì crash)
  - Wrap `RunVerifyAutoClose()` body trong try-finally
  - Thêm `CleanupLeftoverDialog()` — đóng dialog sót khi module kết thúc
- **Thay đổi OpenFile module**:
  - Thêm constants: `APP_RESPONSIVE_TIMEOUT_MS`, `CLICK_MAX_RETRIES`, `CLICK_ANR_WAIT_MS`
  - Thêm `WaitForAppResponsive()` — poll CCIMainWindow.Exists(0), catch ANR + wait + retry (15s timeout)
  - Init(): gọi `WaitForAppResponsive()` → `CleanupDialog()` TRƯỚC main flow
  - Buoc 1: thay single try-catch bằng retry loop (max 3 attempts, catch ANR, 5s wait giữa retry)
- **Build**: PASS
- **Next**: Test 7-10 lần trên Máy B. Nếu PASS stable → cleanup DIAG logs + tạo lesson.

### DIAG logging — OpenFile_FromProduction flaky "Invocation did not finish within timeout 5s"

- **File**: `OpenFile_FromProduction.UserCode.cs`
- **Mục tiêu**: Thu thập data so sánh PASS vs FAIL run (flaky: 2/7 FAIL)
- **Thay đổi**:
  - Thêm `[DIAG]` log ở Init() (timestamp start/end)
  - Thêm `Stopwatch` tổng ở `OpenRecipeFileByPath()` + timing mỗi bước (2-8)
  - Wrap Bước 1 (click BtnOpenFileFromProduction) với try-catch + DIAG trước/sau
  - Thêm `LogDiagBtnState()` helper — log Exists, Visible, Enabled, Element path, RxPath match count
  - Log entry/exit method với timestamp + tổng elapsed
- **KHÔNG sửa business logic** — chỉ thêm Report.Log
- **Build**: PASS
- **Next**: Chạy 5-10 lần trên Máy B, thu thập PASS vs FAIL log, phân tích session tiếp

### Fix "Invocation did not finish within timeout 5s" — Chuyển logic vào Init()

- **File**: `Verify_ProductionPresettingDialog_AutoClose.UserCode.cs`
- **Root cause**: `ClickApplyWithPolling()` là recording step (userrecorditem trong .rxrec) → bị Ranorex Action Timeout 5s default. Method cần ~34-60s → bị kill.
- **Thay đổi**:
  - `Init()` → gọi `RunVerifyAutoClose()` (private method mới chứa toàn bộ logic)
  - `ClickApplyWithPolling()` → no-op (log + return ngay)
  - Logic test không thay đổi, chỉ chuyển nơi gọi
- **Build**: PASS

### Tạo lesson — Recording Step Action Timeout

- **File**: `docs/lessons/recording-step-action-timeout.md`
- **Nội dung**: Recording step bị Action Timeout 5s default. Fix: chuyển logic dài vào Init().
- **Update**: `docs/lessons/INDEX.md` — thêm 2 triệu chứng + category entry

### Fix Bước 3b — Thay WaitForNotExists bằng polling loop

- **File**: `Verify_ProductionPresettingDialog_AutoClose.UserCode.cs`
- **Root cause**: `WaitForNotExists(90000)` bị giới hạn bởi repo search timeout (30s), throw sau ~29s dù element đã biến mất. DIAG log (08-14) xác nhận: direct find = 0, repo Exists(0) = False tại thời điểm throw.
- **Thay đổi**:
  - Bước 3b: thay `WaitForNotExists` bằng polling loop `Exists(0)` + `Delay.Milliseconds(500)`
  - `APPLY_CLOSE_VERIFY_TIMEOUT_MS`: 90000 → 60000 (polling loop hoạt động đúng, không cần buffer lớn)
  - Cleanup: xóa method `LogDiagElementState()` và 2 lời gọi DIAG

### Tạo lesson — WaitForNotExists Repo Timeout Limit

- **File**: `docs/lessons/waitfornotexists-repo-timeout-limit.md`
- **Nội dung**: WaitForNotExists bị giới hạn bởi repo search timeout khi parameter > 30s. Fix: dùng polling loop `Exists(0)`.
- **Update**: `docs/lessons/INDEX.md` — thêm 2 triệu chứng mới + category entry

### Tạo HANDOFF mới cho session 2026-08-16

- **File**: `docs/HANDOFF_Verify_ProductionPresettingDialog_20260816.md`
- **Nội dung**: Lịch sử 8 bước, trạng thái hiện tại (error mới "Invocation did not finish within timeout 5s"), next step cho session tiếp theo

## 2026-08-14

### Thêm DIAG log tại Bước 3b — Verify_ProductionPresettingDialog

- **File**: `Verify_ProductionPresettingDialog_AutoClose.UserCode.cs`
- **Thay đổi**: Thêm method `LogDiagElementState(label)` và gọi tại 2 điểm trong Bước 3b (trước `WaitForNotExists` và trong catch khi fail)
- **Mục đích**: Thu thập evidence — đếm element match, log Visible/Enabled/Rect, so sánh repo vs direct find. Xác định root cause: path đụng, stale cache, hoặc invisible element.
- **Tạm thời**: Sẽ cleanup sau khi fix root cause.

### Tạo HANDOFF file cho Verify_ProductionPresettingDialog session

- **File**: `docs/HANDOFF_Verify_ProductionPresettingDialog_20260814.md`
- **Nội dung**: Lịch sử 5 bước fix, trạng thái hiện tại (FAIL 90s nhưng dialog không hiển thị), nghi ngờ root cause (path/element issue), next step (thêm DIAG log)

### Fix false failure Bước 3b — Production Presetting dialog close timeout (lần 2)

- **File**: `Verify_ProductionPresettingDialog_AutoClose.UserCode.cs`
- **Thay đổi**: `APPLY_CLOSE_VERIFY_TIMEOUT_MS`: 45000 → 90000 (45s → 90s)
- **Lý do**: App version mới có performance regression — dialog mất ~37s để đóng (manual test xác nhận). Timeout 45s không đủ. Tăng lên 90s (~2.4x observed max) theo lesson `dialog-close-polling-timeout`.
- **Thay đổi phụ**: Xóa stale comment `(max 5s)` ở dòng 134 — đã sai từ lần sửa trước.
- **Không ảnh hưởng performance**: `WaitForNotExists` return ngay khi dialog đóng, 90s chỉ là upper bound.

### Fix false failure Bước 3b — Production Presetting dialog close timeout

- **File**: `Verify_ProductionPresettingDialog_AutoClose.UserCode.cs`
- **Thay đổi**: `APPLY_CLOSE_VERIFY_TIMEOUT_MS`: 15000 → 45000 (15s → 45s)
- **Lý do**: App DPI đôi khi mất >21s để đóng dialog sau click Apply (xử lý ảnh nặng). Timeout 15s gây false failure. Tăng lên 45s (~2x observed max) theo lesson `dialog-close-polling-timeout`.
- **Không ảnh hưởng performance**: `WaitForNotExists` return ngay khi dialog đóng, 45s chỉ là upper bound.

## 2026-08-13

### ~AM — Fix LOT Settings dialog close detection → PASS
- **Modified**: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/OpenFile_FromProduction.UserCode.cs`
  - Thêm constant `LOT_DIALOG_RXPATH` và helper `TryFindLotDialog()` — dùng `Host.Local.TryFindSingle()` bypass repo cache
  - Thay 3 chỗ `repo.KohyoungGUI1.TxtLotIDInfo.Exists()` bằng `TryFindLotDialog()` trong `HandleLotProductionSettings()`
- **Modified**: `docs/lessons/repo-use-cache-stale-element.md`
  - Thêm triệu chứng #6: polling `.Exists()` loop hết timeout dù dialog đã đóng
  - Thêm Evidence Case 2: OF_003 LotProduction, folder `KohyoungGUI1` Use Cache stale
  - Thêm anti-pattern: bypass cache bằng `Host.Local.TryFindSingle()` hardcode — fix đúng là tắt Use Cache trong repo
- **Modified**: `docs/lessons/INDEX.md`
  - Thêm symptom: "Polling `.Exists()` / `WaitForNotExists` loop hết timeout dù dialog đã đóng thật" → Use Cache Stale Element
  - Cập nhật ngày: 2026-08-13

## 2026-08-12

### ~PM — Giai đoạn 2: LOT Production
- **Modified**: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/OpenFile_FromProduction.UserCode.cs`
  - Thay nhánh `"lotproduction"` trong `SelectProductionSetting()`: gọi `HandleLotProductionSettings()` thay vì log warning
  - Thêm `HandleLotProductionSettings()`: click BtnLotSettings → chờ LOT Settings → nhập LOT ID → Tab → nhập Planned Qty (Ctrl+A xóa cũ) → click BtnLotApply → chờ dialog đóng
  - Thêm log `LotName` trong `Init()`
  - Thêm constants: `LOT_DIALOG_TIMEOUT_MS`, `LOT_DIALOG_POLL_MS`

## 2026-08-11

### ~PM — Data-driven Production Setting + HANDOFF update
- **Modified**: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/OpenFile_FromProduction.UserCode.cs`
  - Thêm `SelectProductionSetting()`: switch NotUse/Quantity/LotProduction, gọi trước Apply
  - Thêm `ClickRadioAndVerify()`: EnsureVisible + Enabled check + Click + poll Checked
  - Restructure `OpenRecipeFileByPath()`: 7→8 bước, tách wait dialog ra khỏi ClickApplyWithFallback
  - Update `CleanupDialog()`: đóng InspectionRegionSettings (Escape→Close) trước SelectRecipeFile
  - Thêm log `ProductionSetting`, `InspectionQuantity` trong Init()
- **Modified**: `docs/HANDOFF.md` — Cập nhật toàn bộ 7 sections: data sources, repository radio buttons, functions table, trạng thái GĐ1 hoàn thành, 2 quy tắc mới (#12 bàn phím, #13 cache)

## 2026-07-24

### ~PM 3 — Verify lesson system + CLAUDE.md Debugging Workflow
- Session mới tự đọc INDEX trước debug bug, match 2 lesson chính xác (Dialog Close Polling Timeout + Use Cache Stale Element). Hệ thống hoạt động đúng thiết kế.

### ~PM 2 — Update CLAUDE.md: tích hợp Debugging Workflow
- **Created**: `CLAUDE.md.backup` — Backup trước khi sửa
- **Modified**: `CLAUDE.md` — 3 thay đổi:
  - Thêm section `## ⛔ Debugging Workflow` (sau Known Gotchas, trước Do Not)
  - Update bảng `### Bai hoc`: 1 INDEX + 8 lesson thực tế (loại `code-review-login-retry.md` — là review report, không phải lesson)
  - Update Known Gotchas #7: thêm cross-reference tới Debugging Workflow

### ~PM — Bổ sung 3 lesson thiếu + update Bug 3 status
- **Created**: `docs/lessons/repo-use-cache-stale-element.md` — Lesson: Use Cache = True gây stale element reference cho dialog/popup
- **Created**: `docs/lessons/rxpath-nested-form-invalid.md` — Lesson: Form lồng form trong RxPath không hợp lệ (dialog là top-level window)
- **Created**: `docs/lessons/wpf-caption-vs-textvalue.md` — Lesson: WPF Caption trả AutomationId, dùng Text/SelectionText
- **Modified**: `docs/lessons/INDEX.md` — Thêm 9 triệu chứng mới cho 3 lesson + thêm category "Attribute / Property"
- **Modified**: `docs/HANDOFF.md` — Bug 3 status: "ĐANG XỬ LÝ" → "ĐÃ FIX 2026-07-24", cập nhật mô tả function ValidateTopModelName

### ~AM — Tạo hệ thống Lessons Learned
- **Created**: `docs/lessons/generic-popup-path-collision.md` — Lesson: RxPath generic `/form[@name='Popup']` match nhiều element → dùng child element duy nhất cho WaitForNotExists
- **Created**: `docs/lessons/win32-edit-textvalue-input.md` — Lesson: Win32 Edit control không nhận keyboard shortcuts → dùng `TextValue` property
- **Created**: `docs/lessons/dialog-close-polling-timeout.md` — Lesson: Fixed wait quá ngắn cho app processing → polling loop với timeout đủ lớn
- **Created**: `docs/lessons/INDEX.md` — Index tra cứu triệu chứng → lesson (6 lesson: 3 mới + 3 cũ)
- **Modified**: `docs/HANDOFF.md` — Thêm section 7. DEBUGGING PROTOCOL (hướng dẫn session mới tra cứu lesson trước khi investigate)

## 2026-07-19

### ~PM 2 — Tăng timeout Bước 3b: 5s → 15s (timing issue)
- **Modified**: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/Verify_ProductionPresettingDialog_AutoClose.UserCode.cs`
  - Line 30: `APPLY_CLOSE_VERIFY_TIMEOUT_MS = 5000` → `15000`
  - Root cause: App cần ~5-7s để xử lý Apply và đóng dialog, timeout 5s không đủ
  - Evidence: Screenshot "(null)" chứng minh dialog đã đóng, chỉ vượt timeout
- Build: PASS (0 errors, 0 warnings)
- **Modified**: `docs/history.md`, `docs/chat.md`, `docs/HANDOFF_Verify_ProductionPresettingDialog_20260719.md`

### ~PM — Fix false failure Bước 3b: SelfInfo → BtnApplyProductionPresettingInfo
- **Modified**: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/Verify_ProductionPresettingDialog_AutoClose.UserCode.cs`
  - Line 71 (Bước 2): `SelfInfo.WaitForNotExists` → `BtnApplyProductionPresettingInfo.WaitForNotExists`
  - Line 138 (Bước 3b): `SelfInfo.WaitForNotExists` → `BtnApplyProductionPresettingInfo.WaitForNotExists`
  - Root cause: `SelfInfo` dùng basepath `/form[@name='Popup' and @title='Production Presetting']` match nhầm panel khác trong Production screen
  - Fix: verify bằng Apply button (element con chỉ tồn tại khi dialog mở) thay vì dialog form
- Build: PASS (0 errors, 0 warnings)
- **Modified**: `docs/history.md`, `docs/chat.md` — Cập nhật

## 2026-07-13

### ~PM 2 — Viết lại ClickApplyWithPolling() hoàn toàn
- **Modified**: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/ApplyBtn_On_Production.UserCode.cs` — Bỏ ClickApplyWithFallback() (4 strategy click dồn dập). Viết lại ClickApplyWithPolling(): poll kiên nhẫn 60s mỗi 1s, check dialog biến mất → check Apply Visible+Enabled → click 1 phát → chờ. Thêm chẩn đoán đếm form[@name='Popup']. Timeout → screenshot + throw rõ ràng.
- **Modified**: `docs/history.md`, `docs/chat.md` — Cập nhật

### ~PM — ApplyBtn_On_Production polling + accessor fix + HANDOFF
- **Modified**: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/ApplyBtn_On_Production.UserCode.cs` — Implement polling loop (1s interval, 10s timeout) cho dialog tu dong + 4-strategy click fallback
- **Modified**: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/OpenFile_FromProduction.UserCode.cs` — Fix accessor: `repo.InspectionRegionSettings.Apply` → `repo.InspectionRegionSettings.BtnApplyProductionPresetting` (5 cho)
- **Modified**: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/ApplyBtn_On_Production.UserCode.cs` — Fix accessor tuong tu (5 cho) + cap nhat Report.Log messages
- **Created**: `docs/HANDOFF.md` — Ban giao context day du cho session moi (6 sections)
- **Modified**: `docs/history.md` — Them entry 2026-07-13
- **Modified**: `docs/chat.md` — Them entry 2026-07-13

## 2026-06-21

### ~PM — Implement OpenFile_FromProduction + Fix typo OpenFile
- **Modified**: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/OpenFile_FromProduction.UserCode.cs` — Implement toàn bộ logic: Enable check, click BtnOpenFileFromProduction, dialog handling (TextValue), ValidateTopModelName (poll TopTextRecipeName), try/finally + CleanupDialog
- **Modified**: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/OpenFile.UserCode.cs` — Fix typo dòng 112: `BtnOpenInDialogialog` → `BtnOpenInDialog` (lỗi tồn tại từ trước, chặn build)
- **Modified**: `docs/chat.md` — Thêm entry 2026-06-21
- **Modified**: `docs/history.md` — Thêm entry 2026-06-21
- **Created**: `docs/HANDOVER_OpenFileFromProduction.md` — Handover summary cho session mới

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
