# Quản lý giảng viên

Ứng dụng Flutter cho web và Android để quản lý collection Firestore `GiangVien`.
Ứng dụng hỗ trợ đăng nhập Firebase Authentication, thêm/sửa/xóa/tìm kiếm giảng
viên, thống kê lớp và tải ảnh lên Cloudinary. Tài liệu cài đặt, cấu hình Firebase
và Cloudinary, triển khai web, cùng hướng dẫn nộp bài nằm trong
[docs/BAO_CAO.md](docs/BAO_CAO.md).

## Chạy nhanh

```powershell
flutter pub get
flutter run -d chrome --dart-define=CLOUDINARY_CLOUD_NAME=<cloud-name> --dart-define=CLOUDINARY_UPLOAD_PRESET=<unsigned-preset>
```

Tạo tài khoản quản trị trong Firebase Console trước khi đăng nhập. Dữ liệu JSON
để khởi tạo collection nằm ở [data/giang_vien.json](data/giang_vien.json).
