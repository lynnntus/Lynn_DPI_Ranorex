# HANDOFF — Verify_ProductionPresettingDialog_AutoClose

> Session: 2026-08-16

## Task

Module `Verify_ProductionPresettingDialog_AutoClose`. Verify dialog "Production Presetting" tự đóng khi chuyển sang Production tab, fallback click Apply nếu không tự đóng.

## Lịch sử session

1. Fix path đụng (Base path `@title='Production Presetting'`) → PASS
2. Cleanup DIAG, chỉnh timeout Bước 1 = 15s → PASS
3. App version mới regression, tăng timeout Bước 3b: 15s → 45s → 90s
4. Thêm DIAG để debug false failure
5. Phân tích DIAG → phát hiện WaitForNotExists bị giới hạn bởi repo search timeout (30s)
6. Fix: thay WaitForNotExists bằng polling loop với `Exists(0)`, giảm timeout 60s
7. Cleanup DIAG code
8. Tạo lesson mới: `waitfornotexists-repo-timeout-limit.md`
9. Fix "Invocation did not finish within timeout 5s" — chuyển logic vào `Init()`, `ClickApplyWithPolling()` thành no-op
10. Tạo lesson mới: `recording-step-action-timeout.md`, update INDEX

## Trạng thái hiện tại

**FIX ĐÃ APPLY — chờ test trên Máy B.**

### Error đã fix: "Invocation did not finish within timeout 5s"

**Root cause (đã confirm):** `ClickApplyWithPolling()` là **recording step** (userrecorditem trong .rxrec), được gọi từ `Run()` line 82. Ranorex áp dụng Action Timeout 5s mặc định. Method cần ~34-60s → bị kill.

Evidence: [Verify_ProductionPresettingDialog_AutoClose.cs](../Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/Verify_ProductionPresettingDialog_AutoClose.cs) line 80-82:
```csharp
Init();                      // plain method call — KHÔNG có Action Timeout
ClickApplyWithPolling();     // recording step — 5s Action Timeout default
```

**Fix applied:** Chuyển toàn bộ logic vào `Init()` → `RunVerifyAutoClose()`. `ClickApplyWithPolling()` thành no-op (log + return ngay). Build PASS.

### Lesson mới đã tạo
- `docs/lessons/recording-step-action-timeout.md`
- `docs/lessons/INDEX.md` đã update

## Next step

1. Git push code lên Máy B
2. Chạy test — verify `Init()` chạy full logic, `ClickApplyWithPolling()` return ngay
3. Nếu PASS → done. Nếu FAIL → phân tích error mới

## File liên quan

| File | Vai trò |
|------|---------|
| `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/Verify_ProductionPresettingDialog_AutoClose.UserCode.cs` | Custom logic — vừa fix polling loop |
| `docs/lessons/waitfornotexists-repo-timeout-limit.md` | Lesson mới — WaitForNotExists bị giới hạn bởi repo search timeout |
| `docs/lessons/INDEX.md` | Index tra cứu lesson theo triệu chứng |
| `docs/lessons/dialog-close-polling-timeout.md` | Lesson cũ — polling pattern cho dialog close |
| `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_ATRepository.rxrep` | Repository chứa RxPath selector (KHÔNG sửa) |

## Data key

| Observation | Giá trị |
|-------------|---------|
| DIAG log trước (đã có) | `Exists(0)` chạy nhanh, không có vấn đề |
| Log lần này | Error "Invocation did not finish within timeout 5s" |
| Manual click Apply | Dialog đóng sau ~37s |
| Polling loop timeout | 60s (`APPLY_CLOSE_VERIFY_TIMEOUT_MS = 60000`) |
| Fail sau | ~34s (chưa đạt 60s timeout) |
| Thực tế màn hình | Dialog đã đóng khi test báo fail |

## Business context

- Test verify FUNCTIONAL (dialog đóng được), KHÔNG test performance
- PASS khi dialog tự đóng HOẶC click Apply đóng được
- Chấp nhận test chạy chậm với app version mới

## Working rules

Follow `.claude/rules/`, `.claude/lessons/`, `.claude/workflows/`.
Quy trình: PLAN → confirm → code → self-review → build test → báo cáo.
**KHÔNG code ngay khi đọc file.**
