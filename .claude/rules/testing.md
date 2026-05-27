# Quy tắc test & dữ liệu

## Data Source dùng trong test

Data source được quản lý qua **Ranorex CsvDataConnector**, cấu hình trong `.rxtst`.
Mỗi module có thể bind một file CSV riêng.

| Thành phần | Mô tả |
|-----------|-------|
| Connector type | `CsvDataConnector` |
| Cấu hình tại | Ranorex Studio → Manage Data Sources |
| Cột bắt buộc | Phải khớp **chính xác** với tên module variable trong `.rxrec` |

### Ví dụ hiện tại

| File CSV | Connector name | Module | Cột |
|----------|---------------|--------|-----|
| `Users_DataSource.csv` | `NewConnector - CsvDataConnector` | `Login_Pass` | `UserName`, `Password` |

> Khi thêm test data mới: thêm file CSV → tạo connector trong Ranorex Studio
> → bind vào module tương ứng trong `.rxtst`. Không sửa code.

## Lưu ý khi phát triển thêm

- `Recording1` đang trống — đây là nơi cần thêm test action chính cho inspection flow
- Data source được quản lý qua CsvDataConnector — thêm file CSV mới và bind trong Ranorex Studio, không sửa code
- Module `Logout` trong SmokeTest đang bị **disabled** (`enabled="False"` trong `.rxtst`)
- Biến `AppProcessID` truyền từ `StartAUT` → `CloseAUT` qua test case parameter — nếu thêm test case mới cần bind lại biến này
- Tất cả search timeout trong repository đều là 30,000ms (30 giây) — đủ cho app Neptune khởi động chậm

## Bài học từ login automation

> Nguồn: [.claude/lessons/login-retry-lesson.md](../lessons/login-retry-lesson.md)

### R1: WPF ComboBox — dùng `{Home}{Shift+End}{Delete}` thay `{Ctrl+A}`
`Ctrl+A` bị WPF custom control intercept ở control level. Pattern `{Home}{Shift+End}{Delete}` hoạt động ở text cursor level, đáng tin cậy hơn.

### R2: Kiểm tra call chain trước khi sửa hàm
Trước khi sửa method, dùng `Grep` xác nhận method đó thực sự được gọi trong flow đang debug. Ví dụ: `TryLoginWithUser()` chỉ được `LoginRetry.cs` gọi, không phải `Login_Pass` recording.

### R3: Init() không thể skip recording steps
`Init()` chạy TRƯỚC recording steps nhưng không thể ngăn recording chạy. Chỉ có thể thêm logic bổ sung (log, check điều kiện), không thể thay thế flow auto-generated.

### R4: Thêm log entry point khi debug flow
Luôn thêm `Report.Log` ở đầu hàm (ví dụ `"BAT DAU CHAY VAO HAM..."`) để xác nhận hàm có được gọi hay không.

### R5: Login_Pass recording và TryLoginWithUser là 2 flow độc lập
Sửa `TryLoginWithUser()` không ảnh hưởng Login_Pass recording và ngược lại. Cần xác định đúng flow nào đang chạy trước khi debug.
