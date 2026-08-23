# Lesson: ApplicationNotRespondingException — ANR State Cascade

> Ngày tạo: 2026-08-23

---

## Triệu chứng

1. **Nhiều module FAIL liên tiếp** — module A FAIL, module B bắt đầu ngay (~100ms sau) rồi cũng FAIL
2. **Log chứa `"Invocation did not finish within the timeout of '00:00:05'"`** — thời gian 5s cách đều giữa các operation
3. **`Exists(0)` block 5s** thay vì return ngay lập tức
4. **Module B FAIL vì state/dialog từ module A chưa cleanup** — ví dụ dialog còn mở, app chưa responsive

## Root cause

**ApplicationNotRespondingException** — OS-level app hung state.

Khi ứng dụng bị Not Responding (OS-level hung):
- **MỌI** UI interaction (`Exists`, `Click`, property access, `WaitForNotExists`) đều block 5s rồi throw `ApplicationNotRespondingException`
- Message: `"Invocation did not finish within the timeout of '00:00:05'"` — đây là Ranorex/OS ANR timeout, **KHÔNG phải** Recording Step Action Timeout
- App có thể tự hồi phục sau vài giây (~7s theo observation)

### Cascade pattern

```
Module A: Click button → App hung → polling loop KHÔNG catch ANR
→ Exists(0) throw → Module A FAIL → dialog/state chưa cleanup
→ (102ms)
→ Module B: start → Exists(0) throw → FAIL cascade
```

**Cascade xảy ra vì 2 lý do:**
1. Module A **không catch** ANR trong polling/wait loop → crash thay vì retry → dialog/state chưa cleanup
2. Module B **không kiểm tra** app trạng thái responsive trước khi bắt đầu → gặp ANR ngay lập tức

## Phân biệt với Recording Step Action Timeout

| Đặc điểm | ANR (lesson này) | Recording Step Action Timeout |
|-----------|-------------------|-------------------------------|
| Exception | `ApplicationNotRespondingException` | `ActionTimeoutException` |
| Message | "Invocation did not finish within the timeout of '00:00:05'" | "Invocation did not finish within the timeout of '00:00:05'" |
| Nguyên nhân | App bị OS-level hung | User code chạy quá 5s trong recording step |
| Ảnh hưởng | MỌI UI operation block 5s | Chỉ method đang chạy bị kill |
| Fix | Catch ANR + retry + cleanup | Chuyển logic vào Init() |

> **Lưu ý:** Message giống nhau nhưng exception type khác. Kiểm tra `ex.GetType().Name.Contains("ApplicationNotResponding")`.

## Fix chuẩn

### 1. Module gây app hung — catch ANR trong polling loop

```csharp
while (sw.ElapsedMilliseconds < TIMEOUT_MS)
{
    try
    {
        if (!element.Exists(0))
        {
            // done
            break;
        }
    }
    catch (Exception ex)
    {
        if (!ex.GetType().Name.Contains("ApplicationNotResponding"))
            throw;

        Report.Log(ReportLevel.Warn, "Module",
            "[APP_NOT_RESPONDING] App hung khi polling — cho recovery...");
        Thread.Sleep(3000);  // Thread.Sleep, KHÔNG Delay.Milliseconds
        continue;
    }
    Delay.Milliseconds(500);
}
```

### 2. Module gây app hung — try-finally cleanup

```csharp
try
{
    // main logic
}
finally
{
    CleanupLeftoverDialog();
}
```

`CleanupLeftoverDialog()` đóng dialog còn mở bằng `Escape` hoặc `Close()`, bọc trong try-catch.

### 3. Module sau — WaitForAppResponsive() trong Init()

```csharp
private void Init()
{
    WaitForAppResponsive();
    CleanupDialog();
    // ... main flow
}

private void WaitForAppResponsive()
{
    var sw = System.Diagnostics.Stopwatch.StartNew();
    while (sw.ElapsedMilliseconds < APP_RESPONSIVE_TIMEOUT_MS)
    {
        try
        {
            if (someElement.Exists(0))
            {
                Report.Log(ReportLevel.Info, "Module",
                    "App responsive.");
                return;
            }
        }
        catch (Exception ex)
        {
            if (!ex.GetType().Name.Contains("ApplicationNotResponding"))
                throw;

            Report.Log(ReportLevel.Warn, "Module",
                "[APP_NOT_RESPONDING] App chua responsive — cho...");
        }
        Thread.Sleep(APP_RESPONSIVE_RETRY_WAIT_MS);
    }
    Report.Log(ReportLevel.Warn, "Module",
        "App van chua responsive — tiep tuc, co the fail.");
}
```

### 4. Module sau — retry loop cho action chính

```csharp
for (int attempt = 0; attempt <= MAX_RETRIES; attempt++)
{
    try
    {
        element.Click();
        break;  // success
    }
    catch (Exception ex)
    {
        if (!ex.GetType().Name.Contains("ApplicationNotResponding"))
            throw;

        Report.Log(ReportLevel.Warn, "Module",
            string.Format("[APP_NOT_RESPONDING] attempt {0}/{1}",
                attempt + 1, MAX_RETRIES + 1));
        if (attempt < MAX_RETRIES)
            Thread.Sleep(WAIT_MS);
    }
}
```

## Lưu ý quan trọng

### Thread.Sleep vs Delay.Milliseconds trong ANR catch

- **`Thread.Sleep`** = pure .NET sleep, zero AUT dependency — **ĐÚNG** trong ANR catch
- **`Delay.Milliseconds`** = Ranorex delay, có thể interact với AUT — **TRÁNH** trong ANR catch vì app đang hung

### Log pattern

Dùng tag `[APP_NOT_RESPONDING]` (ReportLevel.Warn) mỗi khi catch ANR — dễ tìm trong report.
Dùng tag `[CLEANUP]` cho cleanup actions.

### App recovery time

Theo observation, app Neptune tự hồi phục ~7s sau ANR. Constants phù hợp:
- `ANR_RECOVERY_WAIT_MS = 3000` cho polling loop
- `APP_RESPONSIVE_RETRY_WAIT_MS = 5000` cho WaitForAppResponsive
- `CLICK_ANR_WAIT_MS = 5000` cho click retry

## Ví dụ thực tế

**File affected:**
- `Verify_ProductionPresettingDialog_AutoClose.UserCode.cs` — BUOC 3b catch ANR + finally CleanupLeftoverDialog
- `OpenFile_FromProduction.UserCode.cs` — Init() WaitForAppResponsive + CleanupDialog + Buoc 1 retry loop

**Scenario:** Verify click Apply → app hung → Verify BUOC 3b polling Exists(0) catch ANR + retry → app hồi phục → dialog đóng. Nếu app vẫn hung khi Verify kết thúc → finally CleanupLeftoverDialog đóng dialog. OpenFile bắt đầu → Init() WaitForAppResponsive chờ app → Init() CleanupDialog dọn dialog còn mở → Buoc 1 retry click với ANR catch.
