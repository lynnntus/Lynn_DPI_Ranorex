# Bài học: Debug Login Automation cho Neptune DPI

**Ngày ghi nhận:** 2026-05-26

---

## Vấn đề đã gặp

1. **Username bị nhập sai** — field hiển thị `aakyadman` thay vì `kyadmin` (text cũ không bị xóa, text mới chồng lên)
2. **`TryLoginWithUser()` không được Login_Pass recording gọi** — sửa hàm này nhưng Login_Pass recording không bị ảnh hưởng
3. **`IsLoginSuccessful()` timeout quá ngắn** — 20s không đủ cho app Neptune khởi động chậm

## Triệu chứng lúc đầu

- Screenshot trên Máy B: username field = `aakyadman`, lỗi "The user ID you entered is incorrect"
- Console log: repository caching warnings cho SomeText, XPWWatermark, Login — mỗi element mất ~1.5 phút tìm
- Thay đổi delay trong `TryLoginWithUser()` "không có tác dụng" khi chạy qua Login_Pass recording

## Nguyên nhân gốc (Root Cause)

### 1. `{Ctrl+A}` không hoạt động trên WPF ComboBox
- Element `SomeText` là **TextBlock display** bên trong ComboBox, không phải TextBox input
- `Ctrl+A` trong WPF ComboBox bị intercept bởi control cha → text cũ không được select hết → text mới nối vào text cũ
- Kết quả: `kyadmin` + `aa` (từ lần trước) = `aakyadman`

### 2. Login_Pass recording KHÔNG gọi TryLoginWithUser()
- `Login_Pass.cs` (auto-generated) gọi `Init()` rồi chạy recording steps trực tiếp
- `TryLoginWithUser()` chỉ được gọi bởi `LoginRetry.cs` (line 65)
- Sửa `TryLoginWithUser()` chỉ có tác dụng khi chạy qua LoginRetry, không ảnh hưởng Login_Pass recording

### 3. Timeout IsLoginSuccessful quá ngắn
- Timeout ban đầu 20s, app Neptune cần nhiều thời gian hơn để load main window
- Đã tăng lên 40s kèm validate text "Create or open recipe."

## Những gì đã thử mà KHÔNG hiệu quả

| Cách thử | Tại sao không hiệu quả |
|----------|----------------------|
| Tăng timeout `IsLoginSuccessful` từ 20s → 40s → 60s | Không giải quyết vấn đề text chồng — username vẫn bị nhập sai |
| Thêm delay trong `TryLoginWithUser()` | Không có tác dụng khi chạy Login_Pass recording, vì recording KHÔNG gọi hàm này |
| Dùng `{Ctrl+A}` để clear field trước khi nhập | WPF ComboBox intercept Ctrl+A ở control level — text không được select |
| Gọi `TryLoginWithUser()` từ `Init()` | Recording steps vẫn chạy sau Init() → gây double-login hoặc timeout |

## Cách fix đúng

1. **Thay `{Ctrl+A}` bằng `{Home}{Shift+End}{Delete}`** — hoạt động ở text cursor level, không bị WPF ComboBox intercept
2. **Tăng delay**: 500ms sau click (WPF focus transfer), 200ms giữa các keystroke
3. **Thêm log "BAT DAU CHAY VAO HAM TryLoginWithUser"** — để xác nhận hàm có thực sự được gọi hay không
4. **Rewrite `IsLoginSuccessful()`** — 40s wait + validate "Create or open recipe." + log THANH CONG/THAT BAI rõ ràng + screenshot
5. **Thêm skip check trong `Init()`** — nếu CCIMainWindow đã tồn tại (LoginRetry thành công trước đó), log và skip

## File đã thay đổi

| File | Phương thức thay đổi |
|------|---------------------|
| `Login_Pass.UserCode.cs` | `TypeIntoUserField()`, `TypeIntoPasswordField()`, `TryLoginWithUser()`, `IsLoginSuccessful()`, `ClearLoginFields()`, `Init()` |

## Rule rút ra cho lần sau

### R1: WPF ComboBox — dùng `{Home}{Shift+End}{Delete}` thay `{Ctrl+A}`
`Ctrl+A` bị WPF custom control intercept. Pattern `{Home}{Shift+End}{Delete}` hoạt động ở text cursor level, đáng tin cậy trên mọi WPF control.

### R2: Kiểm tra call chain trước khi sửa hàm
Trước khi sửa bất kỳ method nào, **xác nhận method đó thực sự được gọi** trong flow đang debug. Dùng `Grep` tìm tất cả caller. Nếu method chỉ được gọi bởi module khác (ví dụ LoginRetry), sửa nó sẽ không ảnh hưởng module đang xem xét (ví dụ Login_Pass recording).

### R3: Init() không thể skip recording steps
Trong Ranorex partial class, `Init()` chạy TRƯỚC recording steps nhưng không thể ngăn recording chạy. Chỉ có thể thêm logic bổ sung, không thể thay thế flow auto-generated.

### R4: Thêm log entry point khi debug flow
Luôn thêm `Report.Log` ở đầu hàm (ví dụ "BAT DAU CHAY VAO HAM TryLoginWithUser") để xác nhận hàm có được gọi hay không. Giúp phân biệt: hàm không chạy vs hàm chạy nhưng logic sai.

### R5: Login_Pass recording và TryLoginWithUser là 2 flow độc lập
- **Login_Pass recording**: `Init()` → auto-generated steps (click, type, click Login, delay 12s, WaitForExists 20s, validate)
- **TryLoginWithUser()**: Chỉ được gọi bởi `LoginRetry.cs` — clear field, type, click Login, delay 30s, `IsLoginSuccessful()`
- Sửa 1 flow không ảnh hưởng flow kia

## Dấu hiệu nhận biết vấn đề tương tự

- Text trong field bị **chồng/nối** thay vì replace → nghi `Ctrl+A` không hoạt động trên WPF control
- Sửa hàm nhưng **"không thấy tác dụng"** → kiểm tra call chain, hàm có thể không được gọi trong flow đang chạy
- **WPF ComboBox** hoặc custom control → không tin tưởng keyboard shortcut chuẩn (Ctrl+A, Ctrl+C, v.v.)
- Element có tên `*Watermark*`, `*Placeholder*` → có thể là display-only element, không phải input element

## Vấn đề chưa giải quyết

1. **Repository caching** trên Máy B — mỗi element mất ~1.5 phút tìm. Cần tắt `usecache="True"` trong Ranorex Studio
2. **Login_Pass recording chạy sau LoginRetry** trong SmokeTest — nếu LoginRetry thành công, Login_Pass recording sẽ timeout vì login window đã đóng. Cần restructure `.rxtst` trên Máy B
