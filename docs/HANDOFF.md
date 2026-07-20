# HANDOFF — Lynn_DPI_AT Session Context

> Tao boi Claude Code — cap nhat 2026-07-20
> Muc dich: Ban giao context cho session moi

---

## 1. TONG QUAN DU AN

- **Framework**: Ranorex 10.7, .NET Framework 4.8, C#
- **Platform**: x86 (32-bit) — bat buoc
- **AUT**: `C:\Kohyoung\AOI\AOIGUI.exe` (Neptune DPI)
- **IDE**: Ranorex Studio (mo file `Lynn_DPI_AT.rxsln`)
- **Data source**: CSV + CsvDataConnector (cau hinh trong Ranorex Studio)
- **Git root**: `f:\RanorexProjects\Lynn_DPI_AT\`
- **Code path**: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/` (3 cap thu muc)

### Module flow

```
StartAUT → Login_Pass → OpenFile → Recording1 → Logout → CloseAUT
```

### Test Suite structure (tu .rxtst)

```
Lynn_DPI_AT (suite)
└── Lynn_DPI_AT (testcase)
    ├── TestCase
    │   ├── setup: StartAUT
    │   ├── Recording1
    │   └── teardown: CloseAUT
    ├── SmokeTest
    │   ├── StartAUT
    │   ├── Users (smartfolder, datasource=NewConnector, rows 1-2)
    │   │   └── LoginRetry
    │   ├── Login_Pass [DISABLED]
    │   └── Logout [DISABLED]
    ├── OpenFile (datasource=OpenFile)
    │   └── OpenFile module
    ├── Production_TabNavigation
    │   ├── Tab_Production
    │   └── Verify_ProductionPresettingDialog_AutoClose
    ├── Production_OpenFile
    │   └── Production_OpenFile (smartfolder, datasource=Production_OpenFile)
    │       └── OpenFile_FromProduction
    └── Logout
        └── Logout module
```

### Data sources

| File CSV | Connector | Module | Cot |
|----------|-----------|--------|-----|
| `Users.csv` | `NewConnector` | `LoginRetry` | `UserName`, `Password` |
| `OpenFileData.csv` | `OpenFile` | `OpenFile` | `CaseId`, `Enabled`, `RecipeFilePath`, `ExpectedFileName`, `Model Name` |
| `Production_OpenFileData.csv` | `Production_OpenFile` | `OpenFile_FromProduction` | `CaseId`, `Enabled`, `RecipeFilePath`, `ExpectedFileName`, `ModeName` |

---

## 2. REPOSITORY — Cau truc UI (tu Lynn_DPI_ATRepository.rxrep)

### Cac AppFolder va items chinh

| AppFolder | Base RxPath | Use Cache | Items |
|-----------|-------------|-----------|-------|
| `CCILoginWindow` | `/form[@name='View']` | True | `Login`, `XIDPWLoginArea`(`SomeText`, `TextXPW`, `XPWWatermark`) |
| `CCIMainWindow` | `/form[@title='CCIMainWindow']` | True | `CreateOrOpenRecipe`, `SomeButton`, `LeftMenuOpenToogleButton`, `SomeIndicator`, `Text`, `SomeIndicator1`, `SomeText`, `MenuOpenRecipe`, `SomeTable`, `Production`, `Area1`(`BtnMore`, `TopTextRecipeName`, `BtnOpenFileFromProduction`) |
| `ShutdownDialog` | `/form[@name='Popup' and @title='Inspection Region Settings']` | False | `BtnDualClose_Shutdown` |
| `InspectionRegionSettings` | `/form[@name='Popup' and @title='Production Presetting']` | False | `BtnDualClose`, `ProductionStopsWhenAllLOTInspection`, `LOTProduction`, `Settings`, **`BtnApplyProductionPresetting`** |
| `SelectRecipeFile` | `/form[@title='Select Recipe File']` | False | `SystemItemNameDisplay`, `Text1148`, `TxtFileNameInDialog` |
| `KohyoungGUI1` | `/form[@processname='KohyoungGUI']` | True | `SomeText`, `SomeText1`, `Apply`, `TabProduction`, `Continue`, `HeaderTextBlock1`, `Settings`, `PARTContentHost`, `PARTContentHost1` |
| `Explorer` | `/desktop[@processname='explorer']` | True | `NEPTUNECALLINONE`, `ExportLynn` |
| Root level | — | — | `BtnOpenInDialog` → `/form[@title='Select Recipe File']/button[@text='&Open']` |

> Ca 2 folder dung `form[@name='Popup']` deu da dat Use Cache = False (Bug 1 da fix).

### CANH BAO: 2 nut Apply khac nhau

| Accessor | RxPath | Dung cho |
|----------|--------|----------|
| `repo.InspectionRegionSettings.BtnApplyProductionPresetting` | `/form[@name='Popup' and @title='Production Presetting']//button[@text='Apply']` | Apply tren dialog Production Presetting |
| `repo.KohyoungGUI1.Apply` | `/form[@processname='KohyoungGUI']/container[@caption='']/button[@text='Apply']` | Apply tren main window (khac!) |

> **KHONG duoc nham lan 2 nut nay.** Truoc khi dung accessor, LUON doc `.rxrep` de xac nhan.

### CANH BAO: 2 folder cung dung form[@name='Popup']

| Folder | Base RxPath | @title |
|--------|-------------|--------|
| `InspectionRegionSettings` | `/form[@name='Popup' and @title='Production Presetting']` | Production Presetting |
| `ShutdownDialog` | `/form[@name='Popup' and @title='Inspection Region Settings']` | Inspection Region Settings |

> `@title` la phan phan biet duy nhat. Khong duoc bo `@title` khoi basepath.

### CANH BAO: Ten trung lap giua cac folder

- `Settings` ton tai trong CA `InspectionRegionSettings` VA `KohyoungGUI1` — RxPath khac nhau
- `SomeText` ton tai trong nhieu folder — phai chi dinh dung folder

---

## 3. FUNCTIONS — Chi tiet cac UserCode file

### StartAUT.UserCode.cs

| Method | Mo ta |
|--------|-------|
| `Init()` | Goi `LoginRetry.ResetState()` de reset `credentialFound` cho lan chay moi |

### LoginRetry.cs (ModuleType.UserCode)

| Method | Mo ta |
|--------|-------|
| `ResetState()` | Static — reset `credentialFound = false` |
| `ITestModule.Run()` | Entry point. Kiem tra `credentialFound` → skip neu da login. Kiem tra `CCIMainWindow` → skip neu da ton tai. Goi `Login_Pass.TryLoginWithUser()`. Neu thanh cong → set `Login_Pass.Instance.UserName/Password`, `credentialFound = true`. Neu that bai → screenshot, clear fields, hoac check main window muon |

Variables: `UserName`, `Password` (tu CSV qua data binding)
Constants: `LOGIN_WINDOW_EXIST_CHECK_MS = 5000`

### Login_Pass.UserCode.cs

| Method | Mo ta |
|--------|-------|
| `Init()` | Kiem tra `CCIMainWindow` da ton tai → skip login. Goi `WaitForLoginWindowReady()` |
| `WaitForLoginWindowReady()` | Cho login window + fields san sang |
| `TryLoginWithUser(user, pass)` | Static — nhap user/pass, click Login, smart wait main window |
| `TypeIntoUserField(value)` | Static — WPF pattern: `{Home}{Shift+End}{Delete}` + type |
| `TypeIntoPasswordField(pass)` | Static — tuong tu user field |
| `ClearLoginFields()` | Static — xoa ca 2 fields |
| `IsLoginSuccessful()` | Static — goi `WaitForMainWindowAfterLogin()` |
| `WaitForMainWindowAfterLogin()` | Static — poll `CCIMainWindow` toi da 120s |

Constants: `LOGIN_WINDOW_TIMEOUT_MS=80000`, `LOGIN_FIELD_TIMEOUT_MS=10000`, `MAIN_WINDOW_TIMEOUT_MS=80000`, `POST_LOGIN_MAIN_WINDOW_TIMEOUT_MS=120000`, `POST_LOGIN_POLL_INTERVAL_MS=2000`

### OpenFile.UserCode.cs

| Method | Mo ta |
|--------|-------|
| `Init()` | Log `Enable`, `RecipeFilePath`, `ExpectedFileName` |
| `OpenRecipeFileByPath(recipeFilePath)` | Flow 7 buoc: check Enable → verify CCIMainWindow → activate → menu click → nhap path → click Open → validate ModelName |
| `EnterPathIntoFileNameField(path)` | Set `TextValue` truc tiep, verify match |
| `ReadFileNameField()` | Try `TextValue` → fallback `WindowText` |
| `WaitForMenuOpenRecipeClickable(timeoutMs, pollIntervalMs)` | Poll `MenuOpenRecipe` Visible+Enabled, max 50s |
| `ValidateModelName()` | 2-phase poll: Phase A cho View container (60s), Phase B cho ModelName text (60s tiep) |
| `ProbeSignals(phase)` | Investigation — check View container + ModelName text tai thoi diem goi |
| `Finish()` | Dong dialog neu con mo |
| `InvestigateModelNameElement()` | Investigation — traverse SomeText + ancestors, log attributes |
| `LogElement(el, label)` | Log tat ca attributes cua element |
| `LogChildren(parent, parentLabel)` | Log children (max 10) cua element |
| `SafeAttr(el, attr)` | Helper — doc attribute an toan |

Constants: `FILE_DIALOG_TIMEOUT_MS=15000`, `DIALOG_CLOSE_TIMEOUT_MS=5000`, `MENU_OPEN_RECIPE_TIMEOUT_MS=50000`, `MENU_POLL_INTERVAL_MS=400`

### Tab_Production.UserCode.cs

| Method | Mo ta |
|--------|-------|
| `Init()` | Trong (stub) |

### Verify_ProductionPresettingDialog_AutoClose.UserCode.cs

| Method | Mo ta |
|--------|-------|
| `Init()` | Log "Module bat dau" |
| `ClickApplyWithPolling()` | 3 buoc: (1) Cho dialog xuat hien max 10s. (2) Cho dialog TU DONG dong max 30s bang `BtnApplyProductionPresettingInfo.WaitForNotExists()`. (3) Fallback: poll Apply button Visible+Enabled max 10s → click → verify dong |
| `LogPopupAndApplyDiag(tag)` | **CODE TAM** — log so luong Popup, Apply buttons, accessor state, screenshot |
| `TakeScreenshot()` | Screenshot dialog hoac man hinh |

Constants: `DIALOG_APPEAR_TIMEOUT_MS=10000`, `DIALOG_AUTOCLOSE_TIMEOUT_MS=30000`, `APPLY_ENABLED_TIMEOUT_MS=10000`, `APPLY_CLOSE_VERIFY_TIMEOUT_MS=15000`, `POLL_INTERVAL_MS=500`

### OpenFile_FromProduction.UserCode.cs

| Method | Mo ta |
|--------|-------|
| `Init()` | Log `Enable`, `RecipeFilePath`, `ModelName` |
| `OpenRecipeFileByPath()` | Flow 7 buoc: check Enable → click BtnOpenFileFromProduction → cho dialog → nhap path → click Open → click Apply (fallback) → validate TopModelName |
| `EnterPathIntoFileNameField(path)` | Set `TextValue`, verify match |
| `ReadFileNameField()` | Try `TextValue` → fallback `WindowText` |
| `ValidateTopModelName()` | Poll `TopTextRecipeName.Caption` contains `ModelName`, max 60s |
| `ClickApplyWithFallback()` | 4 strategy: (1) Native Click, (2) Focus+Space, (3) UIA Exists+Click, (4) Coordinate click. Kiem tra dialog dong sau moi strategy |
| `LogPopupAndApplyDiag(tag)` | **CODE TAM** — log so luong Popup, Apply buttons, accessor state, screenshot |
| `CleanupDialog()` | Escape → Close dialog neu con mo |

Constants: `FILE_DIALOG_TIMEOUT_MS=15000`, `APPLY_PRESETTING_TIMEOUT_MS=15000`, `TOP_VALIDATE_TIMEOUT_MS=60000`, `TOP_VALIDATE_POLL_MS=2000`

### Recording1.UserCode.cs

| Method | Mo ta |
|--------|-------|
| `Init()` | Trong (stub) |

### Logout.UserCode.cs

| Method | Mo ta |
|--------|-------|
| `Init()` | Trong (stub) |

### CloseAUT.UserCode.cs

| Method | Mo ta |
|--------|-------|
| `Init()` | Trong (stub) |

---

## 4. TEST SUITE — Cau hinh (.rxtst)

### Test case hierarchy

| Test Group | Module | Data Source | Ghi chu |
|------------|--------|-------------|---------|
| TestCase | StartAUT → Recording1 → CloseAUT | — | Basic flow, `AppProcessID` truyen tu StartAUT → CloseAUT |
| SmokeTest | StartAUT → LoginRetry → Login_Pass [DISABLED] → Logout [DISABLED] | `Users.csv` (rows 1-2) | Login retry qua CSV |
| OpenFile | OpenFile | `OpenFileData.csv` | Open recipe tu menu |
| Production_TabNavigation | Tab_Production → Verify_ProductionPresettingDialog_AutoClose | — | Chuyen tab Production + verify dialog tu dong dong |
| Production_OpenFile | OpenFile_FromProduction | `Production_OpenFileData.csv` | Open recipe tu Production tab |
| Logout | Logout | — | Logout cuoi cung |

### Luu y quan trong

- `Login_Pass` va `Logout` trong SmokeTest deu **DISABLED**
- `AppProcessID` truyen tu `StartAUT` → `CloseAUT` qua test case parameter — neu them test case moi can bind lai
- Tat ca search timeout trong repository: 30,000ms (30 giay)

---

## 5. VAN DE DANG XU LY

### ĐÃ FIX (phiên 2026-07-20)

**Bug 1 — Repo cache element cha đã chết (root cause chính)**
- Triệu chứng: "Element is not visible" khi click Apply, dù Spy thấy nút hiển thị bình thường.
- Log DIAG: chỉ có 1 form[@name='Popup'] (giả thuyết "nhiều Popup" là SAI). Tìm trực tiếp ->
  Apply Visible=True, Rect={998,849,120,32}. Qua repo accessor -> Visible=False, Rect={0,0,0,0}.
- Nguyên nhân: folder InspectionRegionSettings cache form[@name='Popup'] cũ đã đóng.
- FIX: Use Cache = False cho folder đó. Sau fix Apply click được (Strategy 2 Focus+Space).
- Folder ShutdownDialog cũng dùng form[@name='Popup'] -> nên tắt cache tương tự.

**Bug 2 — Path lồng form trong form**
- BtnApplyProductionPresetting từng có robustPath /form[@processname='KohyoungGUI']/
  form[@name='Popup']//button[...] — hai form nối nhau, không hợp lệ. Đã sửa:
    Item     : .//button[@text='Apply']
    Robust   : /form[@name='Popup' and @title='Production Presetting']//button[@text='Apply']
    Absolute : (giống Robust)
- Giữ @title vì repo có 2 folder cùng dùng form[@name='Popup'] (ShutdownDialog='Inspection
  Region Settings', InspectionRegionSettings='Production Presetting').

### ĐANG XỬ LÝ
**Bug 3 — ValidateTopModelName đọc sai attribute**: Actual='topTextRecipeName' không đổi suốt
60s poll. Spy xác minh: Caption trả về AUTOMATIONID, text thật ("KYE_Ver9_3_Job remake_1") nằm
ở Text/SelectionText. ModelName trong CSV ĐÚNG, không cần sửa. Chưa fix.

**Bug 4 — ClickApplyWithFallback() chờ quá ngắn sau khi click Apply**
- Triệu chứng: Strategy 1 click Apply thành công, dialog chuyển sang trạng thái "Please Wait"
  (app đang load jobfile). Nhưng code chỉ chờ 3 giây (`DIALOG_CLOSE_CHECK_MS = 3000`), thấy
  dialog vẫn mở → tưởng click thất bại → nhảy sang strategy tiếp. Thực tế chỉ cần chờ đủ lâu.
- Nguyên nhân: `DIALOG_CLOSE_CHECK_MS = 3000` quá ngắn. App load jobfile có thể mất 30-60 giây.
- FIX: Sau Strategy 1, poll dialog tối đa 60 giây (log mỗi 10 giây). Chỉ khi hết 60 giây mà
  dialog vẫn mở thì mới chuyển sang strategy tiếp.

### TỒN ĐỌNG
- BtnApplyProductionPresetting vẫn fallback sang Robust path (~30s/lần), chưa fail nhưng chậm.
- ClickApplyWithFallback() có 4 strategy nhưng CẢ 4 dùng cùng 1 element -> không phải dự phòng
  thật; chỉ Strategy 2 ăn. Nên thay bằng poll mỗi 1s, timeout 60-90s: (1) dialog mất -> Success;
  (2) Apply Visible+Enabled -> click ĐÚNG 1 phát; (3) chưa sẵn sàng -> chờ.
- Code DIAG (LogPopupAndApplyDiag) là code tạm, xóa sau.

### HÀNH VI DIALOG "Production Presetting" (xác minh tay)
Hiện ở trạng thái LOADING, lúc đó Apply KHÔNG nhận click.
(a) Chuyển sang tab Production: dialog TỰ biến mất, không cần Apply.
(b) Mở jobfile từ tab Production: BẮT BUỘC click Apply mới đóng.

---

## 6. QUY TAC

1. **LUON doc `.rxrep` TRUOC khi tham chieu accessor** — Da co loi dung sai `repo.InspectionRegionSettings.Apply` (item nay nam o `KohyoungGUI1`, khong phai `InspectionRegionSettings`). Accessor dung la `repo.InspectionRegionSettings.BtnApplyProductionPresetting`.

2. **CHI sua file `.UserCode.cs`** — Cac file `.cs` khong co hau to `.UserCode.cs` (tru `LoginRetry.cs`) la auto-generated boi Ranorex, se bi ghi de. KHONG sua `.rxrec`, `.rxrep`, `.rxtst`, `.csproj`.

3. **User la Manual SQA, khong biet C#** — Giai thich bang tieng Viet, don gian, tranh thuat ngu phuc tap. Khi de xuat fix, mo ta hanh vi mong muon truoc, code sau.

4. **Claude Code KHONG build duoc Ranorex** — MSBuild co the chay nhung Ranorex co cac dependency dac biet. Kiem tra syntax bang MSBuild neu can, nhung ket qua test phai chay tren Ranorex Studio (May B).

5. **Investigation truoc khi fix** — Workflow bat buoc: Investigation → Evidence (report) → Root Cause → Proposed Fix → Confirm → Implement. KHONG implement fix truoc khi chung minh root cause.

6. **KHONG hardcode** credentials, duong dan tuyet doi, hoac gia tri test data trong UserCode. Du lieu qua data binding (`this.VariableName`).

7. **Element "tim thay nhung not visible"** → kiem tra Use Cache cua folder cha TRUOC khi nghi code.

8. **Caption cua WPF element** co the tra ve automationid thay vi text hien thi. Xac minh bang Spy truoc khi dung `GetAttributeValueText`.

9. **Khong long form trong form.** Form Popup la cua so doc lap.

10. **2 may**: May A (Claude Code sua code) va may Ranorex (chinh repository + chay test). File `.rxrep` chi sua tren may Ranorex. Truoc khi doc/tham chieu `.rxrep`, phai dong bo ban moi nhat tu may Ranorex ve.

11. **Khi copy code tu may A sang may Ranorex**, KHONG de `.rxrep` va file `.cs` sinh tu no (vd `Lynn_DPI_ATRepository.cs`) — se mat cac thiet lap nhu Use Cache va path da sua.
