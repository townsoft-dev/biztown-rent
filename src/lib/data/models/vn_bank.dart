/// Danh sách ngân hàng VN + mã BIN chuẩn NAPAS (dùng sinh mã QR VietQR —
/// `tb_house.bankBin`). Đây là dữ liệu tham chiếu công khai, cố định (không
/// đổi theo thời gian thực) nên hardcode thẳng thay vì gọi API ngoài — chỉ
/// liệt kê các ngân hàng phổ biến nhất tại VN, đủ dùng cho P-03 "Bank name".
class VnBank {
  final String bin;
  final String name;

  const VnBank({required this.bin, required this.name});

  static const all = <VnBank>[
    VnBank(bin: '970436', name: 'Vietcombank'),
    VnBank(bin: '970415', name: 'VietinBank'),
    VnBank(bin: '970418', name: 'BIDV'),
    VnBank(bin: '970405', name: 'Agribank'),
    VnBank(bin: '970407', name: 'Techcombank'),
    VnBank(bin: '970416', name: 'ACB'),
    VnBank(bin: '970422', name: 'MB Bank'),
    VnBank(bin: '970432', name: 'VPBank'),
    VnBank(bin: '970423', name: 'TPBank'),
    VnBank(bin: '970403', name: 'Sacombank'),
    VnBank(bin: '970437', name: 'HDBank'),
    VnBank(bin: '970443', name: 'SHB'),
    VnBank(bin: '970441', name: 'VIB'),
    VnBank(bin: '970448', name: 'OCB'),
    VnBank(bin: '970426', name: 'MSB'),
    VnBank(bin: '970440', name: 'SeABank'),
    VnBank(bin: '970431', name: 'Eximbank'),
  ];

  static VnBank? byBin(String? bin) {
    if (bin == null) return null;
    for (final bank in all) {
      if (bank.bin == bin) return bank;
    }
    return null;
  }
}
