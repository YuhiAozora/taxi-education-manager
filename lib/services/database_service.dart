import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/education_item.dart';
import '../models/learning_record.dart';
import '../models/medical_checkup.dart';
import '../models/company.dart';
import '../models/leave_request.dart';
import '../models/vehicle_inspection.dart';
import '../models/accident_report.dart';
import '../models/education_record.dart';
import 'auth_service.dart';

class DatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint('🔧 Initializing Firebase Firestore...');
    }
    
    try {
      // ログイン状態の復元を試みる
      await AuthService.restoreSession();
      
      if (kDebugMode) {
        debugPrint('✅ Firebase Firestore initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Warning: Could not restore session: $e');
        debugPrint('Continuing without session restore...');
      }
      // Continue without restored session - user will need to login
    }
  }

  // ==================== User Operations ====================
  
  static User? getCurrentUser() {
    return AuthService.currentUser;
  }

  static Future<User?> login(String employeeNumber, String password) async {
    return await AuthService.login(employeeNumber, password);
  }

  static Future<void> logout() async {
    await AuthService.logout();
  }

  static User? getUserByEmployeeNumber(String employeeNumber) {
    // This is synchronous in Hive version, but for Firestore we need async
    // For now, return current user if it matches
    final currentUser = AuthService.currentUser;
    if (currentUser != null && 
        currentUser.employeeNumber.toUpperCase() == employeeNumber.toUpperCase()) {
      return currentUser;
    }
    return null;
  }

  static Future<List<User>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return User(
          employeeNumber: doc.id,
          name: data['name'] as String,
          password: data['password'] as String,
          role: data['role'] as String,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting users: $e');
      }
      return [];
    }
  }

  static Future<void> saveUser(User user) async {
    try {
      await _firestore.collection('users').doc(user.employeeNumber).set({
        'name': user.name,
        'password': user.password,
        'role': user.isAdmin ? 'admin' : 'driver',
        'hire_date': user.createdAt,
        'birth_date': user.createdAt,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving user: $e');
      }
      rethrow;
    }
  }

  // ==================== Education Item Operations ====================

  static Future<List<EducationItem>> getEducationItems() async {
    // Web版ではダミーデータを返す
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 300));
      return [
        EducationItem(
          id: 'edu1',
          title: '安全運転の基礎',
          description: '安全運転の基本的な知識と技術を学びます',
          category: '安全運転',
          durationMinutes: 30,
          isRequired: true,
          order: 1,
        ),
        EducationItem(
          id: 'edu2',
          title: '交通法規の理解',
          description: '最新の交通法規について学習します',
          category: '法規',
          durationMinutes: 45,
          isRequired: true,
          order: 2,
        ),
        EducationItem(
          id: 'edu3',
          title: '接客マナー',
          description: 'お客様への適切な接客方法を学びます',
          category: '接客',
          durationMinutes: 30,
          isRequired: true,
          order: 3,
        ),
        EducationItem(
          id: 'edu4',
          title: '事故対応手順',
          description: '万が一の事故時の対応手順を学習します',
          category: '安全運転',
          durationMinutes: 60,
          isRequired: true,
          order: 4,
        ),
        EducationItem(
          id: 'edu5',
          title: '健康管理',
          description: '運転者の健康管理について学びます',
          category: '健康',
          durationMinutes: 30,
          isRequired: false,
          order: 5,
        ),
      ];
    }
    
    try {
      final snapshot = await _firestore
          .collection('education_items')
          .orderBy('order')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return EducationItem(
          id: doc.id,
          title: data['title'] as String,
          description: data['description'] as String,
          category: data['category'] as String,
          durationMinutes: data['duration_minutes'] as int,
          isRequired: data['required'] as bool,
          order: data['order'] as int,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting education items: $e');
      }
      return [];
    }
  }

  static Future<EducationItem?> getEducationItem(String id) async {
    try {
      final doc = await _firestore.collection('education_items').doc(id).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      return EducationItem(
        id: doc.id,
        title: data['title'] as String,
        description: data['description'] as String,
        category: data['category'] as String,
        durationMinutes: data['duration_minutes'] as int,
        isRequired: data['required'] as bool,
        order: data['order'] as int,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting education item: $e');
      }
      return null;
    }
  }

  static Future<void> saveEducationItem(EducationItem item) async {
    try {
      await _firestore.collection('education_items').doc(item.id).set({
        'title': item.title,
        'description': item.description,
        'category': item.category,
        'duration_minutes': item.durationMinutes,
        'required': item.isRequired,
        'order': item.order,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving education item: $e');
      }
      rethrow;
    }
  }

  // ==================== Learning Record Operations ====================

  static Future<List<LearningRecord>> getLearningRecordsByUser(String employeeNumber) async {
    try {
      final snapshot = await _firestore
          .collection('learning_records')
          .where('user_id', isEqualTo: employeeNumber)
          .get();
      
      final records = snapshot.docs.map((doc) {
        final data = doc.data();
        return LearningRecord(
          id: doc.id,
          userId: data['user_id'] as String,
          educationItemId: data['education_item_id'] as String,
          completedAt: (data['completed_at'] as Timestamp).toDate(),
          durationMinutes: data['duration_minutes'] as int,
          notes: data['notes'] as String? ?? '',
        );
      }).toList();
      
      // Sort by completion date (newest first)
      records.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return records;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting learning records: $e');
      }
      return [];
    }
  }

  static Future<List<LearningRecord>> getAllLearningRecords() async {
    try {
      final snapshot = await _firestore.collection('learning_records').get();
      
      final records = snapshot.docs.map((doc) {
        final data = doc.data();
        return LearningRecord(
          id: doc.id,
          userId: data['user_id'] as String,
          educationItemId: data['education_item_id'] as String,
          completedAt: (data['completed_at'] as Timestamp).toDate(),
          durationMinutes: data['duration_minutes'] as int,
          notes: data['notes'] as String? ?? '',
        );
      }).toList();
      
      records.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return records;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting all learning records: $e');
      }
      return [];
    }
  }

  static Future<void> saveLearningRecord(LearningRecord record) async {
    try {
      if (record.id.isEmpty) {
        // New record
        await _firestore.collection('learning_records').add({
          'user_id': record.userId,
          'education_item_id': record.educationItemId,
          'completed_at': Timestamp.fromDate(record.completedAt),
          'duration_minutes': record.durationMinutes,
          'notes': record.notes,
          'created_at': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing record
        await _firestore.collection('learning_records').doc(record.id).set({
          'user_id': record.userId,
          'education_item_id': record.educationItemId,
          'completed_at': Timestamp.fromDate(record.completedAt),
          'duration_minutes': record.durationMinutes,
          'notes': record.notes,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving learning record: $e');
      }
      rethrow;
    }
  }

  static Future<void> deleteLearningRecord(String id) async {
    try {
      await _firestore.collection('learning_records').doc(id).delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting learning record: $e');
      }
      rethrow;
    }
  }

  // ==================== Medical Checkup Operations ====================

  static Future<List<MedicalCheckup>> getMedicalCheckupsByUser(String employeeNumber) async {
    try {
      final snapshot = await _firestore
          .collection('medical_checkups')
          .where('user_id', isEqualTo: employeeNumber)
          .get();
      
      final checkups = snapshot.docs.map((doc) {
        final data = doc.data();
        return MedicalCheckup(
          id: doc.id,
          userId: data['user_id'] as String,
          type: MedicalCheckupType.values.firstWhere(
            (e) => e.toString().split('.').last == data['checkup_type'],
          ),
          checkupDate: (data['checkup_date'] as Timestamp).toDate(),
          nextDueDate: (data['next_due_date'] as Timestamp).toDate(),
          institution: data['institution'] as String,
          certificateNumber: data['certificate_number'] as String? ?? '',
          notes: data['notes'] as String? ?? '',
        );
      }).toList();
      
      checkups.sort((a, b) => b.checkupDate.compareTo(a.checkupDate));
      return checkups;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting medical checkups: $e');
      }
      return [];
    }
  }

  static Future<List<MedicalCheckup>> getAllMedicalCheckups() async {
    try {
      final snapshot = await _firestore.collection('medical_checkups').get();
      
      final checkups = snapshot.docs.map((doc) {
        final data = doc.data();
        return MedicalCheckup(
          id: doc.id,
          userId: data['user_id'] as String,
          type: MedicalCheckupType.values.firstWhere(
            (e) => e.toString().split('.').last == data['checkup_type'],
          ),
          checkupDate: (data['checkup_date'] as Timestamp).toDate(),
          nextDueDate: (data['next_due_date'] as Timestamp).toDate(),
          institution: data['institution'] as String,
          certificateNumber: data['certificate_number'] as String? ?? '',
          notes: data['notes'] as String? ?? '',
        );
      }).toList();
      
      checkups.sort((a, b) => b.checkupDate.compareTo(a.checkupDate));
      return checkups;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting all medical checkups: $e');
      }
      return [];
    }
  }

  static Future<void> saveMedicalCheckup(MedicalCheckup checkup) async {
    try {
      if (checkup.id.isEmpty) {
        // New checkup
        await _firestore.collection('medical_checkups').add({
          'user_id': checkup.userId,
          'checkup_type': checkup.type.toString().split('.').last,
          'checkup_date': Timestamp.fromDate(checkup.checkupDate),
          'next_due_date': Timestamp.fromDate(checkup.nextDueDate),
          'institution': checkup.institution,
          'certificate_number': checkup.certificateNumber,
          'notes': checkup.notes,
          'created_at': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing checkup
        await _firestore.collection('medical_checkups').doc(checkup.id).set({
          'user_id': checkup.userId,
          'checkup_type': checkup.type.toString().split('.').last,
          'checkup_date': Timestamp.fromDate(checkup.checkupDate),
          'next_due_date': Timestamp.fromDate(checkup.nextDueDate),
          'institution': checkup.institution,
          'certificate_number': checkup.certificateNumber,
          'notes': checkup.notes,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving medical checkup: $e');
      }
      rethrow;
    }
  }

  static Future<void> deleteMedicalCheckup(String id) async {
    try {
      await _firestore.collection('medical_checkups').doc(id).delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting medical checkup: $e');
      }
      rethrow;
    }
  }

  // ==================== Utility Methods ====================

  static Future<void> clearAllData() async {
    // For Firestore, we don't implement this as it could be dangerous
    // Data management should be done through Firebase Console
    if (kDebugMode) {
      debugPrint('⚠️ clearAllData() is not implemented for Firestore');
      debugPrint('Please manage data through Firebase Console');
    }
  }

  // ==================== Compatibility Methods (for existing screens) ====================
  
  /// Get all drivers (non-admin users)
  static Future<List<User>> getAllDrivers() async {
    try {
      final allUsers = await getAllUsers();
      return allUsers.where((user) => !user.isAdmin).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting drivers: $e');
      }
      return [];
    }
  }
  
  /// Get upcoming checkup notifications
  static Future<Map<String, dynamic>> getUpcomingCheckupNotifications() async {
    try {
      final allCheckups = await getAllMedicalCheckups();
      final now = DateTime.now();
      
      int overdueCount = 0;
      int upcomingCount = 0;
      
      for (var checkup in allCheckups) {
        if (checkup.nextDueDate.isBefore(now)) {
          overdueCount++;
        } else if (checkup.nextDueDate.difference(now).inDays <= 30) {
          upcomingCount++;
        }
      }
      
      return {
        'overdue': overdueCount,
        'upcoming': upcomingCount,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting notifications: $e');
      }
      return {'overdue': 0, 'upcoming': 0};
    }
  }
  
  /// Get medical checkup statistics for a user
  static Future<Map<String, int>> getMedicalCheckupStatistics(String employeeNumber) async {
    try {
      final checkups = await getMedicalCheckupsByUser(employeeNumber);
      final now = DateTime.now();
      
      int total = 6; // 6 types of checkups
      int upToDate = 0;
      int upcoming = 0;
      int overdue = 0;
      
      // Count by type
      final types = <MedicalCheckupType>{};
      for (var checkup in checkups) {
        if (!types.contains(checkup.type)) {
          types.add(checkup.type);
          
          if (checkup.nextDueDate.isAfter(now.add(const Duration(days: 30)))) {
            upToDate++;
          } else if (checkup.nextDueDate.isAfter(now)) {
            upcoming++;
          } else {
            overdue++;
          }
        }
      }
      
      return {
        'total': total,
        'upToDate': upToDate,
        'upcoming': upcoming,
        'overdue': overdue,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting statistics: $e');
      }
      return {'total': 6, 'upToDate': 0, 'upcoming': 0, 'overdue': 0};
    }
  }
  
  /// Get latest checkup by type
  static Future<MedicalCheckup?> getLatestCheckupByType(
    String employeeNumber,
    MedicalCheckupType type,
  ) async {
    try {
      final checkups = await getMedicalCheckupsByUser(employeeNumber);
      final filtered = checkups.where((c) => c.type == type).toList();
      
      if (filtered.isEmpty) return null;
      
      filtered.sort((a, b) => b.checkupDate.compareTo(a.checkupDate));
      return filtered.first;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting latest checkup: $e');
      }
      return null;
    }
  }
  
  /// Get all education items (alias for compatibility)
  static Future<List<EducationItem>> getAllEducationItems() async {
    return await getEducationItems();
  }
  
  /// Get education items by category
  static Future<List<EducationItem>> getEducationItemsByCategory(String category) async {
    try {
      final items = await getEducationItems();
      return items.where((item) => item.category == category).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting items by category: $e');
      }
      return [];
    }
  }
  
  /// Get completed items count for a user
  static Future<int> getCompletedItemsCount(String employeeNumber) async {
    try {
      final records = await getLearningRecordsByUser(employeeNumber);
      final uniqueItems = <String>{};
      for (var record in records) {
        uniqueItems.add(record.educationItemId);
      }
      return uniqueItems.length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting completed count: $e');
      }
      return 0;
    }
  }
  
  /// Get total learning minutes for a user
  static Future<int> getTotalLearningMinutes(String employeeNumber) async {
    try {
      final records = await getLearningRecordsByUser(employeeNumber);
      int total = 0;
      for (var record in records) {
        total += record.durationMinutes;
      }
      return total;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting total minutes: $e');
      }
      return 0;
    }
  }
  
  /// Get average quiz score (placeholder - returns 0 as quiz feature not implemented)
  static Future<double> getAverageQuizScore(String employeeNumber) async {
    return 0.0;
  }
  
  /// Get user by employee number (async version)
  static Future<User?> getUser(String employeeNumber) async {
    try {
      final doc = await _firestore.collection('users').doc(employeeNumber.toUpperCase()).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      return User(
        employeeNumber: doc.id,
        name: data['name'] as String,
        password: data['password'] as String,
        role: data['role'] as String,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting user: $e');
      }
      return null;
    }
  }
  
  /// Clear current user (for logout compatibility)
  static Future<void> clearCurrentUser() async {
    await logout();
  }
  
  // ==================== Company Operations ====================
  
  /// Get all companies
  static Future<List<Company>> getAllCompanies() async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        return Company.fromJson(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting companies: $e');
      }
      return [];
    }
  }
  
  /// Get company by ID
  static Future<Company?> getCompany(String companyId) async {
    try {
      final doc = await _firestore.collection('companies').doc(companyId).get();
      if (!doc.exists) return null;
      
      return Company.fromJson(doc.data()!, doc.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting company: $e');
      }
      return null;
    }
  }
  
  /// Save company
  static Future<void> saveCompany(Company company) async {
    try {
      if (company.id.isEmpty) {
        // Create new company
        await _firestore.collection('companies').add(company.toJson());
      } else {
        // Update existing company
        await _firestore.collection('companies').doc(company.id).set(company.toJson());
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving company: $e');
      }
      rethrow;
    }
  }
  
  // ==================== Vehicle Inspection Operations ====================
  
  /// Save vehicle inspection (Web版では後で実装)
  static Future<void> saveVehicleInspection(dynamic inspection) async {
    // Web版では一旦何もしない（後でローカルストレージに保存）
    if (kDebugMode) {
      debugPrint('✅ Vehicle inspection saved (demo mode)');
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }
  
  /// Get vehicle inspections by user
  static Future<List> getVehicleInspections(String userId) async {
    // Web版ではダミーデータを返す（空リスト）
    if (kDebugMode) {
      debugPrint('📋 Getting vehicle inspections for: $userId');
    }
    await Future.delayed(const Duration(milliseconds: 500));
    return <dynamic>[];
  }

  // ==================== Leave Request Operations ====================
  
  /// Save leave request
  static Future<void> saveLeaveRequest(dynamic request) async {
    // Web版ではローカルに保存（ダミー処理）
    if (kDebugMode) {
      debugPrint('💾 Saving leave request (demo mode)');
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }
  
  /// Get leave requests by employee
  static Future<List> getLeaveRequestsByEmployee(String employeeNumber) async {
    // Web版ではダミーデータを返す（空リスト）
    if (kDebugMode) {
      debugPrint('📋 Getting leave requests for: $employeeNumber');
    }
    await Future.delayed(const Duration(milliseconds: 500));
    return <dynamic>[];
  }
  
  /// Get all leave requests for company admin
  static Future<List> getAllLeaveRequests(String companyId) async {
    // Web版ではダミーデータを返す（空リスト）
    if (kDebugMode) {
      debugPrint('📋 Getting all leave requests for company: $companyId');
    }
    await Future.delayed(const Duration(milliseconds: 500));
    return <dynamic>[];
  }
  
  /// Update leave request status
  static Future<void> updateLeaveRequestStatus(
    String requestId,
    LeaveStatus status,
    String approverName,
    String? approverComment,
  ) async {
    // Web版ではダミー処理
    if (kDebugMode) {
      debugPrint('✅ Leave request status updated (demo mode): $requestId -> $status');
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }
  
  /// Get leave requests by user ID (alias for getLeaveRequestsByEmployee)
  static Future<List> getLeaveRequests(String userId) async {
    return getLeaveRequestsByEmployee(userId);
  }

  // ==================== Shift Schedule Operations ====================
  
  /// Get shift schedules for driver
  static Future<List> getShiftSchedules(String employeeNumber, DateTime month) async {
    // Web版ではダミーデータを返す（空リスト）
    if (kDebugMode) {
      debugPrint('📋 Getting shift schedules for: $employeeNumber');
    }
    await Future.delayed(const Duration(milliseconds: 500));
    return <dynamic>[];
  }

  // ==================== Accident Report Operations ====================
  
  /// Save accident report
  static Future<void> saveAccidentReport(dynamic report) async {
    // Web版ではローカルに保存（ダミー処理）
    if (kDebugMode) {
      debugPrint('💾 Saving accident report (demo mode)');
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }
  
  /// Get accident reports by driver
  static Future<List> getAccidentReportsByDriver(String driverId) async {
    // Web版ではダミーデータを返す（空リスト）
    if (kDebugMode) {
      debugPrint('📋 Getting accident reports for: $driverId');
    }
    await Future.delayed(const Duration(milliseconds: 500));
    return <dynamic>[];
  }
  
  /// Get all accident reports for company
  static Future<List> getAllAccidentReports(String companyId) async {
    // Web版ではダミーデータを返す（空リスト）
    if (kDebugMode) {
      debugPrint('📋 Getting all accident reports for company: $companyId');
    }
    await Future.delayed(const Duration(milliseconds: 500));
    return <dynamic>[];
  }
  
  /// Update accident report status
  static Future<void> updateAccidentReportStatus(String reportId, String status, {String? adminComment}) async {
    // Web版ではダミー処理
    if (kDebugMode) {
      debugPrint('✅ Accident report status updated (demo mode): $reportId -> $status');
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // ==================== Education Record Operations ====================
  
  /// 教育台帳の作成・更新（全記録を統合）
  static Future<void> updateEducationRecord(String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('📚 Updating education record for: $userId');
      }

      // 各データを収集
      final user = getUserByEmployeeNumber(userId);
      if (user == null) {
        throw Exception('User not found: $userId');
      }

      // 教育実績を取得（ダミーデータ）
      final educationHistory = <EducationHistory>[];
      // TODO: 実際のデータを取得する実装を追加

      // 健康診断記録を取得（ダミーデータ）
      final medicalCheckups = <MedicalCheckupRecord>[];
      // TODO: 実際のデータを取得する実装を追加

      // 整備点検記録を取得
      final vehicleData = await getVehicleInspections(userId);
      final vehicleInspections = vehicleData.map((inspection) {
        final data = inspection as Map<String, dynamic>;
        return VehicleInspectionRecord(
          inspectionDate: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          okCount: data['okCount'] as int? ?? 0,
          ngCount: data['ngCount'] as int? ?? 0,
          notes: data['notes'] as String?,
        );
      }).toList();

      // 休暇記録を取得
      final leaveData = await getLeaveRequests(userId);
      final leaveRecords = leaveData.map((leave) {
        final data = leave as Map<String, dynamic>;
        return LeaveRecord(
          startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          leaveType: _getLeaveTypeLabel(data['type'] as String? ?? ''),
          status: _getLeaveStatusLabel(data['status'] as String? ?? ''),
          approver: data['approver'] as String?,
          approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
        );
      }).toList();

      // 事故報告記録を取得
      final accidentData = await getAccidentReportsByDriver(userId);
      final accidentRecords = accidentData.map((accident) {
        final data = accident as Map<String, dynamic>;
        return AccidentRecord(
          accidentDate: (data['accidentDateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
          location: data['location'] as String? ?? '',
          type: data['type'] as String? ?? '',
          severity: data['severity'] as String? ?? '',
          status: data['status'] as String? ?? '',
          processingNotes: data['processingNotes'] as String?,
        );
      }).toList();

      // 教育台帳を作成
      final educationRecord = EducationRecord(
        userId: userId,
        userName: user.name,
        companyId: 'COMPANY001', // TODO: ユーザーの会社IDを取得
        joinDate: user.createdAt ?? DateTime.now(),
        experienceYears: 5, // TODO: 経験年数を計算
        licenseType: '普通二種',
        licenseExpiry: DateTime.now().add(const Duration(days: 1095)), // 3年後
        educationHistory: educationHistory,
        medicalCheckups: medicalCheckups,
        vehicleInspections: vehicleInspections,
        leaveRecords: leaveRecords,
        accidentRecords: accidentRecords,
        adminNotes: null,
        lastUpdated: DateTime.now(),
      );

      // Firestoreに保存
      await _firestore
          .collection('education_records')
          .doc(userId)
          .set(educationRecord.toJson(), SetOptions(merge: true));

      if (kDebugMode) {
        debugPrint('✅ Education record updated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating education record: $e');
      }
      rethrow;
    }
  }

  /// 教育台帳を取得
  static Future<EducationRecord?> getEducationRecord(String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('📚 Getting education record for: $userId');
      }

      final doc = await _firestore
          .collection('education_records')
          .doc(userId)
          .get();

      if (!doc.exists) {
        // 教育台帳が存在しない場合は作成
        await updateEducationRecord(userId);
        
        // 再度取得
        final newDoc = await _firestore
            .collection('education_records')
            .doc(userId)
            .get();
            
        if (newDoc.exists) {
          return EducationRecord.fromFirestore(newDoc.data()!);
        }
        return null;
      }

      return EducationRecord.fromFirestore(doc.data()!);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting education record: $e');
      }
      return null;
    }
  }

  /// 会社の全運転手の教育台帳を取得（管理者用）
  static Future<List<EducationRecord>> getEducationRecordsByCompany(String companyId) async {
    try {
      if (kDebugMode) {
        debugPrint('📚 Getting education records for company: $companyId');
      }

      final snapshot = await _firestore
          .collection('education_records')
          .where('companyId', isEqualTo: companyId)
          .get();

      return snapshot.docs
          .map((doc) => EducationRecord.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting company education records: $e');
      }
      return [];
    }
  }

  /// 全運転手の教育台帳を取得（スーパー管理者用）
  static Future<List<EducationRecord>> getAllEducationRecords() async {
    try {
      if (kDebugMode) {
        debugPrint('📚 Getting all education records');
      }

      final snapshot = await _firestore
          .collection('education_records')
          .get();

      return snapshot.docs
          .map((doc) => EducationRecord.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting all education records: $e');
      }
      return [];
    }
  }

  /// 教育台帳の管理者コメントを更新
  static Future<void> updateEducationRecordNotes(String userId, String notes) async {
    try {
      await _firestore
          .collection('education_records')
          .doc(userId)
          .update({
        'adminNotes': notes,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ Education record notes updated');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating notes: $e');
      }
      rethrow;
    }
  }

  // Helper functions
  static String _getLeaveTypeLabel(String type) {
    switch (type) {
      case 'paidLeave':
        return '有給休暇';
      case 'specialLeave':
        return '特別休暇';
      case 'absence':
        return '欠勤届';
      case 'compensatory':
        return '代休届';
      default:
        return type;
    }
  }

  static String _getLeaveStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return '承認待ち';
      case 'approved':
        return '承認済み';
      case 'rejected':
        return '却下';
      case 'cancelled':
        return '取り消し';
      default:
        return status;
    }
  }

  /// 会社の全ユーザーを取得
  static Future<List<User>> getUsersByCompany(String companyId) async {
    // サンプルユーザーを返す（Firestore未実装のため）
    return Future.value([
      User(
        employeeNumber: 'D101',
        name: '田中太郎',
        password: '2026',
        role: 'driver',
        companyId: companyId,
        email: 'tanaka@example.com',
        phone: '090-1234-5678',
        address: '東京都渋谷区〇〇1-2-3',
        birthDate: DateTime(1990, 4, 1),
        gender: '男性',
      ),
      User(
        employeeNumber: 'D102',
        name: '佐藤花子',
        password: '2026',
        role: 'driver',
        companyId: companyId,
        email: 'sato@example.com',
        phone: '080-9876-5432',
        address: '東京都新宿区△△2-3-4',
        birthDate: DateTime(1985, 7, 15),
        gender: '女性',
      ),
    ]);
  }

  /// 教育記録簿用の年度別データを取得
  static Future<List<Map<String, dynamic>>> getEducationRegisterData({
    required String companyId,
    required int year,
  }) async {
    try {
      // 年度の開始日と終了日を計算（日本の会計年度: 4月始まり）
      final startDate = DateTime(year, 4, 1);
      final endDate = DateTime(year + 1, 3, 31, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection('learning_records')
          .where('company_id', isEqualTo: companyId)
          .where('completed_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('completed_at', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      print('📚 教育記録簿データ取得: ${querySnapshot.docs.length}件');
      
      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('❌ 教育記録簿データ取得エラー: $e');
      
      // サンプルデータを返す（開発・テスト用）
      return _generateSampleEducationRegisterData(year);
    }
  }

  /// サンプル教育記録簿データを生成（開発・テスト用）
  static List<Map<String, dynamic>> _generateSampleEducationRegisterData(int year) {
    final now = DateTime.now();
    final baseDate = DateTime(year, 4, 1);
    
    return List.generate(12, (index) {
      final date = baseDate.add(Duration(days: index * 30 + 7));
      final categories = ['law', 'safety', 'service', 'vehicle', 'emergency', 'health'];
      final category = categories[index % categories.length];
      
      return {
        'id': 'sample_record_$index',
        'recordId': 'REC${year}${(index + 1).toString().padLeft(3, '0')}',
        'driverId': index % 2 == 0 ? 'D101' : 'D102',
        'driverName': index % 2 == 0 ? '田中太郎' : '佐藤花子',
        'date': Timestamp.fromDate(date),
        'content': _getSampleContent(category),
        'durationMinutes': 60 + (index % 3) * 30,
        'instructor': index % 3 == 0 ? '山田教育担当' : '鈴木管理者',
        'category': category,
        'companyId': 'SAMPLE_COMPANY',
        'notes': index % 4 == 0 ? '理解度良好' : null,
        'createdAt': Timestamp.fromDate(date),
      };
    });
  }

  /// カテゴリー別のサンプルコンテンツを取得
  static String _getSampleContent(String category) {
    switch (category) {
      case 'law':
        return '道路交通法改正に関する研修';
      case 'safety':
        return '安全運転とヒヤリハット事例研究';
      case 'service':
        return '接客マナーとクレーム対応';
      case 'vehicle':
        return '車両の日常点検と整備知識';
      case 'emergency':
        return '緊急時の対応マニュアル';
      case 'health':
        return '健康管理と疲労軽減対策';
      default:
        return '一般教育研修';
    }
  }
}
