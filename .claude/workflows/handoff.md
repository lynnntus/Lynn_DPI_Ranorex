# Chuyển giao sang Máy Test

## Đường dẫn absolute cần cập nhật

| Đường dẫn hardcode | File | Cần sửa? |
|--------------------|------|----------|
| `D:\RanorexProjects\Lynn_DPI_AT\TestData.xlsx` | `Login_Pass.UserCode.cs` dòng 30-31 | **CÓ** — phải khớp vị trí thực tế trên Máy Test |
| `D:\RanorexProjects\Lynn_DPI_AT\TestData.xlsx` | `Lynn_DPI_AT.rxtst` datasource | CÓ — cần update trong Ranorex Studio |
| `C:\Kohyoung\AOI\AOIGUI.exe` | `StartAUT.cs` (auto-generated) | Chỉ đúng nếu Máy Test cài Neptune ở cùng đường dẫn |

## Checklist trước khi chạy trên Máy Test

1. Copy toàn bộ thư mục `Lynn_DPI_AT\` (solution folder) sang Máy Test
2. Đảm bảo `TestData.xlsx` nằm đúng đường dẫn hoặc sửa path trong `Login_Pass.UserCode.cs`
3. Đảm bảo `TestData.xlsx` sheet "Login" có ít nhất 1 dòng credential
4. Đảm bảo Neptune (`AOIGUI.exe`) đã cài tại `C:\Kohyoung\AOI\AOIGUI.exe`
5. Mở `Lynn_DPI_AT.rxsln` bằng Ranorex Studio trên Máy Test
6. Chọn test case cần chạy → bấm Run

## Yêu cầu phần mềm trên Máy Test

- Ranorex Studio 10.7+
- Microsoft ACE OLEDB 12.0 provider (để đọc Excel qua OleDb)
- .NET Framework 4.8
- Neptune (AOIGUI.exe) đã cài và chạy được

## Nếu build lỗi trên Máy Test

- Kiểm tra Ranorex Studio version (cần 10.7+)
- Kiểm tra `System.Data` reference
- Kiểm tra Microsoft ACE OLEDB 12.0 provider đã cài chưa
