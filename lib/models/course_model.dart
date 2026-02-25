class CourseModel {
  final int id;
  final String statut;
  final String statutPaiement;
  final double departLat;
  final double departLng;
  final String? departAdresse;
  final double destinationLat;
  final double destinationLng;
  final String? destinationAdresse;
  final double? prixEstime;
  final double? prixFinal;
  final String? modePaiement;
  final double? distanceKm;
  final int? noteConducteur;
  final ConducteurInfo? conducteur;

  const CourseModel({
    required this.id,
    required this.statut,
    required this.statutPaiement,
    required this.departLat,
    required this.departLng,
    this.departAdresse,
    required this.destinationLat,
    required this.destinationLng,
    this.destinationAdresse,
    this.prixEstime,
    this.prixFinal,
    this.modePaiement,
    this.distanceKm,
    this.noteConducteur,
    this.conducteur,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'],
      statut: json['statut'] ?? 'EN_ATTENTE',
      statutPaiement: json['statut_paiement'] ?? 'EN_ATTENTE',
      departLat: (json['depart_lat'] ?? 0.0).toDouble(),
      departLng: (json['depart_lng'] ?? 0.0).toDouble(),
      departAdresse: json['depart_adresse'],
      destinationLat: (json['destination_lat'] ?? 0.0).toDouble(),
      destinationLng: (json['destination_lng'] ?? 0.0).toDouble(),
      destinationAdresse: json['destination_adresse'],
      prixEstime: json['prix_estime']?.toDouble(),
      prixFinal: json['prix_final']?.toDouble(),
      modePaiement: json['mode_paiement'],
      distanceKm: json['distance_km']?.toDouble(),
      noteConducteur: json['note_conducteur'],
      conducteur: json['conducteur'] != null
          ? ConducteurInfo.fromJson(json['conducteur'])
          : null,
    );
  }

  // Helper statuts
  bool get enAttente => statut == 'EN_ATTENTE';
  bool get acceptee => statut == 'ACCEPTEE';
  bool get enCours => statut == 'EN_COURS';
  bool get arrivee => statut == 'ARRIVEE';
  bool get terminee => statut == 'TERMINEE';
  bool get annulee => statut == 'ANNULEE';
  bool get paiementConfirme => statutPaiement == 'CONFIRME';
}

class ConducteurInfo {
  final String id;
  final String nom;
  final String prenom;
  final String? photoProfil;
  final String? immatriculation;
  final double? noteMoyenne;
  final String? typeVehicule;

  const ConducteurInfo({
    required this.id,
    required this.nom,
    required this.prenom,
    this.photoProfil,
    this.immatriculation,
    this.noteMoyenne,
    this.typeVehicule,
  });

  factory ConducteurInfo.fromJson(Map<String, dynamic> json) {
    return ConducteurInfo(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      photoProfil: json['photo_profil'],
      immatriculation: json['immatriculation'],
      noteMoyenne: json['note_moyenne']?.toDouble(),
      typeVehicule: json['type_vehicule'],
    );
  }

  String get nomComplet => '$prenom $nom';
}
