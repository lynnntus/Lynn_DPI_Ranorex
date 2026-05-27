# Lynn_DPI_AT - Ranorex Automation Test

Project automation test cho ứng dụng desktop Neptune (KohYoung DPI).

## ⛔ LUÔN ÁP DỤNG — Đọc trước khi làm bất cứ điều gì

### File được phép sửa
| File | Ghi chú |
|------|---------|
| `*.UserCode.cs` | Custom logic của từng recording module |
| File `.cs` do Claude Code tự tạo | Các file được Claude Code sinh ra trong quá trình làm việc |
| `.claude/rules/*.md` | Rule files của dự án |

### File KHÔNG được sửa (auto-generated, bị ghi đè bởi Ranorex)
| Loại | Ví dụ |
|------|-------|
| Recording class | `StartAUT.cs`, `Login_Pass.cs`, `Logout.cs`, `Recording1.cs`, `CloseAUT.cs` |
| Repository class | `Lynn_DPI_ATRepository.cs` |
| Extension cấm | `.rxrec`, `.rxrep`, `.rxtst`, `.csproj`, `.rximg` |

### Pattern bắt buộc khi viết UserCode

```csharp
// ✅ ĐÚNG — đọc module variable được Ranorex inject qua data binding
string value = this.VariableName;   // tên khớp với variable trong .rxrec

// ❌ SAI — tự đọc file
string value = File.ReadAllLines("data.csv")[0];

// ❌ SAI — hardcode giá trị
string value = "hardcoded_value";
string path  = @"D:\RanorexProjects\...";

// Ví dụ thực tế — Login_Pass
string user = this.UserName;
string pass = this.Password;
```

### Entry point hợp lệ trong UserCode
- `Init()` — chạy trước recording, gọi custom logic từ đây
- `Finish()` — chạy sau recording, dùng cho cleanup
- Không tạo `Main()` hay entry point nào khác

## Chi tiết theo chủ đề (đọc khi cần)

### Quy tắc
| File | Nội dung |
|------|----------|
| [.claude/rules/safety.md](.claude/rules/safety.md) | Cảnh báo đầy đủ, ví dụ sai/đúng cho từng trường hợp |
| [.claude/rules/coding.md](.claude/rules/coding.md) | Partial class pattern, static vs instance, phạm vi sửa đổi |
| [.claude/rules/testing.md](.claude/rules/testing.md) | Data source CSV, lưu ý phát triển thêm |
| [.claude/rules/data_binding.md](.claude/rules/data_binding.md) | Cấu hình CsvDataConnector, thêm CSV mới, kiểm tra binding |

### Bài học
| File | Nội dung |
|------|----------|
| [.claude/lessons/login-retry-lesson.md](.claude/lessons/login-retry-lesson.md) | Bài học từ debug login: WPF input, call chain, Init() limitations |

### Workflow
| File | Nội dung |
|------|----------|
| [.claude/workflows/build.md](.claude/workflows/build.md) | Lệnh MSBuild, chạy exe, mở Ranorex Studio |
| [.claude/workflows/test-run.md](.claude/workflows/test-run.md) | Cấu trúc test suite, SmokeTest, TestCase, Logout |
| [.claude/workflows/handoff.md](.claude/workflows/handoff.md) | Chuyển giao Máy Test, đường dẫn cần sửa, checklist |

### Context dự án
| File | Nội dung |
|------|----------|
| [.claude/context/project.md](.claude/context/project.md) | Tổng quan, framework, cấu trúc thư mục |
| [.claude/context/modules.md](.claude/context/modules.md) | Danh sách và chi tiết các module hiện có trong dự án |
| [.claude/context/repository.md](.claude/context/repository.md) | Cửa sổ UI Repository, cấu hình Ranorex.rxsettings |
