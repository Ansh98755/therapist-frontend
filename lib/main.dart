import 'package:flutter/material.dart';
import 'package:therapist_app/core/app_state.dart';
import 'package:therapist_app/routes/routes.dart';
import 'package:therapist_app/screens/auth_wrapper.dart';
import 'package:therapist_app/utils/color_constants/color_constants.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Niti Therapist App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.brown,
        primaryColor: ColorConstants.primaryBrownColor,
        scaffoldBackgroundColor: ColorConstants.colorF5F5F5,
        appBarTheme: AppBarTheme(
          backgroundColor: ColorConstants.whiteColor,
          elevation: 0,
          iconTheme: IconThemeData(color: ColorConstants.primaryBrownColor),
          titleTextStyle: TextStyle(
            color: ColorConstants.primaryBrownColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConstants.primaryBrownColor,
            foregroundColor: ColorConstants.whiteColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: ColorConstants.whiteColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ColorConstants.colorE0E0E0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ColorConstants.colorE0E0E0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: ColorConstants.primaryBrownColor,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ColorConstants.redColor),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const AuthWrapper(),
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
