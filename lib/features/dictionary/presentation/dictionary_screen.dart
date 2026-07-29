import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// DictionaryScreen — lista de todos los temas del diccionario LSM
// ---------------------------------------------------------------------------

class DictionaryScreen extends StatelessWidget {
  const DictionaryScreen({super.key});

  static const _topics = [
    (
    id: 'familia',
    label: 'Familia',
    icon: Icons.family_restroom_rounded,
    color: Color(0xFF2563EB),
    ready: true,
    ),
    (
    id: 'sustantivos',
    label: 'Sustantivos',
    icon: Icons.text_fields_rounded,
    color: Color(0xFFDB2777),
    ready: false,
    ),
    (
    id: 'dias_semana',
    label: 'Días de la Semana',
    icon: Icons.calendar_view_week_rounded,
    color: Color(0xFF059669),
    ready: false,
    ),
    (
    id: 'meses_anio',
    label: 'Meses del Año',
    icon: Icons.calendar_month_rounded,
    color: Color(0xFF7C3AED),
    ready: false,
    ),
    (
    id: 'numeros',
    label: 'Números',
    icon: Icons.pin_rounded,
    color: Color(0xFFD97706),
    ready: false,
    ),
    (
    id: 'pronombres',
    label: 'Pronombres',
    icon: Icons.person_pin_rounded,
    color: Color(0xFF2563EB),
    ready: false,
    ),
    (
    id: 'adjetivos',
    label: 'Adjetivos',
    icon: Icons.style_rounded,
    color: Color(0xFFDB2777),
    ready: false,
    ),
    (
    id: 'abecedario',
    label: 'Abecedario',
    icon: Icons.abc_rounded,
    color: Color(0xFF059669),
    ready: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Diccionario LSM',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: context.textPrimary)),
        backgroundColor: context.cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.dividerColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 16, height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    )),
                const SizedBox(width: 8),
                Text('TEMAS DISPONIBLES',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      letterSpacing: 0.7, color: AppColors.primary,
                    )),
              ],
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemCount: _topics.length,
              itemBuilder: (_, i) => _buildTopicCard(context, i),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(BuildContext context, int index) {
    final topic = _topics[index];

    return GestureDetector(
      onTap: () {
        if (topic.ready) {
          context.push(RouteNames.family);
        } else {
          context.push(RouteNames.dictionaryComingSoonPath, extra: topic.label);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(context.isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: topic.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: topic.color.withOpacity(0.2)),
              ),
              child: Icon(topic.icon, color: topic.color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              topic.label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            if (!topic.ready)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: context.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Próximamente',
                    style: TextStyle(fontSize: 9.5, color: context.textSecondary, fontWeight: FontWeight.w500)),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_forward_rounded, size: 10, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Text('Ver diccionario',
                      style: TextStyle(fontSize: 9.5, color: AppColors.primary, fontWeight: FontWeight.w500)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}