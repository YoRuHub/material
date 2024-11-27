class Project {
  final int id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  bool isHovered;

  Project({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.isHovered = false,
  });
}
