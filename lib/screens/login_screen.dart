import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import 'driver_menu_screen.dart';
import 'company_admin_menu_screen.dart';
import 'super_admin_menu_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _employeeNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 📱 スマホ向け: ストレージをクリアしてページリロード
  Future<void> _clearStorageAndReload() async {
    // 確認ダイアログを表示
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('ログイン情報をリセット'),
          ],
        ),
        content: const Text(
          '現在のログイン情報をリセットして、\n'
          '別のアカウントでログインできるようにします。\n\n'
          '続けますか？'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('リセットする'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Web版のみ実行
      if (kIsWeb) {
        // LocalStorageをクリア
        await DatabaseService.logout();
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ ログイン情報をリセットしました'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // 入力フォームをクリア
        setState(() {
          _employeeNumberController.clear();
          _passwordController.clear();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Clear storage error: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final employeeNumber = _employeeNumberController.text.trim();
    final password = _passwordController.text;

    try {
      debugPrint('🔍 Firebase Login attempt:');
      debugPrint('  Employee Number: $employeeNumber');

      // Firebase Authentication経由でログイン
      final user = await DatabaseService.login(employeeNumber, password);

      if (user != null) {
        debugPrint('✅ Firebase Login successful!');
        
        if (!mounted) return;

        // 権限に応じて画面を切り替え
        if (user.isSuperAdmin) {
          // スーパー管理者（コミュニティ運営者）→ メニュー画面へ
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => SuperAdminMenuScreen(currentUser: user),
            ),
          );
        } else if (user.isCompanyAdmin) {
          // 会社管理者 → 会社管理者メニュー画面へ
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => CompanyAdminMenuScreen(currentUser: user),
            ),
          );
        } else {
          // 運転者 → メニュー画面へ
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => DriverMenuScreen(currentUser: user),
            ),
          );
        }
      } else {
        // Login failed
        debugPrint('❌ Firebase Login failed');
        if (!mounted) return;
        
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('社員番号またはパスワードが正しくありません'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Error handling
      debugPrint('Firebase Login error: $e');
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'ログインエラーが発生しました';
      if (e.toString().contains('インターネット接続')) {
        errorMessage = 'インターネット接続を確認してください';
      } else if (e.toString().contains('ユーザーが見つかりません')) {
        errorMessage = '社員番号が登録されていません';
      } else if (e.toString().contains('パスワードが正しくありません')) {
        errorMessage = 'パスワードが正しくありません';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_taxi,
                            size: 80,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'タクシー教育管理',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ログイン',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _employeeNumberController,
                            decoration: InputDecoration(
                              labelText: '社員番号',
                              prefixIcon: const Icon(Icons.badge),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              hintText: '例: ADMIN, D001',
                            ),
                            textCapitalization: TextCapitalization.characters,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '社員番号を入力してください';
                              }
                              return null;
                            },
                            autofocus: true,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'パスワード',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'パスワードを入力してください';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _login(),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'ログイン',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // 💡 自動ログイン説明
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, 
                                  color: Colors.blue.shade700, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '前回ログインした場合は\n自動的にログインします',
                                    style: TextStyle(
                                      color: Colors.blue.shade900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // 📱 データリセットボタン（コンパクト版）
                          OutlinedButton.icon(
                            onPressed: _clearStorageAndReload,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange.shade700,
                              side: BorderSide(color: Colors.orange.shade300),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            ),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('他の人でログインする場合はこちら'),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('データベースリセット'),
                                  content: const Text(
                                    'ローカルデータベースを完全にリセットして、\n'
                                    '新しいデータで初期化します。\n\n'
                                    'ログインできない場合はこのボタンを押してください。'
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('キャンセル'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('リセット'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                try {
                                  // Clear all Hive boxes
                                  await DatabaseService.clearAllData();
                                  // Reinitialize
                                  await DatabaseService.initialize();
                                  
                                  if (!mounted) return;
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ データベースをリセットしました！\n再度ログインしてください。'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('❌ リセットエラー: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.refresh, color: Colors.red),
                            label: const Text(
                              'データベースをリセット',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
