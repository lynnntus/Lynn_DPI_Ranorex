# SESSION STARTER — OpenFile Module: Repository Hardcode Issue

> Tạo: 2026-06-06
> Mục đích: Handover cho session re-spy Repository selector, loại bỏ hardcode model name.

---

## Project

- Framework: Ranorex 10.7, .NET Framework 4.8, C#, Platform x86 (32-bit)
- AUT: Neptune DPI desktop app (`C:\Kohyoung\AOI\AOIGUI.exe`)
- Build: `MSBuild Lynn_DPI_AT.csproj /p:Configuration=Debug /p:Platform=x86`
- MSBuild: `C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe`
- csproj: `F:\RanorexProjects\Lynn_DPI_AT\Lynn_DPI_AT\Lynn_DPI_AT\Lynn_DPI_AT\Lynn_DPI_AT.csproj`
- Quy tắc: Đọc `CLAUDE.md` trước. Chỉ sửa `*.UserCode.cs`.

## Knowledge Base

Đọc `docs/OpenFile_KNOWLEDGE.md` (đặc biệt Section 8) để có toàn bộ facts.

---

## Current Status

### PASS (đã xác nhận)

- OpenFile workflow hoạt động hoàn chỉnh (dialog → nhập path → click Open → file load).
- `ValidateModelName()` đã implement trong `OpenFile.UserCode.cs` — dùng `Validate.AreEqual`.
- Đọc actual Model Name từ `SomeText.Element.Parent.Caption` (ANCESTOR_L1).
- CSV đã có cột `ModelName`, data binding hoạt động.
- Validation PASS với recipe `Lynn_Stacking_Underfill`.

### KNOWN ISSUE — Repository Hardcode (CHƯA xử lý)

Repository item `CCIMainWindow.SomeText` (và `SomeIndicator`) đang bị **hardcode** theo giá trị model cụ thể.

Khi đổi TestData sang model khác (ví dụ `Lynn_Array_BadMark` hoặc bất kỳ model nào khác):

- `SomeText.Exists()` = **False**
- `ValidateModelName()` fail
- Đây **KHÔNG phải lỗi logic validation** — root cause nằm ở Repository selector.

---

## Root Cause đã xác nhận

### RxPath hiện tại chứa hardcode caption

**SomeText** — Robust Path:
```
/form[@title='CCIMainWindow']//text[@caption='Lynn_Stacking_Underfill']/text[@caption='']
```

**SomeIndicator** — tương tự, cùng hardcode `@caption='Lynn_Stacking_Underfill'`.

### Tại sao lại hardcode?

Khi spy trong Ranorex Studio, nếu element được spy lúc recipe `Lynn_Stacking_Underfill` đang load, Ranorex tự ghi nhận caption hiện tại vào RxPath. Đây là behavior mặc định của Ranorex — không phải lỗi.

### Hệ quả

| Scenario | SomeText.Exists() | Validation | Kết quả |
|----------|-------------------|------------|---------|
| Recipe = `Lynn_Stacking_Underfill` | True | PASS | OK |
| Recipe = `Lynn_Array_BadMark` | **False** | **FAIL** (throw Exception) | Lỗi giả |
| Recipe = bất kỳ model khác | **False** | **FAIL** (throw Exception) | Lỗi giả |

---

## Evidence

### 1. RxPath trong Repository file

File: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_ATRepository.rxrep`

```xml
<!-- SomeText -->
<item ... robustpath="//text[@caption='Lynn_Stacking_Underfill']/text[@caption='']" />

<!-- SomeIndicator -->
<item ... robustpath="//text[@caption='Lynn_Stacking_Underfill']/text[@caption='']" />
```

### 2. Investigation logs (session trước)

```
[PROBE] SomeText(CHILD): Caption = ''
[PROBE] ANCESTOR_L1: Caption = 'Lynn_Stacking_Underfill'
[PROBE] ANCESTOR_L1: Text = 'Lynn_Stacking_Underfill'
```

→ ANCESTOR_L1 (parent) chứa model name thật. CHILD (SomeText target) chỉ là text rỗng bên trong.

### 3. ValidateModelName() hoạt động đúng

Khi `SomeText.Exists()` = True (recipe đúng), validation logic lấy đúng giá trị từ parent:
```
Expected ModelName = 'Lynn_Stacking_Underfill'
Actual ModelName   = 'Lynn_Stacking_Underfill'
Attribute used = 'Caption'
[Validation] AreEqual — PASS
```

---

## Files đã sửa (session trước)

| File | Thay đổi |
|------|----------|
| `OpenFile.UserCode.cs` | Thêm `ValidateModelName()`, gọi cuối Buoc 7 |

## Files liên quan

| File | Vai trò | Sửa? |
|------|---------|------|
| `OpenFile.UserCode.cs` | Custom logic — validation đã implement | KHÔNG sửa thêm |
| `OpenFile.cs` | Auto-generated — gọi flow chính | KHÔNG sửa |
| `Lynn_DPI_ATRepository.rxrep` | Repository — chứa RxPath **hardcode** | CẦN re-spy trong Ranorex Studio |
| `Lynn_DPI_ATRepository.cs` | Auto-generated từ `.rxrep` | Tự sinh lại sau re-spy |
| `TestData/OpenFileData.csv` | Data source — cột `Model Name` | Không sửa |

---

## Next Investigation Steps

### Step 1: Phân tích cấu trúc UI element

Cần xác định:
- ANCESTOR_L1 (parent của SomeText) có thuộc tính gì **không đổi** giữa các recipe?
- `AutomationId`, `ClassName`, `ControlType` của ANCESTOR_L1 — dùng làm anchor cho dynamic selector.
- Investigation code hiện tại đã log các attribute này — xem lại report hoặc chạy lại.

### Step 2: Re-spy trong Ranorex Studio

1. Mở Ranorex Studio → Repository → `CCIMainWindow`.
2. Load recipe khác (không phải `Lynn_Stacking_Underfill`).
3. Spy lại element chứa Model Name.
4. Tạo RxPath **dynamic** — không chứa giá trị caption cụ thể.

### Step 3: Test với nhiều recipe

- Load lần lượt 2-3 recipe khác nhau.
- Verify selector mới match đúng element chứa Model Name.
- Verify `ValidateModelName()` đọc được actual Model Name từ selector mới.

### Step 4: Cập nhật OpenFile.UserCode.cs (nếu cần)

- Nếu selector mới trỏ vào **ANCESTOR_L1** thay vì CHILD → `ValidateModelName()` có thể cần điều chỉnh (bỏ `.Parent`).
- Nếu selector mới vẫn trỏ vào CHILD → logic hiện tại giữ nguyên.

---

## Risks

| Hạng mục | Rủi ro | Lý do |
|----------|--------|-------|
| Re-spy selector | **TRUNG BÌNH** | Cần tìm attribute ổn định, không phụ thuộc recipe |
| ANCESTOR_L1 structure thay đổi giữa recipes | **THẤP** | UI Neptune có layout cố định cho Recipe Info |
| OpenFile.cs auto-generated dùng SomeIndicator | **CAO** | `SomeIndicator` cũng hardcode — `WaitForExists(30000)` sẽ fail cho recipe khác |
| ValidateModelName() cần sửa sau re-spy | **THẤP** | Chỉ cần điều chỉnh nếu selector trỏ vào element khác |

---

## Recommended Approach

### Ưu tiên 1: Re-spy cả SomeText VÀ SomeIndicator

Cả hai đều hardcode `@caption='Lynn_Stacking_Underfill'`. Nếu chỉ sửa SomeText mà không sửa SomeIndicator, `OpenFile.cs:125` (`SomeIndicatorInfo.WaitForExists(30000)`) sẽ vẫn fail cho recipe khác.

### Ưu tiên 2: Tìm dynamic RxPath

Candidates cho dynamic selector:
```
// Thay vì hardcode caption:
text[@caption='Lynn_Stacking_Underfill']

// Dùng wildcard hoặc structural path:
text[@caption!='']                         ← match bất kỳ text có caption
container[@automationid='View']//text[1]   ← match theo vị trí
```

> Cần verify trong Ranorex Spy với nhiều recipe để chọn approach tốt nhất.

### Ưu tiên 3: KHÔNG sửa ValidateModelName()

Logic validation đã hoạt động đúng. Sau khi re-spy:
- Nếu selector mới trỏ vào element có Caption = Model Name → chỉ cần bỏ `.Parent` trong code.
- Nếu selector mới giữ cấu trúc CHILD/PARENT → giữ nguyên code.

---

## DO NOT

- KHÔNG sửa `ValidateModelName()` logic.
- KHÔNG sửa `.rxrep` bằng tay — phải dùng Ranorex Studio.
- KHÔNG thay đổi data binding hoặc CSV structure.
- KHÔNG commit/push khi chưa được yêu cầu.
