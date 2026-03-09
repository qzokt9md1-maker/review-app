class MaterialReviewSettings {
  final String? docId;
  final String  materialName;
  final double  easyBaseDays;     // できた時の初期日数
  final double  mediumBaseDays;   // 微妙の時の基準日数
  final double  hardBaseDays;     // できない時にリセットする日数
  final double  growthMultiplier; // できた時の伸び倍率
  final bool    enabled;

  const MaterialReviewSettings({
    this.docId,
    required this.materialName,
    this.easyBaseDays     = 3.0,
    this.mediumBaseDays   = 2.0,
    this.hardBaseDays     = 1.0,
    this.growthMultiplier = 2.0,
    this.enabled          = true,
  });

  Map<String, dynamic> toMap() => {
    'materialName':     materialName,
    'easyBaseDays':     easyBaseDays,
    'mediumBaseDays':   mediumBaseDays,
    'hardBaseDays':     hardBaseDays,
    'growthMultiplier': growthMultiplier,
    'enabled':          enabled,
  };

  factory MaterialReviewSettings.fromMap(String docId, Map<String, dynamic> map) {
    return MaterialReviewSettings(
      docId:            docId,
      materialName:     map['materialName']     as String,
      easyBaseDays:     (map['easyBaseDays']     as num?)?.toDouble() ?? 3.0,
      mediumBaseDays:   (map['mediumBaseDays']   as num?)?.toDouble() ?? 2.0,
      hardBaseDays:     (map['hardBaseDays']     as num?)?.toDouble() ?? 1.0,
      growthMultiplier: (map['growthMultiplier'] as num?)?.toDouble() ?? 2.0,
      enabled:          (map['enabled']          as bool?) ?? true,
    );
  }

  MaterialReviewSettings copyWith({
    String? docId,
    String? materialName,
    double? easyBaseDays,
    double? mediumBaseDays,
    double? hardBaseDays,
    double? growthMultiplier,
    bool?   enabled,
  }) {
    return MaterialReviewSettings(
      docId:            docId            ?? this.docId,
      materialName:     materialName     ?? this.materialName,
      easyBaseDays:     easyBaseDays     ?? this.easyBaseDays,
      mediumBaseDays:   mediumBaseDays   ?? this.mediumBaseDays,
      hardBaseDays:     hardBaseDays     ?? this.hardBaseDays,
      growthMultiplier: growthMultiplier ?? this.growthMultiplier,
      enabled:          enabled          ?? this.enabled,
    );
  }
}
