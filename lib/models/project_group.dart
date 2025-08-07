class ProjectGroup {
  int? id;
  String name;
  String description;
  DateTime createdAt;
  int colorCode;
  bool isDefault;

  ProjectGroup({
    this.id,
    required this.name,
    this.description = '',
    DateTime? createdAt,
    this.colorCode = 0xFF2196F3, // 默认蓝色
    this.isDefault = false,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert ProjectGroup to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'colorCode': colorCode,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  // Create ProjectGroup from Map
  factory ProjectGroup.fromMap(Map<String, dynamic> map) {
    return ProjectGroup(
      id: map['id'],
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      colorCode: map['colorCode'] ?? 0xFF2196F3,
      isDefault: map['isDefault'] == 1,
    );
  }

  // Convert to JSON for export
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'colorCode': colorCode,
      'isDefault': isDefault,
    };
  }

  // Create from JSON for import
  factory ProjectGroup.fromJson(Map<String, dynamic> json) {
    return ProjectGroup(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      colorCode: json['colorCode'] ?? 0xFF2196F3,
      isDefault: json['isDefault'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectGroup &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  ProjectGroup copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? createdAt,
    int? colorCode,
    bool? isDefault,
  }) {
    return ProjectGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      colorCode: colorCode ?? this.colorCode,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
