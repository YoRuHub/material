import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

class Node {
  Node({
    required this.position,
    required this.velocity,
    required this.color,
    required this.radius,
    this.isActive = false,
    this.isTemporarilyDetached = false,
    this.parent,
    required this.id,
    required this.title,
    required this.contents,
    required this.projectId,
    required this.createdAt,
    List<Node>? children,
  }) : children = children ?? [];

  vector_math.Vector2 position;
  vector_math.Vector2 velocity;
  vector_math.Vector2? targetPosition;
  Color color;
  double radius;
  bool isActive;
  bool isTemporarilyDetached;
  Node? parent;
  final int id;
  late String title;
  late String contents;
  final int projectId;
  final String createdAt;
  List<Node> children;

  // copyWithをカスタマイズして、必要なフィールドのみを変更
  Node copyWith({
    vector_math.Vector2? position,
    vector_math.Vector2? velocity,
    Color? color,
    double? radius,
    bool? isActive,
    bool? isTemporarilyDetached,
    Node? parent,
    int? id,
    String? title,
    String? contents,
    int? projectId,
    String? createdAt,
    List<Node>? children,
  }) {
    return Node(
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      color: color ?? this.color,
      radius: radius ?? this.radius,
      isActive: isActive ?? this.isActive,
      isTemporarilyDetached:
          isTemporarilyDetached ?? this.isTemporarilyDetached,
      parent: parent ?? this.parent,
      id: id ?? this.id,
      title: title ?? this.title,
      contents: contents ?? this.contents,
      projectId: projectId ?? this.projectId,
      createdAt: createdAt ?? this.createdAt,
      children: children ?? this.children,
    );
  }

  void updatePosition(vector_math.Vector2 newPosition) {
    position = newPosition;

    // 子ノードの位置を更新
    for (var child in children) {
      child.position = vector_math.Vector2(
        child.position.x + (newPosition.x - position.x),
        child.position.y + (newPosition.y - position.y),
      );
      child.parent = this;
    }
  }
}
