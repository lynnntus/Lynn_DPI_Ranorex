# Hướng dẫn Data Binding trong Ranorex

## Tổng quan

Data binding cho phép module chạy lặp với nhiều bộ dữ liệu mà không cần sửa code.
Ranorex tự inject giá trị từ CSV vào module variable trước mỗi lần chạy.

## Cách hoạt động

```
<TenFile>.csv
  Row 1: <data1>  →  Ranorex inject  →  <Module> chạy lần 1
  Row 2: <data2>  →  Ranorex inject  →  <Module> chạy lần 2
```

1. Ranorex đọc CSV theo từng row
2. Mỗi row → chạy module 1 lần, inject giá trị vào module variables
3. UserCode nhận giá trị qua `this.VariableName`

## Cấu hình trong Ranorex Studio (áp dụng cho mọi module)

1. Mở file `.rxtst` → chọn module cần bind
2. Tab **"Data source"** → chọn connector tương ứng
3. Tab **"Data binding"** → map từng cột CSV → module variable
4. Tab **"Iterations"** → chọn `All rows`

## Thêm data source mới

1. Tạo file CSV mới với header khớp tên module variable
2. Ranorex Studio → Manage Data Sources → Add connector → trỏ đến file CSV
3. Bind connector vào module trong `.rxtst`
4. Không sửa bất kỳ file `.cs` nào

## Kiểm tra binding có hoạt động

| Dấu hiệu trong Ranorex Report | Ý nghĩa |
|-------------------------------|---------|
| Module chạy N lần (N = số row CSV) | ✅ Binding hoạt động đúng |
| Module chỉ chạy 1 lần với giá trị default | ❌ Chưa cấu hình binding |
| Warning "variable not bound to data column" | ❌ Tên cột CSV không khớp tên variable |

## Tên cột CSV phải khớp chính xác với module variable

```
Header CSV:               <ColumnName>
Module variable (.rxrec): <ColumnName>
                           ↑ phân biệt hoa/thường, không có khoảng trắng thừa
```

## File CSV hiện tại của dự án

| File CSV | Connector | Module | Cột |
|----------|-----------|--------|-----|
| `Users_DataSource.csv` | `NewConnector - CsvDataConnector` | `Login_Pass` | `UserName`, `Password` |

> Khi thêm module mới cần data-driven: thêm dòng vào bảng này để tracking.
