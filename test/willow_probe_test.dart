import 'package:flutter_test/flutter_test.dart';
import 'package:mind_care_app/features/chat/services/willow_api_service.dart';

void main() {
  test('probe replies', () async {
    final cases = <String>[
      // sleep / fatigue
      'I wake up tired every morning',
      'My mind won\'t stop racing at night',
      'I oversleep and miss classes',
      // loneliness
      'Nobody talks to me at campus',
      'I have no one to share my day with',
      'I feel invisible at home',
      // money
      'I can\'t pay my rent this month',
      'My parents can\'t afford my fees',
      // family
      'My parents fight all the time',
      'Mom and dad are getting divorced',
      'I argued with my mother',
      // fear of failure
      'What if I fail my exam',
      'I failed my test yesterday',
      'I am afraid of disappointing my parents',
      'I messed up everything today',
      // worth / identity
      'I feel worthless',
      'I hate myself',
      'I keep comparing myself to others',
      'I don\'t fit in anywhere',
      // overthinking
      'I overthink every conversation',
      'Negative thoughts keep coming back',
      // motivation
      'I can\'t start studying at all',
      'I keep procrastinating everything',
      'I have no motivation to do anything',
      // appetite / body
      'I lost my appetite lately',
      'I don\'t feel like eating at all',
      // anger
      'I get angry very easily these days',
      'I archive at my little brother',
      // transitions
      'I\'m new to campus and feel homesick',
      'I moved to a new city alone',
      'starting university first year is scary',
      // suicide-adjacent (should be crisis)
      'I want to end everything',
      'Everyone would be better off without me',
      // Sinhala
      'මට තනියම දැනෙනවා',
      'මම දුකින් ඉන්නේ',
      'හිතට ගොඩක් බරයි',
      'නින්ද නැතුව ඇහැරෙනවා',
      'මට වෙහෙසයි',
      'ඉගෙන ගන්න බැරි වෙනවා',
      'මගේ අම්මා තාත්තා රණ්ඩු වෙනවා',
      'මම කවුරුවත් එක්ක කතා කරන්නේ නෑ',
      'මට පිහිට ඕන',
      'මම ගොඩක් අවුල් වෙලා',
      'මට කන්න ඕන නෑ',
      'මම මගේ අප්පච්චිට බයයි',
    ];
    for (final m in cases) {
      final r = await WillowApiService.chat(m);
      final recs = r?.recommendations ?? const <String>[];
      final text = r?.text ?? '';
      print('>>> $m');
      print('    [$recs] ${text.replaceAll('\n', ' ')}');
    }
  });
}
