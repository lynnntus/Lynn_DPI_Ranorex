# HANDOFF — Verify_ProductionPresettingDialog_AutoClose

> Session: 2026-08-14 ~ 2026-08-16

## Task

Module `Verify_ProductionPresettingDialog_AutoClose`. Verify dialog "Production Presetting" tự đóng khi chuyển sang tab Production, fallback click Apply nếu không tự đóng.

## Lịch sử session

1. Fix path đụng (Base path thêm `@title='Production Presetting'`) → PASS
2. Cleanup DIAG, chỉnh timeout Bước 1 = 15s → PASS
3. Giảm Bước 2 = 10s gây side effect → rollback 30s → PASS
4. App version mới regression, manual test 37s → tăng Bước 3b từ 15s → 45s → 90s
5. Timeout 90s vẫn FAIL, nhưng dialog KHÔNG còn hiển thị trên màn hình khi test báo fail
6. Thêm DIAG log tại Bước 3b: `LogDiagElementState()` — chờ chạy test lấy evidence
7. **Phân tích DIAG → root cause: `WaitForNotExists` bị giới hạn bởi repo search timeout (30s)**
8. **Fix: thay WaitForNotExists bằng polling loop `Exists(0)`, cleanup DIAG, giảm timeout 90s → 60s**

## Trạng thái

- **ĐÃ FIX** — chờ chạy test trên máy B để verify
- Timeout Bước 3b = 60s (`APPLY_CLOSE_VERIFY_TIMEOUT_MS = 60000`)
- Bước 3b dùng polling loop `Exists(0)` thay `WaitForNotExists`
- DIAG code đã cleanup

## Root cause (confirmed bằng DIAG evidence)

`WaitForNotExists(90000)` KHÔNG chờ 90s. Bị giới hạn bởi repo search timeout = 30s. Throw exception sau ~29s dù element đã biến mất. Catch block coi đó là "element vẫn tồn tại" → false failure.

Evidence: DIAG `SAU_WAIT_FAIL` xác nhận direct find = 0, repo Exists(0) = False — element đã biến mất tại thời điểm throw.

Lesson mới: [docs/lessons/waitfornotexists-repo-timeout-limit.md](docs/lessons/waitfornotexists-repo-timeout-limit.md)

## File liên quan

| File | Vai trò |
|------|---------|
| `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/Verify_ProductionPresettingDialog_AutoClose.UserCode.cs` | Custom logic — file chính cần sửa |
| `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/Verify_ProductionPresettingDialog_AutoClose.rxrec` | Recording definition (KHÔNG sửa) |
| `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_ATRepository.rxrep` | Repository chứa RxPath selector (KHÔNG sửa) |
| `docs/lessons/generic-popup-path-collision.md` | Lesson về path đụng |
| `docs/lessons/repo-use-cache-stale-element.md` | Lesson về stale reference |

## Data key

| Observation | Giá trị |
|-------------|---------|
| Manual click Apply | Dialog đóng sau ~37s |
| Auto test | Sau 90s vẫn báo element còn tồn tại |
| Thực tế màn hình | Dialog KHÔNG còn hiển thị khi test báo fail |
| Screenshot ~15s sau click Apply | Màn hình đen (dialog đã đóng?) |

## Working rules

Follow `.claude/rules/`, `.claude/lessons/`, `.claude/workflows/`. Quy trình: PLAN → confirm → code → self-review → build test → báo cáo.
