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

## Cách dùng Module Variable trong UserCode

Ranorex inject module variable vào partial class thông qua `.rxrec`.
Trong UserCode, truy cập trực tiếp bằng `this.VariableName`
(tên khớp với variable khai báo trong `.rxrec` của module đó):

```csharp
// ✅ ĐÚNG — pattern tổng quát
string value = this.VariableName;

// ❌ SAI — tự đọc file, phá vỡ data binding
string value = ReadFromFile();
string value = File.ReadAllLines("data.csv")[0];
```

Khi data source được bind trong `.rxtst`, Ranorex tự inject giá trị đúng
vào từng biến trước mỗi lần chạy module.
**UserCode KHÔNG cần và KHÔNG được tự đọc data.**

### Ví dụ thực tế — module Login_Pass

```csharp
// Variable UserName và Password khai báo trong Login_Pass.rxrec
string user = this.UserName;
string pass = this.Password;
```

## Entry Point trong UserCode

| Method | Khi nào chạy | Dùng để |
|--------|-------------|---------|
| `Init()` | Trước khi recording chạy | Khởi tạo, gọi custom logic |
| `Finish()` | Sau khi recording chạy | Cleanup, teardown |
| Custom methods | Được gọi từ `Init()` / `Finish()` | Tách logic phức tạp |

Không tạo `Main()` hay bất kỳ entry point nào khác.

## Static vs Instance method

- **Instance method** (không có `static`): khi cần truy cập `this.VariableName`,
  `repo.*` — phổ biến nhất trong UserCode
- **Static method**: chỉ khi method hoàn toàn không cần `this`

Lỗi thường gặp: khai báo `static` rồi không truy cập được module variable
vì `this` không có trong static context.
