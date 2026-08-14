# HANDOFF — Verify_ProductionPresettingDialog_AutoClose

> Session: 2026-08-14

## Task

Module `Verify_ProductionPresettingDialog_AutoClose`. Verify dialog "Production Presetting" tự đóng khi chuyển sang tab Production, fallback click Apply nếu không tự đóng.

## Lịch sử session

1. Fix path đụng (Base path thêm `@title='Production Presetting'`) → PASS
2. Cleanup DIAG, chỉnh timeout Bước 1 = 15s → PASS
3. Giảm Bước 2 = 10s gây side effect → rollback 30s → PASS
4. App version mới regression, manual test 37s → tăng Bước 3b từ 15s → 45s → 90s
5. Timeout 90s vẫn FAIL, nhưng dialog KHÔNG còn hiển thị trên màn hình khi test báo fail
6. Thêm DIAG log tại Bước 3b: `LogDiagElementState()` — chờ chạy test lấy evidence

## Trạng thái

- Timeout Bước 3b = 90s (`APPLY_CLOSE_VERIFY_TIMEOUT_MS = 90000`)
- Test FAIL sau 90s
- **QUAN TRỌNG**: gap giữa quan sát thực tế và log → nghi ngờ path/element issue, không phải timing

## Nghi ngờ root cause

Ranorex tìm thấy element match path nhưng element đó KHÔNG phải dialog đang hiển thị. Có thể: path đụng, stale reference, invisible element trong UI tree.

## Business context

- Test verify FUNCTIONAL (dialog đóng được), KHÔNG test performance
- PASS khi dialog tự đóng HOẶC click Apply đóng được
- Chấp nhận test chạy chậm với app version mới

## Next step

**DIAG log đã thêm (bước 6)**. Chạy test trên máy B, khi FAIL sẽ có log category `DIAG` trong Ranorex report.

Cách đọc log DIAG:
- `[TRUOC_WAIT]`: trạng thái ngay sau click Apply, trước khi chờ
- `[SAU_WAIT_FAIL]`: trạng thái khi 90s hết mà vẫn báo element tồn tại
- Nếu `So form match > 0` nhưng `Visible=False, Rect=(0,0,0,0)` → stale cache (lesson `repo-use-cache-stale-element`)
- Nếu `So form match > 1` → path đụng (lesson `generic-popup-path-collision`)
- Nếu direct find = 0 nhưng repo Exists = True → stale cache confirmed

Sau khi có log, mở session mới và gửi kết quả DIAG để phân tích root cause.

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
