import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/giang_vien.dart';

class GiangVienService {
  // Kết nối đến collection GiangVien
  final CollectionReference<Map<String, dynamic>> _col = FirebaseFirestore
      .instance
      .collection('GiangVien');

  // READ: Lấy danh sách giảng viên theo thời gian thực
  Stream<List<GiangVien>> layDanhSach() {
    return _col
        .orderBy('Fullname')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => GiangVien.fromMap(doc.data())).toList(),
        );
  }

  // Kiểm tra IDGV đã tồn tại chưa
  Future<bool> tonTai(String idgv) async {
    final doc = await _col.doc(idgv.trim()).get();
    return doc.exists;
  }

  // CREATE: Thêm giảng viên mới
  Future<void> them(GiangVien gv) async {
    // Kiểm tra dữ liệu cơ bản
    if (gv.IDGV.trim().isEmpty) {
      throw ArgumentError('Mã giảng viên không được để trống.');
    }

    final String tenDaTrim = gv.Fullname.trim();

    if (tenDaTrim.isEmpty) {
      throw ArgumentError('Tên giảng viên không được để trống.');
    }

    // Biểu thức Regex: Chỉ cho phép các chữ cái (bao gồm cả tiếng Việt có dấu) và khoảng trắng
    final nameRegExp = RegExp(
      r'^[a-zA-ZÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚĂĐĨŨƠàáâãèéêìíòóôõùúăđĩũơƯĂẠẢẤẦẨẪẬẮẰẲẴẶẸẺẼỀỀỂưăạảấầẩẫậắằẳẵặẹẻẽềềểỄỆỈỊỌỎỐỒỔỖỘỚỜỞỠỢỤỦỨỪễệỉịọỏốồổỗộớờởỡợụủứừỬỮỰỲỴÝỶỸửữựỳỵỷỹ\s]+$',
    );

    if (!nameRegExp.hasMatch(tenDaTrim)) {
      throw ArgumentError(
        'Tên giảng viên không hợp lệ (không được chứa số $tenDaTrim).',
      );
    }

    if (gv.SumClass < 0) {
      throw ArgumentError('Số lớp không được âm.');
    }

    // Kiểm tra trùng mã
    if (await tonTai(gv.IDGV)) {
      throw StateError('Mã giảng viên đã tồn tại.');
    }

    await _col.doc(gv.IDGV.trim()).set(gv.toMap());
  }

  // UPDATE: Cập nhật giảng viên
  Future<void> sua(GiangVien gv) async {
    if (gv.IDGV.trim().isEmpty) {
      throw ArgumentError('Mã giảng viên không được để trống.');
    }

    final String tenDaTrim = gv.Fullname.trim();

    if (tenDaTrim.isEmpty) {
      throw ArgumentError('Tên giảng viên không được để trống.');
    }

    // Biểu thức Regex: Chỉ cho phép các chữ cái (bao gồm cả tiếng Việt có dấu) và khoảng trắng
    final nameRegExp = RegExp(
      r'^[a-zA-ZÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚĂĐĨŨƠàáâãèéêìíòóôõùúăđĩũơƯĂẠẢẤẦẨẪẬẮẰẲẴẶẸẺẼỀỀỂưăạảấầẩẫậắằẳẵặẹẻẽềềểỄỆỈỊỌỎỐỒỔỖỘỚỜỞỠỢỤỦỨỪễệỉịọỏốồổỗộớờởỡợụủứừỬỮỰỲỴÝỶỸửữựỳỵỷỹ\s]+$',
    );

    if (!nameRegExp.hasMatch(tenDaTrim)) {
      throw ArgumentError(
        'Tên giảng viên không hợp lệ (không được chứa số như $tenDaTrim).',
      );
    }
    if (gv.SumClass < 0) {
      throw ArgumentError('Số lớp không được âm.');
    }

    final doc = _col.doc(gv.IDGV.trim());

    if (!(await doc.get()).exists) {
      throw StateError('Không tìm thấy giảng viên cần sửa.');
    }

    await doc.update(gv.toMap());
  }

  // DELETE: Xóa giảng viên
  Future<void> xoa(String idgv) async {
    if (idgv.trim().isEmpty) {
      throw ArgumentError('Mã giảng viên không hợp lệ.');
    }

    await _col.doc(idgv.trim()).delete();
  }
}
