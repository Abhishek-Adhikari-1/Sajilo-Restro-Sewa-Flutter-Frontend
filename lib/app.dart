import 'package:sajilo_restro_sewa/core/errors/app_error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
import 'features/tables/presentation/cubit/table_cubit.dart';
import 'features/tables/domain/repositories/table_repository.dart';
import 'features/tables/data/datasources/table_remote_datasource.dart';
import 'core/network/socket_client.dart';
import 'core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'features/menu/presentation/cubit/menu_cubit.dart';
import 'features/menu/domain/repositories/menu_repository.dart';
import 'features/menu/data/datasources/menu_remote_datasource.dart';
import 'features/orders/presentation/cubit/order_cubit.dart';
import 'features/orders/domain/repositories/order_repository.dart';
import 'features/orders/data/datasources/order_remote_datasource.dart';
import 'features/dashboards/presentation/cubit/dashboard_cubit.dart';
import 'features/dashboards/domain/repositories/dashboard_repository.dart';
import 'features/dashboards/data/datasources/dashboard_remote_datasource.dart';
import 'features/payments/presentation/cubit/payment_cubit.dart';
import 'features/payments/presentation/cubit/billing_history_cubit.dart';
import 'features/payments/presentation/cubit/side_panel_cubit.dart';
import 'features/payments/data/repositories/payment_repository.dart';
import 'features/payments/data/datasources/payment_remote_datasource.dart';
import 'core/constants/app_constants.dart';
import 'core/storage/secure_storage.dart';
import 'features/staff/presentation/cubit/staff_cubit.dart';
import 'features/staff/domain/repositories/staff_repository.dart';
import 'features/staff/data/datasources/staff_remote_datasource.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

class App extends StatelessWidget {
  const App({super.key});

  Dio _buildDio() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.getToken(AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
    return dio;
  }

  @override
  Widget build(BuildContext context) {
    final configuredDio = _buildDio();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => AuthCubit()),
        // Add new Cubits here. Ideally, DI using get_it would be better, but we will instantiate directly for now.
        BlocProvider(
          create: (_) => TableCubit(
            repository: TableRepository(
              remoteDataSource: TableRemoteDataSourceImpl(ApiClient()),
            ),
            socketClient: SocketClient(),
          ),
        ),
        BlocProvider(
          create: (_) => MenuCubit(
            MenuRepository(
              MenuRemoteDataSource(configuredDio),
            ),
            SocketClient(),
          ),
        ),
        BlocProvider(
          create: (_) => OrderCubit(
            OrderRepository(
              OrderRemoteDataSource(configuredDio),
            ),
            SocketClient(),
          ),
        ),
        BlocProvider(
          create: (_) => DashboardCubit(
            DashboardRepository(
              DashboardRemoteDataSource(configuredDio),
            ),
            SocketClient(),
          ),
        ),
        BlocProvider(
          create: (_) => PaymentCubit(
            PaymentRepository(
              PaymentRemoteDataSource(configuredDio),
            ),
          ),
        ),
        BlocProvider(
          create: (_) => SidePanelCubit(
            PaymentRepository(
              PaymentRemoteDataSource(configuredDio),
            ),
          ),
        ),
        BlocProvider(
          create: (_) => BillingHistoryCubit(
            PaymentRepository(
              PaymentRemoteDataSource(configuredDio),
            ),
          ),
        ),
        BlocProvider(
          create: (_) => StaffCubit(
            StaffRepository(
              StaffRemoteDataSource(configuredDio),
            ),
          ),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'Sajilo Restro Sewa',
            scrollBehavior: MyCustomScrollBehavior(),
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
      listenWhen: (_, current) => true,
      listener: (context, state) {
        if (state is Unauthenticated && state.errorMessage != null) {
          AppErrorHandler.show(context, state.errorMessage!);
        }
        if (state is Authenticated) {
          // Connect socket and fetch tables proactively
          final socketClient = SocketClient();
          socketClient.connect().then((_) {
            // Once connected (or if already connected), initialize listeners
            if (context.mounted) {
              context.read<TableCubit>().initSocket();
              context.read<OrderCubit>().initSocket(state.user.id, state.user.role);
              context.read<MenuCubit>().initSocket();
            }
          });
          context.read<TableCubit>().fetchTables();
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
