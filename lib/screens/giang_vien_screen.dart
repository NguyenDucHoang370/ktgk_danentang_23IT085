import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/giang_vien.dart';
import '../services/cloudinary_service.dart';
import '../services/giang_vien_service.dart';

const _mauChinh = Color.fromARGB(255, 2, 78, 2);
const _mauNhat = Color.fromARGB(255, 2, 78, 2);

class GiangVienScreen extends StatefulWidget {
  const GiangVienScreen({super.key});

  @override
  State<GiangVienScreen> createState() => _GiangVienScreenState();
}

class _GiangVienScreenState extends State<GiangVienScreen> {
  final _service = GiangVienService();
  final _searchCtrl = TextEditingController();

  // Tạo stream một lần để tránh kết nối lại mỗi khi gõ tìm kiếm
  late final Stream<List<GiangVien>> _stream = _service.layDanhSach();
  String _tuKhoa = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _thongBao(String msg, {bool loi = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: loi ? Colors.red.shade600 : Colors.green.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  /// Thêm (gv == null) hoặc sửa (gv != null)
  Future<void> _moForm({GiangVien? gv}) async {
    final ketQua = await showModalBottomSheet<GiangVien>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _GiangVienForm(gv: gv),
    );
    if (ketQua == null) return;

    try {
      if (gv == null) {
        if (await _service.tonTai(ketQua.IDGV)) {
          _thongBao('Mã giảng viên "${ketQua.IDGV}" đã tồn tại', loi: true);
          return;
        }
        await _service.them(ketQua);
        _thongBao('Đã thêm giảng viên');
      } else {
        await _service.sua(ketQua);
        _thongBao('Đã cập nhật giảng viên');
      }
    } catch (e) {
      _thongBao('Có lỗi xảy ra: $e', loi: true);
    }
  }

  Future<void> _xacNhanXoa(GiangVien gv) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.red.shade50,
          child: Icon(
            Icons.delete_outline,
            color: Colors.red.shade600,
            size: 30,
          ),
        ),
        title: const Text('Xóa giảng viên?'),
        content: Text(
          'Bạn có chắc muốn xóa "${gv.Fullname}"?\nHành động này không thể hoàn tác.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (dongY != true) return;

    try {
      await _service.xoa(gv.IDGV);
      _thongBao('Đã xóa giảng viên');
    } catch (e) {
      _thongBao('Xóa thất bại: $e', loi: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _moForm(),
        backgroundColor: _mauChinh,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Thêm giảng viên'),
      ),
      body: StreamBuilder<List<GiangVien>>(
        stream: _stream,
        builder: (context, snapshot) {
          final tatCa = snapshot.data ?? [];
          final tongLop = tatCa.fold<int>(0, (s, e) => s + e.SumClass);

          final ds = tatCa.where((gv) {
            return gv.Fullname.toLowerCase().contains(_tuKhoa) ||
                gv.IDGV.toLowerCase().contains(_tuKhoa);
          }).toList();

          return Column(
            children: [
              _Header(
                searchCtrl: _searchCtrl,
                tongGV: tatCa.length,
                tongLop: tongLop,
                onSignOut: () => FirebaseAuth.instance.signOut(),
                onChanged: (v) =>
                    setState(() => _tuKhoa = v.trim().toLowerCase()),
                onClear: () {
                  _searchCtrl.clear();
                  setState(() => _tuKhoa = '');
                },
              ),
              Expanded(child: _noiDung(snapshot, ds)),
            ],
          );
        },
      ),
    );
  }

  Widget _noiDung(AsyncSnapshot<List<GiangVien>> snapshot, List<GiangVien> ds) {
    if (snapshot.hasError) {
      return _TrangThaiRong(
        icon: Icons.error_outline,
        tieuDe: 'Đã xảy ra lỗi',
        moTa: '${snapshot.error}',
      );
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (ds.isEmpty) {
      return _TrangThaiRong(
        icon: _tuKhoa.isEmpty ? Icons.school_outlined : Icons.search_off,
        tieuDe: _tuKhoa.isEmpty
            ? 'Chưa có giảng viên nào'
            : 'Không tìm thấy kết quả',
        moTa: _tuKhoa.isEmpty
            ? 'Bấm "Thêm giảng viên" để bắt đầu'
            : 'Thử tìm với từ khóa khác',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: ds.length,
      itemBuilder: (context, i) {
        final gv = ds[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            key: ValueKey(gv.IDGV),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              await _xacNhanXoa(gv); // danh sách tự cập nhật qua stream
              return false;
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: _GiangVienCard(
              gv: gv,
              onTap: () => _moForm(gv: gv),
              onSua: () => _moForm(gv: gv),
              onXoa: () => _xacNhanXoa(gv),
            ),
          ),
        );
      },
    );
  }
}

/// Phần đầu trang: tiêu đề, tìm kiếm, thống kê
class _Header extends StatelessWidget {
  final TextEditingController searchCtrl;
  final int tongGV;
  final int tongLop;
  final VoidCallback onSignOut;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _Header({
    required this.searchCtrl,
    required this.tongGV,
    required this.tongLop,
    required this.onSignOut,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_mauChinh, _mauNhat],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Giảng viên',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Quản lý danh sách giảng viên',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Đăng xuất',
                onPressed: onSignOut,
                icon: const Icon(Icons.logout, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: searchCtrl,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên hoặc mã giảng viên...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: searchCtrl,
                builder: (_, v, _) => v.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: onClear,
                      ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ThongKe(
                  icon: Icons.people_alt_outlined,
                  so: tongGV,
                  nhan: 'Giảng viên',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ThongKe(
                  icon: Icons.class_outlined,
                  so: tongLop,
                  nhan: 'Tổng số lớp',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThongKe extends StatelessWidget {
  final IconData icon;
  final int so;
  final String nhan;
  const _ThongKe({required this.icon, required this.so, required this.nhan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$so',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                nhan,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Thẻ hiển thị một giảng viên
class _GiangVienCard extends StatelessWidget {
  final GiangVien gv;
  final VoidCallback onTap;
  final VoidCallback onSua;
  final VoidCallback onXoa;

  const _GiangVienCard({
    required this.gv,
    required this.onTap,
    required this.onSua,
    required this.onXoa,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _mauChinh.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.deepPurple.shade100,
                      width: 2,
                    ),
                  ),
                  child: _Avatar(url: gv.Image, ten: gv.Fullname, size: 54),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gv.Fullname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _InfoChip(
                            icon: Icons.badge_outlined,
                            text: gv.IDGV,
                            color: _mauChinh,
                          ),
                          _InfoChip(
                            icon: Icons.class_outlined,
                            text: '${gv.SumClass} lớp',
                            color: Colors.teal.shade600,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (v) => v == 'sua' ? onSua() : onXoa(),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'sua',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined, color: Colors.blue),
                        title: Text('Sửa'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'xoa',
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade600,
                        ),
                        title: const Text('Xóa'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ảnh đại diện: ảnh từ URL, nếu rỗng/lỗi thì hiện chữ cái đầu của tên
class _Avatar extends StatelessWidget {
  final String url;
  final String ten;
  final double size;
  const _Avatar({required this.url, required this.ten, required this.size});

  @override
  Widget build(BuildContext context) {
    final tu = ten.trim().split(' ').where((e) => e.isNotEmpty).toList();
    final chuCai = tu.isEmpty ? '?' : tu.last[0].toUpperCase();

    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade300, Colors.deepPurple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        chuCai,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );

    if (url.trim().isEmpty) return fallback;

    return ClipOval(
      child: Image.network(
        url.trim(),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : fallback,
      ),
    );
  }
}

class _TrangThaiRong extends StatelessWidget {
  final IconData icon;
  final String tieuDe;
  final String moTa;
  const _TrangThaiRong({
    required this.icon,
    required this.tieuDe,
    required this.moTa,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: _mauNhat),
            ),
            const SizedBox(height: 16),
            Text(
              tieuDe,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              moTa,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kiểu ô nhập liệu dùng chung cho form
InputDecoration _kieuO(String nhan, IconData icon) {
  return InputDecoration(
    labelText: nhan,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: Colors.grey.shade100,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _mauChinh, width: 1.5),
    ),
  );
}

/// Form thêm / sửa giảng viên
class _GiangVienForm extends StatefulWidget {
  final GiangVien? gv;
  const _GiangVienForm({this.gv});

  @override
  State<_GiangVienForm> createState() => _GiangVienFormState();
}

class _GiangVienFormState extends State<_GiangVienForm> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  final _cloudinary = CloudinaryService();
  late final TextEditingController _idgv;
  late final TextEditingController _fullname;
  late final TextEditingController _image;
  late final TextEditingController _sumClass;
  Uint8List? _anhDaChon;
  XFile? _tepAnh;
  String? _loiAnh;
  bool _dangLuu = false;

  bool get _laSua => widget.gv != null;

  @override
  void initState() {
    super.initState();
    final gv = widget.gv;
    _idgv = TextEditingController(text: gv?.IDGV);
    _fullname = TextEditingController(text: gv?.Fullname);
    _image = TextEditingController(text: gv?.Image);
    _sumClass = TextEditingController(text: gv?.SumClass.toString() ?? '0');
  }

  @override
  void dispose() {
    _idgv.dispose();
    _fullname.dispose();
    _image.dispose();
    _sumClass.dispose();
    super.dispose();
  }

  Future<void> _chonAnh() async {
    try {
      final tepAnh = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (tepAnh == null || !mounted) return;

      final duLieuAnh = await tepAnh.readAsBytes();
      if (!mounted) return;
      setState(() {
        _tepAnh = tepAnh;
        _anhDaChon = duLieuAnh;
        _loiAnh = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loiAnh = 'Không thể chọn ảnh: $e');
    }
  }

  Future<void> _luu() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _dangLuu = true;
      _loiAnh = null;
    });

    try {
      var imageUrl = _image.text.trim();
      if (_anhDaChon != null) {
        final tepAnh = _tepAnh!;
        imageUrl = await _cloudinary.uploadImage(
          bytes: _anhDaChon!,
          filename: tepAnh.name,
          contentType: tepAnh.mimeType ?? 'image/jpeg',
        );
      }

      if (!mounted) return;
      Navigator.pop(
        context,
        GiangVien(
          IDGV: _idgv.text.trim(),
          Fullname: _fullname.text.trim(),
          Image: imageUrl,
          SumClass: int.parse(_sumClass.text.trim()),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loiAnh = 'Không thể tải ảnh lên: $e');
    } finally {
      if (mounted) setState(() => _dangLuu = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Ảnh xem trước, cập nhật ngay khi gõ link / tên
              ValueListenableBuilder2(
                a: _image,
                b: _fullname,
                builder: (_) => Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.deepPurple.shade100,
                      width: 3,
                    ),
                  ),
                  child: _anhDaChon == null
                      ? _Avatar(url: _image.text, ten: _fullname.text, size: 84)
                      : ClipOval(
                          child: Image.memory(
                            _anhDaChon!,
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _laSua ? 'Sửa giảng viên' : 'Thêm giảng viên',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _idgv,
                enabled: !_laSua, // không cho sửa mã khi cập nhật
                decoration: _kieuO(
                  'Mã giảng viên (IDGV)',
                  Icons.badge_outlined,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Không được để trống';
                  }
                  if (v.contains('/')) return 'Mã không được chứa dấu "/"';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fullname,
                textCapitalization: TextCapitalization.words,
                decoration: _kieuO(
                  'Họ và tên (Fullname)',
                  Icons.person_outline,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Không được để trống'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _image,
                keyboardType: TextInputType.url,
                decoration: _kieuO('Link ảnh (Image)', Icons.image_outlined),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _dangLuu ? null : _chonAnh,
                  icon: const Icon(Icons.upload_file),
                  label: Text(
                    _tepAnh == null
                        ? 'Chọn ảnh tải lên Cloudinary'
                        : 'Chọn ảnh khác',
                  ),
                ),
              ),
              if (_tepAnh != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Ảnh sẽ được tải lên khi lưu biểu mẫu.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
              if (_loiAnh != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _loiAnh!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _sumClass,
                keyboardType: TextInputType.number,
                decoration: _kieuO(
                  'Tổng số lớp (SumClass)',
                  Icons.class_outlined,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Không được để trống';
                  }
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 0) return 'Nhập số nguyên >= 0';
                  return null;
                },
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _dangLuu ? null : () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _mauChinh,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _dangLuu ? null : _luu,
                      icon: _dangLuu
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        _dangLuu
                            ? 'Đang lưu...'
                            : _laSua
                            ? 'Cập nhật'
                            : 'Lưu',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lắng nghe đồng thời 2 controller để vẽ lại phần xem trước
class ValueListenableBuilder2 extends StatelessWidget {
  final Listenable a;
  final Listenable b;
  final WidgetBuilder builder;
  const ValueListenableBuilder2({
    super.key,
    required this.a,
    required this.b,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([a, b]),
      builder: (context, _) => builder(context),
    );
  }
}
