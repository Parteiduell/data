import 'dart:convert';
import 'dart:io';

import 'package:parteiduell_data/models/quizthese.dart';
import 'package:path/path.dart';

// Alternative Keys für die einzelnen Parteien
Map alternativePartyNames = {
  'BÜNDNIS 90/DIE GRÜNEN': 'GRÜNE',
  'Bündnis 90/ Die Grünen': 'GRÜNE',
  'GRÜNE/B 90': 'GRÜNE',
  'Bündnis 90/Die Grünen': 'GRÜNE',
  'Die Grünen': 'GRÜNE',
  'DIE LINKE.PDS': 'DIE LINKE',
  'Die LINKE': 'DIE LINKE',
  'DIE LINKE.': 'DIE LINKE',
  'Die Linke': 'DIE LINKE',
  'CDU / CSU': 'CDU/CSU',
  'CDU': 'CDU/CSU',
  'CSU': 'CDU/CSU',
  'DIE PARTEI': 'Die PARTEI',
  'Die PARTEI ': 'Die PARTEI',
  'PIRATEN ': 'PIRATEN',
  "BVB / FREIE WÄHLER": "FREIE WÄHLER",
  "FBI Freie Wähler": "FREIE WÄHLER",
  "FBI": "FREIE WÄHLER",
  "FBI/FWG": "FREIE WÄHLER",
  "FBI/Freie Wähler": "FREIE WÄHLER",
  "FREIE WÄHLER BREMEN": "FREIE WÄHLER",
  "FREIE WÄHLER": "FREIE WÄHLER",
  "FW FREIE WÄHLER": "FREIE WÄHLER",
  "Freie Wähler Bayern": "FREIE WÄHLER",
  "PDS": "DIE LINKE",
  "ödp": "ÖDP"
};

main(List<String> args) {
  final dataDir = Directory(join('qual-o-mat-data', 'data'));
  for (final yearDirectory in dataDir.listSync()) {
    if (yearDirectory is! Directory) continue;
    for (final occasionDirectory in (yearDirectory as Directory).listSync()) {
      if (occasionDirectory is! Directory) continue;

      final answerFile = File(join(occasionDirectory.path, 'answer.json'));
      final commentFile = File(join(occasionDirectory.path, 'comment.json'));
      final opinionFile = File(join(occasionDirectory.path, 'opinion.json'));
      final overviewFile = File(join(occasionDirectory.path, 'overview.json'));
      final partyFile = File(join(occasionDirectory.path, 'party.json'));
      final statementFile =
          File(join(occasionDirectory.path, 'statement.json'));

      final overview = json.decode(overviewFile.readAsStringSync());

      final year = overview['date'].substring(0, 4);

      if (year == '2002') continue;

      final title = '${overview['title']} $year';

      final theses = json.decode(statementFile.readAsStringSync());

      final opinions = json.decode(opinionFile.readAsStringSync());
      final commentsList = json.decode(commentFile.readAsStringSync());

      print(title);

      final parties = json.decode(partyFile.readAsStringSync());

      final partyMap = <int, String>{};
      for (final p in parties) {
        var partyName = p['name'];

        if (alternativePartyNames.containsKey(partyName))
          partyName = alternativePartyNames[partyName];

        partyMap[p['id']] = partyName;
      }

      var result = [];

      // Alle Thesen dieser Wahl abarbeiten
      for (var these in theses) {
        Map comments = {};
        // Die Aussagen jeder Partei sammeln und normalisieren
        for (final opinion in opinions) {
          if (opinion['statement'] != these['id']) continue;

          String party = partyMap[opinion['party']];
          final comment =
              commentsList.firstWhere((m) => m['id'] == opinion['comment']);

          final String text = comment['text'];

          if (text ==
              'Zu dieser These hat die Partei keine Begründung vorgelegt.')
            continue;

          comments[party] = text.substring(1, text.length - 1);
        }
        if (these['id'] == null) continue;
        // Neue These der Auswahl hinzufügen
        // TODO Eventuell "category" nutzen
        result.add(
          QuizThese(
            these: these['text'],
            id: 'WOM-${overview['slug']}-${these['id']}',
            statements: comments,
            source: 'Wahl-O-Mat', //  (${overview['data_source']})
            context: title,
          ),
        );
      }

      // Alle Thesen mit Antwortmöglichkeiten in Datei speichern
      final outFile = File('quizQuestions/$title.json');
      outFile.createSync(recursive: true);
      outFile.writeAsStringSync(json.encode(result));
    }
  }
}
