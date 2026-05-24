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
