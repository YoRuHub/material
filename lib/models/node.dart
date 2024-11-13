import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

class Node {
  vector_math.Vector2 position;
  vector_math.Vector2 velocity;
  vector_math.Vector2? targetPosition;
  Color color;
  double radius;
  bool isActive;
  Node? parent;
  List<Node> children;

  Node(this.position, this.velocity, this.color, this.radius,
      {this.isActive = false, this.parent, List<Node>? children})
      : children = children ?? [];
}