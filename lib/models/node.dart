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
  final String createdAt;
  List<Node> children;
}
