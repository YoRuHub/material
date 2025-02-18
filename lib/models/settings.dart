class Settings {
  final double parentChildDistance;
  final double linkDistance;
  final double parentChildAttraction;
  final double linkAttraction;

  Settings(
      {required this.parentChildDistance,
      required this.linkDistance,
      required this.parentChildAttraction,
      required this.linkAttraction});

  Settings copyWith(
      {double? parentChildDistance,
      double? linkDistance,
      double? parentChildAttraction,
      double? linkAttraction}) {
    return Settings(
        parentChildDistance: parentChildDistance ?? this.parentChildDistance,
        linkDistance: linkDistance ?? this.linkDistance,
        parentChildAttraction:
            parentChildAttraction ?? this.parentChildAttraction,
        linkAttraction: linkAttraction ?? this.linkAttraction);
  }
}
