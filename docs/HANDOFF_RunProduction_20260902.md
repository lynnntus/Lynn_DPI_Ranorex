# HANDOFF: RunProduction — Session 2026-09-02

> Ngay tao: 2026-09-02  
> Trang thai: DIAG DA BO SUNG — can deploy va test tren May B  
> File code: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/RunProduction.UserCode.cs` (534 dong)  
> Commit truoc: `9a605f7` | Commit moi: (xem git log)

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

### 2.2. DIAG logging (session nay — commit `9a605f7`)

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

### Buoc 1: Deploy va test (tren May B)

1. Git push tu May A
2. Git pull tren May B
3. Mo Ranorex Studio → chay test case chua RunProduction
4. Mo Ranorex Report → grep `[DIAG_PROGRESS]`

### Buoc 2: Phan tich DIAG output

Voi ket qua DIAG, tra loi cac cau hoi:

| Cau hoi | Xem DIAG nao |
|---------|--------------|
| TxtProducedQtyInfo.Exists(0) = True hay False? | DIAG-A1 |
| Neu True: Text va Caption cua no la gi? | DIAG-A1 |
| ProgressBarInfo.Exists(0) = True hay False? | DIAG-A2 |
| Co bao nhieu text children trong ProgressBar? | DIAG-A3 |
| Text child nao chua gia tri X/Y? | DIAG-A3 TextChild[i] |
| Co ANR exception nao khong? | DIAG-B3, DIAG-A4 |
| Gia tri co thay doi qua cac poll iterations? | DIAG-B2 |

### Buoc 3: Xac dinh root cause va fix

Sau khi co evidence, doi chieu voi 6 gia thuyet (H1-H6):
- Neu H1 confirmed → sua selector hoac doi approach doc child text dung
- Neu H2 confirmed → doi thuoc tinh doc (AccessibleValue, Value, v.v.)
- Neu H3 confirmed → Approach 3 da hoat dong, chi can uu tien no
- Fix phai duoc chung minh bang evidence TRUOC KHI implement

### Buoc 4: Sau khi fix

- Xoa DIAG logging (khong can giu lai trong production)
- Tao lesson moi neu root cause dang ghi lai (hoi user)
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
