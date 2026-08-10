# Lesson: Dialog Close — Polling thay vì Fixed Wait

> **Ngày ghi nhận:** 2026-07-20  
> **Module:** OpenFile_FromProduction  
> **Session/HANDOFF liên quan:** `docs/HANDOFF.md` (Bug 4), commit `6581d17`

---

## Trigger

Khi click một button (ví dụ Apply, Open, OK) trong dialog và cần verify dialog đã đóng, nhưng test báo dialog vẫn mở dù UI cho thấy app đang xử lý (loading/processing).

## KHÔNG áp dụng khi

- Dialog thực sự không đóng vì click button thất bại — xem HANDOFF.md Bug 1 (Use Cache issue).
- `WaitForNotExists` trả kết quả sai vì path collision — xem [generic-popup-path-collision.md](generic-popup-path-collision.md).
- App treo/crash (không phải loading chậm).

## Triệu chứng

1. Click Apply/Open thành công (button nhận click, app bắt đầu processing).
2. Dialog chuyển sang trạng thái "Please Wait" hoặc loading indicator xuất hiện.
3. Code chờ fixed time (ví dụ 3 giây), sau đó check dialog → vẫn mở → test FAIL.
4. Nếu chờ đủ lâu (30-60 giây), dialog sẽ tự đóng khi app xử lý xong.
5. Test chạy lại cùng data — thời gian đóng dialog khác nhau mỗi lần (không ổn định).

## Nguyên nhân gốc

App xử lý background task (load recipe file, apply settings) mất thời gian không cố định. Fixed wait (`Thread.Sleep(3000)` hoặc `Delay.Milliseconds(3000)`) quá ngắn cho trường hợp file lớn hoặc hệ thống chậm.

**Ví dụ thực tế:** `OpenFile_FromProduction` click Apply → app load jobfile. Constant `DIALOG_CLOSE_CHECK_MS = 3000` (3 giây) quá ngắn — app cần 30-60 giây để load. Code tưởng click thất bại → nhảy sang strategy tiếp → gây confusion trong log.

## Cách xác minh

1. Chạy test, quan sát UI trên máy test: sau khi click button, dialog có chuyển sang trạng thái loading không?
2. Nếu có → đợi thủ công (1-2 phút) xem dialog có tự đóng không.
3. Nếu dialog tự đóng sau 30-60 giây → confirm đây là timing issue, không phải click failure.
4. Kiểm tra code: tìm `Thread.Sleep`, `Delay.Milliseconds`, hoặc constant timeout ngắn (< 10s) sau click action.

## Fix chuẩn

**Thay fixed wait bằng polling loop với timeout đủ lớn:**

```csharp
// ❌ SAI — fixed wait quá ngắn, không thích ứng
btn.Click();
Delay.Milliseconds(3000);
if (dialogInfo.Exists(0)) { /* tưởng click thất bại */ }

// ✅ ĐÚNG — polling loop, log progress, timeout đủ lớn
btn.Click();
WaitForDialogClose(maxWaitMs: 60000, pollIntervalMs: 2000, logIntervalMs: 10000);
```

**Pattern `WaitForDialogClose()`:**

```csharp
private bool WaitForDialogClose(int maxWaitMs, int pollIntervalMs, int logIntervalMs)
{
    var sw = System.Diagnostics.Stopwatch.StartNew();
    int lastLogSec = 0;

    while (sw.ElapsedMilliseconds < maxWaitMs)
    {
        if (!dialogInfo.Exists(0))
        {
            Report.Log(ReportLevel.Success, "Module",
                string.Format("Dialog da dong sau {0:F1}s.", sw.ElapsedMilliseconds / 1000.0));
            return true;
        }

        int elapsedSec = (int)(sw.ElapsedMilliseconds / 1000);
        if (elapsedSec >= lastLogSec + logIntervalMs / 1000)
        {
            Report.Log(ReportLevel.Info, "Module",
                string.Format("Cho dialog dong... {0}s/{1}s", elapsedSec, maxWaitMs / 1000));
            lastLogSec = elapsedSec;
        }

        Delay.Milliseconds(pollIntervalMs);
    }

    Report.Log(ReportLevel.Warn, "Module",
        string.Format("Dialog chua dong sau {0}s.", maxWaitMs / 1000));
    return false;
}
```

**Nguyên tắc chọn timeout:**
- Timeout = 2-3x thời gian xử lý dài nhất quan sát được. Ví dụ: app load max 30s → timeout = 60s.
- Poll interval = 1-2 giây (đủ nhanh để phát hiện, không quá nặng).
- Log interval = 10 giây (đủ để theo dõi progress mà không spam report).

## Anti-pattern

- **TUYỆT ĐỐI KHÔNG** dùng `Thread.Sleep` hoặc `Delay.Milliseconds` cố định để chờ dialog đóng. Thời gian xử lý của app không cố định.
- **TUYỆT ĐỐI KHÔNG** giả định "click thất bại" chỉ vì dialog còn mở sau 3-5 giây. App có thể đang processing.
- **TUYỆT ĐỐI KHÔNG** nhảy sang click strategy tiếp nếu chưa chờ đủ thời gian cho strategy hiện tại.
- **LUÔN LUÔN** log thời gian chờ thực tế trong report — giúp debug nếu timeout cần điều chỉnh.
- **LUÔN LUÔN** phân biệt "dialog chưa đóng vì app đang xử lý" vs "dialog chưa đóng vì click thất bại".

## Evidence

- HANDOFF master: `docs/HANDOFF.md` — Bug 4: `DIALOG_CLOSE_CHECK_MS = 3000` quá ngắn, app load 30-60s.
- Commit: `6581d17` — refactor fixed wait thành polling `WaitForDialogClose()`.
- Code thực tế: `OpenFile_FromProduction.UserCode.cs` method `WaitForDialogClose()`.

## Xem thêm

- [generic-popup-path-collision.md](generic-popup-path-collision.md) — nếu polling vẫn fail dù đã chờ đủ lâu, có thể path collision.
