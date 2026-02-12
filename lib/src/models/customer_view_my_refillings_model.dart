class CustomerViewMyRefillingsModel {
  final int stockEventId;
  final String tripId;
  final String type;
  final String quantity;
  final String createdAt;
  final List<MeterReading> meterReadings;
  final List<dynamic> tripMedia;
  final String? customerVehicle;

  CustomerViewMyRefillingsModel({
    required this.stockEventId,
    required this.tripId,
    required this.type,
    required this.quantity,
    required this.createdAt,
    required this.meterReadings,
    required this.tripMedia,
    this.customerVehicle,
  });

  factory CustomerViewMyRefillingsModel.fromJson(Map<String, dynamic> json) {
    return CustomerViewMyRefillingsModel(
      stockEventId: json['stock_event_id'] ?? 0,
      tripId: json['trip_id']?.toString() ?? '',
      type: json['type'] ?? '',
      quantity: json['quantity']?.toString() ?? '0',
      createdAt: json['created_at'] ?? '',
      meterReadings:
          (json['meter_readings'] as List<dynamic>?)
              ?.map((m) => MeterReading.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      tripMedia: json['trip_media'] ?? [],
      customerVehicle: json['customer_vehicle'] as String?,
    );
  }

  bool get isInflow => type.toLowerCase() == 'inflow';
  bool get isOutflow => type.toLowerCase() == 'outflow';

  String get formattedDate {
    try {
      final dateTime = DateTime.parse(createdAt);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return createdAt;
    }
  }

  MeterReading? get startMeterReading {
    try {
      return meterReadings.firstWhere(
        (reading) => reading.readingType == 'customer_start_meter',
      );
    } catch (e) {
      return null;
    }
  }

  MeterReading? get endMeterReading {
    try {
      return meterReadings.firstWhere(
        (reading) => reading.readingType == 'customer_end_meter',
      );
    } catch (e) {
      return null;
    }
  }

  double get quantityValue {
    try {
      return double.parse(quantity);
    } catch (e) {
      return 0.0;
    }
  }
}

class MeterReading {
  final int id;
  final String readingType;
  final String readingValue;
  final String photo;
  final String createdAt;

  MeterReading({
    required this.id,
    required this.readingType,
    required this.readingValue,
    required this.photo,
    required this.createdAt,
  });

  factory MeterReading.fromJson(Map<String, dynamic> json) {
    return MeterReading(
      id: json['id'] ?? 0,
      readingType: json['reading_type'] ?? '',
      readingValue: json['reading_value']?.toString() ?? '0',
      photo: json['photo'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  String get displayName {
    switch (readingType) {
      case 'customer_start_meter':
        return 'Start Meter';
      case 'customer_end_meter':
        return 'End Meter';
      default:
        return readingType.replaceAll('_', ' ').toUpperCase();
    }
  }

  double get value {
    try {
      return double.parse(readingValue);
    } catch (e) {
      return 0.0;
    }
  }

  DateTime get dateTime {
    try {
      return DateTime.parse(createdAt);
    } catch (e) {
      return DateTime.now();
    }
  }
}
