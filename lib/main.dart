import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'views/splash/splash.dart';
import 'viewmodels/hike_viewmodel.dart';
import 'viewmodels/observation_viewmodel.dart';
import 'viewmodels/media_viewmodel.dart';
import 'viewmodels/map_viewmodel.dart';
import 'viewmodels/weather_viewmodel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HikeViewModel()),
        ChangeNotifierProvider(create: (_) => ObservationViewModel()),
        ChangeNotifierProvider(create: (_) => MediaViewModel()),
        ChangeNotifierProvider(create: (_) => MapViewModel()),
        ChangeNotifierProvider(create: (_) => WeatherViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: "PlusJakartaSans",
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
