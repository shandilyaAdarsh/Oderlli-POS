import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerDetails {
  final String? orderId;
  final String? name;
  final String? phone;
  final int guests;
  final String? tableNo;
  final String? tableId;

  const CustomerDetails({
    this.orderId,
    this.name,
    this.phone,
    this.guests = 1,
    this.tableNo,
    this.tableId,
  });

  CustomerDetails copyWith({
    String? orderId,
    String? name,
    String? phone,
    int? guests,
    String? tableNo,
    String? tableId,
  }) {
    return CustomerDetails(
      orderId: orderId ?? this.orderId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      guests: guests ?? this.guests,
      tableNo: tableNo ?? this.tableNo,
      tableId: tableId ?? this.tableId,
    );
  }

  bool get isEmpty => (name == null || name!.isEmpty) && (phone == null || phone!.isEmpty);
}

class CustomerDetailsNotifier extends StateNotifier<CustomerDetails> {
  CustomerDetailsNotifier() : super(const CustomerDetails());

  void setCustomer({String? name, String? phone, int guests = 1}) {
    state = CustomerDetails(
      orderId: '${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      guests: guests,
    );
  }

  void updateTable({String? tableId, String? tableNo}) {
    state = state.copyWith(tableId: tableId, tableNo: tableNo);
  }

  void setDetails({String? name, String? phone}) {
    state = state.copyWith(name: name, phone: phone);
  }

  void clear() {
    state = const CustomerDetails();
  }
}

final customerDetailsProvider = StateNotifierProvider<CustomerDetailsNotifier, CustomerDetails>((ref) {
  return CustomerDetailsNotifier();
});
