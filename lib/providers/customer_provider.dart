import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerDetails {
  final String? name;
  final String? phone;

  const CustomerDetails({this.name, this.phone});

  CustomerDetails copyWith({String? name, String? phone}) {
    return CustomerDetails(
      name: name ?? this.name,
      phone: phone ?? this.phone,
    );
  }

  bool get isEmpty => (name == null || name!.isEmpty) && (phone == null || phone!.isEmpty);
}

class CustomerDetailsNotifier extends StateNotifier<CustomerDetails> {
  CustomerDetailsNotifier() : super(const CustomerDetails());

  void setDetails({String? name, String? phone}) {
    state = CustomerDetails(name: name, phone: phone);
  }

  void clear() {
    state = const CustomerDetails();
  }
}

final customerDetailsProvider = StateNotifierProvider<CustomerDetailsNotifier, CustomerDetails>((ref) {
  return CustomerDetailsNotifier();
});
