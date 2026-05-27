# 03. UserCode Best Practices

> Tài liệu nghiên cứu nội bộ — Lynn_DPI_AT Project  
> Ngày: 2026-05-26

---

## 1. Nguyên tắc cơ bản

### 1.1 Chỉ sửa file `*.UserCode.cs`

```
Module.cs           ← AUTO-GENERATED, KHÔNG SỬA
Module.UserCode.cs  ← CUSTOM CODE, AN TOÀN ĐỂ SỬA
```

Mọi chỉnh sửa trong `.cs` auto-generated sẽ bị **ghi đè** khi mở recording trong Ranorex Studio.

### 1.2 Entry Points

| Method | Khi nào chạy | Dùng để |
|--------|-------------|---------|
| `Init()` | Trước recording steps | Khởi tạo, check preconditions, log |
| `Finish()` | Sau recording steps | Cleanup, teardown |
| Custom methods | Gọi từ `Init()` / `Finish()` | Tách logic phức tạp |

**Lưu ý quan trọng:** `Init()` KHÔNG THỂ ngăn recording steps chạy. Nếu cần kiểm soát hoàn toàn flow → tạo module `ModuleType.UserCode` riêng.

> Evidence: Lesson từ login-retry — gọi `TryLoginWithUser()` trong `Init()` vẫn không ngăn được recording steps chạy sau đó.  
> Xem: `.claude/lessons/login-retry-lesson.md` Rule R3

### 1.3 Truy cập Module Variables

```csharp
// ✅ ĐÚNG — Ranorex inject qua data binding
string user = this.UserName;
string pass = this.Password;

// ❌ SAI — tự đọc file
string user = File.ReadAllLines("data.csv")[0];

// ❌ SAI — hardcode
string user = "kyadmin";
```

---

## 2. Wait Methods — Khi nào dùng gì

### 2.1 So sánh

| Method | Chờ? | Fail test? | Return type | Dùng khi |
|--------|------|-----------|-------------|----------|
| `WaitForExists(ms)` | Có | Throw exception nếu timeout | void | Chờ element xuất hiện, bắt buộc phải có |
| `Exists(ms)` | Có | Không | bool | Kiểm tra element có tồn tại không, xử lý cả 2 case |
| `EnsureVisible()` | Không | Throw nếu fail | void | Scroll element vào view trước khi click |
| `Validate.Exists()` | Có | Log failure | void | Dynamic wait + assertion, tốt cho dynamic UI |

### 2.2 Pattern khuyến nghị

```csharp
// Pattern 1: Chờ bắt buộc — element PHẢI xuất hiện
repo.CCILoginWindow.SelfInfo.WaitForExists(30000);

// Pattern 2: Kiểm tra có/không — xử lý cả 2 trường hợp
if (repo.CCIMainWindow.SelfInfo.Exists(5000))
{
    Report.Log(ReportLevel.Info, "Login", "Main window da xuat hien.");
}
else
{
    Report.Log(ReportLevel.Warn, "Login", "Main window CHUA xuat hien.");
}

// Pattern 3: Validate — ghi nhận kết quả vào report
Validate.Exists(repo.CCIMainWindow.CreateOrOpenRecipeInfo);

// Pattern 4: Validate attribute — kiểm tra text cụ thể
Validate.AttributeEqual(repo.CCIMainWindow.CreateOrOpenRecipeInfo,
    "Text", "Create or open recipe.");
```

### 2.3 Khi nào dùng Delay cố định

Delay cố định (`Delay.Milliseconds()`) chỉ nên dùng khi:

| Trường hợp | Lý do | Ví dụ trong project |
|------------|-------|---------------------|
| WPF focus transfer | Framework cần thời gian xử lý focus | 500ms sau `Click()` |
| Keyboard keystroke | Giữa các phím để tránh bị swallow | 100ms giữa `{Home}` và `{Shift+End}` |
| App processing | Không có element nào thay đổi để detect | 30s sau click Login |
| Animation | UI animation chưa hoàn tất | 200ms sau action |

**Ưu tiên:** `WaitForExists()` / `Exists()` → rồi mới `Delay.Milliseconds()` nếu không có alternative.

---

## 3. Report.Log — Logging hiệu quả

### 3.1 Levels

```csharp
// Debug — chi tiết cho developer
Report.Log(ReportLevel.Info, "Login", "Bat dau nhap username...");

// Success — validation thành công
Report.Log(ReportLevel.Success, "Login", "Login THANH CONG.");

// Warning — đáng chú ý nhưng test tiếp tục
Report.Log(ReportLevel.Warn, "Login", "CCIMainWindow ton tai nhung validate fail.");

// Failure — validation thất bại
Report.Log(ReportLevel.Failure, "Login", "Login THAT BAI — timeout 40 giay.");

// Error — exception/crash
Report.Log(ReportLevel.Error, "Login", "Exception: " + ex.Message);
```

### 3.2 Best Practices cho logging

```csharp
// ✅ Log entry point để xác nhận hàm được gọi
Report.Log(ReportLevel.Info, "Login", "BAT DAU CHAY VAO HAM TryLoginWithUser");

// ✅ Log input values (không log password!)
Report.Log(ReportLevel.Info, "Login",
    string.Format("Thu login voi user '{0}'...", user));

// ✅ Log kết quả rõ ràng
Report.Log(ReportLevel.Success, "Login",
    "Login THANH CONG — CCIMainWindow va 'Create or open recipe.' da xuat hien.");

// ✅ Screenshot kèm mô tả
Report.Screenshot(ReportLevel.Info, "Login",
    "Trang thai UI sau khi login.", repo.CCIMainWindow.Self, false);

// ❌ Log quá chung chung
Report.Log(ReportLevel.Info, "Login", "Done.");
```

> Evidence: Rule R4 từ login-retry-lesson — log "BAT DAU CHAY VAO HAM" giúp xác nhận hàm có được gọi hay không.

---

## 4. Exception Handling

### 4.1 Pattern chuẩn

```csharp
public static bool TryLoginWithUser(string user, string pass)
{
    try
    {
        // ... login steps ...
        return IsLoginSuccessful();
    }
    catch (Exception ex)
    {
        Report.Log(ReportLevel.Error, "Login",
            string.Format("Loi khi login voi user '{0}': {1}", user, ex.Message));
        return false;
    }
}
```

### 4.2 Quy tắc

- **Catch ở mức method** — không catch quá rộng (toàn bộ module)
- **Log exception message** — `ex.Message` đủ, không cần `ex.StackTrace` trong report
- **Return giá trị hợp lý** — `false` cho failure, không throw lại
- **Không dùng catch để bỏ qua lỗi thật** — chỉ catch khi có handling logic

### 4.3 Validate với try-catch

```csharp
// Khi validate có thể fail nhưng không muốn stop test
try
{
    Validate.AttributeEqual(repo.CCIMainWindow.CreateOrOpenRecipeInfo,
        "Text", "Create or open recipe.");
    Report.Log(ReportLevel.Success, "Login", "Validate thanh cong.");
}
catch (Exception ex)
{
    Report.Log(ReportLevel.Warn, "Login",
        string.Format("Validate that bai: {0}", ex.Message));
}
```

---

## 5. Static vs Instance Methods

### 5.1 Khi nào dùng gì

| Loại | Dùng khi | Truy cập `this`? | Ví dụ |
|------|----------|-------------------|-------|
| Instance | Cần module variables | ✅ Có | `Init()`, `Run()` |
| Static | Utility/helper, shared logic | ❌ Không | `TryLoginWithUser()`, `ClearLoginFields()` |

### 5.2 Lỗi thường gặp

```csharp
// ❌ SAI — static method không truy cập được this
public static void DoSomething()
{
    string user = this.UserName;  // Compile error!
}

// ✅ ĐÚNG — truyền giá trị qua parameter
public static void DoSomething(string user)
{
    // Dùng user parameter
}
```

### 5.3 Static flags cho cross-iteration state

```csharp
// LoginRetry.cs — flag giữa các iterations
private static bool credentialFound = false;

void ITestModule.Run()
{
    if (credentialFound)
    {
        Report.Log(ReportLevel.Info, "LoginRetry", "Skip — da tim thay credential.");
        return;
    }
    // ... login logic ...
    credentialFound = true;
}
```

**Lưu ý:** Static flag giữ giá trị suốt test run. Nếu cần reset → set lại trong Setup/Teardown.

---

## 6. Helper Method Organization

### 6.1 Tách logic phức tạp

```csharp
// ✅ Tách thành helper methods rõ ràng
public static bool TryLoginWithUser(string user, string pass)
{
    TypeIntoUserField(user);      // Step 1
    TypeIntoPasswordField(pass);  // Step 2
    ClickLoginButton();           // Step 3
    return IsLoginSuccessful();   // Step 4
}

private static void TypeIntoUserField(string value)
{
    repo.CCILoginWindow.XIDPWLoginArea.SomeText.Click("47;2");
    Delay.Milliseconds(500);
    ClearCurrentField();
    Keyboard.Press(value);
    Delay.Milliseconds(500);
}
```

### 6.2 Naming conventions

- Method names: PascalCase, verb-first (`TypeIntoUserField`, `IsLoginSuccessful`, `ClearLoginFields`)
- Report category: Consistent string (`"Login"`, `"LoginRetry"`)
- Vietnamese messages: Không dấu (ASCII-safe): `"Login thanh cong"`, `"That bai"`

---

## 7. User Code Library Pattern (Advanced)

Cho các method dùng chung giữa nhiều module:

```csharp
// Tạo class riêng với [UserCodeCollection]
[UserCodeCollection]
public class CommonActions
{
    [UserCodeMethod]
    public static void ClearTextField(Ranorex.Text element)
    {
        element.Click();
        Delay.Milliseconds(500);
        Keyboard.Press("{Home}");
        Delay.Milliseconds(100);
        Keyboard.Press("{Shift down}{End}{Shift up}");
        Delay.Milliseconds(100);
        Keyboard.Press("{Delete}");
        Delay.Milliseconds(200);
    }
}
```

**Lưu ý:** Hiện project Lynn_DPI_AT chưa dùng pattern này. Khi project phức tạp hơn, nên cân nhắc.

---

## 8. WPF-specific: Clear Text Field

> Evidence: Root cause chính của bug login — `{Ctrl+A}` không hoạt động trên WPF ComboBox.  
> Xem: `.claude/lessons/login-retry-lesson.md` Rule R1

### Pattern đúng cho WPF

```csharp
// ✅ ĐÚNG — hoạt động trên WPF ComboBox
element.Click("47;2");
Delay.Milliseconds(500);
Keyboard.Press("{Home}");
Delay.Milliseconds(100);
Keyboard.Press("{Shift down}{End}{Shift up}");
Delay.Milliseconds(100);
Keyboard.Press("{Delete}");
Delay.Milliseconds(200);

// ❌ SAI — Ctrl+A bị WPF ComboBox intercept
Keyboard.Press("{Control}a");  // Text cũ không được select!
```

**Lý do:** `Ctrl+A` hoạt động ở control level (ComboBox intercept). `{Home}{Shift+End}` hoạt động ở text cursor level.

---

## 9. Checklist khi viết UserCode mới

- [ ] File đúng là `*.UserCode.cs`?
- [ ] Module variables truy cập qua `this.VariableName`?
- [ ] Không hardcode credentials hoặc paths?
- [ ] Có log entry point (`"BAT DAU CHAY VAO HAM..."`)?
- [ ] Có log kết quả rõ ràng (success/failure)?
- [ ] Exception handling có catch + log?
- [ ] Static vs instance chọn đúng?
- [ ] Wait methods dùng đúng pattern?
- [ ] WPF text clear dùng `{Home}{Shift+End}{Delete}`?
- [ ] Screenshot ở các điểm quan trọng?

---

## 10. Tham khảo

- [Mastering User Code in Ranorex Studio](https://www.ranorex.com/blog/mastering-user-code/)
- [User Code Actions](https://support.ranorex.com/hc/en-us/articles/38079929039633-User-code-actions/)
- [Best Practices – Ranorex](https://kalongs27.rssing.com/chan-14444674/all_p1.html)
- [Report Levels](https://support.ranorex.com/hc/en-us/articles/38080643131409-Report-levels)
- `.claude/lessons/login-retry-lesson.md` (project-specific lessons)
