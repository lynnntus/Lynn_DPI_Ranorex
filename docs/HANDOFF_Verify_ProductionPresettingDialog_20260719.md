# HANDOFF — Verify_ProductionPresettingDialog_AutoClose

> Ngay: 2026-07-19  
> Session: Refactor module verify dialog Production Presetting

---

## Task

Module `Verify_ProductionPresettingDialog_AutoClose` (doi ten tu `ApplyBtn_On_Production`) trong test suite `Production_TabNavigation`. Verify dialog "Production Presetting" tu dong dong khi chuyen sang tab Production, co fallback click Apply neu khong tu dong dong.

### Flow hien tai

```
BUOC 1: Cho dialog xuat hien (max 10s)
  → Exists(DIALOG_APPEAR_TIMEOUT_MS) — Ranorex native API

BUOC 2: Cho dialog tu dong dong (max 30s)
  → WaitForNotExists(DIALOG_AUTOCLOSE_TIMEOUT_MS) — try/catch
  → Thanh cong → TEST PASS, return
  → That bai → fall through sang Buoc 3

BUOC 3: FALLBACK — click Apply
  3a: Poll cho Apply button Visible+Enabled (max 10s) → click
  3b: WaitForNotExists(5s) verify dialog dong sau click Apply
```

---

## Trang thai

- Code da pass review (0 Critical, 2 Warning, 3 Suggestion — khong blocking)
- Buoc 1 + Buoc 2 da refactor tu poll thu cong `Exists(0)` sang Ranorex native API
- Build PASS (0 errors, 0 warnings)
- **DA FIX (2 buoc)**:
  1. Doi target: `SelfInfo.WaitForNotExists` → `BtnApplyProductionPresettingInfo.WaitForNotExists` (Buoc 2 + 3b)
  2. Tang timeout: `APPLY_CLOSE_VERIFY_TIMEOUT_MS` tu 5s → 15s (app can ~5-7s de xu ly Apply)
- Da thu sua Base path repo them `title='Production Presetting'` → van fail → fix bang cach doi target sang Apply button
- **CAN TEST MANUAL** tren may test de xac nhan fix hoat dong

---

## Root cause

Path `/form[@name='Popup']` qua generic, dung nham cac panel khac trong man hinh Production chinh. Ranorex Spy xac nhan nut Apply nam trong dialog co `title='Production Presetting'`.

**Van de cu the**: Sau khi click Apply, dialog dong thanh cong, nhung `SelfInfo.WaitForNotExists` van tim thay element vi `/form[@name='Popup']` match voi panel khac (khong phai dialog Production Presetting).

---

## Giai phap da implement (2026-07-19)

Refactor Buoc 2 va Buoc 3b: thay verify `SelfInfo.WaitForNotExists` tren dialog form → bang `BtnApplyProductionPresettingInfo.WaitForNotExists` tren nut Apply.

**Ly do**:
- Nut Apply chi ton tai khi dialog mo
- Path cua Apply button (`/form[@name='Popup']//button[@text='Apply']`) chinh xac hon
- Khi dialog dong → Apply button bien mat → `WaitForNotExists` thanh cong
- Du basepath match nham form khac, form do khong co `//button[@text='Apply']` → khong bi false match

**Thay doi cu the**:
- Line 71 (Buoc 2): `repo.InspectionRegionSettings.SelfInfo.WaitForNotExists` → `repo.InspectionRegionSettings.BtnApplyProductionPresettingInfo.WaitForNotExists`
- Line 138 (Buoc 3b): tuong tu

---

## Luu y quan trong

1. **Base path folder InspectionRegionSettings da bi sua** — them `title='Production Presetting'`. Can confirm co restore khong vi co the anh huong module khac dung cung folder.

2. **Items lien quan trong folder InspectionRegionSettings**:
   - `BtnDualClose`
   - `LOTProduction`
   - `Settings`
   - `ProductionStopsWhenAllLOTInspection`
   - `BtnApplyProductionPresetting`

3. **Lich su refactor session nay**:
   - Fix false failure Buoc 3b: `Exists(0)` poll → `WaitForNotExists` (da code, da build)
   - Fix W2 review: Buoc 1+2 poll thu cong → Ranorex native API (da code, da build)
   - Root cause Buoc 3b van con: path `/form[@name='Popup']` generic

---

## File lien quan

| File | Trang thai | Ghi chu |
|------|-----------|---------|
| `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/Verify_ProductionPresettingDialog_AutoClose.UserCode.cs` | **Can sua tiep** | Refactor Buoc 3b (va co the Buoc 2) dung Apply button thay dialog form |
| `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/Verify_ProductionPresettingDialog_AutoClose.rxrec` | Khong sua | Recording definition, chua `userrecorditem` goi `ClickApplyWithPolling` |
| `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_ATRepository.rxrep` | **Da sua** | Base path da them `title='Production Presetting'` — can review |

---

## Next step

1. **Test manual** tren may test: chay module, verify Buoc 2 va 3b khong false failure
2. Neu PASS → commit + push
3. Neu FAIL → investigate tiep, co the can xem lai basepath trong `.rxrep`
4. Review lai viec basepath da them `title='Production Presetting'` — confirm cac module khac dung folder `InspectionRegionSettings` khong bi anh huong

---

## Reference

| Tai lieu | Noi dung |
|----------|---------|
| [CLAUDE.md](../CLAUDE.md) | Project rules, coding conventions, known gotchas |
| [.claude/rules/safety.md](../.claude/rules/safety.md) | File safety rules |
| [.claude/rules/coding.md](../.claude/rules/coding.md) | Coding conventions |
| [.claude/agents/code-reviewer.md](../.claude/agents/code-reviewer.md) | Review checklist |
| [docs/ranorex-research/03_UserCode_Best_Practices.md](ranorex-research/03_UserCode_Best_Practices.md) | Ranorex API: Exists vs WaitForExists vs WaitForNotExists |
