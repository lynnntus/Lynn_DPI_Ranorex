# Chi tiết Recording Modules

## StartAUT — Khởi chạy ứng dụng

- Chạy `C:\Kohyoung\AOI\AOIGUI.exe`
- Lưu Process ID vào biến `StartAutProcessIDVar` để dùng khi đóng app

## Login_Pass — Đăng nhập

- Click vào ô username (`xID`), nhập `$UserName`
- Click vào ô password (`xPWWatermark`), nhập `$Password`
- Click nút `Login`
- Chờ 12 giây delay cứng + 20 giây `WaitForExists` cho `CCIMainWindow`
- Validate text `"Create or open recipe."` để xác nhận đăng nhập thành công
- Chụp screenshot

## LoginRetry — Login retry (Custom UserCode module)

- Chờ login window xuất hiện (30s timeout)
- Gọi `Login_Pass.LoginWithAllUsersFromDataSource()` — đọc Excel, thử từng credential
- Nếu thành công: validate "Create or open recipe.", chụp screenshot
- Nếu thất bại: throw `ValidationException`
- Tự đọc Excel qua OleDb, không dùng data binding của Ranorex

## Recording1 — Test chính

- **Hiện đang trống** — chỉ có khung, chưa có action nào

## Logout — Đăng xuất

- Click button trên title bar (`CCIMainWindow.SomeButton`)
- Click `BtnDualClose` trên dialog `InspectionRegionSettings`
- Validate folder `Export_Lynn` trong Explorer
- Chụp screenshot

## CloseAUT — Đóng ứng dụng

- Đóng app bằng `CloseAutProcessIDVar` (Process ID từ StartAUT)
- Timeout đóng: 500ms
