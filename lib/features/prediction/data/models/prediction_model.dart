class PredictionModel {
  final String crop;
  final String disease;
  final double confidence;
  final String description;
  final String symptoms;
  final String causes;
  final String treatment;
  final String organicTreatment;
  final String chemicalTreatment;
  final String prevention;
  final String severity;
  final String reference;

  PredictionModel({
    required this.crop,
    required this.disease,
    required this.confidence,
    required this.description,
    required this.symptoms,
    required this.causes,
    required this.treatment,
    required this.organicTreatment,
    required this.chemicalTreatment,
    required this.prevention,
    required this.severity,
    required this.reference,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      crop: json['crop'] ?? 'Unknown',
      disease: json['disease'] ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      symptoms: json['symptoms'] ?? '',
      causes: json['causes'] ?? '',
      treatment: json['treatment'] ?? '',
      organicTreatment: json['organic_treatment'] ?? json['organic treatment'] ?? '',
      chemicalTreatment: json['chemical_treatment'] ?? json['chemical treatment'] ?? '',
      prevention: json['prevention'] ?? '',
      severity: json['severity'] ?? 'LOW',
      reference: json['reference'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'crop': crop,
      'disease': disease,
      'confidence': confidence,
      'description': description,
      'symptoms': symptoms,
      'causes': causes,
      'treatment': treatment,
      'organic_treatment': organicTreatment,
      'chemical_treatment': chemicalTreatment,
      'prevention': prevention,
      'severity': severity,
      'reference': reference,
    };
  }
}
