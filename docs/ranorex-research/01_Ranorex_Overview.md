# 01. Tổng quan Ranorex

> Tài liệu nghiên cứu nội bộ — Lynn_DPI_AT Project  
> Ngày: 2026-05-26

---

## 1. Ranorex là gì?

Ranorex Studio là công cụ automation testing cho desktop, web, và mobile. Trong project Lynn_DPI_AT, Ranorex được dùng để tự động hóa kiểm thử ứng dụng desktop **Neptune DPI** (KohYoung AOI system) — một ứng dụng WPF chạy trên Windows.

**Version đang dùng:** Ranorex 10.7  
**Runtime:** .NET Framework 4.8  
**Platform:** x86 (32-bit, bắt buộc)

---

## 2. Kiến trúc 4 thành phần chính

```
┌─────────────────────────────────────────────────────────┐
│                      Test Suite (.rxtst)                │
│  Định nghĩa thứ tự chạy, data binding, setup/teardown  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────┐    ┌──────────────────────────┐   │
│  │ Recording Module │    │     Repository (.rxrep)  │   │
│  │    (.rxrec)       │───▶│  UI element mapping      │   │
│  │ Ghi lại thao tác │    │  RxPath selectors         │   │
│  └────────┬─────────┘    └──────────────────────────┘   │
│           │                                              │
│  ┌────────▼─────────┐                                    │
│  │   UserCode        │                                    │
│  │ (.UserCode.cs)    │                                    │
│  │ Custom logic      │                                    │
│  └──────────────────┘                                    │
└─────────────────────────────────────────────────────────┘
```

### 2.1 Test Suite (`.rxtst`)
- File XML định nghĩa cấu trúc test
- Chứa: test case hierarchy, data binding configuration, execution order
- Quản lý: setup/teardown, Smart Folder (data-driven iteration), module ordering
- **KHÔNG sửa trực tiếp** — dùng Ranorex Studio

### 2.2 Recording Module (`.rxrec` + `.cs`)
- Ghi lại thao tác UI (click, type, validate)
- Mỗi recording tạo ra 3 file:
  - `.rxrec` — binary recording definition
  - `.cs` — auto-generated C# code (DO NOT EDIT)
  - `.UserCode.cs` — custom code (SAFE TO EDIT)
- Recording chạy qua method `ITestModule.Run()` trong file `.cs`

### 2.3 Repository (`.rxrep`)
- Centralized mapping của UI elements
- Mỗi element có: logical name + RxPath selector + timeout
- Truy cập qua singleton: `Lynn_DPI_ATRepository.Instance`
- Tạo ra: `.rxrep` (definition) + `.cs` (generated code) + `.rximg` (screenshots)

### 2.4 UserCode (`.UserCode.cs`)
- Partial class extension của recording module
- Entry points: `Init()` (trước recording), `Finish()` (sau recording)
- Nơi duy nhất để thêm custom logic
- Truy cập module variables qua `this.VariableName`

---

## 3. Flow thực thi

```
Program.Main()
    │
    ▼
TestSuiteRunner.Run(typeof(Program), args)
    │
    ▼
Test Suite loads .rxtst
    │
    ├── Setup region
    │   └── StartAUT module → Launch AOIGUI.exe
    │
    ├── Test Case(s)
    │   ├── Module 1: LoginRetry (UserCode) × N CSV rows
    │   ├── Module 2: Login_Pass (Recording)
    │   ├── Module 3: Recording1 (Recording)
    │   └── Module 4: Logout (Recording)
    │
    └── Teardown region
        └── CloseAUT module → Close application
```

**Thứ tự trong mỗi module:**
1. Constructor (set default values)
2. `Init()` (UserCode — custom initialization)
3. Recording steps (auto-generated `Run()`)
4. `Finish()` (UserCode — cleanup, nếu có)

---

## 4. Partial Class Pattern

Đây là pattern quan trọng nhất cần hiểu khi làm việc với Ranorex:

```csharp
// Login_Pass.cs — AUTO-GENERATED, KHÔNG SỬA
// Ranorex tự sinh lại mỗi khi record
public partial class Login_Pass : ITestModule
{
    void ITestModule.Run()
    {
        Init();  // ← gọi UserCode
        // ... recording steps (auto-generated)
        repo.CCILoginWindow.XIDPWLoginArea.SomeText.Click("47;2");
        Keyboard.Press(UserName);
        // ...
    }
}

// Login_Pass.UserCode.cs — SAFE TO EDIT
// Custom logic đặt ở đây
public partial class Login_Pass
{
    private void Init()
    {
        // Custom initialization
        // Chạy TRƯỚC recording steps
        // KHÔNG THỂ ngăn recording steps chạy
    }
}
```

**Quy tắc quan trọng:**
- Cả hai file khai báo cùng 1 class (`partial class Login_Pass`)
- `Init()` chạy trước, nhưng KHÔNG THỂ skip recording steps
- Nếu cần logic hoàn toàn custom → tạo module `ModuleType.UserCode` riêng (như `LoginRetry.cs`)

---

## 5. Các khái niệm quan trọng

### 5.1 Module Variables
- Khai báo trong `.rxrec`, inject vào class tự động
- Truy cập trong UserCode: `this.UserName`, `this.Password`
- **KHÔNG** tự đọc file CSV — Ranorex tự inject giá trị

### 5.2 Data Binding
- CSV/Excel data source → bind vào module variables
- Mỗi row = 1 lần chạy module
- Cấu hình trong `.rxtst` qua Ranorex Studio
- Smart Folder = container cho data-driven iterations

### 5.3 RxPath (RanoreXPath)
- Ngôn ngữ selector cho UI elements (tương tự XPath)
- Ví dụ: `/form[@name='View']/?/?/button[@automationid='xLoginButton']`
- Operators: `@` (attribute), `~` (regex), `>` (starts with), `?` (any child)

### 5.4 Report Levels
| Level | Giá trị | Dùng khi |
|-------|---------|----------|
| Debug | 10 | Thông tin chi tiết cho developer |
| Info | 20 | Bước thực hiện bình thường |
| Warning | 50 | Đáng chú ý nhưng không critical |
| Success | 110 | Validation thành công |
| Failure | 120 | Validation thất bại |

### 5.5 Repository Timeout
- Mỗi element có timeout riêng (default: 30,000ms trong project này)
- **Timeout cascading:** Nếu element nằm trong rooted folder, timeout cộng dồn
  - Element timeout (30s) + Folder timeout (30s) = 60s effective
- Cấu hình global trong `Ranorex.rxsettings`

---

## 6. Sự khác biệt: Recording Module vs UserCode Module

| Đặc điểm | Recording Module | UserCode Module |
|-----------|-----------------|-----------------|
| Tạo bởi | Ranorex Recorder | Developer viết tay |
| Files | `.rxrec` + `.cs` + `.UserCode.cs` | Chỉ 1 file `.cs` |
| Attribute | `ModuleType.Recording` | `ModuleType.UserCode` |
| Entry point | `Init()` + auto `Run()` | Developer viết `Run()` |
| Ví dụ | `Login_Pass`, `Logout` | `LoginRetry` |
| Khi nào dùng | Thao tác UI đơn giản, record được | Logic phức tạp, cần kiểm soát hoàn toàn |

---

## 7. Tham khảo

- [Ranorex Test Suite & Module Overview](https://www.softwaretestinghelp.com/ranorex-tutorial-2/)
- [Mastering User Code in Ranorex Studio](https://www.ranorex.com/blog/mastering-user-code/)
- [User Code Actions](https://support.ranorex.com/hc/en-us/articles/38079929039633-User-code-actions/)
- [Execute a Test Suite](https://support.ranorex.com/hc/en-us/articles/38079820116625-Execute-a-Test-Suite)
