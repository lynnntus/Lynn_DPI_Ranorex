# SESSION STARTER — OpenFile Module Debug (2026-06-03)

## Project
- Framework: Ranorex 10.7, .NET Framework 4.8, C#, Platform x86 (32-bit)
- AUT: Neptune DPI desktop app (`C:\Kohyoung\AOI\AOIGUI.exe`)
- Build: `MSBuild Lynn_DPI_AT.csproj /p:Configuration=Debug /p:Platform=x86`
- MSBuild: `C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe`
- csproj: `F:\RanorexProjects\Lynn_DPI_AT\Lynn_DPI_AT\Lynn_DPI_AT\Lynn_DPI_AT\Lynn_DPI_AT.csproj`
- Quy tac: Doc CLAUDE.md truoc khi lam bat cu dieu gi. Chi sua `*.UserCode.cs`.

## Knowledge Base
Doc `docs/OpenFile_KNOWLEDGE.md` de co toan bo facts, gia thuyet da loai bo, va rules.

## Trang thai hien tai

### Da fix (chua test thuc te)
- **Regression MenuOpenRecipe**: "Element is not visible in the UI" tai line 67.
  - Nguyen nhan: code moi bo warm-up, click MenuOpenRecipe qua som (500ms sau LeftMenuOpenToogleButton).
  - Fix: Them `WaitForMenuOpenRecipeClickable()` — polling max 50s, poll moi 400ms, kiem tra Exists + Visible + Enabled, EnsureVisible() truoc khi click.
  - Build PASS. Chua test thuc te. Chua commit.

### Bug goc (CHUA fix)
- **Text1148 input**: Chua co cach on dinh de nhap full `RecipeFilePath` vao o File name (Win32 Edit trong ComboBox).
- Approach da fail:
  1. Clipboard + Ctrl+V → go literal "v" (modifier keys khong hoat dong)
  2. Ctrl+A → go literal "a"
  3. `SetAttributeValue("WindowText", path)` → "The operation is not supported"

## Recommended Next Actions

### Buoc 1: Test regression fix
- Chay OpenFile trong Ranorex Studio.
- Doc report: tim log `"Poll #1..."`, `"MenuOpenRecipe san sang sau Xms"`, `"Buoc 3 OK"`.
- Neu Buoc 3 PASS → tiep tuc Buoc 2.
- Neu Buoc 3 FAIL → doc polling log de hieu tai sao.

### Buoc 2: Fix bug goc — nhap path vao Text1148
Thu theo thu tu uu tien:

| # | Approach | Mo ta |
|---|---|---|
| 1 | `TextValue = path` | Set property truc tiep qua Ranorex adapter |
| 2 | `PressKeys(fullPath)` | Go tung ky tu, khong modifier keys. Can escape `\` va `:` |
| 3 | `Keyboard.Press(fullPath)` | Go global, can focus dung element |
| 4 | `WM_SETTEXT` P/Invoke | Gui Win32 message truc tiep den control handle |

Truoc khi go: clear field bang triple-click hoac `{Home}{Shift+End}{Delete}`.

### Buoc 3: Bind CSV data source
- File CSV san sang: `TestData/OpenFileData.csv` (RecipeFilePath, ExpectedFileName).
- Can cau hinh connector + binding trong Ranorex Studio (`.rxtst`).

## Rules
- KHONG dung lai: Ctrl+A/Ctrl+V, SetAttributeValue("WindowText"), Report.Success khong verify.
- BAT BUOC: Verify field text truoc click Open. Verify dialog dong. Verify khong popup loi.
- Chi sua `*.UserCode.cs`. Khong commit/push khi chua duoc yeu cau.

## Files chinh
| File | Vai tro |
|---|---|
| `OpenFile.UserCode.cs` | Custom logic — file dang debug |
| `OpenFile.cs` | Auto-generated — KHONG sua |
| `docs/OpenFile_KNOWLEDGE.md` | Knowledge base day du |
