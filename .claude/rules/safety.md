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
