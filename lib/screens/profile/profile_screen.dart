import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = ProfileService();
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();

  UserProfile? _profile;
  bool _loading = true;
  bool _saving = false;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await _service.getMonProfil();
      setState(() {
        _profile = p;
        _nomCtrl.text = p.nom;
        _prenomCtrl.text = p.prenom;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _service.mettreAJourProfil(_nomCtrl.text.trim(), _prenomCtrl.text.trim());
      await _service.savePrenom(_prenomCtrl.text.trim());
      setState(() {
        _profile = _profile!.copyWith(nom: _nomCtrl.text.trim(), prenom: _prenomCtrl.text.trim());
        _editing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour '), backgroundColor: Color(0xFFFF6B00)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _uploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() => _saving = true);
    try {
      final url = await _service.uploadPhotoProfil(File(picked.path));
      setState(() => _profile = _profile!.copyWith(photoProfil: url));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo mise à jour '), backgroundColor: Color(0xFFFF6B00)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur upload: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
        title: const Text('Mon Profil', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          if (!_loading && !_editing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _editing = true),
            ),
          if (_editing)
            TextButton(
              onPressed: () => setState(() {
                _editing = false;
                _nomCtrl.text = _profile!.nom;
                _prenomCtrl.text = _profile!.prenom;
              }),
              child: const Text('Annuler', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildForm(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFF6B00),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 32, top: 8),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: _profile?.photoProfil != null
                      ? Image.network(
                          _profile!.photoProfil!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                        )
                      : _buildAvatarPlaceholder(),
                ),
              ),
              GestureDetector(
                onTap: _saving ? null : _uploadPhoto,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: _saving
                      ? const Padding(
                          padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF6B00)),
                        )
                      : const Icon(Icons.camera_alt, size: 18, color: Color(0xFFFF6B00)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _profile?.nomComplet ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _profile?.role == 'CONDUCTEUR' ? ' Conducteur' : ' Passager',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    final initials = _profile != null
        ? '${_profile!.prenom.isNotEmpty ? _profile!.prenom[0] : ''}${_profile!.nom.isNotEmpty ? _profile!.nom[0] : ''}'.toUpperCase()
        : '?';
    return Container(
      color: const Color(0xFFFF6B00).withOpacity(0.2),
      child: Center(
        child: Text(initials, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFFF6B00))),
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informations personnelles',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333))),
            const SizedBox(height: 16),
            _buildField('Prénom', _prenomCtrl, enabled: _editing, icon: Icons.person_outline),
            const SizedBox(height: 12),
            _buildField('Nom', _nomCtrl, enabled: _editing, icon: Icons.badge_outlined),
            const SizedBox(height: 12),
            _buildInfoTile('Téléphone', _profile?.telephone ?? '-', Icons.phone_outlined),
            const SizedBox(height: 24),
            if (_editing)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : const Text('Enregistrer', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {bool enabled = true, IconData? icon}) {
    return TextFormField(
      controller: ctrl,
      enabled: enabled,
      validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFFFF6B00)) : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF6B00))),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF6B00), size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}
