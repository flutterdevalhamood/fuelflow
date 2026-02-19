class TripCustomer {
  final int id;
  final String name;

  const TripCustomer({required this.id, required this.name});

  factory TripCustomer.fromJson(Map<String, dynamic> json) =>
      TripCustomer(id: json['id'] as int, name: json['name'] as String);
}

class Trip {
  final int id;
  final String customerId;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final String status;
  final String? notes;
  final TripCustomer customer;

  const Trip({
    required this.id,
    required this.customerId,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.status,
    this.notes,
    required this.customer,
  });

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
    id: json['id'] as int,
    customerId: json['customer_id'] as String,
    scheduledStart: DateTime.parse(json['scheduled_start'] as String),
    scheduledEnd: DateTime.parse(json['scheduled_end'] as String),
    status: json['status'] as String,
    notes: json['notes'] as String?,
    customer: TripCustomer.fromJson(json['customer'] as Map<String, dynamic>),
  );
}
