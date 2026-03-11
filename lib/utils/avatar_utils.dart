import 'package:flutter/material.dart';
import '../models/player.dart';

const _base = 'assets/personImages';

const _maleBrackets = <int, List<String>>{
  0: [
    'male_baby_0_3_years.png',
    'male_baby_0_3_years_1.png',
    'male_baby_0_3_years_2.png',
    'male_baby_0_3_years_3.png',
    'male_baby_0_3_years_4.png',
  ],
  3: [
    'male_toddler_3_6_years.png',
    'male_3_6_years_1.png',
    'male_3_6_years_2.png',
    'male_3_6_years_4.png',
  ],
  6: [
    'male_child_6_14_years.png',
    'male_6_14_years_1.png',
    'male_6_14_years_2.png',
    'male_6_14_years_3.png',
    'male_6_14_years_4.png',
  ],
  14: [
    'male_teen_14_18_years.png',
    'male_14_18_years_1.png',
    'male_14_18_years_2.png',
  ],
  18: [
    'male_adult_18_22_years.png',
    'male_18_22_years_1.png',
    'male_18_22_years_2.png',
    'male_18_22_years_3.png',
    'male_18_22_years_4.png',
  ],
  22: [
    'male_adult_22_30_years.png',
    'male_22_30_years_1.png',
    'male_22_30_years_2.png',
    'male_22_30_years_3.png',
  ],
  30: [
    'male_30_50_years.png',
    'male_30_50_years_1.png',
    'male_30_50_years_2.png',
    'male_30_50_years_3.png',
    'male_30_50_years_4.png',
  ],
  50: [
    'male_50_70_years.png',
    'male_50_70_years_1.png',
    'male_50_70_years_2.png',
    'male_50_70_years_3.png',
    'male_50_70_years_4.png',
  ],
  70: [
    'male_70_90_years.png',
    'male_elderly_70_90_years_1.png',
    'male_elderly_70_90_years_2.png',
    'male_elderly_70_90_years_3.png',
  ],
};

const _femaleBrackets = <int, List<String>>{
  0: [
    'female_baby_0_3_years.png',
    'female_baby_0_3_years_1.png',
    'female_baby_0_3_years_2.png',
    'female_baby_0_3_years_3.png',
    'female_baby_0_3_years_4.png',
  ],
  3: [
    'female_toddler_3_6_years.png',
    'female_toddler_3_6_years_1.png',
    'female_3_6_years_1.png',
    'female_3_6_years_2.png',
    'female_3_6_years_3.png',
  ],
  6: [
    'female_child_6_14_years.png',
    'female_child_6_14_years_1.png',
    'female_6_14_years_1.png',
    'female_6_14_years_2.png',
    'female_6_14_years_3.png',
    'female_6_14_years_4.png',
  ],
  14: [
    'female_teen_14_18_years.png',
    'female_teen_14_18_years_1.png',
    'female_14_18_years_1.png',
    'female_14_18_years_2.png',
    'female_14_18_years_3.png',
    'female_14_18_years_4.png',
  ],
  18: [
    'female_adult_18_22_years.png',
    'female_adult_18_22_years_1.png',
    'female_18_22_years_1.png',
    'female_18_22_years_2.png',
    'female_18_22_years_3.png',
    'female_18_22_years_4.png',
  ],
  22: [
    'female_adult_22_30_years.png',
    'female_adult_22_30_years_1.png',
    'female_22_30_years_1.png',
    'female_22_30_years_2.png',
    'female_22_30_years_3.png',
    'female_22_30_years_4.png',
  ],
  30: [
    'female_30_50_years.png',
    'female_30_50_years_1.png',
    'female_30_50_years_2.png',
  ],
  50: [
    'female_50_70_years.png',
    'female_50_70_years_1.png',
    'female_50_70_years_2.png',
    'female_50_70_years_3.png',
    'female_50_70_years_4.png',
  ],
  70: [
    'female_70_90_years.png',
    'female_elderly_70_90_years_1.png',
    'female_elderly_70_90_years_2.png',
    'female_elderly_70_90_years_3.png',
    'female_elderly_70_90_years_4.png',
  ],
};

const _bracketKeys = [0, 3, 6, 14, 18, 22, 30, 50, 70];

String getAvatarPath(Gender gender, int age, int variant) {
  final brackets = gender == Gender.male ? _maleBrackets : _femaleBrackets;

  int bracket = _bracketKeys[0];
  for (final k in _bracketKeys) {
    if (age >= k) bracket = k;
  }

  final files = brackets[bracket]!;
  return '$_base/${files[variant % files.length]}';
}

class PersonAvatar extends StatelessWidget {
  final Gender gender;
  final int age;
  final int variant;
  final double radius;

  const PersonAvatar({
    super.key,
    required this.gender,
    required this.age,
    required this.variant,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          getAvatarPath(gender, age, variant),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
