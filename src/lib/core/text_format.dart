/// Chữ cái đầu tên (VD "Nguyễn Thúy Hường" → "NH") — dùng cho `Avatar` và
/// `ListCard(thumbShape: round)` ở mọi nơi cần avatar chữ cái (P-01/P-02/P-05).
String initialsFromName(String fullName) {
  final parts =
      fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}
