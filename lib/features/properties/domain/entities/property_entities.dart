class PropertyEntity {
  final int? id;
  final String name;
  final String type;
  final String address;
  final String description;

  const PropertyEntity({
    this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.description,
  });

  factory PropertyEntity.fromMap(Map<String, dynamic> map) {
    return PropertyEntity(
      id: map['id'] as int,
      name: map['name'] as String,
      type: map['property_type'] as String,
      address: map['address'] as String? ?? '',
      description: map['description'] as String? ?? '',
    );
  }
}

class DepartmentEntity {
  final int? id;
  final int propertyId;
  final String name;
  final String description;

  const DepartmentEntity({
    this.id,
    required this.propertyId,
    required this.name,
    required this.description,
  });

  factory DepartmentEntity.fromMap(Map<String, dynamic> map) {
    return DepartmentEntity(
      id: map['id'] as int,
      propertyId: map['property_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
    );
  }
}

class UnitEntity {
  final int? id;
  final int propertyId;
  final int? departmentId;
  final String number;
  final String type;
  final int floor;
  final double area;
  final double rent;
  final String status;
  final String description;

  const UnitEntity({
    this.id,
    required this.propertyId,
    this.departmentId,
    required this.number,
    required this.type,
    required this.floor,
    required this.area,
    required this.rent,
    required this.status,
    required this.description,
  });

  factory UnitEntity.fromMap(Map<String, dynamic> map) {
    return UnitEntity(
      id: map['id'] as int,
      propertyId: map['property_id'] as int,
      departmentId: map['department_id'] as int?,
      number: map['unit_number'] as String,
      type: map['unit_type'] as String,
      floor: map['floor_number'] as int? ?? 0,
      area: (map['area'] as num?)?.toDouble() ?? 0,
      rent: (map['monthly_rent'] as num).toDouble(),
      status: map['status'] as String,
      description: map['description'] as String? ?? '',
    );
  }
}
