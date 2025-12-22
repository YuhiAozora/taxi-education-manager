import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/database_service.dart';
import 'screens/login_screen.dart';
import 'screens/driver_menu_screen.dart';
import 'screens/company_admin_menu_screen.dart';
import 'screens/super_admin_menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Web版ではFirebase初期化をスキップ（βテスト用）
    if (!kIsWeb) {
      debugPrint('🔥 Initializing Firebase for Mobile...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase initialized for Mobile');
    } else {
      debugPrint('🌐 Web version: Skipping Firebase initialization (using demo data)');
    }
    
    debugPrint('🚀 Starting app...');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('❌ Initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
    // If initialization fails, show detailed error
    runApp(MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'アプリの初期化に失敗しました',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'エラー詳細:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  '$e',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'スタックトレース:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  '$stackTrace',
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // アプリを再起動（エラーが表示されているため）
                    // Web版では実際にページをリロードする必要あり
                    debugPrint('ページ再読み込みが必要です');
                  },
                  child: const Text('アプリを再起動してください'),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'タクシー教育管理システム',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      // 少し待機してからログイン状態を確認
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      // ✅ 自動ログイン復元（エラーハンドリング付き）
      final currentUser = DatabaseService.getCurrentUser();
    
    if (currentUser != null) {
      // Already logged in (session restored)
      if (currentUser.isSuperAdmin) {
        // スーパー管理者
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => SuperAdminMenuScreen(currentUser: currentUser)),
        );
      } else if (currentUser.isCompanyAdmin) {
        // 会社管理者 → 会社管理者メニュー画面へ
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CompanyAdminMenuScreen(currentUser: currentUser),
          ),
        );
      } else {
        // 運転者 → メニュー画面へ
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DriverMenuScreen(currentUser: currentUser),
          ),
        );
      }
    } else {
      // Not logged in
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
    } catch (e) {
      debugPrint('⚠️ Login check error: $e');
      // エラーが発生してもログイン画面に遷移
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade400,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_taxi,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'タクシー教育管理システム',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Taxi Education Manager',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
