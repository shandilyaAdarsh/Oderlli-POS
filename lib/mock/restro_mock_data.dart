import 'package:flutter/material.dart';

class RestroPopularDish {
  final int id;
  final String name;
  final int numberOfOrders;
  final double price;
  final String emoji;
  final String category;
  final bool isVeg;

  const RestroPopularDish({
    required this.id,
    required this.name,
    required this.numberOfOrders,
    required this.price,
    required this.emoji,
    required this.category,
    required this.isVeg,
  });
}

class RestroMenuItem {
  final int id;
  final String name;
  final double price;
  final String category;
  final bool isVeg;
  final String emoji;

  const RestroMenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.isVeg,
    required this.emoji,
  });
}

class RestroCategory {
  final int id;
  final String name;
  final Color bgColor;
  final String icon;
  final List<RestroMenuItem> items;

  const RestroCategory({
    required this.id,
    required this.name,
    required this.bgColor,
    required this.icon,
    required this.items,
  });
}

class RestroTableItem {
  final String id;
  final String name;
  final String status; // "Booked" or "Available"
  final String initial;
  final int seats;
  final String? customerName;
  final String? customerPhone;
  final double? currentBillTotal;

  const RestroTableItem({
    required this.id,
    required this.name,
    required this.status,
    required this.initial,
    required this.seats,
    this.customerName,
    this.customerPhone,
    this.currentBillTotal,
  });

  bool get isBooked => status.toLowerCase() == 'booked';

  RestroTableItem copyWith({
    String? id,
    String? name,
    String? status,
    String? initial,
    int? seats,
    String? customerName,
    String? customerPhone,
    double? currentBillTotal,
  }) {
    return RestroTableItem(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      initial: initial ?? this.initial,
      seats: seats ?? this.seats,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      currentBillTotal: currentBillTotal ?? this.currentBillTotal,
    );
  }
}

class RestroMetric {
  final String title;
  final String value;
  final String percentage;
  final Color color;
  final bool isIncrease;

  const RestroMetric({
    required this.title,
    required this.value,
    required this.percentage,
    required this.color,
    this.isIncrease = true,
  });
}

class RestroOrder {
  final String id;
  final String customer;
  final String status; // "Ready", "In Progress", "Completed"
  final DateTime dateTime;
  final int itemCount;
  final String tableNo;
  final double total;
  final List<String> itemNames;

  const RestroOrder({
    required this.id,
    required this.customer,
    required this.status,
    required this.dateTime,
    required this.itemCount,
    required this.tableNo,
    required this.total,
    required this.itemNames,
  });

  RestroOrder copyWith({
    String? id,
    String? customer,
    String? status,
    DateTime? dateTime,
    int? itemCount,
    String? tableNo,
    double? total,
    List<String>? itemNames,
  }) {
    return RestroOrder(
      id: id ?? this.id,
      customer: customer ?? this.customer,
      status: status ?? this.status,
      dateTime: dateTime ?? this.dateTime,
      itemCount: itemCount ?? this.itemCount,
      tableNo: tableNo ?? this.tableNo,
      total: total ?? this.total,
      itemNames: itemNames ?? this.itemNames,
    );
  }
}

abstract final class RestroMockData {
  static const List<RestroPopularDish> popularDishes = [
    RestroPopularDish(
      id: 1,
      name: 'Butter Chicken',
      numberOfOrders: 250,
      price: 400.0,
      emoji: '🍗',
      category: 'Main Course',
      isVeg: false,
    ),
    RestroPopularDish(
      id: 2,
      name: 'Paneer Tikka',
      numberOfOrders: 210,
      price: 250.0,
      emoji: '🍢',
      category: 'Starters',
      isVeg: true,
    ),
    RestroPopularDish(
      id: 3,
      name: 'Chicken Biryani',
      numberOfOrders: 320,
      price: 450.0,
      emoji: '🍛',
      category: 'Main Course',
      isVeg: false,
    ),
    RestroPopularDish(
      id: 4,
      name: 'Masala Dosa',
      numberOfOrders: 220,
      price: 180.0,
      emoji: '🥞',
      category: 'Starters',
      isVeg: true,
    ),
    RestroPopularDish(
      id: 5,
      name: 'Chole Bhature',
      numberOfOrders: 270,
      price: 200.0,
      emoji: '🥘',
      category: 'Main Course',
      isVeg: true,
    ),
    RestroPopularDish(
      id: 6,
      name: 'Gulab Jamun',
      numberOfOrders: 310,
      price: 100.0,
      emoji: '🍮',
      category: 'Desserts',
      isVeg: true,
    ),
    RestroPopularDish(
      id: 7,
      name: 'Dal Makhani',
      numberOfOrders: 190,
      price: 180.0,
      emoji: '🍲',
      category: 'Main Course',
      isVeg: true,
    ),
    RestroPopularDish(
      id: 8,
      name: 'Margherita Pizza',
      numberOfOrders: 165,
      price: 350.0,
      emoji: '🍕',
      category: 'Pizzas',
      isVeg: true,
    ),
  ];

  static const List<RestroCategory> categories = [
    RestroCategory(
      id: 1,
      name: "Starters",
      bgColor: Color(0xFFB73E3E),
      icon: "🍲",
      items: [
        RestroMenuItem(id: 101, name: "Paneer Tikka", price: 250, category: "Vegetarian", isVeg: true, emoji: "🍢"),
        RestroMenuItem(id: 102, name: "Chicken Tikka", price: 300, category: "Non-Vegetarian", isVeg: false, emoji: "🍗"),
        RestroMenuItem(id: 103, name: "Tandoori Chicken", price: 350, category: "Non-Vegetarian", isVeg: false, emoji: "🍗"),
        RestroMenuItem(id: 104, name: "Samosa Platter", price: 100, category: "Vegetarian", isVeg: true, emoji: "🥟"),
        RestroMenuItem(id: 105, name: "Aloo Tikki Chaat", price: 120, category: "Vegetarian", isVeg: true, emoji: "🥔"),
        RestroMenuItem(id: 106, name: "Hara Bhara Kebab", price: 220, category: "Vegetarian", isVeg: true, emoji: "🌿"),
      ],
    ),
    RestroCategory(
      id: 2,
      name: "Main Course",
      bgColor: Color(0xFF5B45B0),
      icon: "🍛",
      items: [
        RestroMenuItem(id: 201, name: "Butter Chicken", price: 400, category: "Non-Vegetarian", isVeg: false, emoji: "🍗"),
        RestroMenuItem(id: 202, name: "Paneer Butter Masala", price: 350, category: "Vegetarian", isVeg: true, emoji: "🧀"),
        RestroMenuItem(id: 203, name: "Chicken Biryani", price: 450, category: "Non-Vegetarian", isVeg: false, emoji: "🍛"),
        RestroMenuItem(id: 204, name: "Dal Makhani", price: 180, category: "Vegetarian", isVeg: true, emoji: "🍲"),
        RestroMenuItem(id: 205, name: "Kadai Paneer", price: 300, category: "Vegetarian", isVeg: true, emoji: "🥘"),
        RestroMenuItem(id: 206, name: "Rogan Josh", price: 500, category: "Non-Vegetarian", isVeg: false, emoji: "🍖"),
      ],
    ),
    RestroCategory(
      id: 3,
      name: "Beverages",
      bgColor: Color(0xFF7F167F),
      icon: "🍹",
      items: [
        RestroMenuItem(id: 301, name: "Masala Chai", price: 50, category: "Hot", isVeg: true, emoji: "☕"),
        RestroMenuItem(id: 302, name: "Lemon Soda", price: 80, category: "Cold", isVeg: true, emoji: "🍋"),
        RestroMenuItem(id: 303, name: "Mango Lassi", price: 120, category: "Cold", isVeg: true, emoji: "🥭"),
        RestroMenuItem(id: 304, name: "Cold Coffee", price: 150, category: "Cold", isVeg: true, emoji: "🧋"),
        RestroMenuItem(id: 305, name: "Fresh Lime Water", price: 60, category: "Cold", isVeg: true, emoji: "🥤"),
        RestroMenuItem(id: 306, name: "Iced Peach Tea", price: 100, category: "Cold", isVeg: true, emoji: "🍹"),
      ],
    ),
    RestroCategory(
      id: 4,
      name: "Soups",
      bgColor: Color(0xFF735F32),
      icon: "🍜",
      items: [
        RestroMenuItem(id: 401, name: "Tomato Basil Soup", price: 120, category: "Vegetarian", isVeg: true, emoji: "🍅"),
        RestroMenuItem(id: 402, name: "Sweet Corn Soup", price: 130, category: "Vegetarian", isVeg: true, emoji: "🌽"),
        RestroMenuItem(id: 403, name: "Hot & Sour Soup", price: 140, category: "Vegetarian", isVeg: true, emoji: "🥣"),
        RestroMenuItem(id: 404, name: "Chicken Clear Soup", price: 160, category: "Non-Vegetarian", isVeg: false, emoji: "🍗"),
        RestroMenuItem(id: 405, name: "Cream of Mushroom", price: 150, category: "Vegetarian", isVeg: true, emoji: "🍄"),
      ],
    ),
    RestroCategory(
      id: 5,
      name: "Desserts",
      bgColor: Color(0xFF1D2569),
      icon: "🍰",
      items: [
        RestroMenuItem(id: 501, name: "Gulab Jamun (2 pcs)", price: 100, category: "Vegetarian", isVeg: true, emoji: "🍮"),
        RestroMenuItem(id: 502, name: "Malai Kulfi", price: 150, category: "Vegetarian", isVeg: true, emoji: "🍦"),
        RestroMenuItem(id: 503, name: "Chocolate Lava Cake", price: 250, category: "Vegetarian", isVeg: true, emoji: "🎂"),
        RestroMenuItem(id: 504, name: "Ras Malai", price: 180, category: "Vegetarian", isVeg: true, emoji: "🥛"),
      ],
    ),
    RestroCategory(
      id: 6,
      name: "Pizzas",
      bgColor: Color(0xFF285430),
      icon: "🍕",
      items: [
        RestroMenuItem(id: 601, name: "Margherita Pizza", price: 350, category: "Vegetarian", isVeg: true, emoji: "🧀"),
        RestroMenuItem(id: 602, name: "Veg Supreme Pizza", price: 400, category: "Vegetarian", isVeg: true, emoji: "🫑"),
        RestroMenuItem(id: 603, name: "Pepperoni Chicken Pizza", price: 450, category: "Non-Vegetarian", isVeg: false, emoji: "🍕"),
      ],
    ),
    RestroCategory(
      id: 7,
      name: "Drinks",
      bgColor: Color(0xFFB73E3E),
      icon: "🍺",
      items: [
        RestroMenuItem(id: 701, name: "Craft Beer", price: 200, category: "Beverage", isVeg: true, emoji: "🍺"),
        RestroMenuItem(id: 702, name: "Blue Lagoon Cocktail", price: 400, category: "Beverage", isVeg: true, emoji: "🍸"),
        RestroMenuItem(id: 703, name: "Mojito Mocktail", price: 250, category: "Beverage", isVeg: true, emoji: "🍹"),
      ],
    ),
    RestroCategory(
      id: 8,
      name: "Salads",
      bgColor: Color(0xFF5B45B0),
      icon: "🥗",
      items: [
        RestroMenuItem(id: 801, name: "Caesar Salad", price: 200, category: "Vegetarian", isVeg: true, emoji: "🥗"),
        RestroMenuItem(id: 802, name: "Greek Salad", price: 250, category: "Vegetarian", isVeg: true, emoji: "🥒"),
        RestroMenuItem(id: 803, name: "Fresh Fruit Bowl", price: 150, category: "Vegetarian", isVeg: true, emoji: "🍉"),
        RestroMenuItem(id: 804, name: "Chicken Tikka Salad", price: 300, category: "Non-Vegetarian", isVeg: false, emoji: "🍗"),
      ],
    ),
  ];

  static List<RestroTableItem> initialTables = [
    const RestroTableItem(id: "t-1", name: "1", status: "Booked", initial: "AM", seats: 4, customerName: "Amrit Maurya", customerPhone: "+91 98765 43210", currentBillTotal: 850.0),
    const RestroTableItem(id: "t-2", name: "2", status: "Available", initial: "", seats: 6),
    const RestroTableItem(id: "t-3", name: "3", status: "Booked", initial: "JS", seats: 2, customerName: "John Smith", customerPhone: "+91 91234 56789", currentBillTotal: 420.0),
    const RestroTableItem(id: "t-4", name: "4", status: "Available", initial: "", seats: 4),
    const RestroTableItem(id: "t-5", name: "5", status: "Booked", initial: "PL", seats: 3, customerName: "Priya Lal", customerPhone: "+91 99887 76655", currentBillTotal: 650.0),
    const RestroTableItem(id: "t-6", name: "6", status: "Available", initial: "", seats: 4),
    const RestroTableItem(id: "t-7", name: "7", status: "Booked", initial: "LC", seats: 5, customerName: "Liam Chen", customerPhone: "+91 98112 23344", currentBillTotal: 1200.0),
    const RestroTableItem(id: "t-8", name: "8", status: "Available", initial: "", seats: 5),
    const RestroTableItem(id: "t-9", name: "9", status: "Booked", initial: "NK", seats: 6, customerName: "Nitin Kumar", customerPhone: "+91 97654 32100", currentBillTotal: 980.0),
    const RestroTableItem(id: "t-10", name: "10", status: "Available", initial: "", seats: 6),
    const RestroTableItem(id: "t-11", name: "11", status: "Booked", initial: "GT", seats: 4, customerName: "Gaurav Tiwari", customerPhone: "+91 94567 89012", currentBillTotal: 560.0),
    const RestroTableItem(id: "t-12", name: "12", status: "Available", initial: "", seats: 6),
    const RestroTableItem(id: "t-13", name: "13", status: "Booked", initial: "EK", seats: 2, customerName: "Elena Kapoor", customerPhone: "+91 93456 78901", currentBillTotal: 340.0),
    const RestroTableItem(id: "t-14", name: "14", status: "Available", initial: "", seats: 6),
    const RestroTableItem(id: "t-15", name: "15", status: "Booked", initial: "TW", seats: 3, customerName: "Tanvi Wadhwa", customerPhone: "+91 92345 67890", currentBillTotal: 720.0),
  ];

  static const List<RestroMetric> overallPerformance = [
    RestroMetric(title: "Revenue", value: "₹50,846.90", percentage: "12%", color: Color(0xFF025CCA), isIncrease: false),
    RestroMetric(title: "Outbound Clicks", value: "10,342", percentage: "16%", color: Color(0xFF02CA3A), isIncrease: true),
    RestroMetric(title: "Total Customer", value: "19,720", percentage: "10%", color: Color(0xFFF6B100), isIncrease: true),
    RestroMetric(title: "Event Count", value: "20,000", percentage: "10%", color: Color(0xFFBE3E3F), isIncrease: false),
  ];

  static const List<RestroMetric> itemDetails = [
    RestroMetric(title: "Total Categories", value: "8", percentage: "12%", color: Color(0xFF5B45B0), isIncrease: false),
    RestroMetric(title: "Total Dishes", value: "50", percentage: "12%", color: Color(0xFF285430), isIncrease: true),
    RestroMetric(title: "Active Orders", value: "12", percentage: "12%", color: Color(0xFF735F32), isIncrease: true),
    RestroMetric(title: "Total Tables", value: "15", percentage: "100%", color: Color(0xFF7F167F), isIncrease: true),
  ];

  static List<RestroOrder> initialOrders = [
    RestroOrder(
      id: "1737213120000",
      customer: "Amrit Raj",
      status: "Ready",
      dateTime: DateTime.now().subtract(const Duration(minutes: 12)),
      itemCount: 4,
      tableNo: "3",
      total: 850.0,
      itemNames: ["Butter Chicken", "Paneer Tikka", "Garlic Naan (2)"],
    ),
    RestroOrder(
      id: "1737213250000",
      customer: "John Doe",
      status: "In Progress",
      dateTime: DateTime.now().subtract(const Duration(minutes: 25)),
      itemCount: 3,
      tableNo: "4",
      total: 420.0,
      itemNames: ["Masala Dosa", "Cold Coffee", "Gulab Jamun"],
    ),
    RestroOrder(
      id: "1737213400000",
      customer: "Emma Smith",
      status: "Ready",
      dateTime: DateTime.now().subtract(const Duration(minutes: 35)),
      itemCount: 5,
      tableNo: "5",
      total: 650.0,
      itemNames: ["Dal Makhani", "Jeera Rice", "Kadai Paneer", "Roti (4)"],
    ),
    RestroOrder(
      id: "1737213550000",
      customer: "Chris Brown",
      status: "In Progress",
      dateTime: DateTime.now().subtract(const Duration(minutes: 48)),
      itemCount: 6,
      tableNo: "6",
      total: 1200.0,
      itemNames: ["Chicken Biryani (2)", "Tandoori Chicken", "Mango Lassi (3)"],
    ),
    RestroOrder(
      id: "1737213700000",
      customer: "Sarah Connor",
      status: "Completed",
      dateTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
      itemCount: 2,
      tableNo: "1",
      total: 550.0,
      itemNames: ["Margherita Pizza", "Iced Tea (2)"],
    ),
  ];
}
