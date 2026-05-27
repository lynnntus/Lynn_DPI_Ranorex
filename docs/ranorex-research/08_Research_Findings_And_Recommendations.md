# 08. Research Findings & Recommendations

> Tài liệu nghiên cứu nội bộ — Lynn_DPI_AT Project  
> Ngày: 2026-05-26

---

## 1. Executive Summary

Project Lynn_DPI_AT đã xây dựng được nền tảng automation test cho Neptune DPI với login flow hoạt động (LoginRetry + data-driven), cấu trúc test suite rõ ràng (Setup/Test/Teardown), và repository mapping cho các cửa sổ chính. Tuy nhiên, project đang gặp **2 rủi ro cao** (repository caching trên Máy B, Login_Pass conflict), **4 rủi ro trung bình** (coordinates fragile, Recording1 trống, CSV thiếu data, missing data binding), và cần cải thiện wait strategy để giảm thời gian chạy test. Giai đoạn tiếp theo nên ưu tiên sửa flow conflict, tối ưu performance, và bắt đầu implement test logic chính cho inspection flow.

---

## 2. Key Findings

### 2.1 Về Ranorex Framework

| # | Finding | Impact | Tài liệu chi tiết |
|---|---------|--------|-------------------|
| F1 | Partial class pattern: `.cs` auto-generated + `.UserCode.cs` custom → chỉ sửa UserCode | Nếu sửa sai file, thay đổi bị ghi đè | `01_Ranorex_Overview.md` §4 |
| F2 | Init() chạy TRƯỚC recording nhưng KHÔNG THỂ skip recording steps | Không thể dùng Init() để kiểm soát flow | `03_UserCode_Best_Practices.md` §1.2 |
| F3 | Timeout cascading: rooted folder timeout cộng dồn → effective timeout có thể gấp 3x | 30s × 3 levels = 90 giây thực tế | `04_Repository_Best_Practices.md` §6 |
| F4 | WPF ComboBox intercept `{Ctrl+A}` → phải dùng `{Home}{Shift+End}{Delete}` | Pattern clear field khác với app thông thường | `03_UserCode_Best_Practices.md` §8 |
| F5 | `WaitForExists()` throw exception khi timeout, `Exists()` return false | Chọn đúng method tùy ngữ cảnh | `03_UserCode_Best_Practices.md` §2 |
| F6 | PopupWatcher cho phép xử lý dialog bất ngờ tự động | Cần thiết khi app có popup không đoán trước | `05_Stable_Automation_Strategy.md` §4 |
| F7 | Attribute weight system quyết định selector nào được ưu tiên | Giảm weight dynamic attribute → ổn định hơn | `04_Repository_Best_Practices.md` §4 |
| F8 | Smart Folder = container cho data-driven iterations | Mỗi CSV row = 1 lần chạy module | `01_Ranorex_Overview.md` §5.2 |

### 2.2 Về Project Hiện Tại

| # | Finding | Evidence | Impact |
|---|---------|----------|--------|
| P1 | Login flow hoạt động: LoginRetry × CSV → TryLoginWithUser() → credentialFound flag | `LoginRetry.cs`, `Login_Pass.UserCode.cs` | ✅ Positive — đã có retry mechanism |
| P2 | Login_Pass recording chạy SAU LoginRetry → conflict khi đã login | `Lynn_DPI_AT.rxtst` — module order | 🔴 Login steps chạy trên main window |
| P3 | Repository caching gây chậm trên Máy B (~1.5 phút/element) | `.claude/lessons/login-retry-lesson.md` | 🔴 Test time tăng nhiều lần |
| P4 | Tất cả Click() dùng pixel coordinates | `Login_Pass.UserCode.cs` — `Click("47;2")` | 🟡 Fragile khi DPI/resolution thay đổi |
| P5 | Recording1 trống — chưa có test chính | `Recording1.cs` — empty module | 🟡 Chưa test chức năng DPI |
| P6 | Users_DataSource.csv chỉ có header | File content: 1 line | 🟡 Data binding không có data |
| P7 | Fixed delay 30s sau login thay vì dynamic wait | `Login_Pass.UserCode.cs` line 60 | 🟢 Lãng phí thời gian |
| P8 | Absolute CSV path trong .rxtst | `.rxtst` XML | 🟢 Không portable |

---

## 3. 10 Rules quan trọng nhất

### Rules từ Ranorex Framework

| # | Rule | Lý do |
|---|------|-------|
| R1 | **Chỉ sửa file `*.UserCode.cs`** — không sửa `.cs` auto-generated | Ranorex ghi đè khi re-record |
| R2 | **Dùng `@automationid` làm selector ưu tiên** — tránh dynamic ID | Stable, ít thay đổi theo version |
| R3 | **`WaitForExists()` trước `Delay()`** — dynamic wait ưu tiên hơn fixed delay | Nhanh hơn và ổn định hơn |
| R4 | **Kiểm tra timeout cascading** — rooted folder timeout cộng dồn | Effective timeout có thể gấp 3x expected |
| R5 | **Module variable qua `this.VariableName`** — không hardcode, không đọc file | Bảo đảm data-driven testing |

### Rules từ Project Experience

| # | Rule | Evidence |
|---|------|----------|
| R6 | **WPF clear field: `{Home}{Shift+End}{Delete}`** — không dùng `{Ctrl+A}` | Login-retry-lesson R1 |
| R7 | **Grep call chain trước khi sửa method** — xác nhận method đó thực sự được gọi | Login-retry-lesson R2 |
| R8 | **Init() không thể skip recording** — dùng UserCode module nếu cần kiểm soát flow | Login-retry-lesson R3 |
| R9 | **Log entry point mỗi hàm** — `"BAT DAU CHAY VAO HAM..."` | Login-retry-lesson R4 |
| R10 | **LoginRetry và Login_Pass recording là 2 flow độc lập** — sửa 1 không ảnh hưởng cái kia | Login-retry-lesson R5 |

---

## 4. Cải thiện ngắn hạn (1-2 tuần)

| # | Action | Effort | Risk giải quyết | Chi tiết |
|---|--------|--------|-----------------|---------|
| S1 | Tách Login_Pass recording khỏi SmokeTest hoặc thêm skip condition | Thấp | RISK-02 | Login_Pass recording không cần chạy nếu LoginRetry đã thành công |
| S2 | Test tắt repository caching trên Máy B | Thấp | RISK-01 | Trong Ranorex Studio: CCILoginWindow → Properties → `usecache="False"` |
| S3 | Cấu hình data binding cho Login_Pass | Thấp | RISK-06 | Ranorex Studio → Login_Pass → Data Binding → map columns |
| S4 | Populate Users_DataSource.csv | Thấp | RISK-05 | Thêm data rows (tham khảo `TestData/Users.csv`) |
| S5 | Đổi CSV path sang relative | Thấp | RISK-08 | Ranorex Studio → Data Sources → sửa connector path |

**Tổng effort:** ~2-3 ngày làm việc, tất cả thực hiện trong Ranorex Studio.

---

## 5. Cải thiện trung hạn (1-2 tháng)

| # | Action | Effort | Lợi ích |
|---|--------|--------|---------|
| M1 | Chuyển Click coordinates sang center click | Trung bình | Ổn định khi DPI/resolution thay đổi (RISK-03) |
| M2 | Thay fixed delay 30s bằng dynamic wait | Trung bình | Giảm test time 20+ giây/login (RISK-07) |
| M3 | Implement Recording1 cho inspection flow | Cao | Bắt đầu test chức năng chính của Neptune DPI (RISK-04) |
| M4 | Thêm PopupWatcher cho unexpected dialogs | Trung bình | Tự động xử lý dialog bất ngờ |
| M5 | Enable Logout trong SmokeTest | Thấp | Đảm bảo app ở clean state sau test |

### M1 — Chi tiết: Chuyển coordinates

```csharp
// Trước
repo.CCILoginWindow.XIDPWLoginArea.SomeText.Click("47;2");

// Sau — click center (option 1)
repo.CCILoginWindow.XIDPWLoginArea.SomeText.Click();

// Sau — proportional (option 2, nếu cần click vị trí cụ thể)
// Cấu hình trong Ranorex Studio → Action Spot → Proportional
```

### M2 — Chi tiết: Dynamic wait

```csharp
// Trước
Delay.Milliseconds(30000);
return IsLoginSuccessful();

// Sau
int elapsed = 0;
while (repo.CCILoginWindow.SelfInfo.Exists(2000) && elapsed < 60000)
{
    elapsed += 2000;
}
return IsLoginSuccessful();
```

---

## 6. Cải thiện dài hạn (3+ tháng)

| # | Action | Effort | Lợi ích |
|---|--------|--------|---------|
| L1 | Xây dựng User Code Library (`[UserCodeCollection]`) | Cao | Tái sử dụng helper methods giữa các module |
| L2 | Test data strategy (nhiều CSV, nhiều scenario) | Trung bình | Cover nhiều trường hợp test hơn |
| L3 | CI/CD integration | Cao | Chạy test tự động khi build |
| L4 | Multi-machine test config | Trung bình | Config khác nhau cho Máy A vs Máy B |
| L5 | Test report dashboard | Trung bình | Theo dõi test trend, pass/fail rate |

### L1 — UserCodeCollection pattern

```csharp
[UserCodeCollection]
public class NeptuneActions
{
    [UserCodeMethod]
    public static void ClearWPFField(Ranorex.Text element)
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

    [UserCodeMethod]
    public static bool WaitForWindowDisappear(
        Ranorex.Core.Repository.RepoItemInfo windowInfo, int maxWaitMs)
    {
        int elapsed = 0;
        while (windowInfo.Exists(2000) && elapsed < maxWaitMs)
        {
            elapsed += 2000;
        }
        return !windowInfo.Exists(0);
    }
}
```

---

## 7. Roadmap tổng hợp

```
Tuần 1-2 (Ngắn hạn)
├── S1: Sửa Login_Pass/SmokeTest conflict
├── S2: Test tắt caching Máy B
├── S3: Fix data binding Login_Pass
├── S4: Populate CSV data
└── S5: Relative CSV path

Tháng 1-2 (Trung hạn)
├── M1: Chuyển coordinates → center click
├── M2: Dynamic wait thay fixed delay
├── M3: Implement Recording1 (inspection flow)
├── M4: PopupWatcher cho unexpected dialogs
└── M5: Enable Logout

Tháng 3+ (Dài hạn)
├── L1: UserCodeCollection library
├── L2: Test data strategy
├── L3: CI/CD integration
├── L4: Multi-machine config
└── L5: Test report dashboard
```

---

## 8. Danh sách tài liệu đã tạo

| # | File | Nội dung chính |
|---|------|---------------|
| 1 | `01_Ranorex_Overview.md` | Kiến trúc 4 thành phần, flow thực thi, partial class pattern |
| 2 | `02_Project_Structure_Analysis.md` | Directory tree, phân loại file, repository/test suite structure |
| 3 | `03_UserCode_Best_Practices.md` | Wait methods, Report.Log, exception handling, WPF patterns |
| 4 | `04_Repository_Best_Practices.md` | RxPath, stable selectors, timeout cascading, Spy debugging |
| 5 | `05_Stable_Automation_Strategy_For_DPI.md` | Object vs coordinate, wait strategy, login/popup handling |
| 6 | `06_Debug_And_Troubleshooting_Checklist.md` | 8 checklists, decision trees, Máy A vs Máy B differences |
| 7 | `07_Current_Project_Risks.md` | 8 risks (2 HIGH, 4 MEDIUM, 2 LOW), risk matrix, priorities |
| 8 | `08_Research_Findings_And_Recommendations.md` | Tổng hợp findings, 10 rules, roadmap ngắn/trung/dài hạn |

---

## 9. Nguồn tham khảo chính

### Ranorex Official Documentation
- [Mastering User Code in Ranorex Studio](https://www.ranorex.com/blog/mastering-user-code/)
- [User Code Actions](https://support.ranorex.com/hc/en-us/articles/38079929039633)
- [RanoreXPath Tips and Tricks](https://www.ranorex.com/blog/ranorexpath-tips-and-tricks/)
- [Use Stable Locators](https://www.ranorex.com/blog/best-practices-4-use-stable-locators/)
- [RanoreXPath Solutions](https://support.ranorex.com/hc/en-us/articles/22974736764701)
- [Object Not Found Troubleshooting](https://support.ranorex.com/hc/en-us/articles/22975157755277)
- [PopupWatcher](https://support.ranorex.com/hc/en-us/articles/38080036395025)
- [Smart Folders](https://support.ranorex.com/hc/en-us/articles/38079828843281)
- [Ranorex Spy](https://www.ranorex.com/ranorex-spy/)
- [Report Levels](https://support.ranorex.com/hc/en-us/articles/38080643131409)
- [Dynamic IDs](https://www.ranorex.com/blog/automated-testing-and-dynamic-ids/)

### Project Documentation
- `.claude/lessons/login-retry-lesson.md` — Bài học từ debug login flow
- `.claude/rules/safety.md` — Quy tắc an toàn file
- `.claude/rules/coding.md` — Quy tắc coding Ranorex
- `.claude/rules/testing.md` — Quy tắc test & data
- `.claude/rules/data_binding.md` — Hướng dẫn data binding
- `.claude/context/project.md` — Tổng quan project
- `.claude/context/modules.md` — Chi tiết modules
- `.claude/context/repository.md` — UI repository
