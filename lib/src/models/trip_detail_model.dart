// lib/src/models/trip_detail_model.dart

class TripDetail {
  final int id;
  final String customerId;
  final String scheduledStart;
  final String scheduledEnd;
  final String status;
  final String? notes;
  final String isVerified;
  final TripDetailCustomer customer;
  final List<TripDetailStop> stops;
  final List<TripDetailAssignment> assignments;
  final List<TripDetailEvent> events;
  final List<TripDetailStockEvent> stockEvents;

  TripDetail({
    required this.id,
    required this.customerId,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.status,
    this.notes,
    required this.isVerified,
    required this.customer,
    required this.stops,
    required this.assignments,
    required this.events,
    required this.stockEvents,
  });

  factory TripDetail.fromJson(Map<String, dynamic> json) {
    final trip = json['trip'] as Map<String, dynamic>;
    return TripDetail(
      id: trip['id'] as int,
      customerId: trip['customer_id'].toString(),
      scheduledStart: trip['scheduled_start'] as String,
      scheduledEnd: trip['scheduled_end'] as String,
      status: trip['status'] as String,
      notes: trip['notes'] as String?,
      isVerified: trip['is_verified'].toString(),
      customer: TripDetailCustomer.fromJson(
        trip['customer'] as Map<String, dynamic>,
      ),
      stops:
          (trip['stops'] as List<dynamic>)
              .map((e) => TripDetailStop.fromJson(e as Map<String, dynamic>))
              .toList(),
      assignments:
          (trip['assignments'] as List<dynamic>)
              .map(
                (e) => TripDetailAssignment.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      events:
          (trip['events'] as List<dynamic>)
              .map((e) => TripDetailEvent.fromJson(e as Map<String, dynamic>))
              .toList(),
      stockEvents:
          (trip['stock_events'] as List<dynamic>)
              .map(
                (e) => TripDetailStockEvent.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}

class TripDetailCustomer {
  final int id;
  final String name;
  final String? representative;
  final String? mobile;
  final String? email;
  final String? address;

  TripDetailCustomer({
    required this.id,
    required this.name,
    this.representative,
    this.mobile,
    this.email,
    this.address,
  });

  factory TripDetailCustomer.fromJson(Map<String, dynamic> json) {
    return TripDetailCustomer(
      id: json['id'] as int,
      name: json['Name'] as String,
      representative: json['representative'] as String?,
      mobile: json['mobile'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
    );
  }
}

class TripDetailStop {
  final int id;
  final String stopOrder;
  final String siteId;
  final String status;
  final String expectedQuantity;
  final String expectedArrivalTime;
  final String expectedCompletedTime;
  final String? arrivalTime;
  final String? completedTime;
  final String deliveredQty;
  final TripDetailSite site;
  final List<TripDetailStopVehicle> stopVehicles;

  TripDetailStop({
    required this.id,
    required this.stopOrder,
    required this.siteId,
    required this.status,
    required this.expectedQuantity,
    required this.expectedArrivalTime,
    required this.expectedCompletedTime,
    this.arrivalTime,
    this.completedTime,
    required this.deliveredQty,
    required this.site,
    required this.stopVehicles,
  });

  factory TripDetailStop.fromJson(Map<String, dynamic> json) {
    return TripDetailStop(
      id: json['id'] as int,
      stopOrder: json['stop_order'].toString(),
      siteId: json['site_id'].toString(),
      status: json['status'] as String,
      expectedQuantity: json['expected_quantity'] as String,
      expectedArrivalTime: json['expected_arrival_time'] as String,
      expectedCompletedTime: json['expected_completed_time'] as String,
      arrivalTime: json['arrival_time'] as String?,
      completedTime: json['completed_time'] as String?,
      deliveredQty: json['delivered_qty'] as String,
      site: TripDetailSite.fromJson(json['site'] as Map<String, dynamic>),
      stopVehicles:
          (json['stop_vehicles'] as List<dynamic>)
              .map(
                (e) =>
                    TripDetailStopVehicle.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}

class TripDetailSite {
  final int id;
  final String name;
  final String? description;

  TripDetailSite({required this.id, required this.name, this.description});

  factory TripDetailSite.fromJson(Map<String, dynamic> json) {
    return TripDetailSite(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }
}

class TripDetailStopVehicle {
  final int id;
  final String vehicleId;
  final String plateNo;

  TripDetailStopVehicle({
    required this.id,
    required this.vehicleId,
    required this.plateNo,
  });

  factory TripDetailStopVehicle.fromJson(Map<String, dynamic> json) {
    return TripDetailStopVehicle(
      id: json['id'] as int,
      vehicleId: json['vehicle_id'].toString(),
      plateNo: (json['vehicle'] as Map<String, dynamic>)['plate_no'] as String,
    );
  }
}

class TripDetailAssignment {
  final int id;
  final String status;
  final TripDetailVehicle vehicle;
  final TripDetailDriver driver;
  final String createdAt;

  TripDetailAssignment({
    required this.id,
    required this.status,
    required this.vehicle,
    required this.driver,
    required this.createdAt,
  });

  factory TripDetailAssignment.fromJson(Map<String, dynamic> json) {
    return TripDetailAssignment(
      id: json['id'] as int,
      status: json['status'] as String,
      vehicle: TripDetailVehicle.fromJson(
        json['vehicle'] as Map<String, dynamic>,
      ),
      driver: TripDetailDriver.fromJson(json['driver'] as Map<String, dynamic>),
      createdAt: json['created_at'] as String,
    );
  }
}

class TripDetailVehicle {
  final int id;
  final String plateNo;
  final String? capacity;

  TripDetailVehicle({required this.id, required this.plateNo, this.capacity});

  factory TripDetailVehicle.fromJson(Map<String, dynamic> json) {
    return TripDetailVehicle(
      id: json['id'] as int,
      plateNo: json['plate_no'] as String,
      capacity: json['capacity'] as String?,
    );
  }
}

class TripDetailDriver {
  final int id;
  final String name;
  final String? mobile;

  TripDetailDriver({required this.id, required this.name, this.mobile});

  factory TripDetailDriver.fromJson(Map<String, dynamic> json) {
    return TripDetailDriver(
      id: json['id'] as int,
      name: json['Name'] as String,
      mobile: json['mobile'] as String?,
    );
  }
}

class TripDetailEvent {
  final int id;
  final String eventType;
  final String? description;
  final String? latitude;
  final String? longitude;
  final String createdAt;

  TripDetailEvent({
    required this.id,
    required this.eventType,
    this.description,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory TripDetailEvent.fromJson(Map<String, dynamic> json) {
    return TripDetailEvent(
      id: json['id'] as int,
      eventType: json['event_type'] as String,
      description: json['description'] as String?,
      latitude: json['latitude'] as String?,
      longitude: json['longitude'] as String?,
      createdAt: json['created_at'] as String,
    );
  }
}

class TripDetailStockEvent {
  final int id;
  final String type;
  final String quantity;
  final String beforeQuantity;
  final String afterQuantity;
  final String createdAt;
  final List<TripDetailMeterReading> meterReadings;

  TripDetailStockEvent({
    required this.id,
    required this.type,
    required this.quantity,
    required this.beforeQuantity,
    required this.afterQuantity,
    required this.createdAt,
    required this.meterReadings,
  });

  factory TripDetailStockEvent.fromJson(Map<String, dynamic> json) {
    return TripDetailStockEvent(
      id: json['id'] as int,
      type: json['type'] as String,
      quantity: json['quantity'] as String,
      beforeQuantity: json['before_quantity'] as String,
      afterQuantity: json['after_quantity'] as String,
      createdAt: json['created_at'] as String,
      meterReadings:
          (json['meter_readings'] as List<dynamic>)
              .map(
                (e) =>
                    TripDetailMeterReading.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}

class TripDetailMeterReading {
  final int id;
  final String readingType;
  final String readingValue;
  final String? photoPath;
  final String recordedAt;

  TripDetailMeterReading({
    required this.id,
    required this.readingType,
    required this.readingValue,
    this.photoPath,
    required this.recordedAt,
  });

  factory TripDetailMeterReading.fromJson(Map<String, dynamic> json) {
    return TripDetailMeterReading(
      id: json['id'] as int,
      readingType: json['reading_type'] as String,
      readingValue: json['reading_value'] as String,
      photoPath: json['photo_path'] as String?,
      recordedAt: json['recorded_at'] as String,
    );
  }
}
