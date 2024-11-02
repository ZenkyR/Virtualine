import 'package:flutter/material.dart';

class HeaderBar extends StatelessWidget {
  const HeaderBar({super.key});

  Widget _buildCustomButton({
    required String text,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color textColor,
    required Color hoverColor,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[800]!, width: 0.5),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> states) {
                return states.contains(WidgetState.hovered)
                    ? hoverColor
                    : backgroundColor;
              },
            ),
            overlayColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
                return states.contains(WidgetState.hovered)
                    ? Colors.purple.withOpacity(0.2)
                    : null;
              },
            ),
            elevation: WidgetStateProperty.all(0),
            minimumSize: WidgetStateProperty.all(
              const Size(double.infinity, 45),
            ),
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[900],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCustomButton(
            text: 'Fichier',
            onPressed: () {},
            backgroundColor: Colors.grey[900]!,
            textColor: Colors.white,
            hoverColor: Colors.grey[800]!,
          ),
          _buildCustomButton(
            text: 'Menu',
            onPressed: () {},
            backgroundColor: Colors.grey[900]!,
            textColor: Colors.white,
            hoverColor: Colors.grey[800]!,
          ),
          _buildCustomButton(
            text: 'Bibliothèque',
            onPressed: () {},
            backgroundColor: Colors.grey[900]!,
            textColor: Colors.white,
            hoverColor: Colors.grey[800]!,
          ),
        ],
      ),
    );
  }
}

