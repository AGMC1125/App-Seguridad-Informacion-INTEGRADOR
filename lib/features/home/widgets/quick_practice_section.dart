import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Sección de práctica rápida con tarjetas de actividades cortas.
class QuickPracticeSection extends StatelessWidget {
  const QuickPracticeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PracticeCard(
            icon: Icons.flash_on_rounded,
            label: 'Repaso\nrápido',
            color: const Color(0xFFFFF3E0),
            iconColor: const Color(0xFFFF8F00),
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PracticeCard(
            icon: Icons.quiz_rounded,
            label: 'Quiz\ndiario',
            color: const Color(0xFFE8F5E9),
            iconColor: AppColors.secondary,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PracticeCard(
            icon: Icons.camera_alt_rounded,
            label: 'Practica\ncon cámara',
            color: AppColors.primaryLight,
            iconColor: AppColors.primary,
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

class _PracticeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _PracticeCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: iconColor,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
