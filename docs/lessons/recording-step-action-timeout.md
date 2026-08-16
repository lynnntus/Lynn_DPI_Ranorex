# Lesson: Recording Step Action Timeout

> Ngày tạo: 2026-08-16  
> Module: `Verify_ProductionPresettingDialog_AutoClose`

---

## Triệu chứng

- Error: `"Invocation did not finish within the timeout of '00:00:05'"`
- User code method (registered as `userrecorditem` trong `.rxrec`) bị kill sau 5 giây
- Method cần chạy lâu hơn 5s (polling loop, wait dialog close)
- Logic chạy đúng, dialog đóng thành công, nhưng test vẫn FAIL

## Root cause

Khi method được đăng ký là **recording step** (`userrecorditem` trong `.rxrec`), Ranorex gọi nó từ `ITestModule.Run()` với **Action Timeout mặc định 5 giây**.

```csharp
// Auto-generated Run() — KHÔNG sửa được
void ITestModule.Run()
{
    Init();                      // plain method call — KHÔNG có Action Timeout
    ClickApplyWithPolling();     // recording step — 5s Action Timeout
    Delay.Milliseconds(0);
}
```

Method `ClickApplyWithPolling()` cần ~34-60s để hoàn thành → bị Ranorex kill sau 5s.

### Phân biệt `Init()` vs recording step

| | `Init()` | Recording step (`userrecorditem`) |
|---|---|---|
| Gọi từ | `Run()` — plain method call | `Run()` — qua Ranorex action framework |
| Action Timeout | **Không có** | **5s mặc định** (trừ khi override trong .rxrec) |
| Chạy được bao lâu | Không giới hạn | Bị kill nếu vượt timeout |

## Fix chuẩn

**Chuyển toàn bộ logic dài vào `Init()`**, biến recording step thành no-op:

```csharp
private void Init()
{
    Report.Log(ReportLevel.Info, "Module", "Module bat dau.");
    RunLongRunningLogic();  // Chạy trong Init() — không bị Action Timeout
}

// Recording step — phải return trong 5s
public void ClickApplyWithPolling()
{
    Report.Log(ReportLevel.Info, "Module", "Logic da chay trong Init(). Skip.");
}

private void RunLongRunningLogic()
{
    // Toàn bộ logic cũ của recording step method
}
```

### Tại sao hoạt động:
- `Init()` được `Run()` gọi như plain method call → không có Action Timeout
- Recording step method vẫn tồn tại (bắt buộc vì auto-generated `.cs` gọi nó) nhưng return ngay → pass 5s timeout
- Không cần sửa `.rxrec` hay `.cs` auto-generated

## Anti-patterns

| Sai | Đúng |
|-----|------|
| Sửa `.rxrec` để tăng Action Timeout | Chuyển logic vào `Init()` |
| Sửa auto-generated `.cs` | Chỉ sửa `.UserCode.cs` |
| Tách logic thành nhiều recording steps | Gộp vào 1 method private, gọi từ `Init()` |
| Bỏ qua error "Invocation did not finish" | Phân tích xem method nào là recording step |

## Cách nhận biết method là recording step

1. Mở auto-generated `.cs` (ví dụ `Module.cs`)
2. Tìm method trong `ITestModule.Run()`
3. Nếu method được gọi trực tiếp trong `Run()` (không phải từ `Init()`) → đó là recording step
4. Confirm trong `.rxrec`: tìm tag `<userrecorditem>` chứa tên method

## Tiền lệ trong dự án

- `Login_Pass` module: logic nặng (`WaitForLoginWindowReady()`) chạy trong `Init()`, recording steps chỉ xử lý UI interactions ngắn
- `OpenFile` modules: `OpenRecipeFileByPath()` là recording step nhưng hoàn thành nhanh → chưa gặp vấn đề (nhưng vulnerable nếu app chậm)

## Áp dụng khi nào

- Error message chứa `"Invocation did not finish within the timeout"`
- User code method cần chạy > 5s (polling, wait, retry loop)
- Method được gọi từ `Run()` như recording step
