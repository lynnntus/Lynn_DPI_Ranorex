---
title: Code Review — LoginRetry.cs
date: 2026-05-26
reviewed_from: git commit 832e7e8 (file đã bị xóa khỏi working tree)
status: acknowledged — chưa fix, module đang không active
---

# Code Review — LoginRetry.cs

## Thông tin
- **Ngày ghi nhận:** 2026-05-26
- **File được review:** `LoginRetry.cs` (commit `832e7e8`)
- **Trạng thái file:** Đã bị xóa khỏi working tree, còn trong git history
- **Reviewer:** Claude Code (agent code-reviewer)

---

## Critical (chưa fix)

### C1. `credentialFound` là `static` — state rò rỉ giữa các test run
- **Dòng:** `private static bool credentialFound = false;`
- **Vấn đề:** Biến static tồn tại suốt AppDomain. Nếu test suite chạy lại mà không restart process, `credentialFound` giữ `true` từ lần trước → mọi CSV row bị skip.
- **Lý do chưa fix:** Module đang không active (file đã xóa khỏi working tree), không ảnh hưởng runtime hiện tại.

### C2. `Login_Pass.Instance` có thể `null`
- **Dòng 68-69:** `Login_Pass.Instance.UserName = UserName;`
- **Vấn đề:** Nếu `Login_Pass` chưa được Ranorex instantiate, truy cập `.Instance` throw `NullReferenceException`.
- **Lý do chưa fix:** Như C1.

---

## Warning (chưa fix)

### W1. `repo` khai báo `public static` — không cần thiết
- Nên dùng instance field hoặc truy cập trực tiếp `Lynn_DPI_ATRepository.Instance`.

### W2. Magic number `30000` trong `WaitForExists`
- Timeout 30s hardcode, nên dùng constant.

### W3. Không xử lý khi tất cả CSV row đều thất bại
- Module kết thúc im lặng, test suite tiếp tục mà không biết login chưa thành công.

**Lý do chung chưa fix:** Module không active, chưa ảnh hưởng.

---

## Suggestion (bỏ qua)
- S1. Log message dùng ASCII thay tiếng Việt có dấu
- S2. `Delay.SpeedFactor = 1.00` thừa
- S3. Screenshot trước login mỗi row gây chậm

---

## Khi nào cần quay lại fix

| Trigger | Hành động |
|---------|-----------|
| Khôi phục `LoginRetry.cs` vào working tree | Fix C1, C2 trước khi chạy |
| Test suite chạy không ổn định (skip login bất thường) | Kiểm tra C1 — static state leak |
| Thêm test suite mới dùng LoginRetry | Fix C1, C2, W3 bắt buộc |
| Refactor login flow | Fix toàn bộ Warning |
