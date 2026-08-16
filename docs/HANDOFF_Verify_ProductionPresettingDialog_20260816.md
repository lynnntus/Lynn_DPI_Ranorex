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
11. **Fix ApplicationNotRespondingException cascade** — Verify + OpenFile (chi tiết bên dưới)

## Trạng thái hiện tại

**FIX ANR CASCADE ĐÃ APPLY — chờ test trên Máy B (7-10 lần).**

### Error đã fix: ApplicationNotRespondingException cascade

**Root cause:** App Neptune đôi khi trở thành Not Responding (OS-level hung) sau khi Verify module click Apply trong dialog Production Presetting. Khi app hung:
1. MỌI UI interaction (`Exists`, `Click`, property access) throw `ApplicationNotRespondingException` với message "Invocation did not finish within the timeout of '00:00:05'"
2. Verify BUOC 3b polling loop KHÔNG có try-catch → `Exists(0)` throw → module crash → dialog vẫn mở
3. OpenFile bắt đầu 102ms sau → app vẫn hung → cascade FAIL

**Evidence:**
- DIAG log OpenFile: `ApplicationNotRespondingException` tại Buoc 1, khoảng cách đều 5s giữa các operation
- CleanupDialog log: "Production Presetting con mo" = dialog từ Verify chưa đóng
- Code evidence: BUOC 3a CÓ try-catch (line 107-128), BUOC 3b KHÔNG CÓ (line 150-159)

**Tại sao trước đó không lỗi:** Trước fix #9, `ClickApplyWithPolling()` là recording step bị 5s timeout → logic KHÔNG KỊP đến bước click Apply → Apply chưa bao giờ được click → app không hung.

**Fix applied (6 thay đổi, 2 files):**

| # | File | Thay đổi |
|---|------|---------|
| 1 | Verify UserCode | BUOC 3b: catch ANR + Thread.Sleep(3000) + continue polling |
| 2 | Verify UserCode | try-finally + CleanupLeftoverDialog() trong finally |
| 3 | OpenFile UserCode | Init(): thêm WaitForAppResponsive() — poll 15s, catch ANR |
| 4 | OpenFile UserCode | Init(): gọi CleanupDialog() TRƯỚC main flow |
| 5 | OpenFile UserCode | Buoc 1: retry loop (max 3 attempts, 5s wait, catch ANR) |
| 6 | Cả 2 file | Log `[APP_NOT_RESPONDING]` Warning mỗi lần gặp ANR |

**Confidence: Medium-High (75-80%)** — 1 assumption: Verify gặp ANR chưa trực tiếp confirm (suy luận từ timeline + OpenFile evidence). Fix an toàn ngay cả khi assumption sai (catch blocks không trigger nếu ANR không xảy ra).

### Lesson + DIAG cleanup (chờ stable)
- Sau khi PASS 7-10 lần → tạo lesson về ANR + state cascade
- Sau khi PASS stable → cleanup DIAG logs (LogDiagBtnState, [DIAG] lines)

## Next step

1. Git push code lên Máy B
2. Chạy test 7-10 lần
3. Kỳ vọng: Khi app hung → Verify retry polling → OpenFile wait-for-responsive + retry click → recover → PASS
4. Nếu vẫn fail → app hung quá lâu, cần tăng timeout hoặc điều tra app-level
5. Sau stable → cleanup DIAG + tạo lesson

## File liên quan

| File | Vai trò |
|------|---------|
| `Lynn_DPI_AT/.../Verify_ProductionPresettingDialog_AutoClose.UserCode.cs` | ANR catch + cleanup trong BUOC 3b + finally |
| `Lynn_DPI_AT/.../OpenFile_FromProduction.UserCode.cs` | WaitForAppResponsive + pre-check cleanup + Buoc 1 retry |
| `docs/lessons/INDEX.md` | Index tra cứu lesson theo triệu chứng |

## Data key

| Observation | Giá trị |
|-------------|---------|
| Exception type | `ApplicationNotRespondingException` (OS-level app hung) |
| 5s timeout message | `"Invocation did not finish within the timeout of '00:00:05'"` — Ranorex/OS wait, KHÔNG phải Action Timeout |
| Cascade gap | 102ms giữa Verify FAIL → OpenFile START |
| App recovery | ~7s sau ANR, app tự hồi phục (CleanupDialog hoạt động tại 03:31) |
| Flaky pattern | 2/7 FAIL = app đôi khi hung sau Apply, không phải lúc nào cũng |

## Business context

- Test verify FUNCTIONAL (dialog đóng được), KHÔNG test performance
- PASS khi dialog tự đóng HOẶC click Apply đóng được
- Chấp nhận test chạy chậm với app version mới

## Working rules

Follow `.claude/rules/`, `.claude/lessons/`, `.claude/workflows/`.
Quy trình: PLAN → confirm → code → self-review → build test → báo cáo.
**KHÔNG code ngay khi đọc file.**
