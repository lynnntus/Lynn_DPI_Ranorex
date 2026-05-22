# Cấu trúc Test Suite & Cách chạy

## Cấu trúc Test Suite

```
Lynn_DPI_AT (Test Suite)
└── Lynn_DPI_AT (Test Case chính)
    ├── TestCase                        # Test flow đầy đủ
    │   ├── setup    → StartAUT         # Mở app
    │   ├── Recording1                  # Test chính (đang trống)
    │   └── teardown → CloseAUT         # Đóng app
    │
    ├── SmokeTest                       # Smoke test login
    │   ├── StartAUT                    # Mở app
    │   ├── LoginRetry                  # Login retry (đọc Excel, thử từng user)
    │   ├── Users (Smart Folder, rỗng)  # Không còn chứa module
    │   └── Logout (disabled)           # Đăng xuất (đang tắt)
    │
    └── Logout                          # Test đăng xuất riêng
        └── Logout module
```

## Giải thích

- **TestCase**: Flow test đầy đủ với setup/teardown. `Recording1` đang trống, chờ thêm action.
- **SmokeTest**: Chỉ test đăng nhập. `LoginRetry` tự đọc Excel và retry từng credential. Smart Folder `Users` hiện rỗng (không chứa module con).
- **Logout**: Test đăng xuất riêng biệt.
