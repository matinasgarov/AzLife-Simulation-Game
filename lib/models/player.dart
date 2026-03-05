enum Gender { male, female }

class Person {
  final String name;
  final String surname;
  final Gender gender;
  int relationship; // 0-100
  bool isAlive;
  int age;

  Person({
    required this.name,
    required this.surname,
    required this.gender,
    this.relationship = 100,
    this.isAlive = true,
    this.age = 0,
  });
}

class FamilyMember extends Person {
  final String relation; // "Ana", "Ata", "Qardaş", "Bacıl"

  FamilyMember({
    required super.name,
    required super.surname,
    required super.gender,
    required this.relation,
    super.relationship = 100,
    super.isAlive = true,
    super.age = 0,
  });
}

class SchoolMate extends Person {
  SchoolMate({
    required super.name,
    required super.surname,
    required super.gender,
    super.relationship = 50,
    super.isAlive = true,
    super.age = 0,
  });
}

class Player {
  String name;
  String surname;
  Gender gender;
  String birthCity;
  String title;
  int age;
  int health;
  int happiness;
  int smarts;
  int looks;
  int money;
  
  // Education stats
  bool isEnrolledInSchool = false;
  bool isEnrolledInUniversity = false;
  int universityYearsStudied = 0;
  bool hasBachelorDegree = false;

  double grades = 0.0; // 0.0 to 100.0
  int schoolPopularity = 50;
  int schoolActivity = 50;
  bool studiedHardThisYear = false;
  bool skippedSchoolThisYear = false;

  List<FamilyMember> family = [];
  List<SchoolMate> schoolMates = [];

  Player({
    required this.name,
    required this.surname,
    required this.gender,
    required this.birthCity,
    this.title = "Körpə",
    this.age = 0,
    this.health = 100,
    this.happiness = 100,
    this.smarts = 50,
    this.looks = 50,
    this.money = 0,
  });

  String getEmoji() {
    if (gender == Gender.male) {
      if (age < 3) return "👶";
      if (age < 12) return "👦";
      if (age < 20) return "👱";
      if (age < 40) return "👨";
      if (age < 65) return "🧔";
      return "👴";
    } else {
      if (age < 3) return "👶";
      if (age < 12) return "👧";
      if (age < 20) return "👩";
      if (age < 40) return "👩‍🦰";
      if (age < 65) return "👩‍🦳";
      return "👵";
    }
  }

  void startSchool() {
    isEnrolledInSchool = true;
    grades = smarts * 0.75;
  }
}
