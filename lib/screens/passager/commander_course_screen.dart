import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/course_api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/widgets.dart';

class CommanderCourseScreen extends StatefulWidget {
  final double departLat;
  final double departLng;

  const CommanderCourseScreen({
    super.key,
    required this.departLat,
    required this.departLng,
  });

  @override
  State<CommanderCourseScreen> createState() => _CommanderCourseScreenState();
}

class _CommanderCourseScreenState extends State<CommanderCourseScreen> {
  final _destCtrl = TextEditingController();
  String _modePaiement = 'ESPECES';
  bool _loading = false;
  Map<String, dynamic>? _estimation;

  // Destinations simulées à Lomé
  final List<Map<String, dynamic>> _suggestionsLome = [
    {'adresse': 'Grand Marché, Lomé', 'lat': 6.1345, 'lng': 1.2194},
    {'adresse': 'Aéroport Gnassingbé Eyadéma', 'lat': 6.1635, 'lng': 1.2545},
    {'adresse': 'Université de Lomé', 'lat': 6.1147, 'lng': 1.2219},
    {'adresse': 'Hôpital CHU Sylvanus Olympio', 'lat': 6.1289, 'lng': 1.2156},
    {'adresse': 'Plage de Lomé', 'lat': 6.1199, 'lng': 1.2184},
    {'adresse': 'Palais des Congrès', 'lat': 6.1318, 'lng': 1.2087},
  ];

  Map<String, dynamic>? _selectedDest;

  Future<void> _selectDestination(Map<String, dynamic> dest) async {
    setState(() {
      _selectedDest = dest;
      _destCtrl.text = dest['adresse'];
      _estimation = null;
    });
    // Calculer l'estimation
    try {
      final est = await CourseApiService.estimerCourse(
        dLat: widget.departLat, dLng: widget.departLng,
        aLat: dest['lat'], aLng: dest['lng'],
      );
      setState(() => _estimation = est);
    } catch (_) {
      // Estimation locale de secours
      setState(() => _estimation = {'prix_estime': 1500, 'distance_km': 3.2});
    }
  }

  Future<void> _commander() async {
    if (_selectedDest == null) {
      showSnack(context, 'Choisissez une destination', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final course = await CourseApiService.commanderCourse(
        departLat: widget.departLat,
        departLng: widget.departLng,
        departAdresse: 'Ma position actuelle',
        destLat: _selectedDest!['lat'],
        destLng: _selectedDest!['lng'],
        destAdresse: _selectedDest!['adresse'],
        modePaiement: _modePaiement,
      );
      if (!mounted) return;
      Navigator.pop(context, course);
    } catch (e) {
      showSnack(context, e.toString().replaceAll('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Commander une course'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Champ destination ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Départ (lecture seule)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.my_location_rounded, color: Color(0xFF2196F3), size: 20),
                        SizedBox(width: 12),
                        Text('Ma position actuelle', style: TextStyle(color: AppColors.textMedium, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Destination
                  TextField(
                    controller: _destCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Où allez-vous ?',
                      prefixIcon: const Icon(Icons.flag_rounded, color: AppColors.primary),
                      suffixIcon: _selectedDest != null
                          ? IconButton(
                              icon: const Icon(Icons.close, color: AppColors.textLight),
                              onPressed: () => setState(() { _selectedDest = null; _destCtrl.clear(); _estimation = null; }),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Liste suggestions ───────────────────────────────────
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestionsLome.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final dest = _suggestionsLome[i];
                  final selected = _selectedDest?['adresse'] == dest['adresse'];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary.withOpacity(0.15) : AppColors.background,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.place_rounded,
                        color: selected ? AppColors.primary : AppColors.textLight, size: 20),
                    ),
                    title: Text(dest['adresse'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        color: selected ? AppColors.textDark : AppColors.textDark,
                      ),
                    ),
                    trailing: selected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                    onTap: () => _selectDestination(dest),
                  );
                },
              ),
            ),

            // ─── Panel estimation + commande ─────────────────────────
            if (_estimation != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
                ),
                child: Column(
                  children: [
                    // Info trajet
                    Row(
                      children: [
                        _InfoPill(
                          icon: Icons.route_rounded,
                          label: '${_estimation!['distance_km']} km',
                        ),
                        const SizedBox(width: 12),
                        _InfoPill(
                          icon: Icons.access_time_rounded,
                          label: '~${((_estimation!['distance_km'] as double) * 3).round()} min',
                        ),
                        const Spacer(),
                        Text(
                          '${_estimation!['prix_estime'].toInt()} FCFA',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Mode paiement
                    Row(
                      children: [
                        const Text('Paiement :', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                        const SizedBox(width: 12),
                        _PaiementChip(label: 'Espèces', value: 'ESPECES', selected: _modePaiement == 'ESPECES', onTap: () => setState(() => _modePaiement = 'ESPECES')),
                        const SizedBox(width: 8),
                        _PaiementChip(label: 'T-Money', value: 'TMONEY', selected: _modePaiement == 'TMONEY', onTap: () => setState(() => _modePaiement = 'TMONEY')),
                        const SizedBox(width: 8),
                        _PaiementChip(label: 'Moov', value: 'MOOV_MONEY', selected: _modePaiement == 'MOOV_MONEY', onTap: () => setState(() => _modePaiement = 'MOOV_MONEY')),
                      ],
                    ),
                    const SizedBox(height: 16),

                    PrimaryButton(
                      label: 'Commander maintenant',
                      onPressed: _commander,
                      isLoading: _loading,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _destCtrl.dispose();
    super.dispose();
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMedium),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
        ],
      ),
    );
  }
}

class _PaiementChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  const _PaiementChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.black87 : AppColors.textMedium,
          ),
        ),
      ),
    );
  }
}
