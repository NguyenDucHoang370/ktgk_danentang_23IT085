// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:danentang_ktgk/models/giang_vien.dart';

void main() {
  test('GiangVien serializes exactly the four required fields', () {
    final giangVien = GiangVien(
      IDGV: 'GV001',
      Fullname: 'Nguyễn Văn An',
      Image: 'https://example.com/avatar.jpg',
      SumClass: 3,
    );

    expect(giangVien.toMap(), {
      'IDGV': 'GV001',
      'Fullname': 'Nguyễn Văn An',
      'Image': 'https://example.com/avatar.jpg',
      'SumClass': 3,
    });
    expect(GiangVien.fromMap(giangVien.toMap()).toMap(), giangVien.toMap());
  });
}
