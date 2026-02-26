class GradingResult {
  final String filename;
  final List<StudentGrade> students;
  final Map<String, int> gradeDistribution;
  final DateTime processedAt;

  GradingResult({
    required this.filename,
    required this.students,
    required this.gradeDistribution,
    required this.processedAt,
  });

  Map<String, dynamic> toJson() => {
    'filename': filename,
    'students': students.map((s) => s.toJson()).toList(),
    'distribution': gradeDistribution,
    'processedAt': processedAt.toIso8601String(),
  };

  factory GradingResult.fromJson(Map<String, dynamic> json) => GradingResult(
    filename: json['filename'],
    students: (json['students'] as List)
        .map((s) => StudentGrade.fromJson(s))
        .toList(),
    gradeDistribution: Map<String, int>.from(json['distribution']),
    processedAt: DateTime.parse(json['processedAt']),
  );
}

class StudentGrade {
  final String name;
  final double score;
  final String grade;

  StudentGrade({
    required this.name,
    required this.score,
    required this.grade,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'score': score,
    'grade': grade,
  };

  factory StudentGrade.fromJson(Map<String, dynamic> json) => StudentGrade(
    name: json['name'],
    score: json['score'].toDouble(),
    grade: json['grade'],
  );
}

class GradeScale {
  final double aMin;
  final double bMin;
  final double cMin;
  final double dMin;

  const GradeScale({
    this.aMin = 90.0,
    this.bMin = 80.0,
    this.cMin = 70.0,
    this.dMin = 60.0,
  });

  String calculateGrade(double score) {
    if (score >= aMin) return 'A';
    if (score >= bMin) return 'B';
    if (score >= cMin) return 'C';
    if (score >= dMin) return 'D';
    return 'F';
  }

  Map<String, dynamic> toJson() => {
    'aMin': aMin,
    'bMin': bMin,
    'cMin': cMin,
    'dMin': dMin,
  };

  factory GradeScale.fromJson(Map<String, dynamic> json) => GradeScale(
    aMin: json['aMin'].toDouble(),
    bMin: json['bMin'].toDouble(),
    cMin: json['cMin'].toDouble(),
    dMin: json['dMin'].toDouble(),
  );
}