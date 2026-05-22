# Quy tắc test & dữ liệu

## File Excel dùng trong test

**File**: `Lynn_DPI_AT/TestData.xlsx` — Sheet `Login`

| Cột  | Ý nghĩa      | Ví dụ  |
|------|---------------|--------|
| User | Tên đăng nhập | lynn   |
| Pass | Mật khẩu      | 1234   |

### Cách hoạt động

- Trong `.rxtst`, data source `Users` trỏ đến `TestData.xlsx`, sheet `Login`
- Module `Login_Pass` bind biến `UserName` ← cột `User`, `Password` ← cột `Pass`
- Test chạy lặp theo từng dòng trong Excel (data-driven)
- Nếu không có data binding, dùng giá trị mặc định: `lynn` / `1234`
- Ngoài ra còn có `Users_DataSource.csv` (hiện chỉ có header, chưa có data)

### Lưu ý đường dẫn

Đường dẫn Excel trong `.rxtst` đang trỏ `D:\RanorexProjects\...` — nếu chạy từ máy khác cần cập nhật path trong Ranorex Studio.

## Lưu ý khi phát triển thêm

- `Recording1` đang trống — đây là nơi cần thêm test action chính cho inspection flow
- `Users_DataSource.csv` chỉ có header — cần thêm data nếu muốn dùng CSV thay Excel
- Module `Logout` trong SmokeTest đang bị **disabled** (`enabled="False"` trong `.rxtst`)
- Biến `AppProcessID` truyền từ `StartAUT` → `CloseAUT` qua test case parameter — nếu thêm test case mới cần bind lại biến này
- Tất cả search timeout trong repository đều là 30,000ms (30 giây) — đủ cho app Neptune khởi động chậm
