import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipr/data/models.dart';
import 'package:swipr/data/photo_repository.dart';
import 'package:swipr/features/swipe_session/widgets/card_stack.dart';

/// The image placeholder spinner never settles in tests, so pump past the
/// longest card animation instead.
Future<void> settle(WidgetTester tester) async {
  await tester.pump(); // first frame starts the animation ticker
  await tester.pump(const Duration(seconds: 1));
}

AssetEntity _asset(String id) => AssetEntity(id: id, typeInt: 1, width: 300, height: 400);

void main() {
  late List<(String, Decision)> swiped;
  late List<String> tapped;
  late CardStackController controller;

  Future<void> pumpStack(WidgetTester tester, List<AssetEntity> cards) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 600,
                child: CardStack(
                  cards: cards,
                  controller: controller,
                  onSwiped: (a, d) => swiped.add((a.id, d)),
                  onTap: (a) => tapped.add(a.id),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  setUp(() {
    swiped = [];
    tapped = [];
    controller = CardStackController();
  });

  final cards = [_asset('1'), _asset('2'), _asset('3'), _asset('4'), _asset('5')];

  testWidgets('builds the top card, two peeking cards and one hidden spare', (tester) async {
    await pumpStack(tester, cards);
    expect(find.byKey(const ValueKey('1')), findsOneWidget);
    expect(find.byKey(const ValueKey('4')), findsOneWidget);
    expect(find.byKey(const ValueKey('5')), findsNothing);
  });

  testWidgets('undo slides the card back without firing a swipe', (tester) async {
    await pumpStack(tester, cards);
    controller.swipe(Decision.delete);
    await settle(tester);
    expect(swiped, [('1', Decision.delete)]);

    controller.animateReturn(Decision.delete);
    await settle(tester);
    expect(swiped, hasLength(1));
    expect(controller.isAnimating, isFalse);
  });

  testWidgets('short drag springs back', (tester) async {
    await pumpStack(tester, cards);
    await tester.timedDrag(find.byKey(const ValueKey('1')), const Offset(60, 0), const Duration(milliseconds: 500));
    await settle(tester);
    expect(swiped, isEmpty);
  });

  testWidgets('long drag right keeps, left deletes', (tester) async {
    await pumpStack(tester, cards);
    await tester.timedDrag(find.byKey(const ValueKey('1')), const Offset(220, 0), const Duration(milliseconds: 600));
    await settle(tester);
    expect(swiped, [('1', Decision.keep)]);

    await pumpStack(tester, cards.sublist(1));
    await tester.timedDrag(find.byKey(const ValueKey('2')), const Offset(-220, 0), const Duration(milliseconds: 600));
    await settle(tester);
    expect(swiped.last, ('2', Decision.delete));
  });

  testWidgets('quick fling commits even when short', (tester) async {
    await pumpStack(tester, cards);
    await tester.fling(find.byKey(const ValueKey('1')), const Offset(-80, 0), 2000);
    await settle(tester);
    expect(swiped, [('1', Decision.delete)]);
  });

  testWidgets('buttons go through the same animation and callback', (tester) async {
    await pumpStack(tester, cards);
    controller.swipe(Decision.keep);
    await tester.pump(const Duration(milliseconds: 50));
    expect(swiped, isEmpty, reason: 'callback fires only after the fly-out animation');
    expect(controller.isAnimating, isTrue);
    await settle(tester);
    expect(swiped, [('1', Decision.keep)]);
  });

  testWidgets('tap opens zoom instead of swiping', (tester) async {
    await pumpStack(tester, cards);
    await tester.tap(find.byKey(const ValueKey('1')));
    await settle(tester);
    expect(tapped, ['1']);
    expect(swiped, isEmpty);
  });
}
