# Quy tắc an toàn file

## File KHÔNG được sửa (auto-generated bởi Ranorex)

Các file sau do Ranorex tự sinh lại mỗi khi record. Mọi chỉnh sửa sẽ bị ghi đè:

- `StartAUT.cs`
- `Login_Pass.cs`
- `Logout.cs`
- `Recording1.cs`
- `CloseAUT.cs`
- `Lynn_DPI_ATRepository.cs`

## File extension KHÔNG được sửa

| Extension | Lý do |
|-----------|-------|
| `.rxrec` | Recording definition — Ranorex quản lý |
| `.rxrep` | Repository definition — chứa RxPath selector |
| `.rxtst` | Test suite config — quản lý data binding, test hierarchy |
| `.csproj` | Project file — Ranorex quản lý build references |
| `.rximg` | Repository image blob |

## Cảnh báo XPath / RxPath selector

**KHÔNG thay đổi XPath / RxPath selector** trong `Lynn_DPI_ATRepository.rxrep`. Các selector được record từ UI thật của ứng dụng Neptune. Sửa sai sẽ làm test không tìm được element.

## Cảnh báo namespace

**KHÔNG xóa các `using Ranorex.*`** ở đầu file — đây là namespace bắt buộc của Ranorex framework. Các namespace thường gặp:

```csharp
using Ranorex;
using Ranorex.Core;
using Ranorex.Core.Repository;
using Ranorex.Core.Testing;
```

## Cảnh báo: KHÔNG hardcode credentials trong UserCode

```csharp
// ❌ SAI — hardcode phá vỡ data-driven testing và lộ thông tin nhạy cảm
string user = "kyadmin";
string pass = "21077421!";

// ✅ ĐÚNG — để Ranorex inject qua data binding
string user = this.UserName;
string pass = this.Password;
```

Hardcode credentials dẫn đến:
- Test không còn data-driven
- Thông tin nhạy cảm bị lưu trong source code / version control
- Phá vỡ mục đích của CsvDataConnector

## Cảnh báo: KHÔNG dùng đường dẫn tuyệt đối trong UserCode

```csharp
// ❌ SAI — chỉ chạy được trên 1 máy
string path = @"D:\RanorexProjects\Lynn_DPI_AT\TestData.xlsx";

// ✅ ĐÚNG — đường dẫn data source được cấu hình trong Ranorex Studio
// Vào Manage Data Sources, UserCode không tự quản lý đường dẫn
```

Đường dẫn tuyệt đối khiến test không chạy được trên CI/CD hoặc máy khác.
