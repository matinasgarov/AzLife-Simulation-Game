import 'dart:io';

void main() {
  final dir = Directory('assets/gameImages');
  if (!dir.existsSync()) {
    stderr.writeln('Directory not found: assets/gameImages');
    exitCode = 1;
    return;
  }

  final files = dir
      .listSync()
      .whereType<File>()
      .map((f) => f.uri.pathSegments.last)
      .toSet();

  final requiredCanonical = <String>[];
  final missingCanonical = <String>[];
  final presentCanonical = <String>[];
  final onlyReverse = <String>[];

  for (int a = 0; a <= 6; a++) {
    for (int b = a; b <= 6; b++) {
      final canonical = 'domino_${a}_$b.png';
      final reverse = 'domino_${b}_$a.png';
      requiredCanonical.add(canonical);

      if (files.contains(canonical)) {
        presentCanonical.add(canonical);
      } else if (files.contains(reverse)) {
        onlyReverse.add('$canonical (found as $reverse)');
      } else {
        missingCanonical.add(canonical);
      }
    }
  }

  final dominoNamed = files.where((f) => f.startsWith('domino_')).toList()..sort();
  final nonCanonicalDomino = dominoNamed
      .where((f) {
        final m = RegExp(r'^domino_(\d)_(\d)\.png$').firstMatch(f);
        if (m == null) return true;
        final a = int.parse(m.group(1)!);
        final b = int.parse(m.group(2)!);
        return a > b;
      })
      .toList()
    ..sort();

  stdout.writeln('Domino asset check');
  stdout.writeln('Required canonical tiles: ${requiredCanonical.length}');
  stdout.writeln('Present canonical: ${presentCanonical.length}');
  stdout.writeln('Present as reverse only: ${onlyReverse.length}');
  stdout.writeln('Missing: ${missingCanonical.length}');
  stdout.writeln('');

  if (onlyReverse.isNotEmpty) {
    stdout.writeln('Reverse-only files (works in-game, but consider renaming):');
    for (final f in onlyReverse) {
      stdout.writeln('  - $f');
    }
    stdout.writeln('');
  }

  if (missingCanonical.isNotEmpty) {
    stdout.writeln('Missing required files:');
    for (final f in missingCanonical) {
      stdout.writeln('  - $f');
    }
    stdout.writeln('');
  }

  if (nonCanonicalDomino.isNotEmpty) {
    stdout.writeln('Non-canonical domino filenames found (a > b or unexpected pattern):');
    for (final f in nonCanonicalDomino) {
      stdout.writeln('  - $f');
    }
    stdout.writeln('');
  }

  if (missingCanonical.isNotEmpty) {
    exitCode = 2;
  }
}
