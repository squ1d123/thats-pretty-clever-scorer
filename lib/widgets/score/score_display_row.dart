import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_theme.dart';

class ScoreDisplayRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool isWinner;

  const ScoreDisplayRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.isWinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.getScoreAreaTextColor(label.toLowerCase()),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$value',
            style: TextStyle(
              color: isWinner ? Colors.black87 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class ScoreInputRow extends StatelessWidget {
  final String label;
  final Color color;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final bool isFox;

  const ScoreInputRow({
    super.key,
    required this.label,
    required this.color,
    required this.controller,
    required this.onChanged,
    this.isFox = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (isFox)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
                child: SvgPicture.asset(
                'assets/fox.svg',
                width: 24,
                height: 24,
              ),

            )
          else
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: '0',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
    );
  }
}
