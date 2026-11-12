// These property names intentionally match the required Firestore field names.
// ignore_for_file: non_constant_identifier_names

class GiangVien {
  // 1. Khai báo đúng 4 thuộc tính
  final String IDGV;
  final String Fullname;
  final String Image;
  final int SumClass;

  // 2. Constructor
  GiangVien({
    required this.IDGV,
    required this.Fullname,
    required this.Image,
    required this.SumClass,
  });

  // 3. Chuyển đối tượng GiangVien thành Map để lưu Firestore
  Map<String, dynamic> toMap() {
    return {
      'IDGV': IDGV,
      'Fullname': Fullname,
      'Image': Image,
      'SumClass': SumClass,
    };
  }

  // 4. Chuyển dữ liệu Map từ Firestore thành đối tượng GiangVien
  factory GiangVien.fromMap(Map<String, dynamic> map) {
    return GiangVien(
      IDGV: map['IDGV'] ?? '',
      Fullname: map['Fullname'] ?? '',
      Image: map['Image'] ?? '',
      SumClass: (map['SumClass'] as num?)?.toInt() ?? 0,
    );
  }
}
