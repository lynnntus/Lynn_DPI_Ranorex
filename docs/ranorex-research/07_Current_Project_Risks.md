# 07. Current Project Risks

> Tài liệu nghiên cứu nội bộ — Lynn_DPI_AT Project  
> Ngày: 2026-05-26

---

## 1. Tổng quan Risk Assessment

| Mức độ | Số lượng | Cần hành động |
|--------|----------|---------------|
| 🔴 HIGH | 2 | Ngay — ảnh hưởng test reliability |
| 🟡 MEDIUM | 4 | Sớm — ảnh hưởng maintainability và coverage |
| 🟢 LOW | 2 | Khi có thời gian — cải thiện quality |

---

## 2. Chi tiết từng Risk

### RISK-01: Repository Caching gây chậm trên Máy B 🔴 HIGH

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Repository caching (`usecache="True"`) trên Máy B khiến mỗi element mất ~1.5 phút để tìm |
| **File liên quan** | `Lynn_DPI_ATRepository.rxrep` |
| **Evidence** | `.claude/lessons/login-retry-lesson.md` — "Repository caching trên Máy B — mỗi element mất ~1.5 phút tìm" |
| **Impact** | Test chạy cực chậm trên Máy B. Timeout cascading (30s × 3 levels = 90s) cộng thêm caching delay → có thể mất 3-5 phút chỉ cho login flow |
| **Nguyên nhân gốc** | `usecache="True"` trên CCILoginWindow + timeout cascading qua nhiều rooted folder |
| **Hướng xử lý** | 1. Thử tắt `usecache="False"` cho CCILoginWindow trong Ranorex Studio. 2. Giảm timeout cho nested folders. 3. Flatten repository hierarchy nếu có thể |
| **Need to verify** | Tắt caching có thực sự cải thiện performance trên Máy B không |

---

### RISK-02: Login_Pass recording chạy sau LoginRetry → conflict 🔴 HIGH

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Trong SmokeTest, Login_Pass recording chạy SAU LoginRetry. Nếu LoginRetry đã login thành công, Login_Pass recording vẫn chạy tất cả steps (click vào fields, nhập credentials) trên main window thay vì login window |
| **File liên quan** | `Lynn_DPI_AT.rxtst`, `Login_Pass.cs`, `Login_Pass.UserCode.cs` |
| **Evidence** | `Login_Pass.UserCode.cs` — Init() kiểm tra `CCIMainWindow.Exists(2000)` và log "skip" nhưng recording steps vẫn chạy. `Login_Pass.cs` — Run() gọi Init() rồi chạy recording steps bất kể Init() làm gì |
| **Impact** | Recording steps thao tác trên main window thay vì login window → click sai element → test fail hoặc hành vi không mong muốn |
| **Nguyên nhân gốc** | Init() KHÔNG THỂ skip recording steps (Ranorex limitation) |
| **Hướng xử lý** | 1. Tách Login_Pass ra khỏi SmokeTest flow (không cần nếu đã có LoginRetry). 2. Hoặc: thêm conditional logic trong recording steps (cần sửa recording). 3. Hoặc: chuyển Login_Pass thành UserCode module hoàn toàn |

---

### RISK-03: Fixed coordinates trong Click() ⚠️ 🟡 MEDIUM

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Tất cả Click() dùng element-relative pixel coordinates thay vì click vào center |
| **File liên quan** | `Login_Pass.UserCode.cs` |
| **Evidence** | `SomeText.Click("47;2")`, `XPWWatermark.Click("36;6")`, `Login.Click("10;8")` |
| **Impact** | Coordinates có thể sai khi element resize, DPI scaling thay đổi, hoặc font size khác. Hiện tại hoạt động nhưng fragile cho long-term |
| **Nguyên nhân gốc** | Coordinates được ghi lại từ recording session, chưa được optimize |
| **Hướng xử lý** | Chuyển sang `Click()` không tham số (click center) hoặc dùng Proportional coordinates. Test lại trên Máy B sau khi thay đổi |

---

### RISK-04: Recording1 trống — chưa có test logic chính 🟡 MEDIUM

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Recording1 module không có test action nào. Đây được thiết kế là nơi đặt test logic chính cho inspection flow nhưng chưa implement |
| **File liên quan** | `Recording1.cs`, `Recording1.UserCode.cs`, `Recording1.rxrec` |
| **Evidence** | `Recording1.cs` — chỉ có empty constructor và Init(). `Recording1.UserCode.cs` — Init() rỗng |
| **Impact** | SmokeTest hiện chỉ test Login, chưa test bất kỳ chức năng chính nào của Neptune DPI |
| **Nguyên nhân gốc** | Project mới bắt đầu, chưa đến giai đoạn implement test chính |
| **Hướng xử lý** | Xác định test scenario chính cho inspection flow → record hoặc viết UserCode cho Recording1 |

---

### RISK-05: Users_DataSource.csv chỉ có header 🟡 MEDIUM

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | File CSV chỉ có 1 dòng header `UserName,Password`, không có data rows |
| **File liên quan** | `Lynn_DPI_AT/Lynn_DPI_AT/Lynn_DPI_AT/Users_DataSource.csv` |
| **Evidence** | File content: `UserName,Password` (1 line only) |
| **Impact** | Nếu module bind vào CSV này, sẽ không có data rows → module chạy 0 lần hoặc dùng default values |
| **Nguyên nhân gốc** | CSV connector tạo ra nhưng chưa populate data |
| **Hướng xử lý** | Thêm data rows vào CSV. Lưu ý: file `TestData/Users.csv` (ở git root) có 2 rows — có thể dùng làm source |

---

### RISK-06: Login_Pass có missingdatabinding 🟡 MEDIUM

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | `.rxtst` chứa tag `<missingdatabinding>` cho Login_Pass module |
| **File liên quan** | `Lynn_DPI_AT.rxtst` |
| **Evidence** | XML tag `<missingdatabinding>` trong test suite definition |
| **Impact** | Module variables UserName và Password dùng default values thay vì CSV data. Login_Pass recording luôn dùng cùng 1 credential |
| **Nguyên nhân gốc** | Data binding chưa được cấu hình hoàn chỉnh trong Ranorex Studio |
| **Hướng xử lý** | Mở Ranorex Studio → Login_Pass → Data Binding → map columns từ CSV connector |

---

### RISK-07: Fixed delays thay vì dynamic wait 🟢 LOW

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Một số chỗ dùng `Delay.Milliseconds()` cố định thay vì dynamic wait |
| **File liên quan** | `Login_Pass.UserCode.cs`, `Login_Pass.cs` |
| **Evidence** | `Delay.Milliseconds(30000)` sau click Login trong TryLoginWithUser(). `Delay.Duration(12000)` trong Login_Pass recording |
| **Impact** | Test luôn mất ít nhất 30 giây cho login bất kể app phản hồi nhanh. Trên máy nhanh, lãng phí 20+ giây mỗi lần login |
| **Nguyên nhân gốc** | Delay cố định đơn giản hơn dynamic wait, hoạt động ổn định dù không tối ưu |
| **Hướng xử lý** | Thay `Delay(30000)` bằng vòng lặp kiểm tra `CCIMainWindow.Exists(2000)` mỗi 2 giây. Giữ max timeout 60 giây |

---

### RISK-08: Absolute CSV path trong .rxtst 🟢 LOW

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Đường dẫn CSV trong `.rxtst` là absolute path |
| **File liên quan** | `Lynn_DPI_AT.rxtst` |
| **Evidence** | CSV connector path chứa `D:\RanorexProjects\...` |
| **Impact** | Test chỉ chạy được trên máy có đúng cấu trúc thư mục `D:\RanorexProjects\...`. Không chạy được trên máy khác hoặc CI/CD |
| **Nguyên nhân gốc** | Ranorex Studio mặc định dùng absolute path khi thêm data source |
| **Hướng xử lý** | Đổi sang relative path trong Ranorex Studio → Data Sources → sửa connector path |

---

## 3. Risk Matrix

```
Impact ↑
       │
  HIGH │  RISK-01        RISK-02
       │  (Caching)      (Login conflict)
       │
  MED  │  RISK-05   RISK-06   RISK-03   RISK-04
       │  (CSV)     (Binding) (Coords)  (Recording1)
       │
  LOW  │                      RISK-07   RISK-08
       │                      (Delays)  (Abs path)
       │
       └──────────────────────────────────────────→ Likelihood
            LOW          MEDIUM           HIGH
```

---

## 4. Ưu tiên xử lý

| Ưu tiên | Risk ID | Hành động | Effort |
|---------|---------|-----------|--------|
| 1 | RISK-02 | Tách Login_Pass khỏi SmokeTest hoặc thêm skip logic | Thấp |
| 2 | RISK-01 | Test tắt caching trên Máy B | Thấp |
| 3 | RISK-06 | Cấu hình data binding cho Login_Pass | Thấp |
| 4 | RISK-05 | Populate CSV data | Thấp |
| 5 | RISK-03 | Chuyển coordinates sang center click | Trung bình |
| 6 | RISK-07 | Thay fixed delay bằng dynamic wait | Trung bình |
| 7 | RISK-04 | Implement Recording1 test logic | Cao |
| 8 | RISK-08 | Đổi absolute path sang relative | Thấp |

---

## 5. Tham khảo

- `Login_Pass.UserCode.cs` — source code login flow
- `Login_Pass.cs` — auto-generated recording steps
- `LoginRetry.cs` — credential retry module
- `Lynn_DPI_AT.rxtst` — test suite configuration
- `Lynn_DPI_ATRepository.rxrep` — UI element repository
- `.claude/lessons/login-retry-lesson.md` — lessons learned
- `.claude/rules/testing.md` — testing rules
