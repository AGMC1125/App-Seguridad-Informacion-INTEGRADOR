import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'word_detail_screen.dart';

// ---------------------------------------------------------------------------
// FamilyScreen — diccionario de familia LSM
// ---------------------------------------------------------------------------

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  String _selectedAvatarCode = 'nino';

  static const _avatars = [
    (id: 'nino',          icon: Icons.boy_rounded,   label: 'Niño',   color: Color(0xFF2563EB)),
    (id: 'nina',          icon: Icons.girl_rounded,  label: 'Niña',   color: Color(0xFFDB2777)),
    (id: 'hombre_adulto', icon: Icons.man_rounded,   label: 'Hombre', color: Color(0xFF059669)),
    (id: 'mujer_adulta',  icon: Icons.woman_rounded, label: 'Mujer',  color: Color(0xFF7C3AED)),
  ];

  // 12 palabras de familia disponibles en el diccionario
  static const _familyWords = [
    (word: 'abuelo',   icon: Icons.man_rounded,        label: 'Abuelo'),
    (word: 'abuela',   icon: Icons.woman_rounded,     label: 'Abuela'),
    (word: 'papa',     icon: Icons.man_rounded,        label: 'Papá'),
    (word: 'mama',     icon: Icons.woman_rounded,      label: 'Mamá'),
    (word: 'hijo',     icon: Icons.boy_rounded,        label: 'Hijo'),
    (word: 'hija',     icon: Icons.girl_rounded,       label: 'Hija'),
    (word: 'hermano',  icon: Icons.face_rounded,       label: 'Hermano'),
    (word: 'hermana',  icon: Icons.face_3_rounded,     label: 'Hermana'),
    (word: 'tio',      icon: Icons.person_rounded,     label: 'Tío'),
    (word: 'tia',      icon: Icons.person_2_rounded,   label: 'Tía'),
    (word: 'primo',    icon: Icons.child_care_rounded, label: 'Primo'),
    (word: 'prima',    icon: Icons.child_care_rounded, label: 'Prima'),
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
        title: Text('Familia', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.textPrimary)),
        backgroundColor: context.cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.dividerColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: context.isDark
                      ? [AppColors.darkPrimaryContainer, AppColors.darkSurfaceVariant]
                      : [AppColors.lightPrimaryContainer.withOpacity(0.5), AppColors.lightBackground],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vocabulario de Familia',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary)),
                        Text('12 palabras · Lengua de Señas Mexicana',
                            style: TextStyle(fontSize: 12, color: context.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // ── Selector de avatar ─────────────────────────────────────────
            Text('Avatar para todas las señas',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary)),
            const SizedBox(height: 4),
            Text('El avatar seleccionado se aplicará a todas las palabras',
                style: TextStyle(fontSize: 12, color: context.textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: _avatars.map((a) {
                final isSelected = _selectedAvatarCode == a.id;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedAvatarCode = a.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? a.color.withOpacity(context.isDark ? 0.2 : 0.1) : context.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSelected ? a.color : context.dividerColor, width: isSelected ? 2 : 1),
                        boxShadow: isSelected
                            ? [BoxShadow(color: a.color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 3))]
                            : [],
                      ),
                      child: Column(
                        children: [
                          Icon(a.icon, color: a.color, size: 26),
                          const SizedBox(height: 4),
                          Text(a.label,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                  color: isSelected ? a.color : context.textSecondary),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 26),

            // ── Grid de palabras ───────────────────────────────────────────
            Text('Palabras disponibles',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.9,
              ),
              itemCount: _familyWords.length,
              itemBuilder: (_, index) => _buildWordCard(context, index),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildWordCard(BuildContext context, int index) {
    final word = _familyWords[index];
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WordDetailScreen(
            word: word.word,
            initialAvatarCode: _selectedAvatarCode,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.dividerColor),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(context.isDark ? 0.25 : 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(word.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              word.label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_outline_rounded, size: 11, color: context.textSecondary),
                const SizedBox(width: 3),
                Text('Ver seña', style: TextStyle(fontSize: 10, color: context.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
