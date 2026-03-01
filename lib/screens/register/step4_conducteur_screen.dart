import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/widgets.dart';
import '../login_screen.dart';

class Step4ConducteurScreen extends StatefulWidget {
  final String telephone;
  final String nom;
  final String prenom;
  final String password;

  const Step4ConducteurScreen({
    super.key,
    required this.telephone,
    required this.nom,
    required this.prenom,
    required this.password,
  });

  @override
  State<Step4ConducteurScreen> createState() => _Step4ConducteurScreenState();
}

class _Step4ConducteurScreenState extends State<Step4ConducteurScreen> {
  final _formKey = GlobalKey<FormState>();
  final _immaCtrl = TextEditingController();
  final _permisCtrl = TextEditingController();
  final _picker = ImagePicker();
  bool _loading = false;

  //  NOUVEAU : choix du type de véhicule (ZEM par défaut)
  String _typeVehicule = 'ZEM';

  File? _fileProfil;
  File? _filePermis;
  File? _fileCni;
  File? _fileVehicule;

  Future<void> _pickImage(String type) async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (xFile == null) return;
    setState(() {
      switch (type) {
        case 'profil':
          _fileProfil = File(xFile.path);
          break;
        case 'permis':
          _filePermis = File(xFile.path);
          break;
        case 'cni':
          _fileCni = File(xFile.path);
          break;
        case 'vehicule':
          _fileVehicule = File(xFile.path);
          break;
      }
    });
  }

  Future<void> _inscrire() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fileProfil == null) {
      showSnack(context, 'La photo de profil est obligatoire',
          error: true);
      return;
    }
    if (_filePermis == null) {
      showSnack(context, 'La photo du permis est obligatoire',
          error: true);
      return;
    }
    if (_fileCni == null) {
      showSnack(context, "La photo de la CNI est obligatoire",
          error: true);
      return;
    }
    if (_fileVehicule == null) {
      showSnack(
          context,
          _typeVehicule == 'ZEM'
              ? "La photo de la moto est obligatoire"
              : "La photo du taxi est obligatoire",
          error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await ApiService.registerConducteur(
        telephone: widget.telephone,
        nom: widget.nom,
        prenom: widget.prenom,
        password: widget.password,
        immatriculation: _immaCtrl.text.trim(),
        numeroPermis: _permisCtrl.text.trim(),
        typeVehicule: _typeVehicule, //  NOUVEAU
        fileProfil: _fileProfil!,
        filePermis: _filePermis!,
        fileCni: _fileCni!,
        fileVehicule: _fileVehicule!,
      );
      if (!mounted) return;
      showSnack(context,
          ' Inscription réussie ! En attente de validation admin.');
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      showSnack(context, e.toString().replaceAll('Exception: ', ''),
          error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isZem = _typeVehicule == 'ZEM';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StepIndicator(currentStep: 3, totalSteps: 4),
                const SizedBox(height: 24),

                // ── En-tête dynamique ──────────────────────────────
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        isZem ? '🏍️' : '🚕',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            isZem ? 'Conducteur Zém' : 'Conducteur Taxi',
                            key: ValueKey(_typeVehicule),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        const Text(
                          'Documents requis pour validation',
                          style: TextStyle(
                              color: AppColors.textMedium, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ✅ NOUVEAU — Choix type véhicule
                const Text('Type de véhicule',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                        fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _VehiculeTypeCard(
                      emoji: '🏍️',
                      title: 'Zém',
                      description: 'Moto-taxi',
                      selected: _typeVehicule == 'ZEM',
                      onTap: () => setState(() => _typeVehicule = 'ZEM'),
                    ),
                    const SizedBox(width: 12),
                    _VehiculeTypeCard(
                      emoji: '🚕',
                      title: 'Taxi',
                      description: 'Voiture',
                      selected: _typeVehicule == 'TAXI',
                      onTap: () => setState(() => _typeVehicule = 'TAXI'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Immatriculation ────────────────────────────────
                _sectionTitle('Plaque d\'immatriculation '
                    '${isZem ? 'de la moto' : 'du véhicule'}'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _immaCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: isZem ? 'Ex: TG 1234 AB' : 'Ex: TG 5678 CD',
                    prefixIcon: const Icon(
                        Icons.confirmation_number_outlined,
                        color: AppColors.textLight),
                  ),
                  validator: (v) =>
                  (v == null || v.isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),

                // ── Numéro de permis ───────────────────────────────
                _sectionTitle('Numéro du permis de conduire'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _permisCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Ex: TG-2020-00123',
                    prefixIcon: Icon(Icons.card_membership_outlined,
                        color: AppColors.textLight),
                  ),
                  validator: (v) =>
                  (v == null || v.isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 24),

                // ── Documents photos ───────────────────────────────
                _sectionTitle('Photos & Documents'),
                const SizedBox(height: 4),
                const Text('Toutes les photos sont obligatoires',
                    style:
                    TextStyle(fontSize: 12, color: AppColors.textLight)),
                const SizedBox(height: 14),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _PhotoCard(
                      label: 'Photo de profil',
                      icon: Icons.person_rounded,
                      file: _fileProfil,
                      required: true,
                      onTap: () => _pickImage('profil'),
                    ),
                    _PhotoCard(
                      label: 'Permis de conduire',
                      icon: Icons.card_membership_rounded,
                      file: _filePermis,
                      required: true,
                      onTap: () => _pickImage('permis'),
                    ),
                    _PhotoCard(
                      label: "Carte d'identité (CNI)",
                      icon: Icons.badge_rounded,
                      file: _fileCni,
                      required: true,
                      onTap: () => _pickImage('cni'),
                    ),
                    _PhotoCard(
                      // ✅ Label dynamique selon type véhicule
                      label: isZem ? 'Photo de la moto' : 'Photo du taxi',
                      icon: isZem
                          ? Icons.motorcycle_rounded
                          : Icons.local_taxi_rounded,
                      file: _fileVehicule,
                      required: true,
                      onTap: () => _pickImage('vehicule'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Note admin
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border:
                    Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.primary, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Votre compte sera activé après validation de vos documents par un régulateur.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMedium),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                PrimaryButton(
                  label: "Terminer l'inscription",
                  onPressed: _inscrire,
                  isLoading: _loading,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark),
    );
  }

  @override
  void dispose() {
    _immaCtrl.dispose();
    _permisCtrl.dispose();
    super.dispose();
  }
}

// ─── Card sélection type véhicule ─────────────────────────────────────────

class _VehiculeTypeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _VehiculeTypeCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2.5 : 1,
            ),
            boxShadow: selected
                ? [
              BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]
                : [],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: selected ? AppColors.primary : AppColors.textDark,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMedium),
              ),
              if (selected) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '✓ Sélectionné',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Card photo ───────────────────────────────────────────────────────────

class _PhotoCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final File? file;
  final bool required;
  final VoidCallback onTap;

  const _PhotoCard({
    required this.label,
    required this.icon,
    required this.onTap,
    this.file,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: file != null ? AppColors.primary : AppColors.border,
            width: file != null ? 2 : 1,
          ),
        ),
        child: file != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(file!, fit: BoxFit.cover),
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle),
                  child: const Icon(Icons.check,
                      size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: AppColors.textLight),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.add_circle_outline,
                size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}