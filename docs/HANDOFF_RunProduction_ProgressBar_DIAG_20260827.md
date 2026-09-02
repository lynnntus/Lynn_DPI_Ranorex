# HANDOFF: RunProduction — ProgressBar Diagnostic

> Ngay tao: 2026-08-27  
> Trang thai: CHUA CHUNG MINH — can thu thap evidence tu Ranorex Report + Spy  
> Muc dich: Tai lieu ban giao de debug Step 5 trong RunProduction module

---

## 1. Trieu chung hien tai

### Bao cao tu test run lan 1 (2026-08-25)

```
Step 5: Progress bar text = 'Production Information(Produced Qty./Planned Qty)'
Step 5 FAIL: Khong parse duoc so tu 'Production Information(Produced Qty.'
```

- **Ky vong**: Step 5 doc gia tri dang `"X/Y"` (vi du `"2/2"`) tu progress bar
- **Thuc te**: Doc duoc text label tieu de thay vi gia tri so
- UI hien thi dung `"2/2"` tren progress bar — van de nam o cach doc, khong phai UI

### Bug 2 (DA FIX): Flow chay lai

- Sau khi Step 5 FAIL, recording steps goi lai Step1 → flow chay lai tu dau
- **Da fix** bang guard pattern `_stepsRanFromInit` — recording steps skip khi Init() da chay
- Bug 2 KHONG can dieu tra them

### Trang thai sau fix (2026-08-25)

Code da duoc rewrite voi:
- 3-approach fallback trong `ReadProgressBarText()` + regex validation `\d+/\d+`
- Guard pattern cho recording steps
- Build PASS

**CHUA TEST TREN MAY B** — chua biet fix Bug 1 co hoat dong runtime hay khong.

---

## 2. Flow RunProduction hien tai

```
Init()
  ├── Validate ProductionContext.LastInspectionQuantity
  ├── Set _stepsRanFromInit = true
  └── RunProductionFlow()
        ├── Step1_ClickRunImpl()        — Click nut Run
        ├── Step2_WaitForInspectionCompleteImpl()  — Polling cho Notice popup (max 10h)
        │     └── ReadProgressBarText() dung cho heartbeat log
        ├── Step3_ClickConfirmOnNoticeImpl()  — Click Confirm tren Notice popup
        ├── Step4_ClickCancelOnLotSettingsImpl()  — Click Cancel tren LOT Settings
        └── Step5_VerifyProducedQuantityImpl()  — Doc progress bar value, so sanh voi expected
              └── ReadProgressBarText() — HAM CAN DIEU TRA

Auto-generated Run():
  Init()  →  Step1()  →  Step2()  →  Step3()  →  Step4()  →  Step5()
                ↓           ↓           ↓           ↓           ↓
            [SKIP]      [SKIP]      [SKIP]      [SKIP]      [SKIP]
            (guard)     (guard)     (guard)     (guard)     (guard)
```

### Diem then chot

- Toan bo logic chay trong `Init()` → `RunProductionFlow()`
- Recording steps (goi boi auto-generated `Run()`) chi la no-op guards
- `Step5_VerifyProducedQuantityImpl()` la noi doc va verify progress bar value
- `ReadProgressBarText()` cung duoc goi trong Step 2 heartbeat log

---

## 3. Lessons da kiem tra (tu INDEX.md)

| Lesson | Lien quan | Ket luan |
|--------|-----------|----------|
| **WPF Caption vs Text** | TRUC TIEP | Caption co the tra label/AutomationId thay vi display text. Fix hien tai: doc `Text` truoc, `Caption` sau, validate bang regex |
| **Dynamic RxPath for Hardcoded Selectors** | TRUC TIEP | `TxtProducedQty` robustPath hardcode `@caption='1/1'` — chi match khi gia tri la "1/1" |
| **Use Cache Stale Element** | CAN KIEM TRA | MainView folder co `usecache="False"` nhung cac item con khong set rieng — can xac nhan cache behavior |
| **ANR State Cascade** | DA XU LY | Code da co try-catch cho `ApplicationNotResponding` trong polling loop |
| **Recording Step Action Timeout** | DA XU LY | Logic nam trong Init(), recording steps la no-op |
| **Init() Limitations** | DA XU LY | Guard pattern `_stepsRanFromInit` bypass recording steps |
| **Dialog Close Polling Timeout** | CAN KIEM TRA | Sau Step 4 dong LOT Settings, co the can thoi gian cho UI update progress bar |

---

## 4. Code path va selector lien quan

### 4.1. Repository selectors

#### TxtProducedQty

```
Name:         TxtProducedQty
RxPath:       /form[@title='CCIMainWindow']/container[@automationid='MainView']
              /?/?/container[@automationid='area5_2']
              //progressbar[@automationid='progressBar']/text
RobustPath:   /form[@title='CCIMainWindow']//text[@caption='1/1']
SearchTimeout: 30000ms
UseCache:     (khong set — ke thua tu parent MainView: False)
AddCaps:      text,wpfelement
```

**Van de**: 
- RobustPath hardcode `@caption='1/1'` → chi match khi Caption cua text element = "1/1"
- RxPath dung `.../progressbar/text` (khong co index) → co the match bat ky text child nao
- Progressbar co the co NHIEU text children (label + value)

#### ProgressBar

```
Name:         ProgressBar
RxPath:       /form[@title='CCIMainWindow']/container[@automationid='MainView']
              /?/?/container[@automationid='area5_2']
              //progressbar[@automationid='progressBar']
RobustPath:   /form[@title='CCIMainWindow']//container[@automationid='area5_2']
              /checkbox/container[4]/progressbar[@automationid='progressBar']
SearchTimeout: 30000ms
UseCache:     (khong set — ke thua tu parent MainView: False)
AddCaps:      progressbar,wpfelement,wpfgroupelement
```

#### Parent: MainView folder

```
Name:         MainView
IsRooted:     True
SearchTimeout: 30000ms
UseCache:     False
BasePath:     /form[@title='CCIMainWindow']/container[@automationid='MainView']
```

### 4.2. Code path — ReadProgressBarText()

File: `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/RunProduction.UserCode.cs` (dong 352-405)

```
ReadProgressBarText()
├── Approach 1: repo.TxtProducedQty
│   ├── SafeReadAttribute(el, "Text")  → check IsProgressValue() (regex \d+/\d+)
│   └── SafeReadAttribute(el, "Caption") → check IsProgressValue()
│
├── Approach 2: repo.ProgressBar attributes
│   ├── SafeReadAttribute(pbEl, "Text")
│   ├── SafeReadAttribute(pbEl, "Caption")
│   └── SafeReadAttribute(pbEl, "AccessibleValue")
│
├── Approach 3: Dynamic find text children
│   └── repo.ProgressBar.Find<Ranorex.Text>(".//text")
│       └── foreach text: check Text, Caption attributes
│
└── Fallback: return "(no X/Y found)"
```

**Regex validation** (moi approach):
```csharp
private bool IsProgressValue(string val)
{
    return !string.IsNullOrEmpty(val) && Regex.IsMatch(val, @"\d+\s*/\s*\d+");
}
```

### 4.3. Code path — Step5_VerifyProducedQuantityImpl()

File: `RunProduction.UserCode.cs` (dong 249-318)

```
Step5_VerifyProducedQuantityImpl()
├── Delay 2000ms (cho UI stabilize)
├── Polling loop (max IDLE_VERIFY_TIMEOUT_MS = 10s)
│   ├── Goi ReadProgressBarText()
│   ├── Neu IsProgressValue() → break (co gia tri X/Y)
│   └── Neu khong → tiep tuc polling (1s interval)
│
├── Parse gia tri: split "/" → lay produced (phan truoc /)
├── So sanh produced vs _expectedQty
├── Log PASS hoac FAIL + screenshot
└── KHONG throw exception — chi log
```

---

## 5. Gia thuyet hien tai

### H1: Selector TxtProducedQty match text LABEL thay vi text VALUE (CAO)

**Co so**: 
- RxPath `.../progressbar/text` khong co index — match text child dau tien
- Progressbar co the co nhieu text children: label ("Production Information...") + value ("2/2")
- Text run dau la label → Approach 1 doc label truoc

**Can chung minh**: Ranorex Spy → xem so luong text children cua progressbar, thu tu va attribute values

### H2: Doc sai thuoc tinh Text/Caption/Value (CAO)

**Co so**: 
- Lesson WPF Caption vs Text: WPF controls thuong tra AutomationId qua Caption
- Text attribute co the la null/empty trong mot so WPF implementation
- AccessibleValue co the chua gia tri nhung chua duoc test

**Can chung minh**: Spy → xem tat ca attributes cua text element chua "X/Y"

### H3: Approach 3 (dynamic Find) chua duoc test runtime (TRUNG BINH)

**Co so**: 
- `repo.ProgressBar.Find<Ranorex.Text>(".//text")` — chua xac nhan Adapter.Find<T> API ton tai
- Neu Approach 1 va 2 deu miss, Approach 3 la fallback cuoi cung
- Wrapped trong try-catch, se khong crash nhung se return "(no X/Y found)"

**Can chung minh**: Chay test, xem log co den Approach 3 hay khong

### H4: Stale cache sau khi dong LOT Settings (THAP-TRUNG BINH)

**Co so**: 
- MainView folder co `usecache="False"` → moi truy cap search lai
- NHUNG: `Exists(0)` chi check co mat, khong dam bao element DUNG (co the match label)
- Sau Step 4 (dong LOT Settings), UI co the can thoi gian render lai progress bar

**Can chung minh**: Them DIAG log thoi gian giua Step 4 ket thuc va Step 5 bat dau doc

### H5: ApplicationNotResponding (THAP)

**Co so**: 
- App Neptune co the hung sau inspection (da thay o Step 2)
- ANR khien `GetAttributeValueText()` throw → ReadProgressBarText() catch va return "(read error)"
- Code DA co ANR handling nhung chi o polling level, khong phai o read level

**Can chung minh**: Xem Ranorex Report co ANR warning giua Step 4-5 hay khong

### H6: Timing — progress bar chua update sau dong LOT Settings (THAP-TRUNG BINH)

**Co so**: 
- Step 5 co 2s delay ban dau + polling 10s — co the du
- NHUNG: LOT Settings dialog co the trigger UI refresh — progress bar value thay doi sau khi dialog dong

**Can chung minh**: Them DIAG doc progress bar NGAY SAU Step 4 va TRUOC Step 5 delay

---

## 6. Nhung viec CHUA duoc chung minh

| # | Viec | Cach chung minh |
|---|------|-----------------|
| 1 | Text element nao trong progressbar chua gia tri "X/Y" | Ranorex Spy: navigate den progressbar → list all children |
| 2 | Attribute nao chua "X/Y" (Text, Caption, AccessibleValue, khac) | Spy: xem attribute list cua text element co "X/Y" |
| 3 | RxPath cua repo match dung element nao | Spy: Track → paste RxPath → xem match count va element |
| 4 | `Adapter.Find<Ranorex.Text>(".//text")` co hoat dong runtime | Chay test, xem log Approach 3 |
| 5 | Thoi gian giua Step 4 close va Step 5 read | Them DIAG timestamp log |
| 6 | Fix hien tai co doc dung gia tri "X/Y" hay khong | Chay test tren May B |

---

## 7. Ke hoach session tiep theo

### Nguyen tac: CHI THEM DIAG, CHUA SUA SELECTOR, CHUA TANG TIMEOUT

### Buoc 1: Thu thap evidence tu May B

1. **Chay test** tren May B voi code hien tai (da fix)
2. **Doc Ranorex Report** — tim:
   - Step 5 log: "Progress bar value = ..." → gia tri thuc te doc duoc
   - Co xuat hien "(no X/Y found)" hay "(read error)" khong
   - Co ANR warning giua Step 4-5 khong
   - Recording steps co log "Da chay trong Init(). Skip." khong (xac nhan Bug 2 fix)
3. **Chup Ranorex Report** screenshots cac doan Step 4 va Step 5

### Buoc 2: Dieu tra bang Ranorex Spy (tren May B)

1. Mo Neptune app → chay production den khi hien thi "X/Y" tren progress bar
2. Ranorex Spy → **Track** element chua "X/Y"
3. Ghi lai:
   - RxPath cua element do
   - Tat ca attributes (Text, Caption, AccessibleValue, Name, ClassName)
   - Parent element va children
4. Spy → Track progressbar element → xem **so luong text children**
5. So sanh RxPath cua element chua "X/Y" voi repo `TxtProducedQty` RxPath

### Buoc 3: Them DIAG log (neu can)

Neu test chay nhung Step 5 van FAIL, them DIAG vao `ReadProgressBarText()`:

```csharp
// DIAG — chi de debug, xoa sau khi fix
Report.Log(ReportLevel.Info, "DIAG", string.Format(
    "TxtProducedQty — Text='{0}' Caption='{1}'", textVal, captionVal));
```

Tuong tu cho moi approach trong ReadProgressBarText().

**LUU Y**: Chi them log, KHONG sua selector, KHONG tang timeout, KHONG sua .rxrep.

### Buoc 4: Phan tich va quyet dinh

Dua tren evidence:
- Neu Approach 1 match nhung doc sai attribute → sua ReadProgressBarText() logic
- Neu Approach 1 match sai element → can dynamic RxPath (lesson openfile-dynamic-rxpath)
- Neu Approach 3 crash → dung `Host.Local.Find<Ranorex.Text>()` thay vi `adapter.Find<T>()`
- Neu timing issue → them delay hoac polling truoc khi doc

---

## 8. File duoc phep va KHONG duoc phep sua

### DUOC PHEP sua

| File | Ghi chu |
|------|---------|
| `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/RunProduction.UserCode.cs` | File chinh — them DIAG log, sua ReadProgressBarText() |
| `docs/**/*.md` | Tai lieu, handoff, lessons |
| `.claude/**/*.md` | Rules, lessons, context |

### KHONG DUOC sua

| File | Ly do |
|------|-------|
| `RunProduction.cs` | Auto-generated tu RunProduction.rxrec |
| `Lynn_DPI_ATRepository.cs` | Auto-generated tu .rxrep |
| `Lynn_DPI_ATRepository.rxrep` | Repository — Ranorex quan ly |
| `RunProduction.rxrec` | Recording definition |
| `Lynn_DPI_AT.rxtst` | Test suite config |
| `Lynn_DPI_AT.csproj` | Project file |
| `*.rximg` | Repository image blob |
| Tat ca file `.cs` KHONG co hau to `.UserCode.cs` | Auto-generated, se bi ghi de |

---

## 9. Thong tin can thu thap

### Tu Ranorex Report (sau khi chay test)

| # | Thong tin | Muc dich |
|---|-----------|----------|
| 1 | Step 5 log message day du | Xem ReadProgressBarText() tra ve gi |
| 2 | Co log "Da chay trong Init(). Skip." khong | Xac nhan Bug 2 fix |
| 3 | Timestamp Step 4 OK → Step 5 bat dau | Do timing gap |
| 4 | ANR warnings (neu co) | Xac nhan H5 |
| 5 | Step 2 heartbeat progress value | Xem heartbeat co doc dung khong |
| 6 | Screenshot tai thoi diem Step 5 | So sanh UI vs gia tri doc |

### Tu Ranorex Spy (investigation)

| # | Thong tin | Muc dich |
|---|-----------|----------|
| 1 | So luong text children cua progressbar element | Xac nhan H1 (nhieu children) |
| 2 | Attributes cua TUNG text child | Tim element nao chua "X/Y" |
| 3 | RxPath chinh xac cua text element chua "X/Y" | So sanh voi repo TxtProducedQty |
| 4 | Caption vs Text vs AccessibleValue cua text element | Xac nhan H2 |
| 5 | Element tree: progressbar → children | Hieu cau truc UI |
| 6 | Track repo TxtProducedQty → xem match element nao | Xac nhan RxPath match dung |

### Checklist truoc khi sua code

- [ ] Da co Ranorex Report tu test run moi nhat
- [ ] Da Spy progressbar element va list children
- [ ] Da xac dinh element nao chua "X/Y"
- [ ] Da xac dinh attribute nao chua "X/Y" (Text/Caption/khac)
- [ ] Da so sanh RxPath repo vs RxPath thuc te
- [ ] Da ghi nhan evidence vao handoff/investigation notes
- [ ] Root cause da duoc chung minh bang evidence

---

## Appendix A: Auto-generated Run() — tham khao

```csharp
// File: RunProduction.cs (AUTO-GENERATED — KHONG SUA)
void ITestModule.Run()
{
    Mouse.DefaultMoveTime = 300;
    Keyboard.DefaultKeyPressTime = 20;
    Delay.SpeedFactor = 1.00;

    Init();

    Step1_ClickRun();
    Delay.Milliseconds(0);
    Step2_WaitForInspectionComplete();
    Delay.Milliseconds(0);
    Step3_ClickConfirmOnNotice();
    Delay.Milliseconds(0);
    Step4_ClickCancelOnLotSettings();
    Delay.Milliseconds(0);
    Step5_VerifyProducedQuantity(ValueConverter.ArgumentFromString<int>("expectedQty", "0"));
    Delay.Milliseconds(0);
}
```

## Appendix B: ReadProgressBarText() — 3 approach hien tai

```
Approach 1: repo.TxtProducedQty
  → Text attr → regex check
  → Caption attr → regex check

Approach 2: repo.ProgressBar direct attributes  
  → Text, Caption, AccessibleValue → regex check

Approach 3: Dynamic find children
  → repo.ProgressBar.Find<Ranorex.Text>(".//text")
  → foreach child: Text, Caption → regex check

Fallback: "(no X/Y found)"
```

Regex pattern: `\d+\s*/\s*\d+` — match "X/Y" voi tuy y khoang trang quanh "/".

## Appendix C: ProductionContext — cross-module data

```csharp
// File: ProductionContext.cs (16 dong)
public static class ProductionContext
{
    public static string LastInspectionQuantity { get; set; }
    public static void Reset()
    {
        LastInspectionQuantity = null;
        Report.Log(ReportLevel.Info, "ProductionContext", "Da reset context.");
    }
}
```

- `LastInspectionQuantity` duoc set boi module truoc RunProduction (OpenFile_FromProduction)
- RunProduction doc gia tri nay trong `Init()` de biet so boards can inspect
- KHONG dung module variable / data binding vi RunProduction khong co CSV rieng
