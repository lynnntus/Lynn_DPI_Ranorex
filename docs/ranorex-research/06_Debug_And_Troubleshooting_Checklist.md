# 06. Debug & Troubleshooting Checklist

> Tài liệu nghiên cứu nội bộ — Lynn_DPI_AT Project  
> Ngày: 2026-05-26

---

## 1. Decision Tree tổng quát

```
Test FAIL
│
├── Element visible trong screenshot?
│   ├── YES → RxPath có đúng không?
│   │   ├── YES → Timing issue (xem Checklist 3)
│   │   └── NO  → Selector issue (xem Checklist 2)
│   │
│   └── NO → App có đang chạy không?
│       ├── YES → App chưa load xong (xem Checklist 5)
│       │         hoặc Popup/Dialog che (xem Checklist 4)
│       └── NO  → App crash hoặc chưa start (xem Checklist 5)
│
├── Test pass manual nhưng fail automation?
│   └── Xem Checklist 8
│
└── Module variable có giá trị đúng không?
    ├── YES → Logic issue (xem code)
    └── NO  → Data binding issue (xem Checklist 6)
```

---

## 2. Checklist 1: Test Fail (Tổng quát)

| # | Kiểm tra | Cách kiểm tra | Ghi chú |
|---|----------|--------------|---------|
| 1 | Ranorex Report có screenshot không? | Mở `.rxlog` → tìm screenshot gần failure | Screenshot là bằng chứng quan trọng nhất |
| 2 | Error message nói gì? | Report → tìm `ReportLevel.Error` hoặc `ReportLevel.Failure` | Đọc kỹ message trước khi debug |
| 3 | Module nào fail? | Report → xem module name trong log | Xác định đúng module trước khi sửa |
| 4 | Fail ở step nào? | Report → tìm log cuối cùng trước failure | Log entry point (`"BAT DAU CHAY VAO HAM..."`) giúp xác định |
| 5 | Có exception không? | Report → tìm `Exception` hoặc `Error` | Stack trace cho biết dòng code lỗi |
| 6 | Có retry/skip logic không? | Kiểm tra `credentialFound`, `Exists()` checks | Static flag có thể skip logic quan trọng |
| 7 | Build có thành công không? | Kiểm tra build output, `.exe` timestamp | Code mới có thể chưa được build |

---

## 3. Checklist 2: Object Not Found

| # | Kiểm tra | Cách kiểm tra | Ghi chú |
|---|----------|--------------|---------|
| 1 | RxPath có đúng không? | Ranorex Spy → Track element → so sánh RxPath | Path có thể thay đổi sau UI update |
| 2 | Element có visible không? | Screenshot → element có hiển thị trên màn hình? | Element bị hidden/collapsed sẽ không match |
| 3 | Dynamic ID? | Spy → kiểm tra attribute values mỗi lần chạy | `@id` thay đổi → dùng `@automationid` hoặc regex `~` |
| 4 | Cửa sổ đúng không? | Kiểm tra rooted folder → `@name` hoặc `@title` | Login window vs Main window vs Popup |
| 5 | Element tree quá lớn? | Spy → đếm elements trong tree | Tree >10,000 elements → performance chậm |
| 6 | Quyền Admin? | App chạy as Admin? Ranorex chạy as Admin? | Nếu không cùng privilege → không thể access |
| 7 | DPI Scaling? | Windows Settings → Display → Scale | 125%/150% scaling thay đổi element position |
| 8 | Antivirus/Security? | Tắt antivirus tạm → test lại | Một số antivirus block UI automation |

### Object Not Found — Decision tree chi tiết

```
"Object not found" error
│
├── Element tồn tại trong Spy khi track manual?
│   ├── YES → Timing issue
│   │   ├── Tăng timeout
│   │   ├── Thêm WaitForExists() trước
│   │   └── Kiểm tra timeout cascading (rooted folder)
│   │
│   └── NO → Element thật sự không tồn tại
│       ├── App chưa load xong?
│       ├── Cửa sổ sai? (Login vs Main)
│       ├── UI đã thay đổi? (re-track element)
│       └── Element bị hidden/collapsed?
│
└── Element tồn tại nhưng RxPath không match?
    ├── Dynamic attribute trong path?
    │   ├── Dùng regex: @id~'pattern_\d+'
    │   └── Giảm weight của dynamic attribute
    │
    ├── Path quá dài/fragile?
    │   ├── Rút ngắn bằng wildcard: /?/?/
    │   └── Dùng automationid thay vì path đầy đủ
    │
    └── Multiple elements match?
        ├── Thêm attribute để unique
        └── Dùng index: element[2]
```

---

## 4. Checklist 3: Timeout

| # | Kiểm tra | Cách kiểm tra | Ghi chú |
|---|----------|--------------|---------|
| 1 | Effective timeout bao nhiêu? | Repository → kiểm tra element timeout + folder timeout | Timeout cascading cộng dồn! |
| 2 | Rooted folder nào chứa element? | Repository tree → xem hierarchy | Mỗi rooted folder thêm timeout |
| 3 | `WaitForExists()` hay `Exists()`? | Đọc code → phương thức nào đang dùng? | `WaitForExists` throw, `Exists` return false |
| 4 | App có loading indicator? | Quan sát UI → có spinner/progress? | Chờ indicator biến mất thay vì fixed delay |
| 5 | Fixed delay có quá ngắn/dài? | Đọc `Delay.Milliseconds()` values | 30s cho login processing, 500ms cho WPF focus |

### Timeout Cascading — Ví dụ cụ thể

```
CCILoginWindow (timeout: 30s)              ← Rooted folder
  └── XIDPWLoginArea (timeout: 30s)        ← Nested rooted folder  
      └── SomeText (timeout: 30s)          ← Element

Effective timeout khi tìm SomeText:
= 30s (CCILoginWindow) + 30s (XIDPWLoginArea) + 30s (SomeText)
= 90 giây!

Trên Máy B với caching chậm → có thể lên đến ~1.5 phút
```

> Evidence: `04_Repository_Best_Practices.md` Section 6 — Timeout Cascading.

---

## 5. Checklist 4: Login Fail

| # | Kiểm tra | Cách kiểm tra | Ghi chú |
|---|----------|--------------|---------|
| 1 | Flow nào đang chạy? | Report log → "BAT DAU CHAY VAO HAM TryLoginWithUser" hay recording steps? | LoginRetry gọi TryLoginWithUser, Login_Pass chạy recording |
| 2 | Clear field đúng cách? | Code → dùng `{Home}{Shift+End}{Delete}`? | ❌ `{Ctrl+A}` không hoạt động trên WPF ComboBox |
| 3 | Credential có binding không? | `.rxtst` → kiểm tra data binding config | `missingdatabinding` tag = chưa bind |
| 4 | CSV có data không? | Mở CSV file → kiểm tra có data rows | `Users_DataSource.csv` chỉ có header! |
| 5 | Login window có tồn tại? | `repo.CCILoginWindow.SelfInfo.Exists()` | App chưa khởi động xong |
| 6 | Password field đúng element? | Spy → XPWWatermark vs TextXPW | Click vào watermark overlay, không phải text input |

### Login Flow — Debug diagram

```
LoginRetry.Run()
│
├── credentialFound == true? → SKIP (đã login)
│
├── CCILoginWindow.WaitForExists(30s) → FAIL? → Login window chưa xuất hiện
│
├── TryLoginWithUser(user, pass)
│   ├── TypeIntoUserField(user)
│   │   ├── Click SomeText("47;2") → Đúng element?
│   │   ├── {Home}{Shift+End}{Delete} → Text cũ bị xóa?
│   │   └── Press(value) → Giá trị nhập đúng?
│   │
│   ├── TypeIntoPasswordField(pass)
│   │   ├── Click XPWWatermark("36;6") → Đúng element?
│   │   ├── {Home}{Shift+End}{Delete} → Text cũ bị xóa?
│   │   └── Press(pass) → Giá trị nhập đúng?
│   │
│   ├── Click Login("10;8")
│   ├── Delay 30s
│   │
│   └── IsLoginSuccessful()
│       ├── CCIMainWindow.Exists(40s) → TRUE → Login OK
│       └── CCIMainWindow.Exists(40s) → FALSE → Login FAIL
│
├── success == true → credentialFound = true, share credential
└── success == false → ClearLoginFields(), try next CSV row
```

---

## 6. Checklist 5: App chưa load xong

| # | Kiểm tra | Cách kiểm tra | Ghi chú |
|---|----------|--------------|---------|
| 1 | Process có đang chạy? | Task Manager hoặc `Process.GetProcessesByName()` | AOIGUI.exe cần có trong process list |
| 2 | StartAUT có thành công? | Report → kiểm tra StartAUT module output | AppProcessID phải có giá trị |
| 3 | App cần bao lâu để start? | Đo thời gian manual | Neptune thường cần 10-30 giây |
| 4 | WaitForExists timeout đủ? | Code → `WaitForExists(30000)` đủ cho app chậm? | Tăng nếu app khởi động chậm hơn 30 giây |

---

## 7. Checklist 6: Module Variable chưa bind

| # | Kiểm tra | Cách kiểm tra | Ghi chú |
|---|----------|--------------|---------|
| 1 | Tên cột CSV khớp variable? | So sánh CSV header vs `.rxrec` variable name | Case-sensitive, không có space thừa |
| 2 | `.rxtst` có `missingdatabinding`? | Mở `.rxtst` → search "missingdatabinding" | Tag này = chưa cấu hình binding |
| 3 | Connector trỏ đúng file? | `.rxtst` → data connector path | Đường dẫn absolute có thể sai trên máy khác |
| 4 | Default value có đúng? | `.rxrec` → xem default value của variable | Nếu không bind, module dùng default |

### Dấu hiệu Data Binding không hoạt động

```
✅ Binding OK:
- Module chạy N lần (N = số row CSV)
- Log hiển thị giá trị khác nhau mỗi lần chạy

❌ Binding FAIL:
- Module chỉ chạy 1 lần
- Giá trị variable là default (empty string hoặc hardcoded)
- Report warning: "variable not bound to data column"
```

> Evidence: `.claude/rules/data_binding.md` — bảng kiểm tra binding.

---

## 8. Checklist 7: Recording vs UserCode Conflict

| # | Kiểm tra | Cách kiểm tra | Ghi chú |
|---|----------|--------------|---------|
| 1 | Init() có ngăn recording? | **KHÔNG THỂ** — Init() chạy trước nhưng recording vẫn chạy sau | Dùng UserCode module riêng nếu cần skip |
| 2 | Sửa đúng flow chưa? | Grep → method đó gọi từ đâu? | TryLoginWithUser ≠ Login_Pass recording |
| 3 | File đang sửa có phải UserCode? | Tên file kết thúc bằng `.UserCode.cs`? | `.cs` (không có UserCode) = auto-generated |

### Recording vs UserCode — Khi nào conflict

```
Login_Pass.cs (auto-generated)         Login_Pass.UserCode.cs (custom)
│                                       │
├── void Run()                          ├── void Init()
│   ├── Init() ←─────────────────────── │   ├── Kiểm tra đã login?
│   ├── Click SomeText("47;2")          │   └── Log thông tin
│   ├── Press(UserName)                 │
│   ├── Click XPWWatermark("36;6")      ├── TryLoginWithUser() 
│   ├── Press(Password)                 │   ← Chỉ LoginRetry gọi!
│   ├── Click Login("10;8")             │   ← Login_Pass recording KHÔNG gọi!
│   └── Delay(12000)                    │
│                                       └── IsLoginSuccessful()
│                                           ← Chỉ TryLoginWithUser gọi!
```

> Evidence: `Login_Pass.cs` — recording Run() gọi Init() rồi chạy steps riêng, KHÔNG gọi TryLoginWithUser().

---

## 9. Checklist 8: Pass Manual nhưng Fail Automation

| # | Kiểm tra | Cách kiểm tra | Ghi chú |
|---|----------|--------------|---------|
| 1 | Timing khác nhau? | So sánh tốc độ click manual vs automation | Automation nhanh hơn → element chưa ready |
| 2 | Focus/Active window? | Screenshot → cửa sổ nào đang active? | Click có thể đi vào window sai |
| 3 | Screen resolution? | Kiểm tra resolution Máy A vs Máy B | Resolution khác → coordinates sai |
| 4 | DPI Scaling? | Windows Settings → Display → Scale | 100% vs 125% vs 150% |
| 5 | Accessibility/UI Automation enabled? | Windows Settings → Accessibility | Một số app cần UI Automation service |

### Máy A vs Máy B — Khác biệt phổ biến

| Factor | Máy A (Dev) | Máy B (Test) | Impact |
|--------|-------------|-------------|--------|
| Performance | Nhanh | Có thể chậm hơn | Timeout cần tăng |
| Resolution | 1920×1080 | Có thể khác | Coordinates sai |
| DPI Scale | 100% | Có thể 125% | Element position thay đổi |
| Repository cache | Nhanh | Chậm (~1.5 phút) | Performance issue |
| App version | Latest | Có thể khác | UI elements thay đổi |

> Evidence: `.claude/lessons/login-retry-lesson.md` — "Repository caching trên Máy B — mỗi element mất ~1.5 phút tìm".

---

## 10. Maintenance Mode — Interactive Error Resolution

Ranorex hỗ trợ **Maintenance Mode** khi chạy test từ Ranorex Studio:

| Tình huống | Maintenance Mode cho phép |
|------------|--------------------------|
| Element not found | Pause test → Track element mới → Update RxPath → Resume |
| Unexpected popup | Pause test → Đóng popup thủ công → Resume |
| Wrong value | Pause test → Sửa data → Resume |

### Cách bật

1. Chạy test từ Ranorex Studio (không phải command-line)
2. Khi lỗi xảy ra → Ranorex hiển thị dialog
3. Chọn: Retry / Skip / Edit / Abort
4. **Edit** → mở Spy, track element, sửa RxPath
5. **Retry** → chạy lại step vừa fail

**Lưu ý:** Maintenance Mode chỉ có khi chạy từ Ranorex Studio, KHÔNG có khi chạy từ command-line hoặc CI/CD.

---

## 11. Công cụ Debug

| Công cụ | Mục đích | Khi nào dùng |
|---------|----------|-------------|
| **Ranorex Report** (`.rxlog`) | Xem log, screenshot, timeline | Sau mỗi lần chạy test |
| **Ranorex Spy** | Track element, test RxPath, xem attributes | Khi element not found |
| **Visual Studio Debugger** | Breakpoint, step through code | Khi logic code sai |
| **Task Manager** | Kiểm tra process, memory, CPU | Khi app chậm hoặc hang |
| **Event Viewer** | System errors, app crashes | Khi app crash không có log |

---

## 12. Tham khảo

- [Object not found: RanoreXPath not valid](https://support.ranorex.com/hc/en-us/articles/22975157755277)
- [Troubleshooting: Object not found](https://support.ranorex.com/hc/en-us/articles/38080643131409)
- [Ranorex Spy](https://www.ranorex.com/ranorex-spy/)
- [Maintenance Mode](https://support.ranorex.com/hc/en-us/articles/38079820116625)
- `.claude/lessons/login-retry-lesson.md` (project-specific lessons)
