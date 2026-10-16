import 'package:flutter_test/flutter_test.dart';
import 'package:nimbus/ai.dart';
import 'package:nimbus/data/books.dart';
import 'package:nimbus/data/services.dart';
import 'package:nimbus/sound.dart';
import 'package:nimbus/store.dart';

void main() {
  setUp(() => Sfx.enabled = false);

  test('seed state looks like day one', () {
    final s = AppState.seed();
    expect(s.onboarded, isFalse);
    expect(s.collected.length, 6);
    expect(dueCards(s).length, greaterThan(0));
  });

  test('pack gives S3 first, then XP and streak work', () {
    final store = Store(null);
    store.completeOnboarding(goal: 'clf', minutes: 10, name: 'Koushi');
    expect(store.openPack(), 's3');
    store.collect('s3');
    final before = store.state.xp;
    store.addXP(40, 4);
    expect(store.state.xp, before + 40);
    expect(store.state.collected.containsKey('s3'), isTrue);
  });

  test('Puff compares, costs and remembers', () {
    final s = AppState.seed();
    expect(respond('SQS vs SNS?', s).intent, 'compare');
    expect(respond('How much is 100 GB on S3?', s).intent, 'cost');
    expect(respond('call me Koushik', s).memory?['value'], 'Koushik');
    expect(respond('Remember my exam is on Dec 12', s).memory?['kind'], 'exam');
    expect(respond('I want to hurt myself', s).intent, 'safety');
    expect(findServices('bucket and queue'), containsAll(['s3', 'sqs']));
  });

  test('every service has a pocket book', () {
    for (final s in kServices) {
      expect(getBook(s.id), isNotNull);
    }
  });
}
