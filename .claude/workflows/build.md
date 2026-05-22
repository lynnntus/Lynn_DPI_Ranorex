# Build & Chạy test

## Build bằng MSBuild

```powershell
# Cần Ranorex Studio đã cài trên máy
msbuild Lynn_DPI_AT\Lynn_DPI_AT\Lynn_DPI_AT\Lynn_DPI_AT.csproj /p:Configuration=Debug /p:Platform=x86
```

**Yêu cầu**:
- Ranorex Studio 10.7+ đã cài
- Platform: x86 (32-bit) — bắt buộc, không đổi sang x64
- .NET Framework 4.8

## Chạy test suite

```powershell
# Chạy trực tiếp từ exe
Lynn_DPI_AT\Lynn_DPI_AT\Lynn_DPI_AT\bin\Debug\Lynn_DPI_AT.exe
```

## Mở trong Ranorex Studio

Mở file `Lynn_DPI_AT.rxsln` → chọn test case → bấm Run.
