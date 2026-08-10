# Lynn_DPI_AT - Ranorex Automation Test

Automation test cho ung dung desktop Neptune (KohYoung DPI).

## Project Overview

- **Framework**: Ranorex 10.7, .NET Framework 4.8, C#
- **Platform**: x86 (32-bit) — bat buoc, khong doi sang x64
- **AUT**: `C:\Kohyoung\AOI\AOIGUI.exe` (Neptune DPI)
- **IDE**: Ranorex Studio (mo file `Lynn_DPI_AT.rxsln`)
- **Data source**: CSV + CsvDataConnector (cau hinh trong Ranorex Studio)

### Cau truc thu muc

```
Lynn_DPI_AT/                          # Git root
├── CLAUDE.md
├── TestData/                         # CSV data files
│   ├── OpenFileData.csv
│   └── Users.csv
├── docs/                             # Tai lieu, lessons, handover
└── Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/   # Thu muc code C#
    ├── Lynn_DPI_AT.csproj
    ├── Lynn_DPI_AT.rxtst             # Test suite config
    ├── Lynn_DPI_ATRepository.rxrep   # Repository (RxPath selectors)
    ├── *.rxrec                       # Recording definitions
    ├── *.cs                          # Auto-generated code
    ├── *.UserCode.cs                 # Custom logic (CHI SUA FILE NAY)
    └── Users_DataSource.csv
```

> **Luu y**: Duong dan code la `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/` (3 cap).
> Khi tham chieu file, luon dung duong dan day du tu git root.

### Module flow

```
StartAUT → Login_Pass → OpenFile → Recording1 → Logout → CloseAUT
```

## Commands

**Build (kiem tra compile — chay tren May A):**
```powershell
& "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe" `
  Lynn_DPI_AT\Lynn_DPI_AT\Lynn_DPI_AT\Lynn_DPI_AT.csproj `
  /p:Configuration=Debug /p:Platform=x86
```

**Chay test**: Mo `Lynn_DPI_AT.rxsln` trong Ranorex Studio tren May B → chon test case → Run.

**Khong co CI/CD** — deploy thu cong qua Git push/pull giua May A (code) va May B (test).

## ⛔ File Safety — Doc truoc khi lam bat cu dieu gi

### File duoc phep sua

| Pattern | Ghi chu |
|---------|---------|
| `*.UserCode.cs` | Custom logic cua tung recording module |
| File `.cs` do Claude Code tu tao | LoginRetry.cs va cac file moi |
| `.claude/**/*.md` | Rule files, lessons, context |
| `docs/**/*.md` | Tai lieu du an |

### File KHONG duoc sua

| Loai | Vi du |
|------|-------|
| Recording class | `StartAUT.cs`, `Login_Pass.cs`, `OpenFile.cs`, `Logout.cs`, `Recording1.cs`, `CloseAUT.cs` |
| Repository | `Lynn_DPI_ATRepository.cs`, `Lynn_DPI_ATRepository.rxrep` |
| Extension cam | `.rxrec`, `.rxrep`, `.rxtst`, `.csproj`, `.rximg` |

> Cac file nay do Ranorex auto-generate. Moi chinh sua se bi ghi de.

## Coding Conventions

### Pattern bat buoc: doc module variable tu Ranorex data binding

```csharp
// ✅ DUNG — Ranorex inject qua data binding
string value = this.VariableName;

// ❌ SAI — tu doc file / hardcode
string value = File.ReadAllLines("data.csv")[0];
string value = "hardcoded_value";
string path  = @"D:\RanorexProjects\...";
```

### Entry point hop le trong UserCode

- `Init()` — chay truoc recording steps. Dung cho setup, log, check dieu kien.
- `Finish()` — chay sau recording steps. Dung cho cleanup.
- **KHONG** tao `Main()` hay entry point nao khac.
- `Init()` **khong the skip** recording steps (Ranorex limitation).

### Static vs Instance

- **Instance method** (khong co `static`): khi can `this.VariableName` hoac `repo.*` — pho bien nhat.
- **Static method**: chi khi method hoan toan khong can `this`.
- Loi thuong gap: khai bao `static` roi khong truy cap duoc module variable.

### Dynamic RxPath — khi value phu thuoc TestData

Khi Repository item hard-code value (vd: `@caption='Lynn_Stacking_Underfill'`),
dung dynamic RxPath trong UserCode thay vi sua `.rxrep`:

```csharp
string rxPath = string.Format(
    "/form[@title='CCIMainWindow']//text[@caption='{0}']", this.ModelName);
var element = Host.Local.FindSingle<Ranorex.Text>(rxPath, timeoutMs);
```

Xem chi tiet: [docs/lessons/openfile-dynamic-rxpath-lesson.md](docs/lessons/openfile-dynamic-rxpath-lesson.md)

## Known Gotchas

1. **Triple-nested directory** — Code nam o `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/`. Claude thuong tro sai cap thu muc.

2. **Init() khong skip recording steps** — `Init()` chay TRUOC nhung khong ngan recording steps chay. Chi co the them logic bo sung, khong the thay the flow.

3. **WPF ComboBox input** — `{Ctrl+A}` bi WPF intercept. Dung `{Home}{Shift+End}{Delete}` de clear field.

4. **Repository hard-code caption** — Mot so items (SomeText, SomeIndicator) hard-code `@caption` cu the. Chi match 1 recipe. Dung dynamic RxPath trong UserCode khi can match nhieu values.

5. **Timeout khong phai root cause** — Khi `Exists()` = False nhung UI hien thi dung, van de la selector sai, khong phai timeout ngan. Khong tang timeout de che loi.

6. **SomeText value nam o PARENT** — `SomeText` (child) co `Caption = ''`. Actual value nam o `SomeText.Element.Parent.Caption` (ANCESTOR_L1).

7. **Investigation truoc khi fix** — Workflow bat buoc: Investigation → Evidence (report) → Root Cause → Proposed Fix → Confirm → Implement.

## Do Not

- **Khong sua** `.rxrec`, `.rxrep`, `.rxtst`, `.csproj` — Ranorex auto-generate, se ghi de.
- **Khong sua** cac file `.cs` khong co hau to `.UserCode.cs` (tru LoginRetry.cs).
- **Khong hardcode** credentials, duong dan tuyet doi, hoac gia tri test data trong UserCode.
- **Khong tang timeout** de che selector sai hoac timing issue chua hieu.
- **Khong xoa** `using Ranorex.*` namespaces — bat buoc cho Ranorex framework.
- **Khong implement** fix truoc khi chung minh root cause bang evidence tu report.
- **Khong refactor lon**, doi architecture, hoac sua repository hang loat.
- **Khong commit/push** khi chua duoc user xac nhan.

## Reference (doc khi can)

### Quy tac
| File | Noi dung |
|------|----------|
| [.claude/rules/safety.md](.claude/rules/safety.md) | Canh bao day du, vi du sai/dung |
| [.claude/rules/coding.md](.claude/rules/coding.md) | Partial class, static vs instance, pham vi sua doi |
| [.claude/rules/testing.md](.claude/rules/testing.md) | Data source CSV, luu y phat trien them |
| [.claude/rules/data_binding.md](.claude/rules/data_binding.md) | CsvDataConnector, them CSV moi, kiem tra binding |

### Bai hoc
| File | Noi dung |
|------|----------|
| [.claude/lessons/login-retry-lesson.md](.claude/lessons/login-retry-lesson.md) | Debug login: WPF input, call chain, Init() limitations |
| [docs/lessons/openfile-dynamic-rxpath-lesson.md](docs/lessons/openfile-dynamic-rxpath-lesson.md) | Dynamic RxPath: hard-code selector, investigation flow |

### Workflow
| File | Noi dung |
|------|----------|
| [.claude/workflows/build.md](.claude/workflows/build.md) | MSBuild, chay exe, mo Ranorex Studio |
| [.claude/workflows/test-run.md](.claude/workflows/test-run.md) | Cau truc test suite, SmokeTest, TestCase |
| [.claude/workflows/handoff.md](.claude/workflows/handoff.md) | Chuyen giao May Test, checklist |

### Context du an
| File | Noi dung |
|------|----------|
| [.claude/context/project.md](.claude/context/project.md) | Tong quan, framework, cau truc thu muc |
| [.claude/context/modules.md](.claude/context/modules.md) | Danh sach va chi tiet cac module |
| [.claude/context/repository.md](.claude/context/repository.md) | UI Repository, cau hinh Ranorex.rxsettings |

### Investigation & Knowledge
| File | Noi dung |
|------|----------|
| [docs/OpenFile_KNOWLEDGE.md](docs/OpenFile_KNOWLEDGE.md) | Knowledge base OpenFile — facts da chung minh |
| [docs/HANDOVER_DynamicRxPath_TimingInvestigation.md](docs/HANDOVER_DynamicRxPath_TimingInvestigation.md) | Handover: timing investigation |
