# Build & Deploy — Quy trình 2 máy

## Tổng quan môi trường

| Máy | Vai trò | Phần mềm |
|-----|---------|----------|
| **Máy A** | Sửa code | VS Code + Claude Code, Ranorex SDK, Git |
| **Máy B** | Chạy test | Ranorex Studio, Neptune DPI app, Git |

- Không có CI/CD — deploy thủ công qua Git (push/pull)
- Máy A không có Ranorex Studio và không có app Neptune
- Máy B là nơi duy nhất chạy được test thực tế

## Quy trình sau khi sửa code (Claude Code thực hiện trên Máy A)

### Bước 1 — Kiểm tra compile error bằng MSBuild

```powershell
msbuild Lynn_DPI_AT\Lynn_DPI_AT\Lynn_DPI_AT.csproj /p:Configuration=Debug /p:Platform=x86
```

- **Mục đích**: chỉ check lỗi compile, không chạy test
- **Platform**: x86 (32-bit) — bắt buộc, không đổi sang x64
- **.NET Framework**: 4.8
- Nếu có lỗi compile → sửa ngay trên Máy A trước khi tiếp tục

### Bước 2 — Push code lên GitHub

```
git add <các file đã thay đổi>
git commit -m "[loại] mô tả thay đổi"
```

- **Hỏi người dùng xác nhận** trước khi `git push`
- Sau khi được xác nhận → `git push`

### Bước 3 — Thông báo cho người dùng

Sau khi push thành công, thông báo:

> Đã push xong. Bạn vui lòng `git pull` trên Máy B và chạy SmokeTest,
> sau đó báo kết quả **PASS** hoặc **FAIL** (kèm nội dung lỗi nếu FAIL).

## Vòng lặp fix cho đến khi PASS

```
Người dùng báo kết quả
  │
  ├─ PASS → ✅ Hoàn thành
  │
  └─ FAIL → Đọc nội dung lỗi người dùng cung cấp
             → Sửa code trên Máy A
             → MSBuild check compile
             → git add / commit / hỏi confirm push
             → Thông báo pull và test lại
             → Quay lại đầu vòng lặp
```

Lặp lại cho đến khi người dùng báo **PASS**.
