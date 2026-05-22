# Quy tắc sửa code Ranorex

## Nguyên tắc cơ bản

**Đây là project Ranorex, KHÔNG phải .NET thông thường** — cấu trúc file, build system, và runtime đều do Ranorex quản lý.

## CHỈ sửa file `*.UserCode.cs`

Mỗi recording module có pattern partial class:
- `Module.cs` — **auto-generated**, KHÔNG sửa
- `Module.UserCode.cs` — **custom logic**, an toàn để sửa

### File an toàn để sửa

| File | Loại |
|------|------|
| `StartAUT.UserCode.cs` | UserCode |
| `Login_Pass.UserCode.cs` | UserCode |
| `Recording1.UserCode.cs` | UserCode |
| `Logout.UserCode.cs` | UserCode |
| `CloseAUT.UserCode.cs` | UserCode |
| `LoginRetry.cs` | Custom UserCode module (`ModuleType.UserCode`) |

### File KHÔNG được sửa

| File | Lý do |
|------|-------|
| `StartAUT.cs` | Auto-generated từ `StartAUT.rxrec` |
| `Login_Pass.cs` | Auto-generated từ `Login_Pass.rxrec` |
| `Logout.cs` | Auto-generated từ `Logout.rxrec` |
| `Recording1.cs` | Auto-generated từ `Recording1.rxrec` |
| `CloseAUT.cs` | Auto-generated từ `CloseAUT.rxrec` |
| `Lynn_DPI_ATRepository.cs` | Auto-generated từ `Lynn_DPI_ATRepository.rxrep` |

## Phạm vi sửa đổi

**Chỉ sửa logic test**, không sửa cấu trúc project (`.csproj`, `.rxtst`, `.rxrep`, `.rxrec`).
