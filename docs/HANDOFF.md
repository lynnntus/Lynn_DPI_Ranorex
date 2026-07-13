# HANDOFF — Lynn_DPI_AT Session Context

> Tao boi Claude Code — 2026-07-13
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
    ├── Production_OpenFile
    │   ├── Production_OpenFile (smartfolder, datasource=Production_OpenFile)
    │   │   ├── ApplyBtn_On_Production
    │   │   └── OpenFile_FromProduction
    │   └── Apply_File_FromRecipe [DISABLED]
    └── Logout
        └── Logout module
```

### Data sources

| File CSV | Connector | Module | Cot |
|----------|-----------|--------|-----|
| `Users.csv` | `NewConnector` | `LoginRetry` | `UserName`, `Password` |
| `OpenFileData.csv` | `OpenFile` | `OpenFile` | `CaseId`, `Enabled`, `RecipeFilePath`, `ExpectedFileName`, `Model Name` |
| `Production_OpenFileData.csv` | `Production_OpenFile` | `ApplyBtn_On_Production`, `OpenFile_FromProduction` | `CaseId`, `Enabled`, `RecipeFilePath`, `ExpectedFileName`, `ModeName` |

---

## 2. REPOSITORY — Cau truc UI (tu Lynn_DPI_ATRepository.rxrep)

### Cac AppFolder va items chinh

| AppFolder | Base RxPath | Items |
|-----------|-------------|-------|
| `CCILoginWindow` | `/form[@name='View']` | `Login`, `XIDPWLoginArea`(`SomeText`, `TextXPW`, `XPWWatermark`) |
| `CCIMainWindow` | `/form[@title='CCIMainWindow']` | `CreateOrOpenRecipe`, `SomeButton`, `LeftMenuOpenToogleButton`, `SomeIndicator`, `Text`, `SomeIndicator1`, `SomeText`, `MenuOpenRecipe`, `SomeTable`, `Production`, `Area1`(`BtnMore`, `TopTextRecipeName`, `BtnOpenFileFromProduction`) |
| `InspectionRegionSettings` | `/form[@name='Popup']` | `BtnDualClose`, `ProductionStopsWhenAllLOTInspection`, `LOTProduction`, `Settings`, **`BtnApplyProductionPresetting`** |
| `SelectRecipeFile` | `/form[@title='Select Recipe File']` | `SystemItemNameDisplay`, `Text1148`, `TxtFileNameInDialog` |
| `KohyoungGUI1` | `/form[@processname='KohyoungGUI']` | `SomeText`, `SomeText1`, `Apply`, `TabProduction`, `Continue`, `HeaderTextBlock1`, `Settings`, `PARTContentHost`, `PARTContentHost1` |
| `Explorer` | `/desktop[@processname='explorer']` | `NEPTUNECALLINONE`, `ExportLynn` |
| Root level | — | `BtnOpenInDialog` → `/form[@title='Select Recipe File']/button[@text='&Open']` |

### CANH BAO: 2 nut Apply khac nhau

| Accessor | RxPath | Dung cho |
|----------|--------|----------|
| `repo.InspectionRegionSettings.BtnApplyProductionPresetting` | `/form[@name='Popup']//button[@text='Apply']` | Apply tren dialog Production Presetting |
| `repo.KohyoungGUI1.Apply` | `/form[@processname='KohyoungGUI']/container[@caption='']/button[@text='Apply']` | Apply tren main window (khac!) |

> **KHONG duoc nham lan 2 nut nay.** Truoc khi dung accessor, LUON doc `.rxrep` de xac nhan.

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

### ApplyBtn_On_Production.UserCode.cs

| Method | Mo ta |
|--------|-------|
| `Init()` | Log "Module bat dau" |
| `ClickApplyWithPolling()` | Polling loop: kiem tra dialog `/form[@name='Popup']` moi 1s, toi da 10s. Neu dialog tu dong → return. Neu con → goi `ClickApplyWithFallback()` |
| `ClickApplyWithFallback()` | 4 strategy click Apply: (1) Native WPF Click, (2) Focus+Space, (3) UIA Exists+Click, (4) Coordinate click via ScreenRectangle. Moi strategy check dialog dong chua. Throw exception neu tat ca fail |

Constants: `DIALOG_POLL_INTERVAL_MS=1000`, `DIALOG_POLL_TIMEOUT_MS=10000`, `DIALOG_CLOSE_CHECK_MS=3000`

### OpenFile_FromProduction.UserCode.cs

| Method | Mo ta |
|--------|-------|
| `Init()` | Log `Enable`, `RecipeFilePath`, `ModelName` |
| `OpenRecipeFileByPath()` | Flow 7 buoc: check Enable → click BtnOpenFileFromProduction → cho dialog → nhap path → click Open → click Apply (fallback) → validate TopModelName |
| `EnterPathIntoFileNameField(path)` | Set `TextValue`, verify match |
| `ReadFileNameField()` | Try `TextValue` → fallback `WindowText` |
| `ValidateTopModelName()` | Poll `TopTextRecipeName.Caption` contains `ModelName`, max 60s |
| `ClickApplyWithFallback()` | 4 strategy (giong ApplyBtn_On_Production) |
| `CleanupDialog()` | Escape → Close dialog neu con mo |

Constants: `FILE_DIALOG_TIMEOUT_MS=15000`, `APPLY_PRESETTING_TIMEOUT_MS=15000`, `TOP_VALIDATE_TIMEOUT_MS=60000`, `TOP_VALIDATE_POLL_MS=2000`

### Apply_File_FromRecipe.UserCode.cs

| Method | Mo ta |
|--------|-------|
| `Init()` | Trong (stub) |

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
| Production_OpenFile | ApplyBtn_On_Production → OpenFile_FromProduction | `Production_OpenFileData.csv` | Open recipe tu Production tab |
| Logout | Logout | — | Logout cuoi cung |

### Luu y quan trong

- `Login_Pass` va `Logout` trong SmokeTest deu **DISABLED**
- `Apply_File_FromRecipe` trong Production_OpenFile **DISABLED**
- `AppProcessID` truyen tu `StartAUT` → `CloseAUT` qua test case parameter — neu them test case moi can bind lai
- Tat ca search timeout trong repository: 30,000ms (30 giay)

---

## 5. VAN DE DANG XU LY

### Production Presetting dialog — trang thai loading

**Boi canh:**
Dialog "Production Presetting" (`/form[@name='Popup']`) xuat hien khi:
1. User chuyen tab sang Production (lan dau) → dialog **tu dong dong** sau vai giay
2. User click "Open File from Production" → dialog **can click Apply** de confirm

**Bug hien tai:**
Module `ApplyBtn_On_Production` poll 10s cho dialog tu dong. Nhung:
- Timeout 10s co the khong du cho truong hop loading lau
- Chua kiem tra Apply button co **Visible + Enabled** truoc khi click
- Nen co the click vao Apply khi button chua san sang (greyed out)

**Huong fix da thong nhat:**
- Tang timeout len 60–90 giay
- Moi vong poll (1s) kiem tra 3 dieu kien:
  1. Dialog da dong? → thanh cong, return
  2. Apply button Visible + Enabled? → click 1 lan
  3. Chua san sang? → cho tiep

**Van de chua xac minh:**
- `/form[@name='Popup']` co the match NHIEU WPF window (tooltip, dropdown cung dung ten 'Popup')
- Can log **so luong** `form[@name='Popup']` matches de xac nhan
- Neu luon >= 1 match (vi tooltip/system popup), polling se KHONG BAO GIO thay "dialog dong"
- Can investigate them truoc khi fix

---

## 6. QUY TAC

1. **LUON doc `.rxrep` TRUOC khi tham chieu accessor** — Da co loi dung sai `repo.InspectionRegionSettings.Apply` (item nay nam o `KohyoungGUI1`, khong phai `InspectionRegionSettings`). Accessor dung la `repo.InspectionRegionSettings.BtnApplyProductionPresetting`.

2. **CHI sua file `.UserCode.cs`** — Cac file `.cs` khong co hau to `.UserCode.cs` (tru `LoginRetry.cs`) la auto-generated boi Ranorex, se bi ghi de. KHONG sua `.rxrec`, `.rxrep`, `.rxtst`, `.csproj`.

3. **User la Manual SQA, khong biet C#** — Giai thich bang tieng Viet, don gian, tranh thuat ngu phuc tap. Khi de xuat fix, mo ta hanh vi mong muon truoc, code sau.

4. **Claude Code KHONG build duoc Ranorex** — MSBuild co the chay nhung Ranorex co cac dependency dac biet. Kiem tra syntax bang MSBuild neu can, nhung ket qua test phai chay tren Ranorex Studio (May B).

5. **Investigation truoc khi fix** — Workflow bat buoc: Investigation → Evidence (report) → Root Cause → Proposed Fix → Confirm → Implement. KHONG implement fix truoc khi chung minh root cause.

6. **KHONG hardcode** credentials, duong dan tuyet doi, hoac gia tri test data trong UserCode. Du lieu qua data binding (`this.VariableName`).
