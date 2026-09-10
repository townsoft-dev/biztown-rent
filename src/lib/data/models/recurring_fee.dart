/// 1 dòng phí định kỳ (`tb_house.recurring_fees` / `tb_room.recurring_fees`,
/// lưu dạng `jsonb` `[{name, amount}]` — xem docs/DATABASE.md).
class RecurringFee {
  final String name;
  final num amount;

  const RecurringFee({required this.name, required this.amount});

  factory RecurringFee.fromMap(Map<String, dynamic> map) {
    return RecurringFee(
        name: map['name'] as String, amount: map['amount'] as num);
  }

  Map<String, dynamic> toMap() => {'name': name, 'amount': amount};
}
