enum Gender { male, female }

enum FriendRelationType { friend, bestFriend, partner }

class Person {
  final String name;
  final String surname;
  final Gender gender;
  int relationship; // 0-100
  bool isAlive;
  int age;
  String? imagePath;

  Person({
    required this.name,
    required this.surname,
    required this.gender,
    this.relationship = 100,
    this.isAlive = true,
    this.age = 0,
    this.imagePath,
  });
}

class FamilyMember extends Person {
  final String relation; // "Ana", "Ata", "Qardaş", "Bacı"
  String education;
  String job;
  String maritalStatus;
  List<String> diseases;
  List<String> interactionHistory;
  int monthlyIncome;
  int totalMoney;
  int generosity; // 0-100
  int religiousness; // 0-100
  bool askedMoneyThisYear = false;

  FamilyMember({
    required super.name,
    required super.surname,
    required super.gender,
    required this.relation,
    this.education = "Orta təhsil",
    this.job = "İşsiz",
    this.maritalStatus = "Subay",
    this.diseases = const [],
    List<String>? interactionHistory,
    this.monthlyIncome = 0,
    this.totalMoney = 1000,
    this.generosity = 50,
    this.religiousness = 50,
    super.relationship = 100,
    super.isAlive = true,
    super.age = 0,
    super.imagePath,
  }) : interactionHistory = List<String>.from(interactionHistory ?? const []);
}

class SchoolMate extends Person {
  int money;
  int health;
  int smarts;
  int looks;
  FriendRelationType relationType;
  List<String> interactionHistory;
  bool askedMoneyThisYear;

  SchoolMate({
    required super.name,
    required super.surname,
    required super.gender,
    this.money = 0,
    this.health = 100,
    this.smarts = 50,
    this.looks = 50,
    this.relationType = FriendRelationType.friend,
    List<String>? interactionHistory,
    this.askedMoneyThisYear = false,
    super.relationship = 50,
    super.isAlive = true,
    super.age = 0,
    super.imagePath,
  }) : interactionHistory = List<String>.from(interactionHistory ?? const []);
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
  String? imagePath;
  
  // Education stats
  bool isEnrolledInSchool = false;
  bool isEnrolledInUniversity = false;
  int universityYearsStudied = 0;
  bool hasBachelorDegree = false;

  // Military stats
  bool isInMilitary = false;
  int militaryYearsServed = 0;
  double militaryServiceDuration = 0;
  
  double grades = 0.0; // 0.0 to 100.0
  int schoolPopularity = 50;
  int schoolActivity = 50;
  bool studiedHardThisYear = false;
  bool skippedSchoolThisYear = false;

  bool hasPartner = false;

  List<FamilyMember> family = [];
  List<SchoolMate> friends = [];

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
    this.imagePath,
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
