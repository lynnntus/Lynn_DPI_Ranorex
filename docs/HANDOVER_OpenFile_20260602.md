# HANDOVER SUMMARY — OpenFile Module Debug
**Ngay:** 2026-06-02
**Trang thai:** CHUA PASS — dang cho ket qua test voi approach moi (SetAttributeValue)

---

## 1. Project Info

| Item | Chi tiet |
|------|----------|
| Framework | Ranorex 10.7, .NET Framework 4.8, C# |
| Platform | x86 (32-bit) — bat buoc |
| AUT | Neptune DPI app (`C:\Kohyoung\AOI\AOIGUI.exe`) |
| IDE | Ranorex Studio, mo file `Lynn_DPI_AT.rxsln` |
| Build tool | MSBuild 2019 BuildTools, path: `C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe` |
| Build command | `msbuild Lynn_DPI_AT.csproj /p:Configuration=Debug /p:Platform=x86` |
| csproj path | `F:\RanorexProjects\Lynn_DPI_AT\Lynn_DPI_AT\Lynn_DPI_AT\Lynn_DPI_AT\Lynn_DPI_AT.csproj` |
| Module dang debug | **OpenFile** (mo file recipe trong Neptune) |

### Project structure (chi phan lien quan)

```
Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/
  OpenFile.rxrec                    # Recording definition (KHONG sua)
  OpenFile.cs                       # Auto-generated (KHONG sua)
  OpenFile.UserCode.cs              # Custom logic (FILE CHINH DANG SUA)
  Lynn_DPI_ATRepository.cs          # Auto-generated repo (KHONG sua)
  Lynn_DPI_ATRepository.rxrep       # Repository RxPath (KHONG sua)
```

---

## 2. Current Problem

### Trieu chung
1. **File name field trong Select Recipe File dialog chi chua "v" hoac "av"** thay vi full path
2. **Popup "file does not exist"** xuat hien sau khi click Open
3. **Report PASS** du file chua duoc mo thanh cong (false positive)
4. **Report warning**: "RecipeFilePath, ExpectedFileName are not bound to a data column"

### Ket qua test moi nhat (truoc fix cuoi cung)
- Report: `Lynn_DPI_AT_20260601_215635.rxlog`
- OpenFile PASS trong report nhung thuc te fail
- Field text = "v" (xac nhan bang Ranorex Spy)

---

## 3. Investigation History

### Gia thuyet DA LOAI BO

| # | Gia thuyet | Ly do loai bo |
|---|-----------|---------------|
| 1 | Ctrl+O van con trong code | Grep toan project: 0 match cho Ctrl+O active code. Chi con 2 dong commented out trong OpenFile.cs:116-117 |
| 2 | Binary cu chua rebuild | Binary timestamp (6/2 09:11) moi hon source (6/1 21:52). Ca Debug va Release da rebuild |
| 3 | `element.PressKeys("{Control down}{a}{Control up}")` hoat dong | **KHONG** — voi DefaultKeyPressTime=20ms, Ctrl chua register khi {a} duoc gui. Ket qua: go literal "a" |
| 4 | `Keyboard.Press("{LControlKey down}v{LControlKey up}")` hoat dong | **KHONG** — Spy xac nhan windowtext = "v" sau khi chay. Ctrl+V chi go literal "v" |
| 5 | R1 pattern `{Home}{Shift+End}{Delete}` co the clear field | Chua kiem chung tren control nay, nhung KHONG giai quyet van de paste |

### Nhung gi DA XAC NHAN dung

| # | Fact | Bang chung |
|---|------|-----------|
| 1 | Text1148 la `Ranorex.Text` adapter cho Win32 Edit control (controlid=1148) | Repository code: `new RepoItemInfo(this, "Text1148", "?/?/text[@controlid='1148']", ...)` |
| 2 | RxPath: `?/?/text[@controlid='1148']` duoi `/form[@title='Select Recipe File']` | Lynn_DPI_ATRepository.cs:857 |
| 3 | Spy xac nhan: `NativeWindow windowtext = 'v'` sau Keyboard.Press Ctrl+V | User bao cao tu Ranorex Spy |
| 4 | Moi cach dung keyboard (PressKeys, Keyboard.Press) deu fail tren control nay | Test thuc te tren may |
| 5 | Menu click flow (LeftMenuOpenToogleButton -> MenuOpenRecipe) hoat dong dung | Dialog xuat hien thanh cong moi lan |
| 6 | `repo.ButtonOpen` tro dung scope: `/form[@title='Select Recipe File']/button[@text='&Open']` | User xac nhan bang Ranorex Studio |
| 7 | RecipeFilePath dung default value vi chua bind CSV | Warning trong report + constructor hardcode trong OpenFile.cs:44 |
| 8 | Default path: `C:\Kohyoung\Job\Lynn_20260516_Stacking\Lynn_Stacking_Underfill.kyjob` | OpenFile.cs:44 |

---

## 4. Current Findings

### Root causes DA XAC NHAN

**RC1 — Keyboard input khong hoat dong tren Text1148:**
Moi cach gui phim tat (Ctrl+A, Ctrl+V) den control `text[@controlid='1148']` deu chi go literal character. Ca `element.PressKeys` lan `Keyboard.Press` voi modifier keys deu fail. Day la control dac thu cua Windows File Dialog.

**RC2 — Report false PASS:**
Code cu: `ButtonOpen.Click()` roi ngay `Report.Success` — khong verify dialog da dong, khong detect popup loi.

**RC3 — CSV binding chua cau hinh cho OpenFile:**
`RecipeFilePath` va `ExpectedFileName` chua bind data source. Dung default value tu constructor. Khong phai bug nhung can luu y khi can data-driven.

### Repository items lien quan

| Repo item | RxPath | Kieu | Dung de |
|-----------|--------|------|---------|
| `CCIMainWindow.Self` | `/form[@title='CCIMainWindow']` | Form | Cua so chinh Neptune |
| `CCIMainWindow.LeftMenuOpenToogleButton` | (trong repo) | Button | Nut menu trai |
| `CCIMainWindow.MenuOpenRecipe` | (trong repo) | MenuItem | Muc "Open Recipe" trong menu |
| `SelectRecipeFile.Self` | `/form[@title='Select Recipe File']` | Form | Dialog Open File |
| `SelectRecipeFile.Text1148` | `?/?/text[@controlid='1148']` | Text (Win32 Edit) | File name field |
| `ButtonOpen` | `/form[@title='Select Recipe File']/button[@text='&Open']` | Button | Nut Open trong dialog |
| `CCIMainWindow.SomeIndicator` | `indicator[1]` | Indicator | Chi bao file da load (dung trong recording step) |
| `CCIMainWindow.SomeText` | `...text[@caption='Lynn_Stacking_Underfill.kyjob']...` | Text | Validate ten file (da commented out, hardcode ten cu) |

---

## 5. Files Involved

### OpenFile.cs (auto-generated — KHONG SUA)

| Dong | Noi dung | Trang thai |
|------|----------|-----------|
| 44 | `RecipeFilePath = "C:\\Kohyoung\\Job\\Lynn_20260516_Stacking\\Lynn_Stacking_Underfill.kyjob"` | Default value |
| 45 | `ExpectedFileName = "Lynn_Stacking_Underfill.kyjob"` | Default value |
| 103 | `Keyboard.DefaultKeyPressTime = 20` | Thiet lap runtime — co the anh huong keyboard |
| 106 | `Init()` | Goi Init tren UserCode |
| 116-118 | `Keyboard.Press("{LControlKey down}o{LControlKey up}")` | **COMMENTED OUT** — Ctrl+O da xoa |
| 120 | `OpenRecipeFileByPath(RecipeFilePath)` | **ACTIVE** — goi method chinh |
| 145-146 | `SomeIndicatorInfo.WaitForExists(30000)` | **ACTIVE** — cho file load 30s sau khi method return |
| 152-153 | `Validate.Exists(SomeTextInfo)` | **COMMENTED OUT** — validation hardcode da tat |

### OpenFile.UserCode.cs (DANG SUA — version hien tai)

**Flow chinh (6 buoc):**
1. Buoc 1: Verify `CCIMainWindow` ton tai (10s)
2. Buoc 2: Activate `CCIMainWindow`
3. Buoc 3: Menu click `LeftMenuOpenToogleButton` -> `MenuOpenRecipe` -> Wait dialog (15s)
4. Buoc 4: `EnterPathIntoFileNameField(path)` — **DAY LA PHAN DANG FIX**
5. Buoc 5: Click `ButtonOpen`
6. Buoc 6: Verify dialog da dong (5s). Neu con mo -> Escape + throw exception

**Method `EnterPathIntoFileNameField` (approach hien tai — CHUA TEST):**
```csharp
// Approach: Set attribute truc tiep, khong dung keyboard
repo.SelectRecipeFile.Text1148.Element.SetAttributeValue("WindowText", path);
// Doc lai verify
string fieldText = ReadFileNameField();
// Neu khong khop -> fallback thu "Text" attribute
// Neu van fail -> throw exception, KHONG click Open
```

**Method `ReadFileNameField`:**
```csharp
// Thu TextValue truoc, fallback GetAttributeValueText("WindowText")
```

### OpenFile.rxrec
- Dinh nghia recording steps va module variables (RecipeFilePath, ExpectedFileName)
- KHONG SUA — Ranorex quan ly

### Lynn_DPI_ATRepository.rxrep
- Chua RxPath cho tat ca UI elements
- KHONG SUA — Ranorex quan ly
- Luu y: `SomeText` RxPath hardcode `Lynn_Stacking_Underfill.kyjob` (khong dung variable)

---

## 6. Latest Blocker

### Blocker chinh
**`SetAttributeValue("WindowText", path)` CHUA DUOC TEST.** Build PASS (Debug + Release, 6/2 09:30). Chua chay test thuc te tren Ranorex Studio.

### Cau hoi can tra loi bang test:
1. `SetAttributeValue("WindowText", path)` co thuc su set duoc text vao Win32 Edit control khong?
2. `ReadFileNameField()` (TextValue hoac GetAttributeValueText) co doc lai dung khong?
3. Sau khi set text + click Open, dialog co dong khong?
4. File co thuc su duoc mo trong Neptune khong?

### Neu SetAttributeValue FAIL:
Can thu cac approach khac:
- `Element.SetAttributeValue("Text", path)` (fallback da co trong code)
- `repo.SelectRecipeFile.Text1148.TextValue = path` (set property truc tiep)
- `SendMessage WM_SETTEXT` qua Win32 API (P/Invoke)
- Tim edit control cha (ComboBox chua Edit) va set text tren do

---

## 7. Open Questions

| # | Cau hoi | Tai sao quan trong |
|---|---------|-------------------|
| 1 | `SetAttributeValue("WindowText", ...)` co hoat dong tren Text1148 khong? | Day la approach hien tai, chua test |
| 2 | `ReadFileNameField()` tra ve gi? TextValue hay WindowText? | Can biet de verify dung |
| 3 | Tai sao keyboard modifiers (Ctrl+) khong hoat dong tren control nay? | Hieu ro de chon approach dung. Co the do DefaultKeyPressTime=20ms, hoac do control type |
| 4 | `SomeIndicator.WaitForExists(30000)` o OpenFile.cs:145-146 co PASS khi file mo thanh cong khong? | Neu SomeIndicator khong xuat hien du file mo thanh cong, recording step se throw sau 30s |
| 5 | `RecipeFilePath` default path `C:\Kohyoung\Job\...\Lynn_Stacking_Underfill.kyjob` co ton tai tren May B khong? | Neu file khong ton tai, `File.Exists` se throw truoc khi den dialog |
| 6 | Can bind CSV cho OpenFile module khong? | Hien dung default value. Neu can test nhieu file, phai cau hinh trong Ranorex Studio |

---

## 8. Recommended Next Actions

### Buoc 1 — Chay test voi code hien tai
Chay OpenFile trong Ranorex Studio. Doc report, tim cac log:
- `"Set WindowText truc tiep..."` — confirm method duoc goi
- `"Field text sau set: '...'"` — gia tri thuc te sau set
- `"Path set dung."` hoac `"WindowText khong khop..."` — thanh cong hay fail
- `"Buoc 6 OK"` hoac `"Buoc 6 THAT BAI"` — dialog dong hay con mo

### Buoc 2 — Neu SetAttributeValue FAIL
Kiem tra report log. Tuy theo ket qua:

| Log nhin thay | Y nghia | Action |
|--------------|---------|--------|
| `Field text sau set: ''` (rong) | SetAttributeValue khong co tac dung | Thu approach khac (xem Section 6) |
| `Field text sau set: '<path>'` nhung dialog van mo | Set OK nhung Open click fail | Kiem tra path co dung khong, kiem tra popup |
| Exception `Khong the set path...` | Ca WindowText lan Text deu fail | Can P/Invoke WM_SETTEXT hoac tim control khac |
| `Buoc 6 THAT BAI` | Path dung nhung file khong ton tai | Kiem tra file tren May B |

### Buoc 3 — Neu PASS
- Chay lai 2-3 lan de xac nhan on dinh
- Kiem tra SomeIndicator.WaitForExists co PASS khong (OpenFile.cs:145-146)
- Commit theo workflow build.md

### Luu y cho session moi
- Doc `CLAUDE.md` va tat ca rules truoc khi sua code
- Chi sua `*.UserCode.cs` — KHONG sua `.cs`, `.rxrec`, `.rxrep`, `.rxtst`, `.csproj`
- Build lenh: xem Section 1
- Lesson quan trong: xem `.claude/lessons/login-retry-lesson.md` (R1-R5)
- Keyboard trên control nay KHONG hoat dong — da xac nhan bang Spy
