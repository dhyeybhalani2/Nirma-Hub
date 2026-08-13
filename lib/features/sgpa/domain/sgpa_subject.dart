class SgpaSubject {
  final String subject;
  final List<SgpaComponent> components;

  SgpaSubject({
    required this.subject,
    required this.components,
  });

  factory SgpaSubject.fromJson(Map<String, dynamic> json) {
    return SgpaSubject(
      subject: json['subject'] as String,
      components: (json['components'] as List<dynamic>)
          .map((c) => SgpaComponent.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'components': components.map((c) => c.toJson()).toList(),
    };
  }
}

class SgpaComponent {
  final String label;
  final int maxMarks;

  SgpaComponent({
    required this.label,
    required this.maxMarks,
  });

  factory SgpaComponent.fromJson(Map<String, dynamic> json) {
    return SgpaComponent(
      label: json['label'] as String,
      maxMarks: json['maxMarks'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'maxMarks': maxMarks,
    };
  }
}
