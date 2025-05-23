import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quickrepair/constants/themes.dart';
import 'package:quickrepair/constants/routes.dart';
import 'package:quickrepair/constants/strings.dart';
import 'package:quickrepair/models/report_model.dart';
import 'package:quickrepair/screens/auth/login_screen.dart';
import 'package:quickrepair/screens/auth/register_screen.dart';
import 'package:quickrepair/screens/auth/forgot_password_screen.dart';
import 'package:quickrepair/screens/splash_screen.dart';
import 'package:quickrepair/screens/onboarding/onboarding_screen.dart';
import 'package:quickrepair/screens/home/home_screen.dart';
import 'package:quickrepair/screens/report/create_report_screen.dart';
import 'package:quickrepair/screens/report/report_detail_screen.dart';
import 'package:quickrepair/screens/report/public_reports_screen.dart';
import 'package:quickrepair/services/supabase_service.dart';
import 'package:quickrepair/services/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://galamhpjjcfyiusmriiq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdhbGFtaHBqamNmeWl1c21yaWlxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc0MDM5ODAsImV4cCI6MjA2Mjk3OTk4MH0.3JEODbI3w300D28pEtO1m-inDpllIu2MQNcQG-cE0Eg',
  );
  
  // Note: Storage buckets should be pre-created in the Supabase dashboard
  // rather than trying to create them from the client
  
  // Check if onboarding has been completed
  final prefs = await SharedPreferences.getInstance();
  final bool onboardingCompleted = prefs.getBool('onboardingCompleted') ?? false;

  runApp(MyApp(onboardingCompleted: onboardingCompleted));
}

class MyApp extends StatelessWidget {
  final bool onboardingCompleted;
  const MyApp({super.key, required this.onboardingCompleted});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: AppRoutes.splash,
            routes: {
              AppRoutes.splash: (context) => const SplashScreen(),
              AppRoutes.onboarding: (context) => const OnboardingScreen(),
              AppRoutes.login: (context) => const LoginScreen(),
              AppRoutes.register: (context) => const RegisterScreen(),
              AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
              AppRoutes.home: (context) => const HomeScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == AppRoutes.createReport) {
                final dynamic args = settings.arguments;
                if (args is ReportModel) {
                  return MaterialPageRoute(
                    builder: (context) => CreateReportScreen(reportToEdit: args),
                  );
                } else {
                  return MaterialPageRoute(
                    builder: (context) => const CreateReportScreen(),
                  );
                }
              }
              if (settings.name == AppRoutes.reportDetail) {
                final ReportModel report = settings.arguments as ReportModel;
                return MaterialPageRoute(
                  builder: (context) => ReportDetailScreen(report: report),
                );
              }
              if (settings.name == AppRoutes.publicReports) {
                return MaterialPageRoute(
                  builder: (context) => const PublicReportsScreen(),
                );
              }
              if (settings.name == AppRoutes.splash) {
                 return MaterialPageRoute(builder: (context) => const SplashScreen());
              }
              return MaterialPageRoute(builder: (context) => const SplashScreen());
            },
          );
        },
      ),
    );
  }
}
