import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/navigation/app_back_handler.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';

class TaganaApp extends StatelessWidget {
  const TaganaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TAGANA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
      builder: (context, child) {
        return AppBackHandler(
          canPop: appRouter.canPop,
          onPop: appRouter.pop,
          onExit: SystemNavigator.pop,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}