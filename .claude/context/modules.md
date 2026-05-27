# Chi tiết Recording Modules

## StartAUT — Khởi chạy ứng dụng

- Chạy `C:\Kohyoung\AOI\AOIGUI.exe`
- Lưu Process ID vào biến `StartAutProcessIDVar` để dùng khi đóng app
- Init() gọi `LoginRetry.ResetState()` để reset static state cho mỗi lần chạy mới

## Login_Pass — Đăng nhập (Recording module)

- Click vào ô username (`xID`), nhập `$UserName`
- Click vào ô password (`xPWWatermark`), nhập `$Password`
- Click nút `Login`
- Delay 30s cứng + WaitForExists 50s cho `CCIMainWindow` (tổng ~80s)
- Validate text `"Create or open recipe."` để xác nhận đăng nhập thành công
- Chụp screenshot
- Default credentials trong constructor: lynn/1234
- **Lưu ý:** Init() có skip check nếu CCIMainWindow đã tồn tại, nhưng recording steps vẫn chạy (Ranorex limitation R3)

### UserCode helpers (Login_Pass.UserCode.cs)

| Method | Loại | Mô tả |
|--------|------|-------|
| `Init()` | Instance | Skip check nếu đã login, gọi WaitForLoginWindowReady() |
| `WaitForLoginWindowReady()` | Instance | Smart wait cho login window + login field (80s + 10s) |
| `TryLoginWithUser(user, pass)` | Static | Clear + type credentials + click Login + check success |
| `IsLoginSuccessful()` | Static | Exists(80s) cho CCIMainWindow |
| `TypeIntoUserField(value)` | Static | {Home}{Shift+End}{Delete} + type (WPF-safe) |
| `TypeIntoPasswordField(pass)` | Static | {Home}{Shift+End}{Delete} + type (WPF-safe) |
| `ClearLoginFields()` | Static | Clear cả 2 field |

### Constants

| Constant | Giá trị | Dùng cho |
|----------|---------|----------|
| `LOGIN_WINDOW_TIMEOUT_MS` | 80,000ms | Wait login window |
| `LOGIN_FIELD_TIMEOUT_MS` | 10,000ms | Wait login field |
| `MAIN_WINDOW_TIMEOUT_MS` | 80,000ms | Wait main window sau login |

## LoginRetry — Login retry (Custom UserCode module)

- Iterates CSV rows qua Ranorex data binding (SmartFolder "Users")
- Mỗi row: gọi `Login_Pass.TryLoginWithUser(UserName, Password)`
- Nếu thành công: set `Login_Pass.Instance.UserName/Password`, đặt `credentialFound = true`
- Nếu thất bại: gọi `Login_Pass.ClearLoginFields()`, tiếp tục row tiếp theo
- Static `credentialFound` flag skip các rows còn lại sau khi login thành công
- `ResetState()` method reset credentialFound, được gọi từ StartAUT.Init()

## Recording1 — Test chính

- **Hiện đang trống** — chỉ có khung, chưa có action nào

## Logout — Đăng xuất

- Click button trên title bar (`CCIMainWindow.SomeButton`)
- Click `BtnDualClose` trên dialog `InspectionRegionSettings`
- Validate folder `Export_Lynn` trong Explorer
- Chụp screenshot
- **Lưu ý:** Đang disabled trong SmokeTest (`enabled="False"` trong `.rxtst`)

## CloseAUT — Đóng ứng dụng

- Đóng app bằng `CloseAutProcessIDVar` (Process ID từ StartAUT)
- Timeout đóng: 500ms
