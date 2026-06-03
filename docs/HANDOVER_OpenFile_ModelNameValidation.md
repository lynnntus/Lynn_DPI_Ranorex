# SESSION STARTER — OpenFile Module: ModelName Validation

> Tạo: 2026-06-03
> Mục đích: Handover cho session implement ModelName validation sau khi recipe load.

---

## Project

- Framework: Ranorex 10.7, .NET Framework 4.8, C#, Platform x86 (32-bit)
- AUT: Neptune DPI desktop app (`C:\Kohyoung\AOI\AOIGUI.exe`)
- Build: `MSBuild Lynn_DPI_AT.csproj /p:Configuration=Debug /p:Platform=x86`
- MSBuild: `C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe`
- csproj: `F:\RanorexProjects\Lynn_DPI_AT\Lynn_DPI_AT\Lynn_DPI_AT\Lynn_DPI_AT\Lynn_DPI_AT.csproj`
- Quy tắc: Đọc `CLAUDE.md` trước. Chỉ sửa `*.UserCode.cs`.

## Knowledge Base

Đọc `docs/OpenFile_KNOWLEDGE.md` để có toàn bộ facts, rules, và lesson learned.

---

## Current Status

### PASS (đã xác nhận qua test thực tế)

- Open Recipe dialog mở thành công qua `LeftMenuOpenToogleButton` → `MenuOpenRecipe`.
- `MenuOpenRecipe` polling wait hoạt động (max 50s, poll 400ms).
- `RecipeFilePath` nhập vào `Text1148` thành công bằng `Text1148.TextValue = recipeFilePath`.
- File được mở thực tế trong Neptune application.

### Known Issue (đã xử lý tạm thời)

- Bước 6: verify dialog closed sau click Open gây **false failure**.
- Nguyên nhân: dialog đóng ngay nhưng Neptune cần thời gian load recipe.
- Trạng thái hiện tại: Bước 6 đã thay bằng `Delay(2000)` + `Report.Info` — không throw exception.
- Chưa commit bất kỳ thay đổi nào.

---

## Next Goal

**Validate ModelName sau khi recipe load xong.**

- Logic kỳ vọng:
  1. Click Open → recipe load trong Neptune.
  2. Đọc ModelName từ UI Neptune (Recipe Information panel hoặc tương đương).
  3. So sánh với `ModelName` từ CSV data source.
  4. PASS nếu match, FAIL nếu không match.

---

## Available Data

File CSV: `TestData/OpenFileData.csv`

| Cột | Mô tả | Trạng thái binding |
|-----|-------|-------------------|
| `RecipeFilePath` | Full path đến `.kyjob` file | Đang dùng default value — chưa bind CSV |
| `ExpectedFileName` | Tên file kỳ vọng | Đang dùng default value — chưa bind CSV |
| `ModelName` | Model name kỳ vọng sau load | Chưa bind CSV |

Default value hiện tại: `C:\Kohyoung\Job\Lynn_20260516_Stacking\Lynn_Stacking_Underfill.kyjob`

---

## Current Hypothesis

- Sau khi recipe load, Neptune hiển thị Model Name trong **Recipe Information panel**.
- Validation: đọc text từ repository item tương ứng → so sánh với `ModelName` từ CSV.
- PASS nếu UI ModelName == CSV ModelName (case-insensitive trim).

---

## Required Investigation (TRƯỚC KHI sửa code)

1. **Repository item nào đại diện cho Model Name?**
   - Dùng Spy để inspect Neptune UI sau khi recipe load.
   - Tìm label/text field hiển thị tên model trong Recipe Information panel.
   - Ghi lại: Class, ControlId, AccessibleName, RxPath.

2. **Text có phải dynamic (thay đổi theo recipe) không?**
   - Verify bằng cách load 2 recipe khác nhau, xem text thay đổi.

3. **Item đã có trong `Lynn_DPI_ATRepository.rxrep` chưa?**
   - Nếu chưa: cần thêm vào repository trong Ranorex Studio (KHÔNG sửa `.rxrep` trực tiếp).
   - Nếu đã có: kiểm tra RxPath selector còn đúng không.

4. **`SomeIndicator` trong OpenFile.cs có liên quan đến load complete không?**
   - `OpenFile.cs:145-146`: `SomeIndicator.WaitForExists(30000)` — đây có thể là signal recipe load xong.
   - Nếu `SomeIndicator` đã wait đủ: ModelName đọc được ngay sau đó.

---

## Rules (kế thừa từ session trước)

### KHÔNG dùng lại trên Text1148

- Ctrl+A / Ctrl+V / clipboard.
- `SetAttributeValue("WindowText")`.

### BẮT BUỘC

- Verify field text **trước khi** click Open.
- Chỉ sửa `*.UserCode.cs`.
- Không commit/push khi chưa được yêu cầu.
- Không suy đoán control type từ tên repository item — dùng Spy để xác nhận.
- Ưu tiên Spy evidence hơn giả định từ source code.

---

## Files chính

| File | Vai trò | Ghi chú |
|------|---------|---------|
| `OpenFile.UserCode.cs` | Custom logic — file đang debug | File duy nhất được sửa |
| `OpenFile.cs` | Auto-generated — KHÔNG sửa | Gọi `Init()` → `OpenRecipeFileByPath()` → `SomeIndicator.WaitForExists(30000)` |
| `TestData/OpenFileData.csv` | Data source | Đã có cột ModelName |
| `docs/OpenFile_KNOWLEDGE.md` | Knowledge base đầy đủ | Đọc trước khi làm |
