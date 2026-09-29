enum TopicStatus { pending, active, completed }

class Roadmap {
  const Roadmap({
    required this.id,
    required this.title,
    required this.colorIndex,
    required this.createdAt,
    required this.updatedAt,
    this.orderIndex = 0,
    this.description,
  });

  final String id;
  final String title;
  final String? description;
  final int colorIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int orderIndex;

  Roadmap copyWith({
    String? title,
    String? description,
    int? colorIndex,
    int? orderIndex,
    bool clearDescription = false,
  }) =>
      Roadmap(
        id: id,
        title: title ?? this.title,
        description:
            clearDescription ? null : (description ?? this.description),
        colorIndex: colorIndex ?? this.colorIndex,
        orderIndex: orderIndex ?? this.orderIndex,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'color_index': colorIndex,
        'order_index': orderIndex,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Roadmap.fromMap(Map<String, Object?> map) => Roadmap(
        id: map['id']! as String,
        title: map['title']! as String,
        description: map['description'] as String?,
        colorIndex: map['color_index'] as int? ?? 0,
        orderIndex: map['order_index'] as int? ?? 0,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
      );
}

class Topic {
  const Topic({
    required this.id,
    required this.roadmapId,
    required this.title,
    required this.orderIndex,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  final String id;
  final String roadmapId;
  final String title;
  final String? description;
  final int orderIndex;
  final TopicStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Topic copyWith({
    String? title,
    String? description,
    int? orderIndex,
    TopicStatus? status,
    bool clearDescription = false,
  }) =>
      Topic(
        id: id,
        roadmapId: roadmapId,
        title: title ?? this.title,
        description:
            clearDescription ? null : (description ?? this.description),
        orderIndex: orderIndex ?? this.orderIndex,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'roadmap_id': roadmapId,
        'title': title,
        'description': description,
        'order_index': orderIndex,
        'status': status.name,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Topic.fromMap(Map<String, Object?> map) => Topic(
        id: map['id']! as String,
        roadmapId: map['roadmap_id']! as String,
        title: map['title']! as String,
        description: map['description'] as String?,
        orderIndex: map['order_index'] as int? ?? 0,
        status: TopicStatus.values.byName(map['status']! as String),
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
      );
}
