# Lesson: WaitForNotExists bị giới hạn bởi Repository Search Timeout

> **Ngày ghi nhận:** 2026-08-16  
> **Module:** Verify_ProductionPresettingDialog_AutoClose  
> **Session/HANDOFF liên quan:** `docs/HANDOFF_Verify_ProductionPresettingDialog_20260814.md`

---

## Trigger

Khi `RepoItemInfo.WaitForNotExists(timeout)` throw exception sớm hơn `timeout` chỉ định, dù element đã thực sự biến mất khỏi UI.

## KHÔNG áp dụng khi

- Element thực sự vẫn tồn tại trên UI (kiểm tra bằng Spy hoặc `Host.Local.Find`).
- Lỗi do stale cache — xem [repo-use-cache-stale-element.md](repo-use-cache-stale-element.md).
- Lỗi do path collision — xem [generic-popup-path-collision.md](generic-popup-path-collision.md).
- `WaitForNotExists` timeout parameter ≤ repo search timeout (30s trong project này) — trường hợp này WaitForNotExists hoạt động bình thường.

## Triệu chứng

1. `WaitForNotExists(N)` throw exception sau ~30s (hoặc bằng repo search timeout), KHÔNG phải sau N milliseconds.
2. DIAG log xác nhận: element ĐÃ biến mất tại thời điểm throw (direct find = 0, repo Exists(0) = False).
3. Catch block coi exception là "element vẫn tồn tại" → false failure.
4. Timeline: thời gian từ bắt đầu WaitForNotExists đến throw ≈ repo search timeout (30,000ms), không phải parameter truyền vào.

## Nguyên nhân gốc

`RepoItemInfo.WaitForNotExists(timeout)` nội bộ sử dụng repo search timeout để tìm element. Khi `timeout` parameter > repo search timeout, hành vi không đáng tin cậy:

- Repo search timeout = 30,000ms (cấu hình trong `.rxrep`, áp dụng cho tất cả repo items).
- `WaitForNotExists(90000)` — parameter nói chờ 90s, nhưng thực tế chỉ chờ ~29-30s rồi throw.
- Exception throw dù element đã biến mất, vì nó xảy ra ở ranh giới search timeout.

**Cơ chế:** Ranorex dùng repo search timeout để thực hiện lần search cuối. Nếu element biến mất trong khoảng search timeout, thay vì trả "not exists", nó throw exception khi search timeout hết.

## Cách xác minh

1. So sánh thời gian thực tế của WaitForNotExists vs parameter:
   ```
   Stopwatch: bắt đầu → throw = ~30s (repo search timeout)
   Parameter: 90000ms (90s)
   → Không khớp → WaitForNotExists bị giới hạn
   ```

2. DIAG log tại điểm throw xác nhận element đã biến mất:
   ```csharp
   // Sau catch block
   var count = Host.Local.Find<Form>(rxpath).Count; // = 0
   bool exists = repoItemInfo.Exists(0);             // = False
   ```

3. Nếu cả hai = 0/False → element đã biến mất, WaitForNotExists throw sai.

## Fix chuẩn

**Thay `WaitForNotExists` bằng polling loop dùng `Exists(0)`:**

```csharp
var sw = System.Diagnostics.Stopwatch.StartNew();
bool disappeared = false;
while (sw.ElapsedMilliseconds < TIMEOUT_MS)
{
    if (!repoItemInfo.Exists(0))
    {
        disappeared = true;
        break;
    }
    Delay.Milliseconds(POLL_INTERVAL_MS);
}
sw.Stop();

if (!disappeared)
{
    // Element thực sự vẫn tồn tại → FAIL
    throw new Exception("Element did not disappear within timeout");
}
```

**Ưu điểm:**
- `Exists(0)` check nhanh (0ms timeout), không bị giới hạn bởi repo search timeout.
- Loop tự quản lý overall timeout → chính xác theo parameter.
- Pattern đã dùng thành công ở nhiều module khác (Step 3a, dialog close polling).

## Quy tắc áp dụng

- **KHÔNG dùng** `WaitForNotExists` khi timeout parameter > repo search timeout (30s).
- **LUÔN dùng** polling loop `Exists(0)` cho wait-for-disappear với timeout > 30s.
- `WaitForNotExists` vẫn an toàn khi timeout ≤ repo search timeout.
- Cùng logic áp dụng cho `WaitForExists` nếu cần timeout > repo search timeout — nhưng thường ít gặp vấn đề hơn vì element xuất hiện nhanh.

## Anti-pattern

- **TUYỆT ĐỐI KHÔNG** tăng timeout của `WaitForNotExists` khi nó throw sớm — timeout parameter không phải root cause.
- **TUYỆT ĐỐI KHÔNG** coi exception từ `WaitForNotExists` là "element vẫn tồn tại" mà không verify bằng `Exists(0)`.
- **TUYỆT ĐỐI KHÔNG** tăng repo search timeout trong `.rxrep` để workaround — điều đó ảnh hưởng toàn bộ test suite.

## Evidence

- **Case 1 — Verify_ProductionPresettingDialog_AutoClose (2026-08-16):**
  - `WaitForNotExists(90000)` throw sau ~29s (03:06 → 03:35).
  - DIAG `SAU_WAIT_FAIL`: direct find = 0 form, 0 button; repo Exists(0) = False.
  - Element ĐÃ biến mất, WaitForNotExists throw sai.
  - Fix: polling loop `Exists(0)` với timeout 60s.

## Xem thêm

- [dialog-close-polling-timeout.md](dialog-close-polling-timeout.md) — pattern polling cho dialog close.
- [repo-use-cache-stale-element.md](repo-use-cache-stale-element.md) — nếu `Exists(0)` trả True nhưng element đã biến mất → kiểm tra Use Cache.
