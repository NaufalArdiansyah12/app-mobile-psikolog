import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/screens/onboarding_screen.dart';
import 'package:mobile/screens/launch_splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App starts with OnboardingScreen walkthrough on fresh install', (WidgetTester tester) async {
    await tester.pumpWidget(const MindPalApp(initialScreen: OnboardingScreen()));
    expect(find.textContaining('Curhat Bebas'), findsOneWidget);
    expect(find.text('LEWATI'), findsOneWidget);
    expect(find.text('LANJUT'), findsOneWidget);
  });

  testWidgets('App starts with LaunchSplashScreen for returning user', (WidgetTester tester) async {
    await tester.pumpWidget(const MindPalApp(initialScreen: LaunchSplashScreen()));
    expect(find.text('MindPal'), findsOneWidget);
    expect(find.text('Ruang aman untuk bercerita'), findsOneWidget);
  });
}
