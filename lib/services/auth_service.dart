import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart' as app_models;
import 'web_auth_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static app_models.User? _currentUser;
  
  /// 現在のログインユーザーを取得
  static app_models.User? get currentUser => _currentUser;
  
  /// Firebase Authの現在のユーザー
  static User? get firebaseUser => kIsWeb ? null : _auth.currentUser;
  
  /// ログイン状態の確認
  static bool get isLoggedIn => _currentUser != null;
  
  /// 社員番号とパスワードでログイン
  static Future<app_models.User?> login(String employeeNumber, String password) async {
    // Web版では WebAuthService を使用
    if (kIsWeb) {
      _currentUser = await WebAuthService.login(employeeNumber, password);
      return _currentUser;
    }
    
    // モバイル版の処理
    try {
      // 社員番号を大文字に統一
      final normalizedEmployeeNumber = employeeNumber.toUpperCase().trim();
      
      if (kDebugMode) {
        debugPrint('🔍 Login attempt: $normalizedEmployeeNumber');
      }
      
      // Firestoreからユーザー情報を取得
      final userDoc = await _firestore
          .collection('users')
          .doc(normalizedEmployeeNumber)
          .get();
      
      if (!userDoc.exists) {
        if (kDebugMode) {
          debugPrint('❌ User not found in Firestore');
        }
        throw Exception('ユーザーが見つかりません');
      }
      
      final userData = userDoc.data()!;
      final storedPassword = userData['password'] as String;
      
      // パスワード確認
      if (password != storedPassword) {
        if (kDebugMode) {
          debugPrint('❌ Password mismatch');
        }
        throw Exception('パスワードが正しくありません');
      }
      
      if (kDebugMode) {
        debugPrint('✅ Password verified');
      }
      
      // Web版ではFirebase Authenticationをスキップ
      if (kIsWeb) {
        if (kDebugMode) {
          debugPrint('🌐 Web platform: Skipping Firebase Auth');
        }
        
        // Firestoreのデータだけでログイン
        _currentUser = app_models.User(
          employeeNumber: normalizedEmployeeNumber,
          name: userData['name'] as String,
          password: storedPassword,
          role: userData['role'] as String? ?? 'driver',
          companyId: userData['companyId'] as String? ?? userData['company_id'] as String? ?? '',
        );
        
        if (kDebugMode) {
          debugPrint('✅ Login successful (Web): ${_currentUser!.name}');
        }
        
        return _currentUser;
      }
      
      // モバイル版: Firebase Authentication を使用
      final email = '$normalizedEmployeeNumber@taxi-education.local';
      
      try {
        // 既存アカウントでログイン試行
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        // アカウントが存在しない場合は新規作成
        if (e.toString().contains('user-not-found') || 
            e.toString().contains('INVALID_LOGIN_CREDENTIALS')) {
          await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }
      
      // アプリ用のUserモデルに変換
      _currentUser = app_models.User(
        employeeNumber: normalizedEmployeeNumber,
        name: userData['name'] as String,
        password: storedPassword,
        role: userData['role'] as String? ?? 'driver',
        companyId: userData['companyId'] as String? ?? userData['company_id'] as String? ?? '',
      );
      
      if (kDebugMode) {
        debugPrint('✅ Login successful (Mobile): ${_currentUser!.name}');
      }
      
      return _currentUser;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Login error: $e');
      }
      if (e.toString().contains('network-request-failed')) {
        throw Exception('インターネット接続を確認してください');
      }
      rethrow;
    }
  }
  
  /// ログアウト
  static Future<void> logout() async {
    if (kIsWeb) {
      await WebAuthService.logout();
    } else {
      await _auth.signOut();
    }
    _currentUser = null;
  }
  
  /// ログイン状態の復元
  static Future<app_models.User?> restoreSession() async {
    try {
      // Web版では WebAuthService でセッション復元
      if (kIsWeb) {
        _currentUser = await WebAuthService.restoreSession();
        return _currentUser;
      }
      
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        return null;
      }
      
      // メールアドレスから社員番号を抽出
      final email = firebaseUser.email!;
      final employeeNumber = email.split('@')[0];
      
      // Firestoreからユーザー情報を取得
      final userDoc = await _firestore
          .collection('users')
          .doc(employeeNumber)
          .get();
      
      if (!userDoc.exists) {
        await logout();
        return null;
      }
      
      final userData = userDoc.data()!;
      
      _currentUser = app_models.User(
        employeeNumber: employeeNumber,
        name: userData['name'] as String,
        password: userData['password'] as String,
        role: userData['role'] as String? ?? 'driver',
        companyId: userData['companyId'] as String? ?? userData['company_id'] as String? ?? '',
      );
      
      return _currentUser;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Session restore failed: $e');
      }
      await logout();
      return null;
    }
  }
}
