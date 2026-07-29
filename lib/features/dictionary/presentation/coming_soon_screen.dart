import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// ComingSoonScreen — pantalla para temas del diccionario aún sin contenido
// ---------------------------------------------------------------------------

class ComingSoonScreen extends StatelessWidget {
  final String topicLabel;

  const ComingSoonScreen({super.key, required this.topicLabel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(topicLabel,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: context.textPrimary)),
        backgroundColor: context.cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.dividerColor),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.construction_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              Text('Próximamente',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'El diccionario de $topicLabel está en construcción. Muy pronto vas a poder ver todas las señas aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: context.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}