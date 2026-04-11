class DailyGoals {
  final int calories;
  final int protein;
  final int water;
  final int walking;
  final int? iron;
  final int? calcium;

  DailyGoals({
    required this.calories,
    required this.protein,
    required this.water,
    required this.walking,
    this.iron,
    this.calcium,
  });

  factory DailyGoals.fromJson(Map<String, dynamic> json) {
    return DailyGoals(
      calories: json['calories'] ?? 2200,
      protein: json['protein'] ?? 75,
      water: json['water'] ?? 2500,
      walking: json['walking'] ?? 5000,
      iron: json['iron'],
      calcium: json['calcium'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'water': water,
      'walking': walking,
      'iron': iron,
      'calcium': calcium,
    };
  }
}

class PartnerProfile {
  final String name;
  final String relationship; // 'husband' | 'partner' | 'family'
  final int busyLevel; // 1-5
  final String preferredTone; // 'supportive' | 'factual' | 'humorous'
  final int? trimester;

  PartnerProfile({
    required this.name,
    required this.relationship,
    required this.busyLevel,
    required this.preferredTone,
    this.trimester,
  });

  factory PartnerProfile.fromJson(Map<String, dynamic> json) {
    return PartnerProfile(
      name: json['name'] ?? '',
      relationship: json['relationship'] ?? 'partner',
      busyLevel: json['busyLevel'] ?? 3,
      preferredTone: json['preferredTone'] ?? 'supportive',
      trimester: json['trimester'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'relationship': relationship,
      'busyLevel': busyLevel,
      'preferredTone': preferredTone,
      'trimester': trimester,
    };
  }
}

class UserModel {
  final String uid;
  final String name;
  final String? email;
  final String? photoUrl;
  final String? lastPeriodDate;
  final String? testDate;
  final String? dueDate;
  final int currentWeek;
  final String country;
  final String language;
  final int streakDays;
  final int totalPoints;
  final String plan; // 'free' | 'trial' | 'premium'
  final String? trialStartDate;
  final String? partnerId;
  final String? partnerEmail;
  final bool quietMode;
  final String units; // 'imperial' | 'metric'
  final String createdAt;
  final String region; // 'US' | 'EU' | 'IN'
  final bool? isPremium;
  final bool? trialExpired;
  final DailyGoals? dailyGoals;
  final DailyGoals? achievedToday;
  final String? lastLoginDate;
  final String? lastResetDate;
  final String? height;
  final String? weight;
  final String? prePregnancyWeight;
  final String? bloodType;
  final String? allergies;
  final String? medicalConditions;
  final int? mealsLogged;
  final int? daysTracked;
  final List<String>? badges;
  final bool? isPartnerAccount;
  final PartnerProfile? partnerProfile;
  final String? lastAiInsight;
  final String? lastAiInsightDate;
  final String? subscriptionId;
  final String? subscriptionType; // 'monthly' | 'yearly' | 'trial'
  final String? subscriptionExpiryDate;
  final String? paymentProvider; // 'paypal' | 'razorpay'
  final bool? autoRenew;
  final List<String>? achievedBadges;
  final String? lastCheckInDate;

  UserModel({
    required this.uid,
    required this.name,
    this.email,
    this.photoUrl,
    this.lastPeriodDate,
    this.testDate,
    this.dueDate,
    required this.currentWeek,
    required this.country,
    required this.language,
    required this.streakDays,
    required this.totalPoints,
    required this.plan,
    this.trialStartDate,
    this.partnerId,
    this.partnerEmail,
    required this.quietMode,
    required this.units,
    required this.createdAt,
    required this.region,
    this.isPremium,
    this.trialExpired,
    this.dailyGoals,
    this.achievedToday,
    this.lastLoginDate,
    this.lastResetDate,
    this.height,
    this.weight,
    this.prePregnancyWeight,
    this.bloodType,
    this.allergies,
    this.medicalConditions,
    this.mealsLogged,
    this.daysTracked,
    this.badges,
    this.isPartnerAccount,
    this.partnerProfile,
    this.lastAiInsight,
    this.lastAiInsightDate,
    this.subscriptionId,
    this.subscriptionType,
    this.subscriptionExpiryDate,
    this.paymentProvider,
    this.autoRenew,
    this.achievedBadges,
    this.lastCheckInDate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      photoUrl: json['photoUrl'],
      lastPeriodDate: json['lastPeriodDate'],
      testDate: json['testDate'],
      dueDate: json['dueDate'],
      currentWeek: json['currentWeek'] ?? 0,
      country: json['country'] ?? 'US',
      language: json['language'] ?? 'en',
      streakDays: json['streakDays'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      plan: json['plan'] ?? 'trial',
      trialStartDate: json['trialStartDate'],
      partnerId: json['partnerId'],
      partnerEmail: json['partnerEmail'],
      quietMode: json['quietMode'] ?? false,
      units: json['units'] ?? 'imperial',
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
      region: json['region'] ?? 'US',
      isPremium: json['isPremium'],
      trialExpired: json['trialExpired'],
      dailyGoals: json['dailyGoals'] != null ? DailyGoals.fromJson(json['dailyGoals']) : null,
      achievedToday: json['achievedToday'] != null ? DailyGoals.fromJson(json['achievedToday']) : null,
      lastLoginDate: json['lastLoginDate'],
      lastResetDate: json['lastResetDate'],
      height: json['height'],
      weight: json['weight'],
      prePregnancyWeight: json['prePregnancyWeight'],
      bloodType: json['bloodType'],
      allergies: json['allergies'],
      medicalConditions: json['medicalConditions'],
      mealsLogged: json['mealsLogged'],
      daysTracked: json['daysTracked'],
      badges: json['badges'] != null ? List<String>.from(json['badges']) : null,
      isPartnerAccount: json['isPartnerAccount'],
      partnerProfile: json['partnerProfile'] != null ? PartnerProfile.fromJson(json['partnerProfile']) : null,
      lastAiInsight: json['lastAiInsight'],
      lastAiInsightDate: json['lastAiInsightDate'],
      subscriptionId: json['subscriptionId'],
      subscriptionType: json['subscriptionType'],
      subscriptionExpiryDate: json['subscriptionExpiryDate'],
      paymentProvider: json['paymentProvider'],
      autoRenew: json['autoRenew'],
      achievedBadges: json['achievedBadges'] != null ? List<String>.from(json['achievedBadges']) : null,
      lastCheckInDate: json['lastCheckInDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'lastPeriodDate': lastPeriodDate,
      'testDate': testDate,
      'dueDate': dueDate,
      'currentWeek': currentWeek,
      'country': country,
      'language': language,
      'streakDays': streakDays,
      'totalPoints': totalPoints,
      'plan': plan,
      'trialStartDate': trialStartDate,
      'partnerId': partnerId,
      'partnerEmail': partnerEmail,
      'quietMode': quietMode,
      'units': units,
      'createdAt': createdAt,
      'region': region,
      'isPremium': isPremium,
      'trialExpired': trialExpired,
      'dailyGoals': dailyGoals?.toJson(),
      'achievedToday': achievedToday?.toJson(),
      'lastLoginDate': lastLoginDate,
      'lastResetDate': lastResetDate,
      'height': height,
      'weight': weight,
      'prePregnancyWeight': prePregnancyWeight,
      'bloodType': bloodType,
      'allergies': allergies,
      'medicalConditions': medicalConditions,
      'mealsLogged': mealsLogged,
      'daysTracked': daysTracked,
      'badges': badges,
      'isPartnerAccount': isPartnerAccount,
      'partnerProfile': partnerProfile?.toJson(),
      'lastAiInsight': lastAiInsight,
      'lastAiInsightDate': lastAiInsightDate,
      'subscriptionId': subscriptionId,
      'subscriptionType': subscriptionType,
      'subscriptionExpiryDate': subscriptionExpiryDate,
      'paymentProvider': paymentProvider,
      'autoRenew': autoRenew,
      'achievedBadges': achievedBadges,
      'lastCheckInDate': lastCheckInDate,
    };
  }

  UserModel copyWith({
    String? name,
    String? photoUrl,
    int? currentWeek,
    int? streakDays,
    int? totalPoints,
    String? plan,
    bool? quietMode,
    bool? isPremium,
    bool? trialExpired,
    DailyGoals? achievedToday,
    String? lastLoginDate,
    String? lastResetDate,
    String? subscriptionId,
    String? subscriptionType,
    String? subscriptionExpiryDate,
    String? paymentProvider,
    bool? autoRenew,
    List<String>? achievedBadges,
    String? lastCheckInDate,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      lastPeriodDate: lastPeriodDate,
      testDate: testDate,
      dueDate: dueDate,
      currentWeek: currentWeek ?? this.currentWeek,
      country: country,
      language: language,
      streakDays: streakDays ?? this.streakDays,
      totalPoints: totalPoints ?? this.totalPoints,
      plan: plan ?? this.plan,
      trialStartDate: trialStartDate,
      partnerId: partnerId,
      partnerEmail: partnerEmail,
      quietMode: quietMode ?? this.quietMode,
      units: units,
      createdAt: createdAt,
      region: region,
      isPremium: isPremium ?? this.isPremium,
      trialExpired: trialExpired ?? this.trialExpired,
      dailyGoals: dailyGoals,
      achievedToday: achievedToday ?? this.achievedToday,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      height: height,
      weight: weight,
      prePregnancyWeight: prePregnancyWeight,
      bloodType: bloodType,
      allergies: allergies,
      medicalConditions: medicalConditions,
      mealsLogged: mealsLogged,
      daysTracked: daysTracked,
      badges: badges,
      isPartnerAccount: isPartnerAccount,
      partnerProfile: partnerProfile,
      lastAiInsight: lastAiInsight,
      lastAiInsightDate: lastAiInsightDate,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      subscriptionExpiryDate: subscriptionExpiryDate ?? this.subscriptionExpiryDate,
      paymentProvider: paymentProvider ?? this.paymentProvider,
      autoRenew: autoRenew ?? this.autoRenew,
      achievedBadges: achievedBadges ?? this.achievedBadges,
      lastCheckInDate: lastCheckInDate ?? this.lastCheckInDate,
    );
  }
}
