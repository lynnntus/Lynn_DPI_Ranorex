# Handover: OpenFile_FromProduction Implementation

> Session: 2026-06-21 | Build: PASS | Status: Code hoàn thành, chờ bind CSV + test thực tế

---

## 1. Mục tiêu

Implement `OpenFile_FromProduction.UserCode.cs` — mở recipe file từ tab Production (khác OpenFile dùng menu sidebar). Validate ModelName hiển thị ở vùng TOP sau khi mở file.

## 2. Files đã sửa

| File | Thay đổi |
|------|----------|
| `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/OpenFile_FromProduction.UserCode.cs` | Implement toàn bộ logic (từ stub `throw new NotImplementedException()`) |
| `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/OpenFile.UserCode.cs` | Fix typo 1 dòng duy nhất: `BtnOpenInDialogialog` → `BtnOpenInDialog` (dòng 112) |

## 3. Build: PASS (Debug x86)

## 4. Logic đã implement trong OpenFile_FromProduction.UserCode.cs

6 methods:

| Method | Chức năng |
|--------|-----------|
| `Init()` | Log Enable, RecipeFilePath, ModelName |
| `OpenRecipeFileByPath()` | Method chính — Enable check → file exists → try/finally { Buoc 1-6 + CleanupDialog } → return RecipeFilePath |
| `EnterPathIntoFileNameField(path)` | Set `TextValue` vào ô file name, verify sau khi set |
| `ReadFileNameField()` | Đọc TextValue, fallback WindowText |
| `ValidateTopModelName()` | Guard ModelName rỗng → poll `TopTextRecipeName` caption chứa ModelName (Contains, max 60s, poll 2s) |
| `CleanupDialog()` | try/catch non-fatal: Escape → Close nếu dialog còn mở |

Flow: `Click BtnOpenFileFromProduction → Wait dialog → Enter path → Click Open → Wait load → Validate TOP → Cleanup`

Signature khác OpenFile: `string OpenRecipeFileByPath()` (không có param, đọc `this.RecipeFilePath` trực tiếp, return string).

## 5. OpenFile.UserCode.cs — chỉ sửa typo, không đổi behavior

```diff
- repo.BtnOpenInDialogialog.Click();
+ repo.BtnOpenInDialog.Click();
```

Đây là lỗi tồn tại từ trước (typo "ialog" thừa), chặn build. Repository property đúng là `BtnOpenInDialog` (đã confirm trong `Lynn_DPI_ATRepository.cs`). Không sửa logic, wait, validate, hay bất kỳ behavior nào khác.

## 6. Repository items dùng/reuse

| Item | Nguồn | Reuse? |
|------|-------|--------|
| `repo.SelectRecipeFile` (dialog) | OpenFile | ✅ Reuse |
| `repo.SelectRecipeFile.Text1148` (ô file name) | OpenFile | ✅ Reuse |
| `repo.BtnOpenInDialog` (nút Open) | OpenFile | ✅ Reuse |
| `repo.CCIMainWindow.Area1.BtnOpenFileFromProduction` | Production | 🆕 Riêng |
| `repo.CCIMainWindow.Area1.TopTextRecipeName` / `TopTextRecipeNameInfo` | Production | 🆕 Riêng |

## 7. CSV file và binding cần làm

**File**: `TestData/Production_OpenFileData.csv`

| CSV Column | Module Variable | Binding |
|------------|----------------|---------|
| `CaseId` | — | **Không dùng, không cần bind** |
| `Enabled` | `Enable` | Bind thủ công (tên khác) |
| `RecipeFilePath` | `RecipeFilePath` | Tự bind (cùng tên) |
| `ExpectedFileName` | `ExpectedFileName` | Tự bind (cùng tên) |
| `ModeName` | `ModelName` | ⚠️ **Bind thủ công** (tên khác!) |

## 8. Bước tiếp theo trong Ranorex Studio

1. Manage Data Sources → Add CsvDataConnector → trỏ `TestData/Production_OpenFileData.csv`
2. Chọn module `OpenFile_FromProduction` trong test suite
3. Tab Data Source → chọn connector
4. Tab Data Binding → map: `Enabled` → `Enable`, `ModeName` → `ModelName`
5. Tab Iterations → `All rows`
6. Chạy test → kiểm tra Report:
   - OF_001 (Y): chạy, validate TOP
   - OF_002 (N): skip (`[SKIP]` trong log)
   - OF_003 (Y): chạy, validate TOP

## 9. Rủi ro cần chú ý

| Risk | Mức | Ghi chú |
|------|-----|---------|
| `ModeName` không bind đúng vào `ModelName` | Medium | Tên khác nhau, phải bind thủ công |
| `TopTextRecipeName` caption format khác dự kiến | Medium | Dùng `Contains()` nên linh hoạt |
| Dialog không đóng sau click Open | Low | `CleanupDialog()` trong finally xử lý |
| `BtnOpenFileFromProduction` chưa sẵn sàng khi click | Low | Recording đã click TabProduction trước đó |

## 10. Nguyên tắc

- **KHÔNG sửa thêm code** nếu chưa được yêu cầu
- **KHÔNG sửa** OpenFile logic, .rxrec, .rxrep, .rxtst, .csproj
- **KHÔNG hardcode** path, credentials
- Chỉ sửa file `*.UserCode.cs`
