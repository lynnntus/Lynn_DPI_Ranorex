# 02. Phân tích cấu trúc Project Lynn_DPI_AT

> Tài liệu nghiên cứu nội bộ — Lynn_DPI_AT Project  
> Ngày: 2026-05-26

---

## 1. Directory Tree

```
Lynn_DPI_AT/                              (Git root)
├── CLAUDE.md                             # Quy tắc cho AI assistant
├── Lynn_DPI_AT.sln                       # Visual Studio solution
├── Ranorex.rxsettings                    # Global Ranorex settings
├── TestData/
│   └── Users.csv                         # Test credentials (2 rows)
│
├── .claude/                              # AI documentation
│   ├── context/                          # project.md, modules.md, repository.md
│   ├── lessons/                          # login-retry-lesson.md
│   ├── rules/                            # safety.md, coding.md, testing.md, data_binding.md
│   └── workflows/                        # build.md, test-run.md, handoff.md
│
├── docs/                                 # Research documentation
│   └── ranorex-research/                 # ← Thư mục này
│
└── Lynn_DPI_AT/Lynn_DPI_AT/              (Project root)
    ├── Lynn_DPI_AT.csproj                # MSBuild project
    ├── Lynn_DPI_AT.rxtst                 # Test suite definition
    ├── Lynn_DPI_AT.rxtmg                 # Test management data
    ├── app.config                        # .NET runtime config
    ├── Ranorex.rxsettings                # Project-level Ranorex config
    ├── Program.cs                        # Entry point
    ├── AssemblyInfo.cs                    # Assembly metadata
    │
    ├── RECORDING MODULES (5 modules × 3 files)
    ├── StartAUT.rxrec / .cs / .UserCode.cs
    ├── Login_Pass.rxrec / .cs / .UserCode.cs
    ├── Recording1.rxrec / .cs / .UserCode.cs
    ├── Logout.rxrec / .cs / .UserCode.cs
    ├── CloseAUT.rxrec / .cs / .UserCode.cs
    │
    ├── CUSTOM MODULE
    ├── LoginRetry.cs                     # UserCode module (hand-written)
    │
    ├── REPOSITORY
    ├── Lynn_DPI_ATRepository.rxrep       # UI element mapping
    ├── Lynn_DPI_ATRepository.cs          # Auto-generated repository code
    ├── Lynn_DPI_ATRepository.rximg       # Repository image cache
    │
    ├── DATA FILES
    ├── Users_DataSource.csv              # CSV connector (header only!)
    ├── TestData.csv                      # Test data (2 rows)
    │
    ├── bin/Debug/                        # Compiled output
    └── obj/x86/Debug/                    # Build artifacts
```

---

## 2. Phân loại file

### 2.1 File AUTO-GENERATED (KHÔNG sửa)

| File | Nguồn | Lý do không sửa |
|------|-------|-----------------|
| `StartAUT.cs` | `StartAUT.rxrec` | Ranorex tự sinh lại khi re-record |
| `Login_Pass.cs` | `Login_Pass.rxrec` | Ranorex tự sinh lại khi re-record |
| `Recording1.cs` | `Recording1.rxrec` | Ranorex tự sinh lại khi re-record |
| `Logout.cs` | `Logout.rxrec` | Ranorex tự sinh lại khi re-record |
| `CloseAUT.cs` | `CloseAUT.rxrec` | Ranorex tự sinh lại khi re-record |
| `Lynn_DPI_ATRepository.cs` | `.rxrep` | Ranorex tự sinh lại khi cập nhật repository |
| `AssemblyInfo.cs` | IDE | Assembly metadata |

### 2.2 File SAFE TO EDIT

| File | Loại | Mục đích |
|------|------|----------|
| `StartAUT.UserCode.cs` | UserCode | Custom logic khởi động app (hiện trống) |
| `Login_Pass.UserCode.cs` | UserCode | Login logic: TryLoginWithUser, IsLoginSuccessful, TypeIntoUserField... |
| `Recording1.UserCode.cs` | UserCode | Main test logic (hiện trống) |
| `Logout.UserCode.cs` | UserCode | Logout logic (hiện trống) |
| `CloseAUT.UserCode.cs` | UserCode | Close app logic (hiện trống) |
| `LoginRetry.cs` | Custom module | Retry login qua CSV rows |
| `Program.cs` | Entry point | Test suite runner |

### 2.3 File KHÔNG sửa trực tiếp (dùng Ranorex Studio)

| File | Extension | Lý do |
|------|-----------|-------|
| `Lynn_DPI_AT.rxtst` | `.rxtst` | Test suite config — quản lý qua Ranorex Studio |
| `*.rxrec` | `.rxrec` | Recording definition — binary format |
| `Lynn_DPI_ATRepository.rxrep` | `.rxrep` | Repository — quản lý qua Ranorex Studio |
| `Lynn_DPI_ATRepository.rximg` | `.rximg` | Image cache — binary format |
| `Lynn_DPI_AT.csproj` | `.csproj` | Project file — Ranorex quản lý |

### 2.4 File config/data

| File | Mục đích | Sửa khi nào |
|------|----------|-------------|
| `app.config` | .NET runtime config | Hiếm khi cần sửa |
| `Ranorex.rxsettings` | Timeout, keyboard/mouse defaults | Khi cần thay đổi global timeout |
| `Users_DataSource.csv` | CSV data connector | Khi cần thêm/sửa test credentials |
| `TestData.csv` | Test data backup | Reference only |

---

## 3. Chi tiết từng extension

| Extension | Mô tả | Format | Sửa bằng |
|-----------|--------|--------|----------|
| `.rxtst` | Test suite definition — hierarchy, data binding, execution order | XML | Ranorex Studio |
| `.rxrec` | Recording definition — recorded UI actions | Binary | Ranorex Recorder |
| `.UserCode.cs` | Custom code — partial class extension | C# | Text editor / IDE |
| `.cs` (generated) | Auto-generated code từ recording | C# | KHÔNG SỬA |
| `.rxrep` | Repository — UI element mapping, RxPath | XML/Binary | Ranorex Studio |
| `.rximg` | Repository image cache | Binary | KHÔNG SỬA |
| `.csproj` | MSBuild project file | XML | Ranorex Studio |
| `app.config` | .NET Framework config | XML | Text editor |
| `.rxsettings` | Ranorex global settings | XML | Ranorex Studio / text editor |

---

## 4. Repository Structure

```
Lynn_DPI_ATRepository
│
├── CCILoginWindow                    /form[@name='View']
│   ├── Self (Form)                   Login window
│   ├── Login (Text)                  button[@automationid='xLoginButton']/text[@caption='Login']
│   └── XIDPWLoginArea (Container)    container[@automationid='xIDPWLoginArea']
│       ├── SomeText (Text)           text[@caption='']          ← Username field
│       ├── TextXPW (Text)            text[@automationid='xPW']  ← Password field (gần input)
│       └── XPWWatermark (Text)       text[@automationid='xPWWatermark'] ← Placeholder
│
├── CCIMainWindow                     /form[@title='CCIMainWindow']
│   ├── Self (Form)                   Main application window
│   ├── CreateOrOpenRecipe            Validation target: "Create or open recipe."
│   └── SomeButton                    Menu/action button
│
├── InspectionRegionSettings          /form[@name='Popup']
│   └── BtnDualClose                  Close button
│
├── LynnDPIAT                        /form[@title='Lynn_DPI_AT']
│   └── (Ranorex runtime window)
│
└── Explorer                          /desktop[@processname='explorer']
    └── ExportLynn                    Validation: "Export_Lynn"
```

**Timeout mặc định:** 30,000ms (30 giây) cho tất cả elements.

---

## 5. Test Suite Hierarchy

```
TestSuite: Lynn_DPI_AT
│
└── TestCase: Lynn_DPI_AT
    │
    ├── TestCase: TestCase
    │   ├── Setup
    │   │   └── StartAUT (Recording)         ← Launch AOIGUI.exe
    │   │
    │   ├── Recording1 (Recording)           ← TRỐNG, chưa có test action
    │   │
    │   └── Teardown
    │       └── CloseAUT (Recording)         ← Close app by ProcessID
    │
    ├── TestCase: SmokeTest
    │   ├── StartAUT (Recording)
    │   │
    │   ├── SmartFolder: Users               ← Data-driven (CSV, 2 rows)
    │   │   └── LoginRetry (UserCode)        ← Retry login × CSV rows
    │   │
    │   ├── Login_Pass (Recording)           ← ⚠️ Missing data binding
    │   │
    │   └── Logout (Recording)               ← DISABLED (enabled="False")
    │
    └── TestCase: Logout
        └── Logout (Recording)
```

### Data Binding

| Module | Data Source | Columns | Status |
|--------|-----------|---------|--------|
| LoginRetry | NewConnector (CSV) | UserName, Password | ✅ Bound |
| Login_Pass | NewConnector (CSV) | UserName, Password | ❌ Missing binding |
| StartAUT | — | AppProcessID (output) | ✅ Parameter |
| CloseAUT | — | AppProcessID (input) | ✅ Bound from StartAUT |

---

## 6. Module Analysis

### Modules có custom logic

| Module | File UserCode | Methods chính | Trạng thái |
|--------|--------------|---------------|------------|
| Login_Pass | `Login_Pass.UserCode.cs` | `Init()`, `TryLoginWithUser()`, `TypeIntoUserField()`, `TypeIntoPasswordField()`, `IsLoginSuccessful()`, `ClearLoginFields()` | Active, đã sửa nhiều lần |
| LoginRetry | `LoginRetry.cs` | `Run()` | Active, retry logic hoàn chỉnh |

### Modules trống (chỉ có Init() rỗng)

| Module | File UserCode | Ghi chú |
|--------|--------------|---------|
| StartAUT | `StartAUT.UserCode.cs` | Chỉ launch app, không cần custom logic |
| Recording1 | `Recording1.UserCode.cs` | **Cần implement** — nơi đặt test logic chính |
| Logout | `Logout.UserCode.cs` | Click + validate, chưa cần custom logic |
| CloseAUT | `CloseAUT.UserCode.cs` | Close by ProcessID, không cần custom logic |

---

## 7. Vấn đề hiện tại trong cấu trúc

| # | Vấn đề | Evidence | Impact |
|---|--------|----------|--------|
| 1 | `Users_DataSource.csv` chỉ có header, không có data | File content: `UserName,Password` (1 line) | Data binding không có data rows |
| 2 | Login_Pass có `missingdatabinding` | `.rxtst` XML: `<missingdatabinding>` tag | Variables dùng default values |
| 3 | Recording1 trống | `Recording1.cs`: chỉ có empty `Init()` | Chưa có test action chính |
| 4 | CSV path trong `.rxtst` là absolute | `D:\RanorexProjects\...` | Chỉ chạy trên máy có đúng path |
| 5 | Logout disabled trong SmokeTest | `enabled="False"` trong `.rxtst` | SmokeTest không test logout |

---

## 8. Tham khảo thêm

- Xem [.claude/context/project.md](../../.claude/context/project.md) cho tổng quan project
- Xem [.claude/context/modules.md](../../.claude/context/modules.md) cho chi tiết từng module
- Xem [.claude/context/repository.md](../../.claude/context/repository.md) cho UI repository
