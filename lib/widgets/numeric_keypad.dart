import 'package:flutter/material.dart';
import '../theme.dart';

class NumericKeypad extends StatelessWidget {
  const NumericKeypad({Key? key, required this.onDigit, required this.onBack})
    : super(key: key);

  final void Function(int) onDigit;
  final VoidCallback onBack;

  Widget _buildButton(
    BuildContext context,
    String label, {
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? kDarkCardColor : Colors.white;
    final digitColor = isDark ? Colors.white : kPrimaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    color: Colors.black.withOpacity(0.05),
                  ),
                ],
        ),
        width: 72,
        height: 72,
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: digitColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttons = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '<'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemCount: buttons.length,
        itemBuilder: (context, index) {
          final label = buttons[index];
          if (label.isEmpty) return const SizedBox.shrink();
          if (label == '<') {
            return _buildButton(context, '⌫', onTap: onBack);
          }
          return _buildButton(
            context,
            label,
            onTap: () => onDigit(int.parse(label)),
          );
        },
      ),
    );
  }
}
