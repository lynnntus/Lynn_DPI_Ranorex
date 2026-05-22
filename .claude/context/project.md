# Tổng quan dự án

## Thông tin chung

Project automation test cho ứng dụng desktop **Neptune** (hệ thống kiểm tra DPI của KohYoung).
Dùng Ranorex Studio để record thao tác UI và chạy test tự động, viết bằng C#.

- **Framework**: Ranorex 10.7, .NET Framework 4.8, C#
- **Platform**: x86 (32-bit) — bắt buộc, không đổi sang x64
- **IDE**: Ranorex Studio (mở file `Lynn_DPI_AT.rxsln`)
- **Ứng dụng test (AUT)**: `C:\Kohyoung\AOI\AOIGUI.exe`

## Cấu trúc thư mục

```
Lynn_DPI_AT/                            # Gốc repo
└── Lynn_DPI_AT/                        # Solution folder
    ├── Lynn_DPI_AT.rxsln               # File solution Ranorex
    ├── Lynn_DPI_AT.sln                 # File solution tương thích VS
    ├── Ranorex.rxsettings              # Cấu hình timeout, recorder
    ├── TestData.xlsx                   # DỮ LIỆU TEST (xem rules/testing.md)
    └── Lynn_DPI_AT/                    # Thư mục C# project
        ├── Lynn_DPI_AT.csproj
        ├── Lynn_DPI_AT.rxtst           # Định nghĩa test suite & data binding
        ├── Lynn_DPI_ATRepository.rxrep # Kho UI element (RxPath selector)
        ├── Lynn_DPI_ATRepository.cs    # [TỰ SINH] C# code cho repository
        ├── Users_DataSource.csv        # CSV data source (header only, chưa có data)
        ├── Program.cs                  # Entry point — gọi TestSuiteRunner
        │
        │   --- Recording modules (mỗi module = 3 file) ---
        ├── StartAUT.rxrec / .cs / .UserCode.cs     # Khởi chạy AOIGUI.exe
        ├── Login_Pass.rxrec / .cs / .UserCode.cs    # Đăng nhập
        ├── Recording1.rxrec / .cs / .UserCode.cs    # Test chính (đang trống)
        ├── Logout.rxrec / .cs / .UserCode.cs        # Đăng xuất + validate export
        ├── CloseAUT.rxrec / .cs / .UserCode.cs      # Đóng app theo Process ID
        ├── LoginRetry.cs                             # Custom UserCode module (login retry)
        └── Reports/                                  # Kết quả test (*.rxlog)
```
