class TenantEntity {
  final int? id;
  final String fullName;
  final String phone;
  final String email;
  final String nationalId;
  final String address;
  final String notes;

  const TenantEntity({
    this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.nationalId,
    required this.address,
    required this.notes,
  });

  factory TenantEntity.fromMap(Map<String, dynamic> map) {
    return TenantEntity(
      id: map['id'] as int,
      fullName: map['full_name'] as String,
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      nationalId: map['national_id'] as String? ?? '',
      address: map['address'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
    );
  }
}

class UnitOption {
  final int id;
  final String label;
  final double monthlyRent;
  final String status;

  const UnitOption({
    required this.id,
    required this.label,
    required this.monthlyRent,
    required this.status,
  });

  factory UnitOption.fromMap(Map<String, dynamic> map) {
    return UnitOption(
      id: map['id'] as int,
      label: map['label'] as String,
      monthlyRent: (map['monthly_rent'] as num).toDouble(),
      status: map['status'] as String,
    );
  }
}

class ContractEntity {
  final int? id;
  final String contractNumber;
  final int tenantId;
  final String tenantName;
  final int unitId;
  final String unitLabel;
  final String startDate;
  final String endDate;
  final double monthlyRent;
  final double depositAmount;
  final String status;
  final String notes;

  const ContractEntity({
    this.id,
    required this.contractNumber,
    required this.tenantId,
    required this.tenantName,
    required this.unitId,
    required this.unitLabel,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.depositAmount,
    required this.status,
    required this.notes,
  });

  factory ContractEntity.fromMap(Map<String, dynamic> map) {
    return ContractEntity(
      id: map['id'] as int,
      contractNumber: map['contract_number'] as String,
      tenantId: map['tenant_id'] as int,
      tenantName: map['tenant_name'] as String,
      unitId: map['unit_id'] as int,
      unitLabel: map['unit_label'] as String,
      startDate: map['start_date'] as String,
      endDate: map['end_date'] as String,
      monthlyRent: (map['monthly_rent'] as num).toDouble(),
      depositAmount: (map['deposit_amount'] as num).toDouble(),
      status: map['status'] as String,
      notes: map['notes'] as String? ?? '',
    );
  }
}
