# SESSION HANDOVER — Dynamic RxPath & Timing Investigation

> Tạo: 2026-06-07
> Session trước: 2026-06-06 ~ 2026-06-07
> Mục đích: Handover đầy đủ cho session tiếp theo — dynamic RxPath, timing investigation, repository analysis

---

## Project Context

- **Framework**: Ranorex 10.7, .NET Framework 4.8, C#, Platform x86 (32-bit)
- **AUT**: Neptune DPI desktop app (`C:\Kohyoung\AOI\AOIGUI.exe`)
- **Build**: `MSBuild Lynn_DPI_AT.csproj /p:Configuration=Debug /p:Platform=x86`
- **MSBuild**: `C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe`
- **csproj**: `F:\RanorexProjects\Lynn_DPI_AT\Lynn_DPI_AT\Lynn_DPI_AT\Lynn_DPI_AT\Lynn_DPI_AT.csproj`
- **Quy tắc**: Đọc `CLAUDE.md` trước. Chỉ sửa `*.UserCode.cs`.

## Mục tiêu automation hiện tại

Validate rằng sau khi open recipe file, Neptune hiển thị đúng **ModelName** trong UI. ModelName lấy từ CSV data source (runtime), không hardcode.

## Knowledge Base

Đọc `docs/OpenFile_KNOWLEDGE.md` (đặc biệt Section 8) để có toàn bộ facts từ các session trước.

---

## OpenFile — ModelName Validation

### Problem
Cần validate ModelName hiển thị trong Neptune UI sau khi open recipe. Trước đây dùng `Validate.AreEqual(actual, expected)` đọc từ `repo.CCIMainWindow.SomeText.Element.Parent.Caption`.

### Evidence (đã chứng minh bằng report)
- `ValidateModelName()` với `Validate.AreEqual` **PASS** với recipe `Lynn_Stacking_Underfill` (session 2026-06-06 trước).
- Actual Model Name nằm ở **ANCESTOR_L1** (parent của SomeText), attribute `Caption`.
- Investigation logs xác nhận: `SomeText(CHILD)` có `Caption = ''`, `ANCESTOR_L1` có `Caption = 'Lynn_Stacking_Underfill'`.

### Analysis
- Logic validation đúng, nhưng phụ thuộc vào `repo.CCIMainWindow.SomeText` — item này hardcode caption trong RxPath.
- Khi đổi recipe, `SomeText.Exists()` = False → validation fail trước khi đến logic so sánh.
- Root cause không phải validation logic, mà là **Repository selector**.

### Current Status
- `ValidateModelName()` đã được **viết lại** (session này) — dùng dynamic RxPath thay vì `repo.CCIMainWindow.SomeText`.
- Chưa PASS — đang chờ timing investigation (xem section "Loading Timing Issue").

### Next Action
- Chờ kết quả timing investigation → quyết định approach cuối cùng.

---

## OpenFile — Dynamic RxPath Strategy

### Problem
Repository items `SomeText` và `SomeIndicator` hardcode `@caption='Lynn_Stacking_Underfill'` trong RxPath. Cần strategy dynamic để hoạt động với mọi ModelName.

### Evidence (đã chứng minh bằng Ranorex Spy)

**RxPath hiện tại trong `.rxrep`:**

```
SomeText absPath:
/form[@title='CCIMainWindow']/container[@automationid='MainView']/?/?/container[@automationid='View']//text[@caption='Lynn_Stacking_Underfill']/text[@caption='']

SomeText robustPath:
/form[@title='CCIMainWindow']//text[@caption='Lynn_Stacking_Underfill']/text[@caption='']

SomeIndicator absPath: (giống SomeText)
SomeIndicator robustPath: (rỗng)
```

**Spy investigation (session này) — kết quả trên recipe `Lynn_Array_BadMark`:**

| Thuộc tính node PARENT `text[@caption='Lynn_Array_BadMark']` | Giá trị |
|---|---|
| General: enabled | True |
| General: index | (trống) |
| General: visible | True |
| AutomationId | **Không có** |
| ClassName | **Không có** |
| ControlType | **Không có** |
| Name | **Không có** |
| caption (Text section) | `Lynn_Array_BadMark` (thay đổi theo recipe) |

**Node PARENT không có attribute ổn định nào ngoài `caption`** — chính là ModelName, thay đổi theo recipe.

**Spy investigation — `container[@automationid='View']`:**

| Thuộc tính | Giá trị |
|---|---|
| automationid | `View` |
| enabled | True |
| visible | True |
| caption | (trống) |
| containertype | (trống) |

Dưới `container[@automationid='View']` chỉ thấy 1 nhánh `text` (parent + child).

### Các approach đã thử và loại bỏ

| Approach | Kết quả | Lý do loại bỏ |
|---|---|---|
| Bỏ tick caption trên node CHA trong Spy | Node mất luôn element type `text` → thành wildcard `(any optional)` | Ranorex behavior: khi bỏ hết attribute, node thành wildcard |
| Bỏ tick caption trên node CON | Tương tự — thành wildcard | Cùng behavior |
| Sửa `.rxrep` bằng tay | KHÔNG thử | Rule: không sửa `.rxrep` bằng tay |
| Re-spy trong Ranorex Studio | Chưa hoàn tất | User quyết định đổi hướng sang code approach |
| Regex `~` operator trong Spy | Chưa thử | User quyết định dừng sửa Repository bằng Spy |

### Approach được chọn (đã implement)

**Dynamic RxPath trong UserCode** — dùng `Host.Local.FindSingle<Ranorex.Text>()`:

```csharp
string rxPath = string.Format(
    "/form[@title='CCIMainWindow']//text[@caption='{0}']", expected);
Ranorex.Text foundElement = Host.Local.FindSingle<Ranorex.Text>(rxPath, 30000);
```

- `expected` = `this.ModelName` từ CSV runtime
- Không phụ thuộc vào `repo.CCIMainWindow.SomeText` nữa
- Repository `.rxrep` không bị sửa

### Current Status
- Code đã implement, build PASS.
- Test thực tế: **FAIL** — timeout 30s, element không tìm thấy (xem section "Loading Timing Issue").

### Giả thuyết chưa xác nhận
1. RxPath `/form[@title='CCIMainWindow']//text[@caption='{ModelName}']` có thể match đúng element khi app đã load xong — **CHƯA xác nhận** vì chưa bao giờ test thành công với timing đủ.
2. `container[@automationid='View']` có thể dùng làm "app ready" signal — **CHƯA xác nhận**.

---

## OpenFile — Loading Timing Issue

### Problem
Sau khi click Open trong Select Recipe File dialog, Neptune mất thời gian load recipe. `ValidateModelName()` với dynamic RxPath (30s timeout) fail — element `text[@caption='Lynn_Array_BadMark']` không tìm thấy.

### Evidence (đã chứng minh bằng report — test chạy 2026-06-07)

```
00:13.319 — Info Screenshot (sau click Open, app đang loading)
00:43.476 — Info Screenshot (30s sau, trước khi fail)
00:43.477 — Error: "ModelName KHONG tim thay trong UI. Expected: 'Lynn_Array_BadMark',
             RxPath: '/form[@title='CCIMainWindow']//text[@caption='Lynn_Array_BadMark']'"
00:43.532 — Module Error: ValidateModelName FAIL (exception thrown)
```

Timeline:
- Click Open → ~3s delay → ValidateModelName bắt đầu → 30s timeout → fail
- Tổng: ~33s từ click Open đến fail

### Analysis

**Flow hiện tại trong `ITestModule.Run()` (OpenFile.cs — auto-generated):**

```
Init()
OpenRecipeFileByPath(RecipeFilePath)    ← UserCode, chứa ValidateModelName
│   Buoc 5: Click Open
│   Buoc 6: Delay 3s
│   Buoc 7: ValidateModelName()         ← FAIL sau 30s timeout
│                                       ← exception → dừng ở đây
│
SomeIndicatorInfo.WaitForExists(50000)  ← KHÔNG BAO GIỜ CHẠY ĐẾN
Report.Screenshot(...)                  ← KHÔNG BAO GIỜ CHẠY ĐẾN
```

**Vấn đề timing:**
- Auto-generated code thiết kế `SomeIndicatorInfo.WaitForExists(50000)` = expect recipe load tới **50s**.
- Nhưng step này nằm SAU `OpenRecipeFileByPath()` → không bao giờ chạy đến vì exception trong ValidateModelName.
- ValidateModelName bắt đầu chỉ 3s sau click Open, với 30s timeout → tổng 33s — có thể **chưa đủ**.

**Câu hỏi chưa trả lời:**
1. Recipe load mất bao lâu thực tế? (30s? 50s? 90s?)
2. `text[@caption='{ModelName}']` xuất hiện ngay khi recipe load, hay sau một khoảng delay thêm?
3. `container[@automationid='View']` có phải signal đáng tin cậy cho "app ready" không?

### Approach đã thống nhất: Tách Wait và Validate (Approach C)

```
Buoc 7a: Đợi container[@automationid='View'] xuất hiện (max 60s)
         → signal: Neptune đã render recipe UI

Buoc 7b: Đợi thêm vài giây cho UI elements ổn định

Buoc 7c: FindSingle text[@caption='{ModelName}'] (timeout ngắn 10-15s)
         → lúc này app đã ready, nếu không tìm thấy = thật sự sai ModelName
```

### Investigation code đã implement (ĐANG CHỜ CHẠY)

Code hiện tại trong `ValidateModelName()` là **investigation version** — poll cả hai signal với timing log:

- **Phase A**: Poll `container[@automationid='View']` mỗi 2s, max 60s
- **Phase B**: Poll `text[@caption='{ModelName}']` mỗi 2s, max 120s tổng
- **ProbeSignals("BEFORE_OPEN")**: Check cả hai signal TRƯỚC khi click Open

**Output mong đợi trong report:**

```
[PROBE BEFORE_OPEN] View container = True/False, ModelName text = True/False
[SIGNAL] View container FOUND tai XXXms
[SIGNAL] ModelName text FOUND tai XXXms
=== SIGNAL TIMING SUMMARY ===
```

### Current Status
- Investigation code đã implement, build PASS.
- **CHƯA CHẠY test** — cần chạy và đọc report để lấy timing data.

### Next Action
1. Chạy test với investigation code.
2. Đọc report → xác nhận timing của từng signal.
3. Dựa trên timing data, implement version chính thức của ValidateModelName.

---

## OpenFile — Repository Cache / DataSource Iteration Issue

### Problem (tiềm ẩn)
`SomeIndicator` trong `OpenFile.cs` (auto-generated, line 124-125) cũng hardcode `@caption='Lynn_Stacking_Underfill'`:

```csharp
// OpenFile.cs:124-125 (auto-generated — KHÔNG được sửa)
Report.Log(ReportLevel.Info, "Wait", "Waiting 50s to exist. Associated repository item: 'CCIMainWindow.SomeIndicator'", ...);
repo.CCIMainWindow.SomeIndicatorInfo.WaitForExists(50000);
```

### Evidence
- `SomeIndicator` RxPath trong `.rxrep`:
  ```
  /form[@title='CCIMainWindow']/container[@automationid='MainView']/?/?/container[@automationid='View']//text[@caption='Lynn_Stacking_Underfill']/text[@caption='']
  ```
- Hardcode `@caption='Lynn_Stacking_Underfill'` — giống SomeText.

### Analysis
- Step này nằm SAU `OpenRecipeFileByPath()` trong `ITestModule.Run()`.
- Hiện tại `OpenRecipeFileByPath()` throw exception → step này KHÔNG BAO GIỜ CHẠY ĐẾN.
- Nhưng khi fix xong timing issue và ValidateModelName PASS, flow sẽ tiếp tục đến `SomeIndicatorInfo.WaitForExists(50000)` → sẽ FAIL cho recipe khác.

### Current Status
- **CHƯA xử lý** — bị che bởi timing issue.
- Sẽ cần xử lý sau khi ValidateModelName hoạt động ổn định.

### Các lựa chọn xử lý
1. **Re-spy `SomeIndicator`** trong Ranorex Studio — cần tìm dynamic RxPath
2. **Re-record `OpenFile.rxrec`** — thay step dùng SomeIndicator bằng step khác
3. **Xóa step SomeIndicator** khỏi recording — nếu ValidateModelName đã đủ confirm recipe loaded

### Next Action
- Sau khi timing investigation xong, quyết định approach cho SomeIndicator.

---

## Thay đổi code đã thực hiện (session này)

| File | Thay đổi | Build |
|------|----------|-------|
| `OpenFile.UserCode.cs` | Viết lại `ValidateModelName()` — dynamic RxPath, investigation polling | PASS |
| `OpenFile.UserCode.cs` | Thêm `ProbeSignals(phase)` — check signals trước click Open | PASS |
| `OpenFile.UserCode.cs` | Buoc 7: Bỏ `SomeTextInfo.Exists(30000)`, bỏ `InvestigateModelNameElement()` | PASS |
| `OpenFile.UserCode.cs` | Thêm Buoc 4.5: `ProbeSignals("BEFORE_OPEN")` | PASS |

## Thay đổi đã bị loại bỏ / không thực hiện

| Approach | Lý do loại bỏ |
|---|---|
| Sửa Repository `.rxrep` bằng tay | Rule: không sửa `.rxrep` bằng tay |
| Re-spy bỏ caption trong Ranorex Spy | Bỏ tick caption → element type mất, thành wildcard |
| Re-spy dùng regex `~` operator | User quyết định dừng sửa Repository, chuyển sang code approach |
| Tăng timeout đơn thuần (30s → 90s) | User yêu cầu tìm approach ổn định hơn |

## Dead code còn tồn tại (chưa xóa — cần confirm từ user)

| Code | File | Dòng | Lý do chưa xóa |
|------|------|------|----------------|
| `InvestigateModelNameElement()` | OpenFile.UserCode.cs | ~353-394 | Investigation code cũ, không còn được gọi |
| `LogElement()` | OpenFile.UserCode.cs | ~396-422 | Helper cho investigation |
| `LogChildren()` | OpenFile.UserCode.cs | ~424-456 | Helper cho investigation |
| `PROBE_ATTRS` | OpenFile.UserCode.cs | ~345-351 | Static array cho investigation |

Tất cả nằm trong block `// PHASE 1 INVESTIGATION — temporary`. Không ảnh hưởng runtime vì không được gọi.

---

## Files liên quan

| File | Vai trò | Sửa? |
|------|---------|------|
| `Lynn_DPI_AT/.../OpenFile.UserCode.cs` | Custom logic — investigation code đang chạy | CÓ (session này) |
| `Lynn_DPI_AT/.../OpenFile.cs` | Auto-generated — `ITestModule.Run()`, `SomeIndicator.WaitForExists` | KHÔNG sửa |
| `Lynn_DPI_AT/.../OpenFile.rxrec` | Recording definition, module variables | KHÔNG sửa |
| `Lynn_DPI_AT/.../Lynn_DPI_ATRepository.rxrep` | RxPath selector — hardcode caption | KHÔNG sửa |
| `Lynn_DPI_AT/.../Lynn_DPI_ATRepository.cs` | Auto-generated từ `.rxrep` | KHÔNG sửa |
| `TestData/OpenFileData.csv` | Data source cho OpenFile | KHÔNG sửa |
| `docs/OpenFile_KNOWLEDGE.md` | Knowledge base — facts từ mọi session | Cần update sau investigation |
| `docs/HANDOVER_OpenFile_RepositoryIssue.md` | Handover cũ — vẫn relevant | Tham khảo |

## Repository items liên quan

| Item | RxPath | Hardcode? | Dùng bởi |
|------|--------|-----------|----------|
| `CCIMainWindow.SomeText` | `//text[@caption='Lynn_Stacking_Underfill']/text[@caption='']` | **CÓ** | ~~ValidateModelName~~ (đã thay bằng dynamic) |
| `CCIMainWindow.SomeIndicator` | `//text[@caption='Lynn_Stacking_Underfill']/text[@caption='']` | **CÓ** | OpenFile.cs:125 (auto-generated) |
| `CCIMainWindow.Self` | `/form[@title='CCIMainWindow']` | Không | Activate, screenshot |
| `CCIMainWindow.LeftMenuOpenToogleButton` | (xem repo) | Không | Buoc 3 |
| `CCIMainWindow.MenuOpenRecipe` | `button[@text='Open Recipe']` | Không | Buoc 3 |
| `SelectRecipeFile.Text1148` | `text[@controlid='1148']` | Không | Buoc 4 |
| `ButtonOpen` | `button[@text='&Open']` | Không | Buoc 5 |

## Test Data liên quan

**OpenFileData.csv** (`TestData/OpenFileData.csv`):
```csv
CaseId,Enabled,RecipeFilePath,ExpectedFileName,Model Name
OF_001,Y,C:\Kohyoung\Job\Lynn_20260516_Stacking\Lynn_Stacking_Underfill.kyjob,Lynn_Stacking_Underfill.kyjob,Lynn_Stacking_Underfill
```

**LƯU Ý**: CSV chỉ có 1 row với `Lynn_Stacking_Underfill`. Test fail với `Lynn_Array_BadMark` — nghĩa là recipe đó được load bằng cách khác (không phải từ CSV này), hoặc ModelName variable có default value khác.

**Module variable defaults** (trong `OpenFile.cs` constructor):
```csharp
RecipeFilePath = "C:\\Kohyoung\\Job\\Lynn_20260516_Stacking\\Lynn_Stacking_Underfill.kyjob";
ModelName = "Lynn_Stacking_Underfill";
```

→ Test report fail với `Lynn_Array_BadMark` → có thể CSV đã được sửa trên máy chạy test, hoặc có recipe khác.

---

## Kết luận hiện tại

### Đã chứng minh bằng report
1. OpenFile workflow (dialog → nhập path → click Open → file load) hoạt động.
2. `ValidateModelName()` cũ (dùng `repo.SomeText`) PASS với `Lynn_Stacking_Underfill`.
3. `repo.SomeText` / `repo.SomeIndicator` FAIL với recipe khác (vì hardcode caption).
4. Dynamic RxPath `/form[@title='CCIMainWindow']//text[@caption='Lynn_Array_BadMark']` FAIL sau 30s timeout (test 2026-06-07).

### Chỉ là giả thuyết (chưa chứng minh)
1. Recipe load có thể mất hơn 33s → tăng timeout có thể giải quyết.
2. `container[@automationid='View']` có thể là signal đáng tin cậy cho "app ready".
3. Dynamic RxPath sẽ match đúng element nếu có đủ thời gian.
4. `ProbeSignals("BEFORE_OPEN")` sẽ cho biết View container có tồn tại trước khi load recipe mới.

### KHÔNG nên sửa vội
1. **Không tăng timeout đơn thuần** — cần hiểu timing trước.
2. **Không sửa `.rxrep` bằng tay** — rule project.
3. **Không xóa investigation code** — cần chạy 1 lần để lấy timing data.
4. **Không xử lý SomeIndicator** — bị che bởi timing issue, sẽ giải quyết sau.
5. **Không sửa `ValidateModelName()` logic** — đang ở investigation mode, cần data trước.

---

## Recommended Next Investigation

### Ưu tiên 1: Chạy test với investigation code hiện tại

**Mục tiêu**: Lấy timing data từ report.

**Action**:
1. Đảm bảo recipe `Lynn_Array_BadMark` (hoặc recipe khác) sẽ được load.
2. Chạy test.
3. Đọc report — tìm các log entry:
   - `[PROBE BEFORE_OPEN]` — View container / ModelName text tồn tại trước click Open?
   - `[SIGNAL] View container FOUND tai XXXms` — bao lâu sau click Open?
   - `[SIGNAL] ModelName text FOUND tai XXXms` — bao lâu sau View container?
   - `=== SIGNAL TIMING SUMMARY ===` — tổng kết

**Dựa trên kết quả**:
- Nếu View container FOUND trước ModelName text → dùng View container làm "wait app ready" signal.
- Nếu cả hai NOT FOUND sau 120s → RxPath có thể sai, cần investigation thêm.
- Nếu ModelName text FOUND trong 60-90s → chỉ cần tăng timeout (nhưng vẫn nên dùng View container signal).

### Ưu tiên 2: Implement ValidateModelName chính thức

Sau khi có timing data, viết version chính thức:

```
Phase A: WaitForViewContainer(60s)   ← app ready signal
Phase B: Delay nhỏ (2-5s)           ← buffer cho UI ổn định
Phase C: FindSingle ModelName (15s)  ← validation thực sự
```

Bỏ investigation code (ProbeSignals, polling logs).

### Ưu tiên 3: Xử lý SomeIndicator trong OpenFile.cs

Sau khi ValidateModelName PASS, flow sẽ tiếp tục đến `SomeIndicatorInfo.WaitForExists(50000)` (auto-generated) → FAIL.

Lựa chọn:
- Re-spy `SomeIndicator` trong Ranorex Studio
- Re-record `OpenFile.rxrec` — xóa/thay step SomeIndicator
- Hoặc: trong `Init()` / `Finish()`, tìm cách bypass (nếu có thể)

### Ưu tiên 4: Cleanup dead code

Sau khi mọi thứ ổn định:
- Xóa `InvestigateModelNameElement()` và helpers
- Xóa `ProbeSignals()` (nếu không cần nữa)
- Xóa `PROBE_ATTRS` static array
- Cập nhật `docs/OpenFile_KNOWLEDGE.md`

---

## DO NOT

- KHÔNG sửa `OpenFile.cs` — auto-generated.
- KHÔNG sửa `.rxrep` bằng tay.
- KHÔNG sửa `.rxrec`, `.rxtst`, `.csproj`.
- KHÔNG xóa investigation code trước khi có timing data.
- KHÔNG tăng timeout đơn thuần mà chưa hiểu timing.
- KHÔNG commit/push khi chưa được yêu cầu.
