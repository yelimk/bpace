import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';
import 'screens/splash_screen.dart';
import 'services/api_client.dart';
import 'services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await ApiClient.instance.restoreSession();
    // 백그라운드로 Render 서버 헬스체크(/api/health) 핑을 미리 날려 수면(Sleep) 상태의 서버를 웜업!
    ApiClient.instance.get('/api/health').catchError((_) {});
  } catch (e) {
    debugPrint('Session restore skipped: $e');
  }
  try {
    await LocalNotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Local notification init skipped: $e');
  }
  runApp(const BreathCareApp());
}

class BreathCareApp extends StatelessWidget {
  const BreathCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BPACE',
      debugShowCheckedModeBanner: false,
      // Cross-platform Scroll & Physics Unification
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.darkBg,
        fontFamily: AppFonts.pretendard,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.lightMint,
          secondary: AppColors.coralRed,
          surface: AppColors.darkCharcoal,
          error: AppColors.coralRed,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        splashFactory: InkSparkle.splashFactory,
      ),
      home: const SplashScreen(),
    );
  }
}
