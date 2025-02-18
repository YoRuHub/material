import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/nodeContentsModal/colorPickerDialog/spherical_color_widget.dart';

class ColorPickerDialog extends StatelessWidget {
  final List<Color> availableColors;
  final Color? selectedColor;
  final ValueChanged<Color?> onColorSelected;

  static const double dialogHeight = 150.0;
  static const double dialogWidth = 300.0;
  static const int crossAxisCount = 6;

  const ColorPickerDialog({
    super.key,
    required this.availableColors,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Pick a color',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          _buildResetButton(context),
        ],
      ),
      content: SizedBox(
        height: dialogHeight,
        width: dialogWidth,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
          ),
          itemCount: availableColors.length,
          itemBuilder: (context, index) {
            final color = availableColors[index];
            return SphericalColorWidget(
                color: color,
                isSelected: selectedColor == color,
                onTap: () {
                  onColorSelected(color);
                  Navigator.of(context).pop();
                },
                checkIcon: Icons.check);
          },
        ),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: () {
          onColorSelected(null);
          Navigator.of(context).pop();
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                'Reset',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
