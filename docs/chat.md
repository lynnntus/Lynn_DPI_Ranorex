# Chat History

## 2026-06-06

### ~19:50 — ValidateModelName: dynamic RxPath thay thế hardcode repository
- **Yêu cầu**: Bỏ dependency vào `repo.CCIMainWindow.SomeText` (hardcode `@caption='Lynn_Stacking_Underfill'`), chuyển sang dynamic RxPath dựa trên `this.ModelName` từ CSV
- **Điều tra trước đó**: Spy trong Ranorex Studio xác nhận node PARENT không có `AutomationId`, `ClassName`, `Name` — chỉ có `caption` thay đổi theo recipe. Bỏ tick caption thì selector quá rộng (wildcard)
- **Kết quả**: Viết lại `ValidateModelName()` dùng `Host.Local.FindSingle<Ranorex.Text>(rxPath, 30000)` với RxPath = `/form[@title='CCIMainWindow']//text[@caption='{ModelName}']`
- **Files**: `OpenFile.UserCode.cs`
- **Build**: PASS

### ~session — ModelName Validation: Implementation + Repository Issue Discovery
- **Request**: Tiếp tục từ session trước — implement ValidateModelName() theo proposal đã duyệt, chốt session với knowledge base update và handover
- **Result**: 
  - `ValidateModelName()` implement thành công dùng `Validate.AreEqual`
  - Build PASS (Debug x86)
  - Phát hiện Repository hardcode issue: `SomeText` / `SomeIndicator` chứa `@caption='Lynn_Stacking_Underfill'` → chỉ hoạt động với 1 recipe
  - Chốt session: cập nhật OpenFile_KNOWLEDGE.md, history.md, tạo HANDOVER_OpenFile_RepositoryIssue.md
- **Related files**: 
  - `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/OpenFile.UserCode.cs` (modified — thêm ValidateModelName())
  - `docs/OpenFile_KNOWLEDGE.md` (updated — Section 1, 5, 6, 8)
  - `docs/HANDOVER_OpenFile_RepositoryIssue.md` (created)
  - `docs/history.md` (updated)

## 2026-05-26

### ~23:00 - Project Cleanup
- **Request**: Dọn dẹp project theo Cleanup Rule
- **Result**: Quét toàn bộ project, tìm được 1 file rác (`LoginRetry.cs.bak`), đã xóa sau khi user confirm. Các file `.claude/` và `docs/` đều là tài liệu hợp lệ, giữ nguyên.
- **Related files**: `LoginRetry.cs.bak` (deleted)

### ~16:00 - Ranorex Research Knowledge Base (tiếp tục)
- **Request**: Tiếp tục viết 4 file còn lại (05-08) của knowledge base `docs/ranorex-research/`
- **Result**: Hoàn thành toàn bộ 8 file research documents
- **Related files**:
  - `docs/ranorex-research/05_Stable_Automation_Strategy_For_DPI.md` — Object vs coordinate, wait strategy, login/popup handling, DPI-specific
  - `docs/ranorex-research/06_Debug_And_Troubleshooting_Checklist.md` — 8 checklists, decision trees, Máy A vs Máy B
  - `docs/ranorex-research/07_Current_Project_Risks.md` — 8 risks (2 HIGH, 4 MEDIUM, 2 LOW), risk matrix
  - `docs/ranorex-research/08_Research_Findings_And_Recommendations.md` — Tổng hợp findings, 10 rules, roadmap

### ~14:00 - Ranorex Research Knowledge Base (bắt đầu)
- **Request**: Đóng vai Ranorex Research Expert, tạo knowledge base 8 tài liệu trong `docs/ranorex-research/`
- **Result**: Hoàn thành 4/8 file đầu tiên (01-04)
- **Related files**:
  - `docs/ranorex-research/01_Ranorex_Overview.md`
  - `docs/ranorex-research/02_Project_Structure_Analysis.md`
  - `docs/ranorex-research/03_UserCode_Best_Practices.md`
  - `docs/ranorex-research/04_Repository_Best_Practices.md`

## 2026-05-21

### 17:27 - Project Initialization
- **Request**: Initialize CLAUDE.md for Lynn_DPI_AT Ranorex project
- **Result**: Created `CLAUDE.md` with project overview, build commands, architecture, and test suite structure
- **Related files**: `CLAUDE.md`, `docs/chat.md`, `docs/history.md`, `docs/plan.md`
