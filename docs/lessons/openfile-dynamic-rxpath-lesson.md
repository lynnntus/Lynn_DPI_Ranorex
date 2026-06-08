# Bai hoc: Dynamic RxPath — Xu ly Repository hard-code selector

**Ngay ghi nhan:** 2026-06-08
**Module lien quan:** OpenFile
**Session lien quan:** 2026-06-06 ~ 2026-06-07

---

## Van de da gap (Problem Pattern)

### Trieu chung

1. **Repository item hard-code value trong RxPath** — `SomeText` va `SomeIndicator` chua `@caption='Lynn_Stacking_Underfill'` co dinh trong `.rxrep`.
2. **Test PASS voi 1 recipe, FAIL voi recipe khac** — `SomeText.Exists()` = False khi doi sang `Lynn_Array_BadMark` vi RxPath chi match 1 value cu the.
3. **UI da load nhung Ranorex khong tim thay element** — app hien thi dung ModelName, nhung selector van tro vao value cu.
4. **Timeout khong phai root cause** — tang timeout tu 30s len 90s van fail vi selector sai, khong phai vi app chua load.

### Dau hieu nhan biet

- Test PASS voi data row dau tien (khop voi value hard-code trong repository) nhung FAIL voi row khac.
- Error message: `Element not found` hoac `Exists() = False` cho repository item.
- Screenshot cho thay UI hien thi dung — van de nam o selector, khong phai UI.
- Thay doi TestData CSV → test bat dau fail ma khong sua code gi.

---

## Evidence da gap

### 1. Repository hard-code caption

RxPath trong `.rxrep` cho `SomeText` va `SomeIndicator`:

```
/form[@title='CCIMainWindow']/container[@automationid='MainView']/?/?/container[@automationid='View']//text[@caption='Lynn_Stacking_Underfill']/text[@caption='']
```

`@caption='Lynn_Stacking_Underfill'` la **hard-code** — chi match 1 recipe.

### 2. ModelName validation fail khi doi recipe

- Recipe `Lynn_Stacking_Underfill` → `SomeText.Exists()` = True → validation PASS.
- Recipe `Lynn_Array_BadMark` → `SomeText.Exists()` = False → validation FAIL truoc khi den logic so sanh.
- **Root cause khong phai validation logic** — ma la Repository selector.

### 3. Value nam o PARENT, khong phai CHILD

Investigation logs xac nhan:

| Element | Caption | Text |
|---------|---------|------|
| `SomeText` (CHILD) | `''` (rong) | `null` |
| `ANCESTOR_L1` (parent cua SomeText) | `'Lynn_Stacking_Underfill'` | `'Lynn_Stacking_Underfill'` |

**Ket luan**: Actual ModelName nam o **parent element**, attribute `Caption`.

### 4. Parent node khong co attribute on dinh nao ngoai caption

Spy investigation tren recipe `Lynn_Array_BadMark`:

| Thuoc tinh | Gia tri |
|-----------|---------|
| AutomationId | Khong co |
| ClassName | Khong co |
| ControlType | Khong co |
| Name | Khong co |
| caption | `Lynn_Array_BadMark` (thay doi theo recipe) |

→ Khong the tao selector on dinh tu repository vi attribute duy nhat la `caption` — chinh la value can validate.

### 5. Dynamic RxPath da implement

```csharp
string rxPath = string.Format(
    "/form[@title='CCIMainWindow']//text[@caption='{0}']", expected);
Ranorex.Text foundElement = Host.Local.FindSingle<Ranorex.Text>(rxPath, timeout);
```

- `expected` = `this.ModelName` tu CSV runtime.
- Khong phu thuoc `repo.CCIMainWindow.SomeText` nua.
- Repository `.rxrep` khong bi sua.

### 6. Timing issue phat sinh sau khi doi sang dynamic RxPath

- Dynamic RxPath FAIL sau 30s timeout (test 2026-06-07).
- Auto-generated code thiet ke `SomeIndicatorInfo.WaitForExists(50000)` = expect recipe load toi **50s**.
- Nhung ValidateModelName bat dau chi 3s sau click Open → chua du thoi gian cho app load.
- **Day la van de timing rieng biet**, khong phai van de dynamic RxPath.

---

## Correct Investigation Flow

### Buoc 1: Doc report truoc — khong suy doan

- Tim error message chinh xac.
- Xac dinh step nao fail, timestamp bao nhieu.
- Xem screenshot tai thoi diem fail — UI trang thai nao.

### Buoc 2: Xac dinh Expected value

- Expected value lay tu dau? (`this.VariableName` tu CSV? Default value trong constructor?)
- Kiem tra CSV data source: co dung row/column khong?
- Kiem tra module variable default: co bi override khong?

### Buoc 3: Kiem tra actual UI element

- Dung investigation log de doc attribute cua element va parent.
- Log toi thieu: `Caption`, `Text`, `WindowText`, `AccessibleName`.
- So sanh child vs parent — value co the nam o level khac.

```csharp
// Pattern investigation — log child va parent
var child = repo.CCIMainWindow.SomeText.Element;
LogElement(child, "CHILD");

var parent = child.Parent;
LogElement(parent, "PARENT");
```

### Buoc 4: Xac dinh root cause

| Trieu chung | Root cause kha nang |
|-------------|-------------------|
| `Exists() = False` + UI hien thi dung | Selector hard-code value sai |
| `Exists() = True` + value rong | Value nam o parent, khong phai child |
| `Exists() = True` + value sai | Selector match nhung element, can kiem tra RxPath |
| Timeout + UI chua load | Timing issue — can wait signal |

### Buoc 5: Chi ket luan sau khi co evidence

- Khong gia dinh root cause.
- Khong implement fix truoc khi chung minh.
- Workflow bat buoc: **Investigation → Evidence → Root Cause → Proposed Fix → Confirm → Implement**.

---

## Recommended Solution

### R1: Dung dynamic RxPath trong UserCode khi value phu thuoc TestData

```csharp
// Template: thay {0} bang gia tri tu CSV runtime
string rxPath = string.Format(
    "/form[@title='CCIMainWindow']//text[@caption='{0}']", this.ModelName);

// FindSingle voi timeout hop ly
Ranorex.Text element = Host.Local.FindSingle<Ranorex.Text>(rxPath, timeoutMs);
```

- `this.ModelName` = module variable, Ranorex inject tu CSV.
- Khong phu thuoc repository item hard-code.
- Repository `.rxrep` khong bi sua.

### R2: Tach ro Wait va Validate

```
Phase A: Wait cho app/recipe ready (signal: container[@automationid='View'] xuat hien)
    → xac nhan Neptune da render recipe UI

Phase B: Delay nho (2-5s) cho UI on dinh

Phase C: FindSingle dynamic RxPath (timeout ngan 10-15s)
    → luc nay app da ready, neu khong tim thay = that su sai ModelName
```

Khong gop Wait va Validate vao 1 buoc voi timeout dai — se khong phan biet duoc "app chua load" vs "selector sai".

### R3: Dung Validate.AreEqual hoac Report + controlled fail

```csharp
// Cach 1: Validate.AreEqual — chuan Ranorex, hien thi trong report
Validate.AreEqual(actual, expected);

// Cach 2: Report + throw — khi can custom message
if (actual != expected)
{
    Report.Screenshot(repo.CCIMainWindow.Self, true);
    Report.Log(ReportLevel.Error, "OpenFile",
        string.Format("Expected: '{0}', Actual: '{1}'", expected, actual));
    throw new Exception("Validation FAIL");
}
```

### R4: Khong sua auto-generated file

- `OpenFile.cs` — auto-generated tu `OpenFile.rxrec`. KHONG sua.
- `Lynn_DPI_ATRepository.cs` — auto-generated tu `.rxrep`. KHONG sua.
- Chi sua `OpenFile.UserCode.cs`.

### R5: Khong sua Repository RxPath hang loat

- Repository `.rxrep` do Ranorex Studio quan ly.
- Sua bang tay co the bi ghi de khi re-record.
- Uu tien xu ly trong UserCode, de Repository nguyen.

---

## Anti-patterns

### AP1: Hard-code value trong repository khi value thay doi theo TestData

```
❌ SAI: //text[@caption='Lynn_Stacking_Underfill']/text[@caption='']
         → chi match 1 recipe

✅ DUNG: Dynamic RxPath trong UserCode
         string.Format("//text[@caption='{0}']", this.ModelName)
         → match bat ky recipe nao
```

### AP2: Tang timeout de che selector sai

```
❌ SAI: FindSingle(rxPath, 120000)  // 120s — "cho lau hon se tim thay"
         → Neu selector sai, 120s van fail. Chi lam test chay cham.

✅ DUNG: Xac nhan selector dung truoc, roi dat timeout hop ly.
         Wait app ready (signal) → FindSingle(rxPath, 15000)
```

### AP3: Phu thuoc child element khi value nam o parent

```
❌ SAI: string value = someText.Element.GetAttributeValueText("Caption");
         → CHILD co Caption = '' (rong)

✅ DUNG: string value = someText.Element.Parent.GetAttributeValueText("Caption");
         → PARENT co Caption = 'Lynn_Stacking_Underfill'

✅ TOT HON: Dung dynamic RxPath de tim PARENT truc tiep
         Host.Local.FindSingle<Ranorex.Text>(
             string.Format("//text[@caption='{0}']", expected), timeout);
```

### AP4: Implement fix truoc khi chung minh root cause

```
❌ SAI: "Selector fail → doi sang dynamic RxPath ngay"
         → Chua biet dynamic RxPath co match dung element khong

✅ DUNG: Investigation → Evidence (report logs) → Root Cause → Proposed Fix → Confirm → Implement
```

### AP5: Gop Wait va Validate thanh 1 buoc

```
❌ SAI: FindSingle(dynamicRxPath, 90000)
         → 90s timeout — khong biet app chua load hay selector sai

✅ DUNG:
   WaitForViewContainer(60000)     // Phase A: wait signal
   Delay.Seconds(3)               // Phase B: buffer
   FindSingle(dynamicRxPath, 15000) // Phase C: validate
   → Neu Phase C fail, biet chac app da ready va selector co van de
```

---

## Checklist cho lan sau

Khi gap van de tuong tu (test PASS voi 1 data row, FAIL voi row khac), kiem tra:

| # | Cau hoi | Cach kiem tra |
|---|---------|---------------|
| 1 | Expected value lay tu dau? | Xem `this.VariableName` — co tu CSV hay default? Kiem tra CSV va constructor |
| 2 | RxPath hien tai co hard-code khong? | Grep `@caption=` hoac `@text=` trong `.rxrep`. Bat ky value cu the nao = hard-code |
| 3 | Element chua value la child hay parent? | Investigation log: doc Caption/Text cua child va parent. Spy de xac nhan |
| 4 | UI da ready chua? | Tim signal element (vd: `container[@automationid='View']`). Kiem tra timing trong report |
| 5 | Co dang chay nhieu DataSource rows khong? | Xem `.rxtst` — Iterations = All rows? CSV co nhieu row khong? |
| 6 | Co warning repository cache khong? | Tim "caching" warning trong report. Repository `usecache="True"` co the giu element cu |
| 7 | Auto-generated code co dung repository item hard-code khong? | Doc `OpenFile.cs` — tim `repo.CCIMainWindow.SomeText` hoac `SomeIndicator` |
| 8 | Timeout co hop ly khong? | So sanh timeout voi thoi gian app load thuc te (tu report timing data) |

---

## Files lien quan

| File | Vai tro |
|------|---------|
| `OpenFile.UserCode.cs` | UserCode — noi implement dynamic RxPath |
| `OpenFile.cs` | Auto-generated — chua `SomeIndicatorInfo.WaitForExists` hard-code |
| `Lynn_DPI_ATRepository.rxrep` | Repository — chua RxPath hard-code. KHONG sua |
| `TestData/OpenFileData.csv` | Data source — chua ModelName, RecipeFilePath |
| `docs/HANDOVER_DynamicRxPath_TimingInvestigation.md` | Handover — timing investigation con dang cho |
| `docs/OpenFile_KNOWLEDGE.md` | Knowledge base — Section 8: ModelName Validation facts |

---

## Trang thai hien tai (2026-06-08)

- Dynamic RxPath da implement trong `ValidateModelName()` — **investigation version** (polling + timing logs).
- Build PASS. **Chua chay test** — can chay de lay timing data.
- `SomeIndicator` trong `OpenFile.cs` (auto-generated) van hard-code — se xu ly sau khi timing investigation xong.
- Dead code investigation cu con ton tai (line ~342-462) — khong anh huong runtime.

### Next action

1. Chay test voi investigation code → doc report lay timing data.
2. Dua tren timing data → implement version chinh thuc cua `ValidateModelName()`.
3. Xu ly `SomeIndicator` sau khi ValidateModelName on dinh.
