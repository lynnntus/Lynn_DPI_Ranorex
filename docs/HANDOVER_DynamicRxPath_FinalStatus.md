# DynamicRxPath Final Status

> Tao: 2026-06-08
> Session lien quan: 2026-06-03 ~ 2026-06-08
> Muc dich: Tong hop ket qua cuoi cung cua investigation DynamicRxPath, ModelName Validation va Timing Issue.

---

## 1. Objective

Validate rang sau khi open recipe file trong Neptune, UI hien thi dung **ModelName** tuong ung voi recipe duoc load. ModelName lay tu CSV data source (runtime), khong hardcode.

Yeu cau phu:
- Validation phai hoat dong voi **moi recipe** (khong chi 1 recipe cu the).
- Khong phu thuoc vao repository item hardcode caption.
- Phan biet duoc "app chua load xong" vs "selector sai" trong report.

---

## 2. Confirmed Findings

### 2.1 ModelName nam o Parent, khong phai Child
- **Evidence**: Investigation logs (Ranorex Report, session 2026-06-06).
- `SomeText` (CHILD): `Caption = ''`, `Text = null`.
- `SomeText.Element.Parent` (ANCESTOR_L1): `Caption = 'Lynn_Stacking_Underfill'`, `Text = 'Lynn_Stacking_Underfill'`.
- **Ket luan**: Actual ModelName doc tu ANCESTOR_L1, attribute `Caption`.

### 2.2 Repository hardcode `@caption='Lynn_Stacking_Underfill'`
- **Evidence**: RxPath trong `.rxrep` (doc truc tiep).
- `SomeText` va `SomeIndicator` deu chua `@caption='Lynn_Stacking_Underfill'` co dinh.
- Khi doi recipe → `SomeText.Exists()` = False → validation fail truoc khi den logic so sanh.
- **Ket luan**: Root cause la Repository selector, KHONG phai validation logic.

### 2.3 Parent node khong co attribute on dinh ngoai caption
- **Evidence**: Spy investigation (session 2026-06-07).
- AutomationId, ClassName, ControlType, Name: tat ca **khong co**.
- Attribute duy nhat la `caption` — chinh la value can validate (thay doi theo recipe).
- **Ket luan**: Khong the tao repository selector on dinh. Phai dung dynamic RxPath trong code.

### 2.4 Dynamic RxPath pattern hoat dong (ve mat ky thuat)
- **Evidence**: Build PASS, code review (session 2026-06-07).
- Pattern: `Host.Local.FindSingle<Ranorex.Text>(string.Format("/form[@title='CCIMainWindow']//text[@caption='{0}']", expected), timeout)`.
- Khong phu thuoc `repo.CCIMainWindow.SomeText`.
- **Luu y**: Pattern nay CHUA duoc xac nhan PASS o runtime voi timing du — xem Section 5.

### 2.5 ValidateModelName cu (repo-based) PASS voi 1 recipe
- **Evidence**: Ranorex Report (session 2026-06-06 truoc).
- `Validate.AreEqual(actual, expected)` PASS voi recipe `Lynn_Stacking_Underfill`.
- FAIL voi recipe khac vi `SomeText.Exists()` = False (hardcode).

### 2.6 Timing issue khi chuyen sang dynamic RxPath
- **Evidence**: Ranorex Report (session 2026-06-07).
- Dynamic RxPath FAIL sau 30s timeout voi recipe `Lynn_Array_BadMark`.
- Auto-generated code expect recipe load toi 50s (`SomeIndicatorInfo.WaitForExists(50000)`).
- ValidateModelName bat dau chi 3s sau click Open → chua du thoi gian.
- **Ket luan**: Day la van de timing rieng biet, khong phai dynamic RxPath sai.

---

## 3. Rejected Hypotheses

| Gia thuyet | Bang chung bac bo |
|------------|-------------------|
| Ctrl+A/Ctrl+V de nhap path vao File name | Field chi nhan literal "v"/"a". DefaultKeyPressTime=20ms qua nhanh |
| SetAttributeValue("WindowText") de set path | Loi "The operation is not supported" |
| Bo tick caption trong Ranorex Spy de tao dynamic selector | Node mat element type, thanh wildcard — khong dung duoc |
| Tang timeout don thuan (30s → 90s) se fix | Chua co timing data. Khong biet app load bao lau |
| Selector fail vi RxPath sai | Screenshot cho thay UI hien thi dung — van de la timing |

---

## 4. Current Implementation Status

### Da implement (Build PASS, chua chay test)

| Thay doi | File | Method | Trang thai |
|----------|------|--------|------------|
| Dynamic RxPath validation (investigation version) | `OpenFile.UserCode.cs` | `ValidateModelName()` | Build PASS, chua test |
| Probe signals truoc click Open | `OpenFile.UserCode.cs` | `ProbeSignals(phase)` | Build PASS, chua test |
| Buoc 7 don gian hoa (bo SomeText dependency) | `OpenFile.UserCode.cs` | `OpenRecipeFileByPath()` | Build PASS, chua test |

### Chi tiet ValidateModelName() hien tai (investigation version)

```
Phase A: Poll container[@automationid='View'] moi 2s, max 60s
         → Signal: Neptune da render recipe UI
Phase B: Poll text[@caption='{ModelName}'] moi 2s, max 120s tong
         → Tim ModelName trong UI
Output: Timing logs trong report (SIGNAL TIMING SUMMARY)
```

### Chua implement

| Hang muc | Ly do |
|----------|-------|
| ValidateModelName phien ban chinh thuc (khong polling) | Chua co timing data tu investigation |
| Xu ly SomeIndicator trong OpenFile.cs (auto-generated) | Bi che boi timing issue |
| Cleanup dead code (InvestigateModelNameElement, helpers) | Cho investigation xong |

### Dead code ton tai (khong anh huong runtime)

- `InvestigateModelNameElement()` — line ~353-394
- `LogElement()` — line ~396-422
- `LogChildren()` — line ~424-456
- `PROBE_ATTRS` — line ~345-351

Tat ca khong duoc goi. Nam trong block `// PHASE 1 INVESTIGATION — temporary`.

---

## 5. Timing Investigation Status

### Da dieu tra

- Auto-generated code expect recipe load 50s (`SomeIndicatorInfo.WaitForExists(50000)`).
- Dynamic RxPath voi 30s timeout FAIL (report 2026-06-07).
- Click Open → 3s delay → ValidateModelName bat dau → 30s timeout → tong 33s → fail.

### Chua xac nhan

| Cau hoi | Trang thai |
|---------|------------|
| Recipe load mat bao lau thuc te? | Chua co data |
| `text[@caption='{ModelName}']` xuat hien khi nao sau click Open? | Chua co data |
| `container[@automationid='View']` co phai signal dang tin cay? | Chua co data |
| ProbeSignals("BEFORE_OPEN") cho ket qua gi? | Chua chay |

### Signal dang can nhac

1. `container[@automationid='View']` — dai dien cho recipe UI da render.
2. `text[@caption='{ModelName}']` — chinh la element can validate.

### Vi sao chua chot giai phap cuoi cung

Investigation code da implement nhung **CHUA BAO GIO CHAY**. Khong co timing data thuc te de quyet dinh:
- Timeout bao nhieu la du.
- Signal nao xuat hien truoc.
- Co can tach Wait va Validate khong.

---

## 6. Open Issues

| # | Van de | Muc do | Ghi chu |
|---|--------|--------|---------|
| 1 | Chua co timing data tu investigation code | **HIGH** | Can chay test tren May B de lay data |
| 2 | `SomeIndicator` trong OpenFile.cs hardcode caption | MEDIUM | Bi che boi timing issue. Se FAIL khi ValidateModelName PASS |
| 3 | Dead code investigation cu con ton tai | LOW | Khong anh huong runtime. Cleanup sau |
| 4 | CSV chi co 1 row (`Lynn_Stacking_Underfill`) | LOW | Can them row voi recipe khac de test multi-recipe |

---

## 7. Recommended Next Actions

**Thu tu uu tien:**

1. **Chay test voi investigation code hien tai** (tren May B)
   - Recipe bat ky (uu tien recipe KHAC `Lynn_Stacking_Underfill` de test dynamic).
   - Doc report → tim `[PROBE BEFORE_OPEN]`, `[SIGNAL]`, `SIGNAL TIMING SUMMARY`.
   - Ghi lai timing: View container xuat hien sau bao lau? ModelName text sau bao lau?

2. **Dua tren timing data → implement ValidateModelName chinh thuc**
   - Neu View container FOUND truoc ModelName → dung lam "wait app ready" signal.
   - Neu ca hai NOT FOUND sau 120s → RxPath co the sai, can investigation them.
   - Pattern mong doi: Wait signal (60s) → Delay nho (2-5s) → FindSingle (15s).

3. **Xu ly SomeIndicator** (sau khi ValidateModelName on dinh)
   - Re-spy trong Ranorex Studio, hoac re-record OpenFile.rxrec bo step SomeIndicator.

4. **Cleanup dead code** (sau khi moi thu on dinh)
   - Xoa `InvestigateModelNameElement()`, `LogElement()`, `LogChildren()`, `PROBE_ATTRS`.
   - Xoa `ProbeSignals()` neu khong can.

---

## 8. Lessons Learned

### L1: Khi test PASS voi 1 data row nhung FAIL voi row khac → kiem tra repository hardcode
Repository selector co the chua value cu the (vd: `@caption='Lynn_Stacking_Underfill'`). Day la root cause pho bien nhat, khong phai logic code.

### L2: Khong tang timeout de che selector sai
Neu selector hardcode value sai, timeout bao nhieu cung fail. Xac nhan selector dung truoc, roi moi dat timeout.

### L3: Tach Wait va Validate
Khong gop vao 1 buoc voi timeout dai. Wait cho app ready (signal) → roi validate voi timeout ngan. Nhu vay phan biet duoc "app chua load" vs "selector sai".

### L4: Dynamic RxPath trong UserCode khi Repository khong the dynamic
Khi parent node khong co attribute on dinh (chi co caption thay doi theo data), dung `Host.Local.FindSingle<T>(rxPath, timeout)` voi `string.Format` de inject runtime value.

### L5: Investigation truoc, implement sau
Workflow bat buoc: Investigation → Evidence (report) → Root Cause → Proposed Fix → Confirm → Implement. Khong implement fix truoc khi co bang chung.

### L6: Doc call chain truoc khi debug
Xac nhan method dang debug thuc su duoc goi trong flow hien tai. Ví du: `TryLoginWithUser()` va `Login_Pass` recording la 2 flow doc lap.

---

## Files lien quan

| File | Vai tro |
|------|---------|
| `Lynn_DPI_AT/.../OpenFile.UserCode.cs` | Code chinh — chua investigation version |
| `Lynn_DPI_AT/.../OpenFile.cs` | Auto-generated — KHONG sua |
| `Lynn_DPI_ATRepository.rxrep` | Repository — chua hardcode caption. KHONG sua |
| `TestData/OpenFileData.csv` | Data source — cot ModelName, RecipeFilePath, Enable |
| `docs/OpenFile_KNOWLEDGE.md` | Knowledge base day du |
| `docs/lessons/openfile-dynamic-rxpath-lesson.md` | Lesson learn chi tiet |
