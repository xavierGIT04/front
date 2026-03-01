import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getMesNotifications();
      setState(() => _notifications = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _marquerToutesLues() async {
    await _service.marquerToutesLues();
    setState(() {
      for (var n in _notifications) {
        n.lu = true;
      }
    });
  }

  Future<void> _marquerLue(NotificationModel notif) async {
    if (notif.lu) return;
    await _service.marquerLue(notif.id);
    setState(() => notif.lu = true);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final nonLues = _notifications.where((n) => !n.lu).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          if (nonLues > 0)
            TextButton(
              onPressed: _marquerToutesLues,
              child: const Text('Tout lire', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
          : _notifications.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFFFF6B00),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    itemBuilder: (context, i) => _buildTile(_notifications[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔔', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('Aucune notification',
              style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Vos notifications apparaîtront ici',
              style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildTile(NotificationModel notif) {
    return GestureDetector(
      onTap: () => _marquerLue(notif),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: notif.lu ? Colors.white : const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
          border: notif.lu ? null : Border.all(color: const Color(0xFFFF6B00).withOpacity(0.3)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00).withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(notif.icone, style: const TextStyle(fontSize: 22)),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  notif.titre,
                  style: TextStyle(
                    fontWeight: notif.lu ? FontWeight.normal : FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              if (!notif.lu)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFFFF6B00), shape: BoxShape.circle),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(notif.message, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
              const SizedBox(height: 4),
              Text(_formatDate(notif.dateCreation),
                  style: TextStyle(color: Colors.grey[400], fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
