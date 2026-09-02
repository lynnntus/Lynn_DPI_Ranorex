# HANDOFF: RunProduction — Session 2026-09-02

> Ngay tao: 2026-09-02  
> Trang thai: APPROACH 4 DA IMPLEMENT — can deploy va test tren May B  
> File code: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/RunProduction.UserCode.cs` (~580 dong)  
> Commit truoc: `9a605f7` | Commit moi: (chua commit — cho user xac nhan)

---

## 1. Van de hien tai

### Bug chinh (CHUA FIX — dang thu thap evidence)

Step 5 trong RunProduction doc duoc **text label** thay vi **gia tri so** tu progress bar:

```
Ky vong:  "2/2"  (X/Y — produced/planned)
Thuc te:  "Production Information(Produced Qty./Planned Qty)"
```

- UI hien thi dung `"2/2"` — van de nam o cach doc attribute, khong phai UI
- Root cause CHUA DUOC CHUNG MINH — can evidence tu DIAG log

### Bug 2 (DA FIX)

Flow chay lap lai sau khi Step 5 FAIL — da fix bang guard pattern `_stepsRanFromInit` (commit 2026-08-25). Khong can dieu tra them.

---

## 2. Nhung gi da thuc hien

### 2.1. Code rewrite (truoc session nay)

- 3-approach fallback trong `ReadProgressBarText()`:
  1. TxtProducedQty repo item (Text, Caption)
  2. ProgressBar direct attributes (Text, Caption, AccessibleValue)
  3. Dynamic `Find<Ranorex.Text>(".//text")` — enum tat ca text children
- Regex validation `IsProgressValue()`: pattern `\d+\s*/\s*\d+`
- Guard pattern `_stepsRanFromInit` ngan recording steps chay lai

### 2.2. Approach 4 — Parent Search (session nay — chua commit)

Them Approach 4 vao `ReadProgressBarText()` (dong ~499-544):
- Tim text tu PARENT cua ProgressBar, leo toi da 3 level
- Moi level: log AutomationId + ControlTypeName (DIAG-A5 ParentSearch)
- Tim tat ca text elements bang `Find<Ranorex.Text>(".//text")`
- Doc 3 attribute: Text, Caption, AccessibleValue
- Chi nhan gia tri khop `IsProgressValue()` (regex `\d+\s*/\s*\d+`)
- Wrap trong try-catch voi DIAG logging
- Build: PASS — 0 error, 0 warning (Debug x86)

### 2.3. DIAG logging (session truoc — commit `9a605f7`)

Them diagnostic logging voi prefix `[DIAG_PROGRESS]` de grep trong Ranorex Report:

| ID | Vi tri | Log gi | Evidence cho |
|----|--------|--------|-------------|
| **DIAG-B1** | Step5 (dong 253-255) | Timestamp `System.DateTime.Now` khi Step5 bat dau | Timing baseline |
| **DIAG-B2** | Step5 polling loop (dong 270-272) | Poll iteration #, result, elapsed ms | Gia tri qua tung vong poll |
| **DIAG-B3** | Step5 catch ANR (dong 280-282) | Exception type, message | H5 (ANR co xay ra?) |
| **DIAG-A1** | ReadProgressBarText Approach 1 (dong 372-414) | TxtProducedQtyInfo.Exists(0), Visible, Enabled, ScreenRect, Text, Caption, AccessibleValue, Value, SelectionText | H1, H2 |
| **DIAG-A2** | ReadProgressBarText Approach 2 (dong 418-453) | ProgressBarInfo.Exists(0), Text, Caption, AccessibleValue, **Value**, Minimum, Maximum | H2 |
| **DIAG-A3** | ReadProgressBarText Approach 3 (dong 456-495) | Text children count, moi child: Text, Caption, **AccessibleValue**, Visible, ScreenRect | H1 (bao nhieu children, thu tu) |
| **DIAG-A4** | ReadProgressBarText outer catch (dong 500-507) | Exception type, message, phan biet ANR vs non-ANR | H5 |
| **DIAG-A5** | ReadProgressBarText Approach 4 (dong 499-544) | ParentSearch: level, AutomationId, ControlType, text count, Text/Caption/AccessibleValue cua moi text child | H7 (text la sibling) |

Helper moi: `SafeGetScreenRect()` (dong 521-525) — tra ve ScreenRectangle dang string, wrap try-catch.

### 2.3. Build

- MSBuild Debug x86: **0 error, 0 warning**
- Dung `System.DateTime` thay `DateTime` (tranh CS0104 ambiguous voi `Ranorex.DateTime`)

---

## 3. 6 gia thuyet can kiem chung

| # | Gia thuyet | Muc do | DIAG se cho thay |
|---|-----------|--------|-----------------|
| H1 | Selector TxtProducedQty match text LABEL thay vi VALUE | CAO | DIAG-A1: Exists=True nhung Text/Caption la label. DIAG-A3: nhieu text children, child nao chua X/Y |
| H2 | Doc sai thuoc tinh (Caption tra AutomationId, khong phai display text) | CAO | DIAG-A1: so sanh Text vs Caption vs AccessibleValue. DIAG-A2: tuong tu cho ProgressBar |
| H3 | Approach 3 (dynamic find) chua duoc test runtime | TRUNG BINH | DIAG-A3: Text children count, moi child Text/Caption/Visible |
| H4 | Stale cache reference | THAP-TB | DIAG-A1: ScreenRect co dung? Visible=True? |
| H5 | ANR (App Not Responding) | THAP | DIAG-B3/A4: exception logs neu co ANR |
| H6 | Timing — UI chua update progress bar | THAP-TB | DIAG-B2: gia tri thay doi qua cac poll iterations |
| **H7** | **Text "X/Y" la SIBLING cua ProgressBar, khong phai child** | **CAO — root cause** | **DIAG-A5: ParentSearch tim thay text khop X/Y tai level nao** |

---

## 4. File va code lien quan

### File chinh

| File | Dong | Noi dung |
|------|------|---------|
| `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/RunProduction.UserCode.cs` | 1-533 | Toan bo logic RunProduction |
| — Constants | 27-36 | Timeout/interval values |
| — Init() + flow | 41-72 | Entry point, goi RunProductionFlow() |
| — Step guards | 78-126 | `_stepsRanFromInit` guards |
| — Step5_VerifyProducedQuantityImpl() | 249-334 | Polling loop doc progress bar, DIAG-B1/B2/B3 |
| — ReadProgressBarText() | 368-508 | 3-approach fallback + DIAG-A1/A2/A3/A4 |
| — Helpers | 510-533 | IsProgressValue, SafeReadAttribute, SafeGetScreenRect, TakeScreenshot |

### Tai lieu tham chieu

| File | Noi dung |
|------|---------|
| `docs/HANDOFF_RunProduction_ProgressBar_DIAG_20260827.md` | Handoff goc: trieu chung, 6 gia thuyet, selector chi tiet, code path |
| `docs/lessons/INDEX.md` | Bang tra cuu trieu chung → lesson |
| `docs/lessons/wpf-caption-vs-textvalue.md` | WPF Caption tra AutomationId |
| `docs/lessons/openfile-dynamic-rxpath-lesson.md` | Dynamic RxPath cho hardcoded selector |

### Repository selectors lien quan

```
TxtProducedQty:
  RxPath:     .../progressbar[@automationid='progressBar']/text
  RobustPath: //text[@caption='1/1']        ← HARDCODE, chi match "1/1"
  UseCache:   False (ke thua tu MainView)

ProgressBar:
  RxPath:     .../progressbar[@automationid='progressBar']
  UseCache:   False (ke thua tu MainView)
```

---

## 5. Viec can tiep tuc

### Buoc 1: Commit va deploy (tren May A → May B)

1. User xac nhan → git commit + push tu May A
2. Git pull tren May B
3. Mo Ranorex Studio → chay test case chua RunProduction
4. Mo Ranorex Report → grep `[DIAG_PROGRESS]`

### Buoc 2: Kiem tra ket qua Approach 4

| Ky vong | DIAG log |
|---------|----------|
| ParentSearch L0/L1/L2 — thay text khop X/Y | `[DIAG_PROGRESS] ParentSearch L{n} Text[{j}]` |
| Return gia tri dung (vd: "2/2") | `[DIAG_PROGRESS] Poll #N result='2/2'` |
| Step 5 PASS | Ranorex Report status |

Neu Approach 4 KHONG tim thay text:
- Doc DIAG ParentSearch de xem AutomationId/ControlType tai moi level
- Xem xet tang so level (hien tai max 3)
- Hoac dung Spy de xac dinh vi tri chinh xac cua text element

### Buoc 3: Sau khi PASS stable

- Xoa DIAG logging (khong can giu lai trong production)
- Tao lesson moi cho H7 (text sibling pattern) → hoi user
- Update INDEX.md

---

## 6. Gioi han theo CLAUDE.md

| Quy tac | Chi tiet |
|---------|---------|
| CHI sua `*.UserCode.cs` | Khong sua `.cs` auto-generated, `.rxrec`, `.rxrep`, `.rxtst`, `.csproj` |
| Khong sua selector | Selector trong `.rxrep` do Ranorex quan ly |
| Khong hardcode | Credentials, duong dan tuyet doi, gia tri test data |
| Khong tang timeout | De che selector sai hoac timing issue chua hieu |
| Dung `this.VariableName` | Doc module variable tu Ranorex data binding, khong tu doc file |
| Dung `System.DateTime` | Tranh CS0104 ambiguous voi `Ranorex.DateTime` |
| Khong implement fix truoc evidence | Phai chung minh root cause bang DIAG report truoc |
| Doc INDEX.md truoc khi debug | Luon doi chieu trieu chung voi lessons da co |
| Thu muc code 3 cap | `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/` |

---

## 7. Lich su lien quan

| Ngay | Noi dung | Commit |
|------|---------|--------|
| 2026-08-25 | Rewrite RunProduction: 3-approach fallback, guard pattern, build PASS | (xem git log) |
| 2026-08-27 | Tao handoff DIAG doc (6 gia thuyet, selector details) | — |
| 2026-09-02 | Them DIAG logging [DIAG_PROGRESS], build PASS | `9a605f7` |
| 2026-09-02 | Bo sung DIAG gap: Value (A2), AccessibleValue (A3 log+return), build PASS | (xem git log) |
| 2026-09-02 | Phan tich DIAG tu May B → H1-H6 loai tru, xac dinh H7 (text la sibling) | — |
| 2026-09-02 | Implement Approach 4: ParentSearch 3 level + DIAG-A5, build PASS | (chua commit) |
