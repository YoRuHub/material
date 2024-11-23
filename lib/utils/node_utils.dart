import 'package:flutter_app/models/node.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

/// 親ノードを探す関数
Node? findParentNode(Node node) {
  return node.parent;
}

/// ノードが親を持つかどうかをチェック
bool hasParent(Node node) {
  return node.parent != null;
}

/// 指定したノードの全ての子ノードを取得
List<Node> getAllDescendants(Node node) {
  List<Node> descendants = [];
  for (var child in node.children) {
    descendants.add(child);
    descendants.addAll(getAllDescendants(child));
  }
  return descendants;
}

/// 指定したノードの親から先祖を辿る関数
List<Node> getAncestors(Node node) {
  List<Node> ancestors = [];
  Node? current = node.parent;
  while (current != null) {
    ancestors.add(current);
    current = current.parent;
  }
  return ancestors;
}

/// ノードの位置を更新する関数
void updateNodePosition(Node node, vector_math.Vector2 newPosition) {
  node.position = newPosition;
}

/// ノードが特定の親に属しているか確認する関数
bool isDescendantOf(Node node, Node parent) {
  if (node.parent == null) return false;
  if (node.parent == parent) return true;
  return isDescendantOf(node.parent!, parent);
}

/// ノードの子供を追加する関数
void addChildNode(Node parent, Node child) {
  parent.children.add(child);
  child.parent = parent;
}

/// ノードの子供を削除する関数
void removeChildNode(Node parent, Node child) {
  parent.children.remove(child);
  child.parent = null;
}
