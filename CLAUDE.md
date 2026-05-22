# Lynn_DPI_AT - Ranorex Automation Test

Project automation test cho ứng dụng desktop Neptune (KohYoung DPI). Chi tiết được tách thành các file trong `.claude/`.

## Quy tắc (Rules)

| File | Nội dung |
|------|----------|
| [.claude/rules/safety.md](.claude/rules/safety.md) | File KHÔNG được sửa, extension cấm, cảnh báo XPath/namespace |
| [.claude/rules/coding.md](.claude/rules/coding.md) | Chỉ sửa `*.UserCode.cs`, partial class pattern, phạm vi sửa đổi |
| [.claude/rules/testing.md](.claude/rules/testing.md) | File Excel, data binding, CSV, lưu ý phát triển thêm |

## Workflow

| File | Nội dung |
|------|----------|
| [.claude/workflows/build.md](.claude/workflows/build.md) | Lệnh MSBuild, chạy exe, mở Ranorex Studio |
| [.claude/workflows/test-run.md](.claude/workflows/test-run.md) | Cấu trúc test suite, SmokeTest, TestCase, Logout |
| [.claude/workflows/handoff.md](.claude/workflows/handoff.md) | Chuyển giao Máy Test, đường dẫn cần sửa, checklist |

## Context dự án

| File | Nội dung |
|------|----------|
| [.claude/context/project.md](.claude/context/project.md) | Tổng quan, framework, cấu trúc thư mục |
| [.claude/context/modules.md](.claude/context/modules.md) | Chi tiết 6 module: StartAUT, Login_Pass, LoginRetry, Recording1, Logout, CloseAUT |
| [.claude/context/repository.md](.claude/context/repository.md) | 5 cửa sổ UI Repository, cấu hình Ranorex.rxsettings |
