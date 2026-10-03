import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/models/models.dart';
import 'package:mobile/screens/chat_session_detail_screen.dart';
import 'package:mobile/screens/doctor_detail_screen.dart';
import 'package:mobile/screens/settings_screen.dart';
import 'package:mobile/screens/onboarding_screen.dart';
import 'package:mobile/screens/launch_splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App starts with OnboardingScreen walkthrough on fresh install', (WidgetTester tester) async {
    await tester.pumpWidget(const HevenlyApp(initialScreen: OnboardingScreen()));
    expect(find.textContaining('Curhat Bebas'), findsOneWidget);
    expect(find.text('LEWATI'), findsOneWidget);
    expect(find.text('LANJUT'), findsOneWidget);
  });

  testWidgets('App starts with LaunchSplashScreen for returning user', (WidgetTester tester) async {
    await tester.pumpWidget(const HevenlyApp(initialScreen: LaunchSplashScreen()));
    expect(find.text('Hevenly'), findsOneWidget);
    expect(find.text('Ruang aman untuk bercerita & pulih'), findsOneWidget);
  });

  testWidgets('MainNavigationScreen shows confirmation modal when leaving unsaved chat', (WidgetTester tester) async {
    await tester.pumpWidget(const HevenlyApp(initialScreen: MainNavigationScreen()));
    await tester.pumpAndSettle();

    // Switch to Chat tab (index 2)
    final aiTab = find.byIcon(Icons.auto_awesome_rounded);
    expect(aiTab, findsWidgets);
    await tester.tap(aiTab.first);
    await tester.pumpAndSettle();

    // Verify on Chat tab
    expect(find.text('Hevenly AI'), findsOneWidget);

    // Enter text and send message
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);
    await tester.enterText(textField, 'Halo Hevenly, aku butuh teman');
    final sendButton = find.byIcon(Icons.send_rounded);
    await tester.tap(sendButton);
    await tester.pump();

    // Now try to switch to Beranda tab (index 0)
    final homeTab = find.text('Beranda');
    await tester.tap(homeTab);
    await tester.pumpAndSettle();

    // Expect confirmation dialog
    expect(find.text('Simpan Percakapan?'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Tidak'), findsOneWidget);
    expect(find.text('Simpan'), findsOneWidget);

    // Tap Batal -> Dialog closes, stays on Chat
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Simpan Percakapan?'), findsNothing);
    expect(find.text('Hevenly AI'), findsOneWidget);
  });

  testWidgets('ChatSessionDetailScreen has button to continue chat with AI', (WidgetTester tester) async {
    final session = ChatSession(
      id: 'test_session_1',
      createdAt: DateTime.now(),
      messages: [
        ChatMessage(role: 'user', content: 'Halo, aku cemas banget hari ini'),
        ChatMessage(role: 'assistant', content: 'Kenapa kamu cemas? Ceritakan lebih lanjut.'),
      ],
      analysis: ChatAnalysisResult(
        distressScore: 6,
        distressLevel: 'Sedang',
        dominantEmotions: ['Cemas', 'Lelah'],
        cognitiveDistortions: ['Catastrophizing'],
        summary: 'Merasa cemas',
        cbtInsights: 'Kenali fakta',
        actionRecommendations: ['Napas dalam'],
      ),
    );

    await tester.pumpWidget(MaterialApp(
      home: ChatSessionDetailScreen(session: session),
    ));
    await tester.pumpAndSettle();

    // Verify continue chat button is present
    final continueBtn = find.text('Lanjutkan Percakapan dengan AI');
    expect(continueBtn, findsOneWidget);

    // Tap continue chat
    await tester.tap(continueBtn);
    await tester.pumpAndSettle();

    // Verify ChatScreen opened with previous messages
    expect(find.text('Lanjutan Sesi Jurnal • Aktif 24/7'), findsOneWidget);
    expect(find.text('Halo, aku cemas banget hari ini'), findsOneWidget);
    expect(find.text('Kenapa kamu cemas? Ceritakan lebih lanjut.'), findsOneWidget);
  });

  testWidgets('DoctorDetailScreen renders schedule slots and booked indicator', (WidgetTester tester) async {
    final doctor = {
      'id': 'psy_test',
      'name': 'dr. Nadia S., Sp.KJ',
      'role': 'Psikiater Klinis',
      'experience': '8 tahun',
      'rating': 4.9,
      'price': 'Rp 250.000',
    };

    await tester.pumpWidget(MaterialApp(
      home: DoctorDetailScreen(doctor: doctor),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Pilih Tanggal Sesi'), findsOneWidget);
    expect(find.text('Pilih Waktu Konsultasi'), findsOneWidget);
    expect(find.text('09:00 - 11:00 WIB'), findsOneWidget);
    expect(find.text('Lanjut ke Pembayaran'), findsOneWidget);
  });

  testWidgets('SettingsScreen opens Edit Profile and shows upload photo options', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: SettingsScreen(),
    ));
    await tester.pumpAndSettle();

    // Verify profile menu items exist
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('My Stats'), findsOneWidget);
    expect(find.text('Social Media'), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);

    // Tap Edit Profile
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();

    // Verify upload options in bottom sheet
    expect(find.text('Pilih Galeri'), findsOneWidget);
    expect(find.text('Kamera'), findsOneWidget);
    expect(find.text('Simpan Perubahan'), findsOneWidget);
  });
}
