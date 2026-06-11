import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/auth/presentation/screens/account_restricted_screen.dart';
import 'features/auth/presentation/screens/email_verify_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/dashboards/presentation/shells/admin_shell.dart';
import 'features/dashboards/presentation/shells/cashier_shell.dart';
import 'features/dashboards/presentation/shells/kitchen_shell.dart';
import 'features/dashboards/presentation/shells/waiter_shell.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => AuthCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'Sajilo Restro Sewa',
            themeMode: themeMode,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            home: const AuthGate(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (_, current) =>
          current is Unauthenticated && current.errorMessage != null,
      listener: (context, state) {
        if (state is Unauthenticated && state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
        }
      },
      builder: (context, state) {
        if (state is AuthInitial || state is SessionCheckLoading) {
          return const SplashScreen();
        }

        if (state is EmailUnverified) {
          return EmailVerifyScreen(user: state.user);
        }

        if (state is AccountRestricted) {
          return AccountRestrictedScreen(
            user: state.user,
            reason: state.reason,
            isRechecking: state.isRechecking,
          );
        }

        if (state is Authenticated) {
          switch (state.user.role.toLowerCase()) {
            case 'admin':
              return AdminShell(user: state.user);
            case 'cashier':
              return CashierShell(user: state.user);
            case 'kitchen':
              return KitchenShell(user: state.user);
            case 'waiter':
              return WaiterShell(user: state.user);
            default:
              return const LoginScreen();
          }
        }

        return const LoginScreen();
      },
    );
  }
}
