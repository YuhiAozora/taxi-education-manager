import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import 'driver_home_screen.dart';
import 'admin_home_screen.dart';

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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final employeeNumber = _employeeNumberController.text.trim();
    final password = _passwordController.text;

    try {
      final user = DatabaseService.getUserByEmployeeNumber(employeeNumber);

      debugPrint('🔍 Login attempt:');
      debugPrint('  Employee Number: $employeeNumber');
      debugPrint('  User found: ${user != null}');
      if (user != null) {
        debugPrint('  User name: ${user.name}');
        debugPrint('  User password: ${user.password}');
        debugPrint('  Input password: $password');
        debugPrint('  Password match: ${user.password == password}');
        debugPrint('  Password trimmed match: ${user.password.trim() == password.trim()}');
      }

      if (user != null && user.password.trim() == password.trim()) {
        // Login successful
        debugPrint('✅ Login successful!');
        await DatabaseService.setCurrentUser(user);

        if (!mounted) return;

        if (user.isAdmin) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
          );
        }
      } else {
        // Login failed
        debugPrint('❌ Login failed');
        if (!mounted) return;
        
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('社員番号またはパスワードが正しくありません\n(入力: $employeeNumber)'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Error handling
      debugPrint('Login error: $e');
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラーが発生しました: $e'),
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
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'デモアカウント',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text('管理者: ADMIN / admin123'),
                                const Text('乗務員1: D001 / pass123'),
                                const Text('乗務員2: D002 / pass123'),
                              ],
                            ),
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
