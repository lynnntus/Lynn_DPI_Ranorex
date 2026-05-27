# 05. Chiến lược Automation ổn định cho DPI

> Tài liệu nghiên cứu nội bộ — Lynn_DPI_AT Project  
> Ngày: 2026-05-26

---

## 1. Object-based vs Coordinate-based Automation

### 1.1 So sánh

| Tiêu chí | Object-based | Coordinate-based |
|----------|-------------|-----------------|
| Selector | `@automationid`, `@name`, `@caption` | Pixel position: `Click("47;2")` |
| Ổn định | ✅ Cao — không phụ thuộc vị trí | ⚠️ Thấp — thay đổi khi resize/DPI |
| Maintain | Dễ đọc, dễ debug | Khó hiểu, khó update |
| Khi nào dùng | **Ưu tiên luôn** — mọi element có selector | **Chỉ khi bắt buộc** — element không có selector |

### 1.2 Tình trạng hiện tại trong project

```csharp
// ⚠️ Đang dùng coordinate-based — nên chuyển sang object-based khi có thể
repo.CCILoginWindow.XIDPWLoginArea.SomeText.Click("47;2");
repo.CCILoginWindow.XIDPWLoginArea.XPWWatermark.Click("36;6");
repo.CCILoginWindow.Login.Click("10;8");
```

> Evidence: `Login_Pass.UserCode.cs` — tất cả Click() đều dùng element-relative coordinates.

### 1.3 Action Spot Settings

Ranorex hỗ trợ 3 chế độ Action Spot:

| Chế độ | Mô tả | Khi nào dùng |
|--------|--------|-------------|
| **None** (Center) | Click vào tâm element | ✅ Ổn định nhất — phần lớn trường hợp |
| **Pixel** | Offset pixel cố định từ góc trên-trái | ⚠️ Chỉ khi phải click vào vị trí cụ thể trong element |
| **Proportional** | Tỷ lệ % theo kích thước element | ✅ Tốt hơn Pixel — scale theo element size |

**Khuyến nghị:** Chuyển từ Pixel coordinates (`"47;2"`) sang None (center) hoặc Proportional khi element có thể resize.

---

## 2. Wait Strategy

### 2.1 Nguyên tắc: Dynamic wait trước, Fixed delay sau

```
Ưu tiên 1: WaitForExists() / Exists()     ← Element xuất hiện
Ưu tiên 2: Validate.Exists()              ← Element xuất hiện + ghi report
Ưu tiên 3: Delay.Milliseconds()           ← Không có element để wait
```

### 2.2 Tình trạng delay hiện tại

| Vị trí | Delay | Lý do | Có thể cải thiện? |
|--------|-------|-------|-------------------|
| `TryLoginWithUser()` — sau Click Login | 30,000ms | Chờ app xử lý login | ⚠️ Có — dùng `WaitForExists()` cho CCIMainWindow |
| `TypeIntoUserField()` — sau Click | 500ms | WPF focus transfer | ✅ Hợp lý — WPF cần thời gian |
| `TypeIntoUserField()` — giữa keystrokes | 100-200ms | Keyboard processing | ✅ Hợp lý — tránh keystroke swallowed |
| `TypeIntoPasswordField()` — sau Click | 500ms | WPF focus transfer | ✅ Hợp lý |

> Evidence: `Login_Pass.UserCode.cs` lines 57-60 — `Delay.Milliseconds(30000)` sau click Login.

### 2.3 Pattern khuyến nghị: Replace fixed delay bằng dynamic wait

```csharp
// ❌ Hiện tại — chờ cố định 30 giây dù app có thể load nhanh hơn
repo.CCILoginWindow.Login.Click("10;8");
Delay.Milliseconds(30000);
return IsLoginSuccessful();

// ✅ Cải thiện — chờ đến khi login window biến mất HOẶC main window xuất hiện
repo.CCILoginWindow.Login.Click("10;8");

// Chờ login window biến mất (tín hiệu app đang xử lý)
int elapsed = 0;
while (repo.CCILoginWindow.SelfInfo.Exists(2000) && elapsed < 60000)
{
    elapsed += 2000;
}

return IsLoginSuccessful();
```

### 2.4 Khi nào Fixed Delay là hợp lý

| Tình huống | Lý do không thể dùng dynamic wait |
|------------|-----------------------------------|
| WPF focus transfer (500ms) | Không có element nào thay đổi trạng thái |
| Keyboard keystroke gap (100ms) | Framework cần thời gian buffer giữa các phím |
| Animation (200ms) | UI animation không thay đổi element properties |
| App internal processing | Không có indicator visible nào |

---

## 3. Login/Logout Flow

### 3.1 Kiến trúc hiện tại

```
SmokeTest
├── StartAUT          ← Launch AOIGUI.exe
├── SmartFolder: Users (CSV, 2 rows)
│   └── LoginRetry    ← Thử từng credential, dừng khi thành công
├── Login_Pass        ← Recording steps (chạy sau LoginRetry)
└── Logout            ← DISABLED
```

### 3.2 LoginRetry Pattern (đã hoạt động tốt)

```
CSV Row 1: kyadmin/pass1
  → TryLoginWithUser("kyadmin", "pass1")
  → Thành công? → credentialFound = true, skip rows còn lại

CSV Row 2: admin/pass2
  → credentialFound == true → Skip

Login_Pass recording
  → Init() kiểm tra CCIMainWindow.Exists(2000)
  → Đã login → log "skip" (nhưng recording steps vẫn chạy!)
```

> Evidence: `LoginRetry.cs` — static flag `credentialFound` để skip CSV rows sau khi login thành công.

### 3.3 Credential Sharing: LoginRetry → Login_Pass

```csharp
// LoginRetry.cs — sau khi login thành công
Login_Pass.Instance.UserName = UserName;
Login_Pass.Instance.Password = Password;
credentialFound = true;
```

Cơ chế này cho phép Login_Pass recording biết credential nào đã thành công, nhưng có hạn chế:
- Login_Pass recording vẫn chạy steps của nó (Init() không thể skip)
- Nếu đã login, recording steps sẽ thao tác trên main window thay vì login window → **có thể gây lỗi**

### 3.4 Logout Flow

Module `Logout` trong SmokeTest đang **disabled** (`enabled="False"` trong `.rxtst`).

> Evidence: `Lynn_DPI_AT.rxtst` — `<testmodule ... enabled="False">`

**Hệ quả:**
- App không được logout sau SmokeTest
- Nếu test suite chạy tiếp các test case khác, app vẫn ở trạng thái logged-in
- Có thể ảnh hưởng đến test case tiếp theo

---

## 4. Popup/Dialog Handling

### 4.1 PopupWatcher (Ranorex built-in)

PopupWatcher là cơ chế giám sát liên tục, tự động xử lý dialog bất ngờ:

```csharp
// Khởi tạo PopupWatcher
PopupWatcher watcher = new PopupWatcher();

// Đăng ký popup cần xử lý
watcher.Watch(repo.UnexpectedDialog.SelfInfo, HandleUnexpectedDialog);

// Bắt đầu giám sát
watcher.Start();

// ... chạy test ...

// Dừng giám sát
watcher.Stop();

// Handler
private static void HandleUnexpectedDialog(
    Ranorex.Core.Repository.RepoItemInfo info, Ranorex.Core.Element element)
{
    Report.Log(ReportLevel.Warn, "PopupHandler", "Unexpected dialog detected!");
    Report.Screenshot();
    // Click OK/Close/Cancel tùy loại dialog
}
```

### 4.2 Phân loại Dialog

| Loại | Ví dụ | Xử lý |
|------|-------|-------|
| **Expected** | Login window, confirmation dialog | Xử lý trong test flow bình thường |
| **Unexpected** | Error dialog, license warning | PopupWatcher tự động xử lý |
| **System** | Windows Update, antivirus | PopupWatcher hoặc tắt trước khi test |

### 4.3 DPI-specific: Dialogs đã biết

| Dialog | Repository element | Xử lý hiện tại |
|--------|-------------------|-----------------|
| InspectionRegionSettings | `repo.InspectionRegionSettings.BtnDualClose` | Có element nhưng chưa có handler |

> Evidence: `Lynn_DPI_ATRepository.rxrep` — folder `InspectionRegionSettings` với `BtnDualClose`.

### 4.4 Khi nào nên dùng PopupWatcher

- App Neptune có thể hiển thị dialog bất ngờ (license, error, warning)
- Nếu dialog xuất hiện giữa test flow, test sẽ fail vì element bị che
- PopupWatcher chạy nền, kiểm tra liên tục, không ảnh hưởng test performance

**Need to verify:** App Neptune có những popup bất ngờ nào → Cần chạy manual test nhiều lần để xác định danh sách đầy đủ.

---

## 5. Loading Screen Handling

### 5.1 Neptune App Startup

App Neptune (AOIGUI.exe) khởi động chậm — cần strategy chờ đúng:

```csharp
// Pattern: Chờ app ready
// 1. Launch app
// 2. Chờ login window xuất hiện
repo.CCILoginWindow.SelfInfo.WaitForExists(30000);

// 3. Delay nhỏ cho WPF render hoàn tất
Delay.Milliseconds(500);

// 4. Bắt đầu thao tác
```

### 5.2 Sau Login — Chờ Main Window

```csharp
// Pattern: Chờ main window + validate text
bool mainWindowExists = repo.CCIMainWindow.SelfInfo.Exists(40000);

if (mainWindowExists)
{
    // Validate app ở trạng thái đúng
    Validate.AttributeEqual(repo.CCIMainWindow.CreateOrOpenRecipeInfo,
        "Text", "Create or open recipe.");
}
```

> Evidence: `Login_Pass.UserCode.cs` — `IsLoginSuccessful()` chờ 40 giây cho CCIMainWindow.

### 5.3 Pattern cho loading indicator (nếu có)

```csharp
// Nếu app có loading spinner/progress bar
// 1. Chờ loading indicator xuất hiện
repo.LoadingIndicator.SelfInfo.WaitForExists(5000);

// 2. Chờ loading indicator biến mất
int maxWait = 60000;
int elapsed = 0;
while (repo.LoadingIndicator.SelfInfo.Exists(2000) && elapsed < maxWait)
{
    elapsed += 2000;
}

// 3. Thao tác tiếp
```

**Need to verify:** Neptune có loading indicator không → Cần kiểm tra UI khi app khởi động.

---

## 6. Module Design cho tái sử dụng

### 6.1 Nguyên tắc

| Nguyên tắc | Giải thích |
|-----------|-----------|
| **Single Responsibility** | Mỗi module làm 1 việc: Login, Logout, StartAUT, CloseAUT |
| **Parameterized** | Dùng module variables thay hardcode |
| **Stateless** (ưu tiên) | Không giữ state giữa các lần chạy, trừ khi cần thiết |
| **Idempotent** | Chạy lại không gây side effect — check trạng thái trước khi thao tác |

### 6.2 Static Flag — Khi nào hợp lý

```csharp
// LoginRetry dùng static flag để skip CSV rows đã xử lý
private static bool credentialFound = false;

// ✅ Hợp lý vì:
// - Cần giữ state giữa các iterations (CSV rows)
// - Reset khi test suite restart (static var bị reset)
// - Chỉ 1 flag đơn giản, không phức tạp

// ⚠️ Cẩn thận:
// - Static flag giữ giá trị suốt test run
// - Nếu cần reset giữa test cases → phải reset thủ công
```

### 6.3 Setup/Teardown

```
Test Case
├── Setup
│   └── StartAUT           ← Launch app, output AppProcessID
├── Test modules
│   ├── LoginRetry          ← Login
│   ├── Login_Pass          ← (Recording)
│   └── Recording1          ← Test actions
└── Teardown
    └── CloseAUT            ← Close by AppProcessID
```

**Lợi ích:**
- StartAUT/CloseAUT chạy 1 lần cho mỗi test case
- AppProcessID truyền từ Setup → Teardown → đảm bảo close đúng process
- Nếu test fail giữa chừng, Teardown vẫn chạy → app được cleanup

### 6.4 Smart Folder cho Data-Driven

```
SmartFolder: Users (bind CSV, 2 rows)
└── LoginRetry
    ← Chạy 2 lần, 1 lần/row
    ← credentialFound skip rows thừa
```

> Evidence: `Lynn_DPI_AT.rxtst` — SmartFolder "Users" bind `NewConnector - CsvDataConnector`.

---

## 7. State Verification trước thao tác

### 7.1 Nguyên tắc: Check trước, Act sau

```csharp
// ✅ Kiểm tra trạng thái trước khi thao tác
if (repo.CCILoginWindow.SelfInfo.Exists(3000))
{
    // Login window tồn tại → thực hiện login
    TypeIntoUserField(user);
    TypeIntoPasswordField(pass);
    repo.CCILoginWindow.Login.Click("10;8");
}
else if (repo.CCIMainWindow.SelfInfo.Exists(2000))
{
    // Đã login → skip
    Report.Log(ReportLevel.Info, "Login", "Da login, skip.");
}
else
{
    // Không có window nào → lỗi
    Report.Log(ReportLevel.Error, "Login", "Khong tim thay window nao!");
}
```

### 7.2 Ví dụ trong project

```csharp
// Login_Pass.Init() — kiểm tra trước khi recording chạy
if (repo.CCIMainWindow.SelfInfo.Exists(2000))
{
    Report.Log(ReportLevel.Success, "Login",
        "LoginRetry da login thanh cong truoc do. Login_Pass skip login steps.");
}

// ClearLoginFields() — kiểm tra login window trước khi clear
if (!repo.CCILoginWindow.SelfInfo.Exists(3000))
    return;
```

> Evidence: `Login_Pass.UserCode.cs` — Init() line 32, ClearLoginFields() line 109.

---

## 8. DPI-specific: Neptune App

### 8.1 Đặc điểm Neptune cần lưu ý

| Đặc điểm | Impact | Strategy |
|-----------|--------|----------|
| WPF application | `{Ctrl+A}` không hoạt động trên ComboBox | Dùng `{Home}{Shift+End}{Delete}` |
| Khởi động chậm | Login window mất 10-30 giây | `WaitForExists(30000)` |
| Login processing chậm | Main window mất 30-40 giây | Fixed delay 30s hoặc dynamic wait |
| Repository caching | Máy B chậm ~1.5 phút/element | Xem xét tắt `usecache` |
| Custom controls | Element có thể không expose standard attributes | Dùng `@automationid` khi có |

### 8.2 Timeout Tuning Rationale

| Element | Timeout hiện tại | Lý do |
|---------|-----------------|-------|
| CCILoginWindow | 30,000ms | App cần thời gian khởi động |
| CCIMainWindow (IsLoginSuccessful) | 40,000ms | Login processing + render |
| CCIMainWindow (Init check) | 2,000ms | Quick check — chỉ cần biết có/không |
| CCILoginWindow (ClearFields) | 3,000ms | Quick check trước khi clear |
| All repository elements (default) | 30,000ms | Global default trong Ranorex.rxsettings |

### 8.3 WPF Automation Quirks

| Quirk | Ảnh hưởng | Workaround |
|-------|-----------|------------|
| `{Ctrl+A}` intercept | Text không được select trong ComboBox | `{Home}{Shift+End}{Delete}` |
| Focus transfer delay | Click vào field nhưng keystroke đi vào field cũ | `Delay.Milliseconds(500)` sau Click |
| Watermark overlay | Password field có watermark text che input | Click vào watermark element trước |
| State caching | Element state không update real-time | Dùng `Exists()` với timeout ngắn |

> Evidence: `Login_Pass.UserCode.cs` — TypeIntoPasswordField click vào XPWWatermark thay vì TextXPW.

---

## 9. Checklist khi implement test case mới

- [ ] Xác định elements cần thao tác — track trong Ranorex Spy
- [ ] Ưu tiên `@automationid`, `@name` — tránh dynamic ID
- [ ] Dùng `WaitForExists()` / `Exists()` thay fixed delay
- [ ] Kiểm tra trạng thái trước khi thao tác (`Exists()` check)
- [ ] Clear field bằng `{Home}{Shift+End}{Delete}` (WPF)
- [ ] Thêm `Report.Log()` ở entry point và kết quả
- [ ] Thêm `Report.Screenshot()` ở các bước quan trọng
- [ ] Exception handling với try-catch + log
- [ ] Test trên cả Máy A và Máy B
- [ ] Kiểm tra timeout hợp lý cho Neptune app

---

## 10. Tham khảo

- [Ranorex PopupWatcher](https://support.ranorex.com/hc/en-us/articles/38080036395025-PopupWatcher)
- [Wait Methods in Ranorex](https://support.ranorex.com/hc/en-us/articles/38079820116625)
- [Object Not Found Troubleshooting](https://support.ranorex.com/hc/en-us/articles/22975157755277-Object-not-found-RanoreXPath-not-valid/)
- [Smart Folders](https://support.ranorex.com/hc/en-us/articles/38079828843281-Smart-folders/)
- `.claude/lessons/login-retry-lesson.md` (project-specific lessons)
