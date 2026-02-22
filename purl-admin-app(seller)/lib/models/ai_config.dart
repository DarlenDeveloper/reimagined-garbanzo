import 'package:cloud_firestore/cloud_firestore.dart';

class AIServiceConfig {
  final bool enabled;
  final String status;
  final String? vapiAssistantId;
  final String? vapiPhoneNumberId;
  final String? didId;
  final String? phoneNumber;
  final String storeName;
  final AISubscription subscription;
  final DateTime createdAt;
  final DateTime updatedAt;

  AIServiceConfig({
    required this.enabled,
    required this.status,
    this.vapiAssistantId,
    this.vapiPhoneNumberId,
    this.didId,
    this.phoneNumber,
    required this.storeName,
    required this.subscription,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AIServiceConfig.fromFirestore(Map<String, dynamic> data) {
    return AIServiceConfig(
      enabled: data['enabled'] ?? false,
      status: data['status'] ?? 'inactive',
      vapiAssistantId: data['vapiAssistantId'],
      vapiPhoneNumberId: data['vapiPhoneNumberId'],
      didId: data['didId'],
      phoneNumber: data['phoneNumber'],
      storeName: data['storeName'] ?? '',
      subscription: AISubscription.fromFirestore(data['subscription'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  bool get isActive => enabled && status == 'active';
  bool get isGracePeriod => enabled && status == 'grace_period';
  bool get isExpired => status == 'expired';
}

class AISubscription {
  final String plan;
  final double monthlyFee;
  final String currency;
  final DateTime startDate;
  final DateTime expiryDate;
  final DateTime? gracePeriodEndsAt;
  final int minutesIncluded;
  final double usedMinutes;
  final String status;
  final int renewalCount;
  final DateTime? lastRenewalDate;

  AISubscription({
    required this.plan,
    required this.monthlyFee,
    required this.currency,
    required this.startDate,
    required this.expiryDate,
    this.gracePeriodEndsAt,
    required this.minutesIncluded,
    required this.usedMinutes,
    required this.status,
    required this.renewalCount,
    this.lastRenewalDate,
  });

  factory AISubscription.fromFirestore(Map<String, dynamic> data) {
    return AISubscription(
      plan: data['plan'] ?? 'Basic',
      monthlyFee: (data['monthlyFee'] ?? 20.0).toDouble(),
      currency: data['currency'] ?? 'USD',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      gracePeriodEndsAt: (data['gracePeriodEndsAt'] as Timestamp?)?.toDate(),
      minutesIncluded: data['minutesIncluded'] ?? 100,
      usedMinutes: (data['usedMinutes'] ?? 0).toDouble(),
      status: data['status'] ?? 'inactive',
      renewalCount: data['renewalCount'] ?? 0,
      lastRenewalDate: (data['lastRenewalDate'] as Timestamp?)?.toDate(),
    );
  }

  int get remainingMinutes => (minutesIncluded - usedMinutes).round().clamp(0, minutesIncluded);
  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;
  bool get isExpiringSoon => daysUntilExpiry <= 7 && daysUntilExpiry > 0;
}

class CallLog {
  final String id;
  final String callId;
  final String customerPhone;
  final String? customerName;
  final int duration;
  final String transcript;
  final String summary;
  final int? csatScore;
  final double cost;
  final DateTime createdAt;

  CallLog({
    required this.id,
    required this.callId,
    required this.customerPhone,
    this.customerName,
    required this.duration,
    required this.transcript,
    required this.summary,
    this.csatScore,
    required this.cost,
    required this.createdAt,
  });

  factory CallLog.fromFirestore(String id, Map<String, dynamic> data) {
    return CallLog(
      id: id,
      callId: data['callId'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerName: data['customerName'],
      duration: data['duration'] ?? 0,
      transcript: data['transcript'] ?? '',
      summary: data['summary'] ?? '',
      csatScore: data['csatScore'],
      cost: (data['cost'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get formattedCustomerPhone {
    // Add +256 prefix if not present
    if (customerPhone.startsWith('+')) {
      return customerPhone;
    }
    return '+256$customerPhone';
  }

  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes}m ${seconds}s';
  }

  String get formattedPhone {
    // Add +256 prefix if not present
    if (customerPhone.startsWith('+')) {
      return customerPhone;
    }
    return '+256$customerPhone';
  }
}
