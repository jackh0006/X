import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:x/app.dart';
import 'package:x/settings.dart';

import 'fakes.dart';

Future<void> pumpApp(
  WidgetTester tester, {
  ThemeMode mode = ThemeMode.light,
  FakeXService? service,
  Size size = const Size(1200, 1000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    XApp(
      service: service ?? FakeXService(),
      settings: SettingsController.inMemory(mode),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('exactly four sections and navigation works', (tester) async {
    await pumpApp(tester);
    expect(find.text('Seal a message.'), findsOneWidget);
    expect(find.text('SEND'), findsWidgets);
    expect(find.text('RECEIVE'), findsWidgets);
    expect(find.text('DONATE'), findsWidgets);
    expect(find.text('ABOUT'), findsWidgets);

    await tester.tap(find.text('RECEIVE').last);
    await tester.pumpAndSettle();
    expect(find.text('Open a sealed message.'), findsOneWidget);

    await tester.tap(find.text('DONATE').last);
    await tester.pumpAndSettle();
    expect(find.text('Keep X free and independent.'), findsOneWidget);

    await tester.tap(find.text('ABOUT').last);
    await tester.pumpAndSettle();
    expect(find.text('jackh109867@gmail.com'), findsOneWidget);
    expect(find.text('Made by jackh0006, with AI assistance.'), findsOneWidget);
  });

  testWidgets('send encrypts, shows portable text, and copies it',
      (tester) async {
    String? clipboard;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(
        SystemChannels.platform, null));

    await pumpApp(tester);
    await tester.enterText(
        find.byKey(const Key('send-message')), 'Meet me at the old bridge.');
    await tester.enterText(find.byKey(const Key('send-passphrase')),
        'correct horse battery staple');
    await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Encrypt message'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Encrypt message'));
    await tester.pumpAndSettle();

    expect(find.text('Encrypted text'), findsOneWidget);
    expect(find.text(FakeXService.cannedPayload), findsOneWidget);
    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Copy'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Copy'));
    await tester.pumpAndSettle();
    expect(clipboard, FakeXService.cannedPayload);
  });

  testWidgets('send generates a strong passphrase', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Generate strong passphrase'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
        find.byKey(const Key('send-passphrase')));
    expect(field.controller!.text, FakeXService.generated);
    expect(find.text('Strong'), findsOneWidget);
  });

  testWidgets('send rejects a short passphrase and empty message',
      (tester) async {
    await pumpApp(tester);
    await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Encrypt message'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Encrypt message'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a message first.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('send-message')), 'secret');
    await tester.enterText(find.byKey(const Key('send-passphrase')), 'short');
    await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Encrypt message'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Encrypt message'));
    await tester.pumpAndSettle();
    expect(find.text('Use a passphrase of at least 8 characters.'),
        findsOneWidget);
  });

  testWidgets('receive decrypts with the right passphrase, fails otherwise',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('RECEIVE').last);
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('receive-payload')), FakeXService.cannedPayload);
    await tester.enterText(
        find.byKey(const Key('receive-passphrase')), 'wrong password');
    await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Decrypt message'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Decrypt message'));
    await tester.pumpAndSettle();
    expect(
      find.text(
          'Wrong passphrase, or the encrypted text was modified or corrupted.'),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(const Key('receive-passphrase')),
        'correct horse battery staple');
    await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Decrypt message'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Decrypt message'));
    await tester.pumpAndSettle();
    expect(find.text(FakeXService.cannedPlaintext), findsOneWidget);
  });

  testWidgets('receive rejects malformed text', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('RECEIVE').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('receive-payload')), 'not encrypted');
    await tester.enterText(
        find.byKey(const Key('receive-passphrase')), 'long enough passphrase');
    await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Decrypt message'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Decrypt message'));
    await tester.pumpAndSettle();
    expect(find.text('Invalid encrypted text: missing X1 prefix.'),
        findsOneWidget);
  });

  testWidgets('donate shows verified addresses and copies one', (tester) async {
    String? clipboard;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(
        SystemChannels.platform, null));

    await pumpApp(tester);
    await tester.tap(find.text('DONATE').last);
    await tester.pumpAndSettle();
    expect(find.text('bc1q8t0fn2yrsy4lh3m0pz34uj27t8vxjeavkjym83'),
        findsOneWidget);
    await tester.tap(find.byTooltip('Copy Bitcoin address'));
    await tester.pumpAndSettle();
    expect(clipboard, 'bc1q8t0fn2yrsy4lh3m0pz34uj27t8vxjeavkjym83');
  });

  testWidgets('theme can be switched and is persisted in controller',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Theme: Light'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets('about discloses limitations honestly', (tester) async {
    await pumpApp(tester, mode: ThemeMode.dark);
    await tester.tap(find.text('ABOUT').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('No independent security audit'), findsOneWidget);
    expect(find.textContaining('Version 1.0.0'), findsOneWidget);
    expect(find.text('APACHE-2.0'), findsOneWidget);
  });

  testWidgets('mobile layout has bottom navigation and no overflow',
      (tester) async {
    await pumpApp(tester, size: const Size(390, 844));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('RECEIVE').last);
    await tester.pumpAndSettle();
    expect(find.text('Open a sealed message.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text scaling remains usable', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(tester, size: const Size(390, 844));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('DONATE').last);
    await tester.pumpAndSettle();
    expect(find.text('Bitcoin'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
