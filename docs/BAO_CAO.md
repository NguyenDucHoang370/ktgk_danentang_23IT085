# Báo cáo: Ứng dụng quản lý giảng viên

## 1. Mục tiêu và công nghệ

- Flutter/Dart, chạy trên trình duyệt web và Android.
- Firebase Authentication (Email/Password) cho đăng nhập quản trị.
- Cloud Firestore lưu dữ liệu thời gian thực.
- Cloudinary lưu ảnh; Firestore chỉ lưu URL trong trường `Image`.
- `image_picker` chọn ảnh trên web/thiết bị di động; `http` gửi ảnh đến Cloudinary.

## 2. Cấu trúc dữ liệu

Tên collection: `GiangVien` (trong cơ sở dữ liệu Firebase project `danentanggk-3f30c`).

Mỗi document dùng `IDGV` làm document ID và chỉ chứa chính xác bốn trường:

| Trường | Kiểu | Ý nghĩa |
|---|---|---|
| `IDGV` | string | Mã giảng viên, duy nhất và trùng document ID |
| `Fullname` | string | Họ và tên |
| `Image` | string | URL ảnh Cloudinary; có thể để trống |
| `SumClass` | integer | Tổng số lớp, số nguyên không âm |

File dữ liệu JSON mẫu dùng để nhập thủ công vào Firestore:
[data/giang_vien.json](../data/giang_vien.json). Không tạo trường bổ sung trong
document. Khi nhập từng phần tử, đặt document ID bằng giá trị `IDGV`.

## 3. Cài đặt môi trường và thư viện

Cài Flutter stable và bật hỗ trợ web:

```powershell
flutter doctor
flutter config --enable-web
flutter pub get
```

Các thư viện liên quan đã khai báo trong `pubspec.yaml`:

```text
firebase_core
firebase_auth
cloud_firestore
image_picker
http
http_parser
```

Nếu cần cài thủ công bằng Dart:

```powershell
flutter pub add firebase_core firebase_auth cloud_firestore image_picker http http_parser
```

## 4. Cấu hình Firebase

1. Mở Firebase Console, chọn project đã cấu hình trong
   `lib/firebase_options.dart` hoặc thay cấu hình bằng project của bạn qua
   FlutterFire CLI.
2. Tạo Firestore Database.
3. Trong **Authentication → Sign-in method**, bật **Email/Password**.
4. Trong **Authentication → Users**, tạo tài khoản quản trị. Ứng dụng không
   cung cấp đăng ký công khai; chỉ tạo tài khoản cho người quản trị tin cậy.
5. Đăng nhập Firebase CLI rồi triển khai `firestore.rules`:

   ```powershell
   firebase login
   firebase deploy --only firestore:rules --project danentanggk-3f30c
   ```

   Quy tắc yêu cầu đã đăng nhập và chỉ chấp nhận đúng bốn khóa ở collection
   `GiangVien`. Không bật quyền đọc/ghi công khai.
6. Nhập mẫu từ `data/giang_vien.json` trong Firestore Console; đặt ID document
   theo `IDGV`.

## 5. Cấu hình Cloudinary

1. Tạo tài khoản Cloudinary và ghi lại **Cloud name**.
2. Tạo **Unsigned upload preset** trong Upload settings. Giới hạn định dạng
   ảnh và dung lượng tối đa phù hợp trong preset; không bật thêm quyền không cần
   thiết.
3. Chạy ứng dụng với các giá trị của tài khoản:

   ```powershell
   flutter run -d chrome --dart-define=CLOUDINARY_CLOUD_NAME=<cloud-name> --dart-define=CLOUDINARY_UPLOAD_PRESET=<unsigned-preset>
   ```

   Android:

   ```powershell
   flutter run -d <device-id> --dart-define=CLOUDINARY_CLOUD_NAME=<cloud-name> --dart-define=CLOUDINARY_UPLOAD_PRESET=<unsigned-preset>
   ```

   `CLOUDINARY_CLOUD_NAME` và tên unsigned preset không phải API secret. Không
   đưa API secret vào ứng dụng client. Nếu chưa cấu hình, thao tác tải ảnh sẽ
   báo lỗi rõ ràng; có thể nhập sẵn URL vào trường `Image`.

## 6. Chức năng

- Đăng nhập Email/Password và đăng xuất.
- Danh sách giảng viên cập nhật theo thời gian thực.
- Tạo mới, cập nhật, xóa có xác nhận; mã `IDGV` không được trùng.
- Tìm kiếm theo mã/tên; thống kê tổng giảng viên và tổng số lớp.
- Chọn ảnh từ thiết bị/trình duyệt, xem trước và tải Cloudinary; URL được lưu
  vào trường `Image`, không lưu dữ liệu ảnh vào Firestore.
- Hiển thị ảnh và thông tin trên web/di động; ảnh lỗi hoặc thiếu URL dùng avatar
  thay thế.

## 7. Chạy, kiểm thử và build web

```powershell
flutter test
flutter analyze
flutter run -d chrome --dart-define=CLOUDINARY_CLOUD_NAME=<cloud-name> --dart-define=CLOUDINARY_UPLOAD_PRESET=<unsigned-preset>
flutter build web --release --dart-define=CLOUDINARY_CLOUD_NAME=<cloud-name> --dart-define=CLOUDINARY_UPLOAD_PRESET=<unsigned-preset>
```

Thư mục phát hành web nằm tại `build/web`. Có thể triển khai lên Firebase
Hosting, GitHub Pages hoặc máy chủ static có HTTPS (Firebase Auth cần cấu hình
authorized domains phù hợp trong Console).

## 8. Hình ảnh minh họa và thông tin nộp bài

Ảnh chụp phải được bổ sung sau khi chạy trên Firebase/Cloudinary thật; không
đính kèm ảnh giả lập. Gợi ý lưu ảnh vào `docs/screenshots/`:

1. `login.png` — màn hình đăng nhập.
2. `web-list.png` — danh sách và thống kê trên trình duyệt.
3. `create-edit.png` — form thêm/sửa và ảnh xem trước.
4. `mobile-list.png` — danh sách trên Android.
5. `firestore.png` — Firestore Console hiển thị collection và bốn trường.
6. `cloudinary.png` — thư viện Cloudinary có ảnh vừa tải lên.

- GitHub source: thêm URL repository sau khi đẩy mã nguồn.
- Video demo: thêm URL video sau khi ghi hình.
- Tệp dữ liệu nộp kèm: `data/giang_vien.json`.

Các thao tác tạo Firebase project, tạo tài khoản, nhập dữ liệu và tạo preset
Cloudinary cần được thực hiện trong tài khoản dịch vụ của người nộp bài; mã nguồn
không thể tự chụp ảnh Console hoặc tạo URL GitHub/video thay người dùng.

## 9. Luồng hoạt động của mã nguồn

### 9.1. Khởi động và xác thực

1. `lib/main.dart` khởi tạo Flutter và Firebase theo cấu hình nền tảng trong
   `lib/firebase_options.dart`, sau đó chạy `MyApp`.
2. `MyApp` đặt `AuthGate` làm trang gốc. `AuthGate` lắng nghe
   `FirebaseAuth.instance.authStateChanges()`:
   - Chờ dữ liệu: hiển thị vòng tải.
   - Chưa đăng nhập: hiển thị `AuthScreen`.
   - Đã đăng nhập: hiển thị `GiangVienScreen`.
   - Luồng xác thực lỗi: hiển thị thông báo lỗi.
3. `AuthScreen` kiểm tra định dạng email và mật khẩu không rỗng, sau đó gọi
   `signInWithEmailAndPassword`. Lỗi được chuyển thành thông báo phù hợp.
   Đăng nhập/đăng xuất làm thay đổi auth stream, vì vậy `AuthGate` tự chuyển
   màn hình; không cần điều hướng thủ công.

### 9.2. Đọc danh sách, tìm kiếm và thống kê

1. `GiangVienScreen` khởi tạo `GiangVienService` và một stream danh sách.
2. `GiangVienService.layDanhSach()` truy vấn collection Firestore `GiangVien`,
   sắp xếp theo `Fullname`, rồi chuyển document thành `GiangVien`.
3. `StreamBuilder` dựng lại danh sách theo thời gian thực khi Firestore thay đổi.
   Màn hình tính tổng số giảng viên và tổng `SumClass` từ danh sách đầy đủ.
4. Tìm kiếm được xử lý cục bộ theo `IDGV` hoặc `Fullname`, không tạo stream mới.
   Giao diện hiển thị riêng trạng thái đang tải, lỗi, danh sách rỗng và không
   có kết quả. Ảnh thiếu hoặc lỗi tải được thay bằng chữ cái đầu tên.

### 9.3. Thêm và cập nhật

1. Nút **Thêm giảng viên** mở form trống; chạm một thẻ mở form cập nhật với dữ
   liệu hiện có. Khi cập nhật, `IDGV` bị khóa.
2. Form kiểm tra mã không rỗng và không có `/`, tên không rỗng, `SumClass` là
   số nguyên không âm. Người dùng có thể nhập URL ảnh hoặc chọn ảnh từ thiết bị.
3. Nếu chọn ảnh, `image_picker` đọc ảnh thành bytes và hiển thị xem trước.
   Khi lưu, `CloudinaryService` gửi multipart request tới Cloudinary; form dùng
   `secure_url` trả về làm giá trị `Image`. Nếu không chọn ảnh, form dùng URL
   nhập tay. Lỗi tải ảnh được hiển thị và không trả kết quả form.
4. Khi thêm, màn hình kiểm tra mã tồn tại rồi gọi `GiangVienService.them()`.
   Service kiểm tra lại mã, tên (chỉ chữ và khoảng trắng) và số lớp, rồi ghi
   document có ID bằng mã đã trim. Khi sửa, service xác nhận document tồn tại
   rồi cập nhật document đó.
5. Sau thao tác thành công hoặc lỗi, màn hình hiện `SnackBar`. Thay đổi Firestore
   được phản ánh qua stream trong danh sách và thống kê.

### 9.4. Xóa và mô hình dữ liệu

1. Xóa từ thẻ hoặc vuốt thẻ đều mở hộp thoại xác nhận. **Hủy** không gọi service;
   **Xóa** gọi `GiangVienService.xoa()`, sau đó danh sách tự cập nhật qua stream.
2. `GiangVien.toMap()` ánh xạ đúng bốn trường `IDGV`, `Fullname`, `Image`,
   `SumClass`; `GiangVien.fromMap()` chuyển dữ liệu Firestore về đối tượng và
   dùng giá trị mặc định chuỗi rỗng/số 0 cho trường thiếu.

## 10. Kịch bản kiểm thử

### 10.1. Kiểm thử tự động hiện có

`test/widget_test.dart` hiện có một kiểm thử model: xác nhận `toMap()` có đúng
bốn trường và dữ liệu không đổi khi chuyển qua `fromMap()` rồi `toMap()`. Đây
chưa phải kiểm thử giao diện hoặc tích hợp Firebase/Cloudinary. Các kịch bản
dưới đây là kế hoạch kiểm thử bổ sung; chỉ ghi nhận đạt sau khi thực sự chạy.

### 10.2. Dữ liệu và môi trường

- Dùng Firebase project thử nghiệm, bật Email/Password, tạo tài khoản quản trị
  và áp dụng Firestore Rules.
- Dữ liệu mẫu: `GV001` / Nguyễn Văn An / 3 lớp; `GV002` / Trần Thị Bình /
  2 lớp; `GV003` / Lê Minh Châu / 4 lớp. Tổng kỳ vọng là 3 giảng viên, 9 lớp.
- Chuẩn bị ảnh hợp lệ và cấu hình Cloudinary unsigned upload preset khi chạy
  các trường hợp tải ảnh.
- Chỉ dùng dữ liệu/môi trường thử nghiệm cho các trường hợp quyền truy cập,
  lỗi mạng hoặc xóa dữ liệu.

### 10.3. Danh sách kịch bản

| ID | Phạm vi | Thao tác | Kết quả mong đợi |
|---|---|---|---|
| TC-01 | Model | Tạo đối tượng, kiểm tra `toMap()` và chuyển vòng `fromMap()` | Có đúng bốn khóa; dữ liệu giữ nguyên. |
| TC-02 | Model | Đọc map có trường thiếu hoặc `SumClass` kiểu số | Trường thiếu nhận mặc định; số được chuyển thành `int`. |
| TC-03 | Đăng nhập | Mở ứng dụng khi chưa đăng nhập | Hiện màn hình đăng nhập, không hiện danh sách quản lý. |
| TC-04 | Đăng nhập | Email sai định dạng hoặc bỏ trống mật khẩu | Hiện lỗi tại form; không gửi yêu cầu xác thực. |
| TC-05 | Đăng nhập | Đăng nhập đúng rồi đăng xuất | Vào màn hình quản lý sau đăng nhập; quay về đăng nhập sau đăng xuất. |
| TC-06 | Đăng nhập | Sai mật khẩu hoặc mất kết nối | Có thông báo lỗi; không chuyển sang màn hình quản lý. |
| TC-07 | Danh sách | Mở danh sách với ba bản ghi mẫu | Hiện đủ ba bản ghi, tổng giảng viên 3, tổng lớp 9. |
| TC-08 | Tìm kiếm | Tìm một phần mã/tên, khác hoa thường; sau đó xóa từ khóa | Lọc đúng; xóa từ khóa khôi phục danh sách đầy đủ. |
| TC-09 | Thêm | Thêm mã mới, tên hợp lệ, ảnh trống, số lớp 0 | Lưu đúng document và bốn trường; danh sách/thống kê cập nhật. |
| TC-10 | Kiểm tra dữ liệu | Thử mã trùng/rỗng/có `/`, tên rỗng/có chữ số, số lớp âm/không nguyên | Bị từ chối; không ghi bản ghi không hợp lệ. |
| TC-11 | Trùng mã | Tạo cùng mã ở hai phiên gần như đồng thời | Chỉ có một document cùng ID; do kiểm tra hiện tại là đọc rồi ghi, cả hai phiên có thể báo thành công và dữ liệu ghi sau có thể ghi đè. |
| TC-12 | Ảnh | Chọn ảnh hợp lệ và lưu khi Cloudinary sẵn sàng | Có xem trước; URL `secure_url` được lưu vào `Image`, không lưu bytes ảnh. |
| TC-13 | Ảnh | Cloudinary lỗi, mất mạng hoặc trả thiếu `secure_url` | Hiện lỗi tải ảnh; không lưu thay đổi form. |
| TC-14 | Cập nhật | Sửa tên/số lớp/URL ảnh của bản ghi có sẵn | Cùng document được cập nhật; mã không sửa; thống kê thay đổi đúng. |
| TC-15 | Cập nhật | Cập nhật mã không tồn tại | Báo không tìm thấy; không tạo document mới. |
| TC-16 | Xóa | Hủy xác nhận, sau đó xác nhận xóa | Hủy giữ nguyên; xác nhận xóa document và cập nhật danh sách/thống kê. |
| TC-17 | Ảnh hiển thị | Dùng URL ảnh rỗng hoặc URL lỗi | Hiện avatar dự phòng, thông tin còn lại vẫn hiển thị. |
| TC-18 | Lỗi dữ liệu | Từ chối quyền đọc Firestore hoặc làm stream phát lỗi | Hiện trạng thái lỗi, không hiển thị nhầm như danh sách rỗng. |

### 10.4. Lệnh chạy kiểm tra

```powershell
flutter test
flutter analyze
```

Sau khi bổ sung kiểm thử tích hợp, chạy lại các lệnh trên và thực hiện TC-03
đến TC-18 trên project Firebase/Cloudinary thử nghiệm. Khi nghiệm thu, ghi rõ
kết quả thực tế, nền tảng và cấu hình đã dùng; không xem các kịch bản tích hợp
là đạt nếu chưa thực sự chạy.
