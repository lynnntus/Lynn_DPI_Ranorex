# UI Repository & Cấu hình

## UI Repository — 5 cửa sổ ứng dụng

Repository (`Lynn_DPI_ATRepository`) quản lý UI element qua RxPath:

| Tên trong repo              | RxPath gốc                        | Vai trò                    |
|-----------------------------|------------------------------------|----------------------------|
| `CCILoginWindow`            | `/form[@name='View']`              | Màn hình đăng nhập         |
| `CCIMainWindow`             | `/form[@title='CCIMainWindow']`    | Cửa sổ chính sau login     |
| `InspectionRegionSettings`  | `/form[@name='Popup']`             | Dialog cài đặt             |
| `LynnDPIAT`                | `/form[@title='Lynn_DPI_AT']`      | Cửa sổ Ranorex runtime     |
| `Explorer`                  | `/desktop[@processname='explorer']`| File Explorer (validate export) |

## Cấu hình quan trọng (Ranorex.rxsettings)

- **Search timeout mặc định**: 10,000ms (10 giây)
- **Keyboard pre-delay**: 150ms
- **Mouse move time**: 300ms
- **Validate**: fail on mismatch, screenshot khi lỗi
- **Report**: sinh file `%S_%Y%M%D_%T.rxlog` trong thư mục `Reports/`
