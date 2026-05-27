# 04. Repository Best Practices

> Tài liệu nghiên cứu nội bộ — Lynn_DPI_AT Project  
> Ngày: 2026-05-26

---

## 1. Repository hoạt động như thế nào

Ranorex Repository là **centralized storage** cho tất cả UI element definitions. Mỗi element được định nghĩa bằng:

- **Logical name** — tên dễ đọc (ví dụ: `CCILoginWindow.Login`)
- **RxPath** — selector để tìm element trên UI (ví dụ: `button[@automationid='xLoginButton']`)
- **Timeout** — thời gian chờ tối đa khi tìm element

Repository được truy cập qua singleton pattern:
```csharp
public static Lynn_DPI_ATRepository repo = Lynn_DPI_ATRepository.Instance;

// Sử dụng
repo.CCILoginWindow.Login.Click("10;8");
repo.CCIMainWindow.SelfInfo.WaitForExists(30000);
```

---

## 2. RxPath (RanoreXPath)

### 2.1 Anatomy

```
/form[@name='View']/?/?/button[@automationid='xLoginButton']/text[@caption='Login']
│                   │     │                                    │
└── Root element    │     └── Attribute selector               └── Child element
                    └── Wildcard (any child)
```

### 2.2 Operators

| Operator | Ý nghĩa | Ví dụ |
|----------|---------|-------|
| `@` | Attribute selector | `@name='View'` |
| `~` | Regex match | `@id~'btn_\d+'` |
| `>` | Starts with | `@id>'btn_'` |
| `?` | Any single child | `/?/?/button` |
| `//` | Any descendant | `.//text[@caption='']` |

### 2.3 XPath Axes (nâng cao)

| Axis | Dùng khi |
|------|----------|
| `ancestor::` | Tìm element cha ở bất kỳ level nào |
| `..` | Đi lên 1 level (parent) |
| `following-sibling::` | Tìm sibling sau element hiện tại |

---

## 3. Chọn Selector ổn định

### 3.1 Ưu tiên Stable Attributes

| Ưu tiên | Attribute | Lý do |
|---------|-----------|-------|
| 1 | `@automationid` | Dev gán, ít thay đổi |
| 2 | `@name` | Control name, thường stable |
| 3 | `@innertext` / `@caption` | Text hiển thị, stable nếu không i18n |
| 4 | `@class` | Control type |
| ❌ | Dynamic IDs | Thay đổi mỗi lần chạy app |

### 3.2 Ví dụ trong project

```
✅ Stable — dùng automationid
button[@automationid='xLoginButton']
text[@automationid='xPW']
container[@automationid='xIDPWLoginArea']

✅ Stable — dùng name/title
form[@name='View']            ← Login window
form[@title='CCIMainWindow']  ← Main window

⚠️ Fragile — caption rỗng
text[@caption='']             ← SomeText (username field)
                                 Có thể match nhiều elements
```

### 3.3 Tránh path quá dài

```
// ❌ Fragile — quá nhiều level, dễ break khi UI thay đổi
/form[@name='View']/container/container/stackpanel/grid/textbox[@id='123']

// ✅ Stable — dùng automationid, ít level
/form[@name='View']/?/?/text[@automationid='xPW']
```

---

## 4. Attribute Weight System

Ranorex dùng **weight** để quyết định attribute nào được ưu tiên khi sinh RxPath:

| Weight | Ý nghĩa |
|--------|---------|
| > 100 | Attribute được dùng trong path |
| = 100 | Ngưỡng mặc định |
| < 100 | Attribute bị bỏ qua |
| 0 | Hoàn toàn bỏ qua |

### Cách điều chỉnh

1. Mở Ranorex Spy → Track element
2. Xem danh sách attributes và weights
3. **Tăng weight** cho stable attributes (automationid, name)
4. **Giảm weight** cho dynamic attributes (random IDs)

**Ví dụ:** Nếu element có dynamic `@id='rand_12345'` (weight 200) và stable `@automationid='loginBtn'` (weight 150):
- Giảm `@id` weight xuống 0
- Ranorex sẽ dùng `@automationid` thay thế

---

## 5. Dynamic Elements

### 5.1 Dùng Regex

```
// Match IDs với pattern thay đổi
text[@id~'user_\d+']     ← Match: user_1, user_2, user_99

// Match partial text
button[@caption~'Save.*']  ← Match: Save, Save Draft, Save & Close
```

### 5.2 Dùng Starts With / Ends With

```
text[@id>'prefix_']    ← Starts with "prefix_"
```

### 5.3 Repository Variables

Thay hardcoded value bằng variable:
```
// Trong repository: text[@caption=$expectedText]
// Trong code: set variable value trước khi dùng
```

---

## 6. Timeout Cascading (Quan trọng!)

### 6.1 Cách timeout hoạt động

Mỗi **rooted folder** trong repository có timeout riêng. Khi tìm element, timeout **cộng dồn**:

```
CCILoginWindow (30s)                    ← Rooted folder
  └── XIDPWLoginArea (30s)              ← Nested folder
      └── SomeText (30s)                ← Element

Effective timeout = 30s + 30s + 30s = 90 giây!
```

### 6.2 Hệ quả trong project

- `repo.CCILoginWindow.XIDPWLoginArea.SomeText` → effective timeout có thể lên đến **90 giây**
- Trên Máy B với repository caching chậm → ~1.5 phút/element
- **Đây là root cause** của performance issue trên Máy B

> Evidence: login-retry-lesson.md — "Repository caching trên Máy B — mỗi element mất ~1.5 phút tìm"

### 6.3 Cách giảm

1. **Giảm timeout** cho rooted folders không cần wait lâu
2. **Flatten hierarchy** — giảm số rooted folders
3. **Tắt caching** (`usecache="False"`) nếu gây chậm
4. **Dùng `Exists(timeout)` thay `WaitForExists(timeout)`** — trả false thay vì throw

---

## 7. Ranorex Spy — Công cụ Debug

### 7.1 Chức năng chính

| Feature | Mục đích |
|---------|----------|
| **Track Element** | Hover lên UI → xem RxPath và attributes |
| **Highlight Elements** | Hiển thị elements Ranorex nhận diện được |
| **Path Editor** | Sửa RxPath và test real-time |
| **Properties** | Xem tất cả attributes và values |
| **Snapshot** | Lưu trạng thái UI cho troubleshooting |

### 7.2 Workflow debug object recognition

1. **Mở Spy** → Track element trên UI
2. **Kiểm tra attributes** — có stable attribute không?
3. **Test RxPath** — path có match đúng element không?
4. **Check weight** — dynamic attribute có weight quá cao không?
5. **Verify uniqueness** — path có match nhiều elements không?

---

## 8. Rules khi Update Repository

### 8.1 Khi nào cần update

| Tình huống | Hành động |
|------------|-----------|
| UI thay đổi (button đổi vị trí) | Re-track element trong Spy |
| Element không tìm thấy | Kiểm tra RxPath, update nếu cần |
| Thêm test cho màn hình mới | Thêm folder + elements mới |
| Performance chậm | Review timeout, tắt caching |

### 8.2 Checklist khi update

- [ ] Backup `.rxrep` trước khi sửa
- [ ] Track element trong Ranorex Spy trước
- [ ] Dùng stable attributes (automationid, name)
- [ ] Tránh dynamic IDs
- [ ] Test RxPath match đúng 1 element
- [ ] Kiểm tra timeout hợp lý
- [ ] Verify trên cả Máy A và Máy B

### 8.3 KHÔNG SỬA trực tiếp `.rxrep` bằng text editor

Repository file nên được quản lý qua Ranorex Studio. Sửa trực tiếp XML có thể gây lỗi format.

---

## 9. DPI-specific: Elements hiện tại

### 9.1 Login Window

| Element | RxPath | Mục đích | Ghi chú |
|---------|--------|----------|---------|
| SomeText | `text[@caption='']` | Username field | ⚠️ Caption rỗng, fragile |
| TextXPW | `text[@automationid='xPW']` | Password field (gần input) | ✅ Stable automationid |
| XPWWatermark | `text[@automationid='xPWWatermark']` | Password placeholder | Biến mất khi có text |
| Login | `button[@automationid='xLoginButton']/text[@caption='Login']` | Login button | ✅ Stable |

### 9.2 Vấn đề caching

- `usecache="True"` cho `CCILoginWindow` có thể gây chậm trên Máy B
- **Need to verify:** Tắt caching có cải thiện performance không

---

## 10. Tham khảo

- [RanoreXPath: Tips and Tricks](https://www.ranorex.com/blog/ranorexpath-tips-and-tricks/)
- [Test Automation Best Practice #4: Use Reliable Locators](https://www.ranorex.com/blog/best-practices-4-use-stable-locators/)
- [RanoreXPath Solutions](https://support.ranorex.com/hc/en-us/articles/22974736764701-RanoreXPath-solutions/)
- [Ranorex Spy](https://www.ranorex.com/ranorex-spy/)
- [Automated Testing and Dynamic IDs](https://www.ranorex.com/blog/automated-testing-and-dynamic-ids/)
