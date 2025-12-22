import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user.dart' as app_models;

/// Web専用の認証サービス（LocalStorage使用）
class WebAuthService {
  static const String _storageKey = 'taxi_education_user';
  
  static app_models.User? _currentUser;
  
  static app_models.User? get currentUser => _currentUser;
  
  static bool get isLoggedIn => _currentUser != null;
  
  /// ログイン（Web版 - 簡易認証）
  static Future<app_models.User?> login(String employeeNumber, String password) async {
    try {
      final normalizedEmployeeNumber = employeeNumber.toUpperCase().trim();
      
      if (kDebugMode) {
        debugPrint('🌐 Web Login attempt: $normalizedEmployeeNumber');
      }
      
      // デモ用の認証データ（本番環境では必ずFirestoreから取得）
      // 3層構造: スーパー管理者 → 会社管理者 → 運転手
      final demoUsers = {
        // 🏛️ レイヤー1: スーパー管理者（コミュニティ運営者）
        'ADMIN': {
          'name': 'システム管理者',
          'password': 'admin123',
          'role': 'super_admin',
          'companyId': '',  // 全企業を管理
        },
        
        // 🏢 レイヤー2: 会社管理者（東京タクシー株式会社）
        'ADMIN001': {
          'name': '東京タクシー管理者',
          'password': 'admin123',
          'role': 'company_admin',
          'companyId': 'company001',
        },
        
        // 🚗 レイヤー3: 運転手（東京タクシー株式会社）
        'D001': {
          'name': '山田太郎',
          'password': 'password123',
          'role': 'driver',
          'companyId': 'company001',
        },
        'D002': {
          'name': '佐藤次郎',
          'password': 'password123',
          'role': 'driver',
          'companyId': 'company001',
        },
        'D003': {
          'name': '鈴木三郎',
          'password': 'password123',
          'role': 'driver',
          'companyId': 'company001',
        },
        
        // 🏢 レイヤー2: 会社管理者（大阪交通サービス）
        'ADMIN002': {
          'name': '大阪交通管理者',
          'password': 'admin123',
          'role': 'company_admin',
          'companyId': 'company002',
        },
        
        // 🚗 レイヤー3: 運転手（大阪交通サービス）
        'D004': {
          'name': '田中四郎',
          'password': 'password123',
          'role': 'driver',
          'companyId': 'company002',
        },
        'D005': {
          'name': '高橋五郎',
          'password': 'password123',
          'role': 'driver',
          'companyId': 'company002',
        },
        
        // ===== βテスト用アカウント =====
        
        // 🧪 βテスト - 管理者（テスト会社）
        'M101': {
          'name': '諸星健二',
          'password': 'manager2024',
          'role': 'company_admin',
          'companyId': 'beta_company',
        },
        'M102': {
          'name': '富岡広一',
          'password': 'manager2024',
          'role': 'company_admin',
          'companyId': 'beta_company',
        },
        
        // 🧪 βテスト - 運転手（テスト会社）
        'D101': {
          'name': '金子一也',
          'password': 'driver2024',
          'role': 'driver',
          'companyId': 'beta_company',
        },
        'D102': {
          'name': '大谷理一',
          'password': 'driver2024',
          'role': 'driver',
          'companyId': 'beta_company',
        },
        'D103': {
          'name': '森下久美子',
          'password': 'driver2024',
          'role': 'driver',
          'companyId': 'beta_company',
        },
        'D104': {
          'name': '石塚裕美子',
          'password': 'driver2024',
          'role': 'driver',
          'companyId': 'beta_company',
        },
        'D105': {
          'name': '福島舞',
          'password': 'driver2024',
          'role': 'driver',
          'companyId': 'beta_company',
        },
      };
      
      // ユーザーチェック
      if (!demoUsers.containsKey(normalizedEmployeeNumber)) {
        throw Exception('ユーザーが見つかりません');
      }
      
      final userData = demoUsers[normalizedEmployeeNumber]!;
      
      // パスワードチェック
      if (password != userData['password']) {
        throw Exception('パスワードが正しくありません');
      }
      
      // ユーザーオブジェクト作成
      _currentUser = app_models.User(
        employeeNumber: normalizedEmployeeNumber,
        name: userData['name'] as String,
        password: password,
        role: userData['role'] as String,
        companyId: userData['companyId'] as String,
      );
      
      // LocalStorageに保存
      _saveToStorage(_currentUser!);
      
      if (kDebugMode) {
        debugPrint('✅ Web Login successful: ${_currentUser!.name}');
      }
      
      return _currentUser;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Web Login error: $e');
      }
      rethrow;
    }
  }
  
  /// ログアウト
  static Future<void> logout() async {
    _currentUser = null;
    
    // 🔒 セキュリティ強化: LocalStorageを完全にクリア
    html.window.localStorage.remove(_storageKey);
    
    // 🧹 追加: 他のユーザーデータもクリア（念のため）
    try {
      html.window.localStorage.clear();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ LocalStorage clear warning: $e');
      }
    }
    
    if (kDebugMode) {
      debugPrint('✅ Web Logout successful - LocalStorage cleared');
    }
  }
  
  /// セッション復元
  static Future<app_models.User?> restoreSession() async {
    try {
      final userJson = html.window.localStorage[_storageKey];
      
      if (userJson == null) {
        return null;
      }
      
      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      
      _currentUser = app_models.User(
        employeeNumber: userData['employeeNumber'] as String,
        name: userData['name'] as String,
        password: userData['password'] as String,
        role: userData['role'] as String,
        companyId: userData['companyId'] as String? ?? '',
      );
      
      if (kDebugMode) {
        debugPrint('✅ Web Session restored: ${_currentUser!.name}');
      }
      
      return _currentUser;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Web Session restore failed: $e');
      }
      return null;
    }
  }
  
  /// LocalStorageに保存
  static void _saveToStorage(app_models.User user) {
    final userJson = jsonEncode({
      'employeeNumber': user.employeeNumber,
      'name': user.name,
      'password': user.password,
      'role': user.role,
      'companyId': user.companyId,
    });
    
    html.window.localStorage[_storageKey] = userJson;
  }
}
