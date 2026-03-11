enum Gender { male, female }

enum FriendRelationType { friend, bestFriend, partner, ex }

enum PartnerStatus { partner, fiance, married }

class Person {
  final String name;
  final String surname;
  final Gender gender;
  int relationship; // 0-100
  bool isAlive;
  int age;
  String? imagePath;
  int imageVariant;

  Person({
    required this.name,
    required this.surname,
    required this.gender,
    this.relationship = 100,
    this.isAlive = true,
    this.age = 0,
    this.imagePath,
    this.imageVariant = 0,
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
  int looks; // 0-100
  int health; // 0-100
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
    this.looks = 60,
    this.health = 70,
    super.relationship = 100,
    super.isAlive = true,
    super.age = 0,
    super.imagePath,
    super.imageVariant = 0,
  }) : interactionHistory = List<String>.from(interactionHistory ?? const []);

  Map<String, dynamic> toJson() => {
        'name': name,
        'surname': surname,
        'gender': gender.name,
        'relationship': relationship,
        'isAlive': isAlive,
        'age': age,
        'imagePath': imagePath,
        'imageVariant': imageVariant,
        'relation': relation,
        'education': education,
        'job': job,
        'maritalStatus': maritalStatus,
        'diseases': diseases,
        'interactionHistory': interactionHistory,
        'monthlyIncome': monthlyIncome,
        'totalMoney': totalMoney,
        'generosity': generosity,
        'religiousness': religiousness,
        'looks': looks,
        'health': health,
        'askedMoneyThisYear': askedMoneyThisYear,
      };

  factory FamilyMember.fromJson(Map<String, dynamic> j) => FamilyMember(
        name: j['name'] as String,
        surname: j['surname'] as String,
        gender: Gender.values.firstWhere((e) => e.name == j['gender']),
        relation: j['relation'] as String,
        education: j['education'] as String? ?? 'Orta təhsil',
        job: j['job'] as String? ?? 'İşsiz',
        maritalStatus: j['maritalStatus'] as String? ?? 'Subay',
        diseases: List<String>.from(j['diseases'] as List? ?? []),
        interactionHistory: List<String>.from(j['interactionHistory'] as List? ?? []),
        monthlyIncome: j['monthlyIncome'] as int? ?? 0,
        totalMoney: j['totalMoney'] as int? ?? 1000,
        generosity: j['generosity'] as int? ?? 50,
        religiousness: j['religiousness'] as int? ?? 50,
        looks: j['looks'] as int? ?? 60,
        health: j['health'] as int? ?? 70,
        relationship: j['relationship'] as int? ?? 100,
        isAlive: j['isAlive'] as bool? ?? true,
        age: j['age'] as int? ?? 0,
        imagePath: j['imagePath'] as String?,
        imageVariant: j['imageVariant'] as int? ?? 0,
      )..askedMoneyThisYear = j['askedMoneyThisYear'] as bool? ?? false;
}

class SchoolMate extends Person {
  int money;
  int health;
  int smarts;
  int looks;
  FriendRelationType relationType;
  List<String> interactionHistory;
  bool askedMoneyThisYear;
  String occupation;
  int partnerStartAge;
  int netWorth;

  // Proposal / wedding fields
  PartnerStatus partnerStatus;
  int proposalCooldownYears;
  String weddingVenue;
  int weddingGuestTier;
  int weddingScheduledAge;
  String weddingPlanStatus; // "none" | "planned"
  int weddingTotalCost;
  bool weddingDepositPaid;

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
    this.occupation = "",
    this.partnerStartAge = 0,
    this.netWorth = 0,
    this.partnerStatus = PartnerStatus.partner,
    this.proposalCooldownYears = 0,
    this.weddingVenue = "",
    this.weddingGuestTier = 1,
    this.weddingScheduledAge = 0,
    this.weddingPlanStatus = "none",
    this.weddingTotalCost = 0,
    this.weddingDepositPaid = false,
    super.relationship = 50,
    super.isAlive = true,
    super.age = 0,
    super.imagePath,
    super.imageVariant = 0,
  }) : interactionHistory = List<String>.from(interactionHistory ?? const []);

  Map<String, dynamic> toJson() => {
        'name': name,
        'surname': surname,
        'gender': gender.name,
        'relationship': relationship,
        'isAlive': isAlive,
        'age': age,
        'imagePath': imagePath,
        'imageVariant': imageVariant,
        'money': money,
        'health': health,
        'smarts': smarts,
        'looks': looks,
        'relationType': relationType.name,
        'interactionHistory': interactionHistory,
        'askedMoneyThisYear': askedMoneyThisYear,
        'occupation': occupation,
        'partnerStartAge': partnerStartAge,
        'netWorth': netWorth,
        'partnerStatus': partnerStatus.name,
        'proposalCooldownYears': proposalCooldownYears,
        'weddingVenue': weddingVenue,
        'weddingGuestTier': weddingGuestTier,
        'weddingScheduledAge': weddingScheduledAge,
        'weddingPlanStatus': weddingPlanStatus,
        'weddingTotalCost': weddingTotalCost,
        'weddingDepositPaid': weddingDepositPaid,
      };

  factory SchoolMate.fromJson(Map<String, dynamic> j) => SchoolMate(
        name: j['name'] as String,
        surname: j['surname'] as String,
        gender: Gender.values.firstWhere((e) => e.name == j['gender']),
        money: j['money'] as int? ?? 0,
        health: j['health'] as int? ?? 100,
        smarts: j['smarts'] as int? ?? 50,
        looks: j['looks'] as int? ?? 50,
        relationType: FriendRelationType.values.firstWhere(
          (e) => e.name == (j['relationType'] as String? ?? 'friend'),
        ),
        interactionHistory: List<String>.from(j['interactionHistory'] as List? ?? []),
        askedMoneyThisYear: j['askedMoneyThisYear'] as bool? ?? false,
        occupation: j['occupation'] as String? ?? '',
        partnerStartAge: j['partnerStartAge'] as int? ?? 0,
        netWorth: j['netWorth'] as int? ?? 0,
        partnerStatus: PartnerStatus.values.firstWhere(
          (e) => e.name == (j['partnerStatus'] as String? ?? 'partner'),
        ),
        proposalCooldownYears: j['proposalCooldownYears'] as int? ?? 0,
        weddingVenue: j['weddingVenue'] as String? ?? '',
        weddingGuestTier: j['weddingGuestTier'] as int? ?? 1,
        weddingScheduledAge: j['weddingScheduledAge'] as int? ?? 0,
        weddingPlanStatus: j['weddingPlanStatus'] as String? ?? 'none',
        weddingTotalCost: j['weddingTotalCost'] as int? ?? 0,
        weddingDepositPaid: j['weddingDepositPaid'] as bool? ?? false,
        relationship: j['relationship'] as int? ?? 50,
        isAlive: j['isAlive'] as bool? ?? true,
        age: j['age'] as int? ?? 0,
        imagePath: j['imagePath'] as String?,
        imageVariant: j['imageVariant'] as int? ?? 0,
      );
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
  int imageVariant;

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
    this.imageVariant = 0,
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

  Map<String, dynamic> toJson() => {
        'name': name,
        'surname': surname,
        'gender': gender.name,
        'birthCity': birthCity,
        'title': title,
        'age': age,
        'health': health,
        'happiness': happiness,
        'smarts': smarts,
        'looks': looks,
        'money': money,
        'imagePath': imagePath,
        'imageVariant': imageVariant,
        'isEnrolledInSchool': isEnrolledInSchool,
        'isEnrolledInUniversity': isEnrolledInUniversity,
        'universityYearsStudied': universityYearsStudied,
        'hasBachelorDegree': hasBachelorDegree,
        'isInMilitary': isInMilitary,
        'militaryYearsServed': militaryYearsServed,
        'militaryServiceDuration': militaryServiceDuration,
        'grades': grades,
        'schoolPopularity': schoolPopularity,
        'schoolActivity': schoolActivity,
        'studiedHardThisYear': studiedHardThisYear,
        'skippedSchoolThisYear': skippedSchoolThisYear,
        'hasPartner': hasPartner,
        'family': family.map((m) => m.toJson()).toList(),
        'friends': friends.map((f) => f.toJson()).toList(),
      };

  factory Player.fromJson(Map<String, dynamic> j) {
    final player = Player(
      name: j['name'] as String,
      surname: j['surname'] as String,
      gender: Gender.values.firstWhere((e) => e.name == j['gender']),
      birthCity: j['birthCity'] as String,
      title: j['title'] as String? ?? 'Körpə',
      age: j['age'] as int? ?? 0,
      health: j['health'] as int? ?? 100,
      happiness: j['happiness'] as int? ?? 100,
      smarts: j['smarts'] as int? ?? 50,
      looks: j['looks'] as int? ?? 50,
      money: j['money'] as int? ?? 0,
      imagePath: j['imagePath'] as String?,
      imageVariant: j['imageVariant'] as int? ?? 0,
    );
    player.isEnrolledInSchool     = j['isEnrolledInSchool'] as bool? ?? false;
    player.isEnrolledInUniversity = j['isEnrolledInUniversity'] as bool? ?? false;
    player.universityYearsStudied = j['universityYearsStudied'] as int? ?? 0;
    player.hasBachelorDegree      = j['hasBachelorDegree'] as bool? ?? false;
    player.isInMilitary           = j['isInMilitary'] as bool? ?? false;
    player.militaryYearsServed    = j['militaryYearsServed'] as int? ?? 0;
    player.militaryServiceDuration = (j['militaryServiceDuration'] as num?)?.toDouble() ?? 0;
    player.grades                 = (j['grades'] as num?)?.toDouble() ?? 0.0;
    player.schoolPopularity       = j['schoolPopularity'] as int? ?? 50;
    player.schoolActivity         = j['schoolActivity'] as int? ?? 50;
    player.studiedHardThisYear    = j['studiedHardThisYear'] as bool? ?? false;
    player.skippedSchoolThisYear  = j['skippedSchoolThisYear'] as bool? ?? false;
    player.hasPartner             = j['hasPartner'] as bool? ?? false;
    player.family = (j['family'] as List? ?? [])
        .map((m) => FamilyMember.fromJson(m as Map<String, dynamic>))
        .toList();
    player.friends = (j['friends'] as List? ?? [])
        .map((f) => SchoolMate.fromJson(f as Map<String, dynamic>))
        .toList();
    return player;
  }
}
