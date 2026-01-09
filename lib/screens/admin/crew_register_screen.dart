import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/crew_register.dart';
import '../../services/database_service.dart';
import '../../services/pdf_service.dart';

/// 乗務員台帳管理画面（管理者用）
class CrewRegisterScreen extends StatefulWidget {
  final User currentUser;

  const CrewRegisterScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<CrewRegisterScreen> createState() => _CrewRegisterScreenState();
}

class _CrewRegisterScreenState extends State<CrewRegisterScreen> {
  List<User> _drivers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final drivers = await DatabaseService.getUsersByCompany(
        widget.currentUser.companyId ?? '',
      );
      
      // 運転手のみフィルタリング
      final driverUsers = drivers.where((user) => user.role == 'driver').toList();
      
      setState(() {
        _drivers = driverUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'ドライバー一覧の取得に失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _generateCrewRegisterPdf(User driver) async {
    // ローディング表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // データを取得
      final medicalCheckups = await DatabaseService.getMedicalCheckupsByUser(
        driver.employeeNumber,
      );
      
      final completedItems = await DatabaseService.getCompletedItemsCount(
        driver.id,
      );
      
      final totalMinutes = await DatabaseService.getTotalLearningMinutes(
        driver.id,
      );
      
      final averageScore = await DatabaseService.getAverageQuizScore(
        driver.id,
      );

      // 乗務員台帳モデルを作成
      final register = CrewRegister(
        user: driver,
        medicalCheckups: medicalCheckups,
        licenseInfo: null, // 今後実装
        educationSummary: EducationSummary(
          totalCompletedItems: completedItems,
          totalMinutes: totalMinutes,
          averageScore: averageScore,
          lastLearningDate: null, // 今後実装
          itemsThisYear: completedItems, // 簡易版
          minutesThisYear: totalMinutes,   // 簡易版
        ),
        accidentSummary: AccidentSummary(
          totalAccidents: 0,        // 今後実装
          minorAccidents: 0,
          moderateAccidents: 0,
          seriousAccidents: 0,
          lastAccidentDate: null,
          accidentsThisYear: 0,
        ),
      );

      // PDF生成
      final pdfBytes = await PdfService.generateCrewRegisterPdf(register);

      // ローディングを閉じる
      if (mounted) {
        Navigator.of(context).pop();
      }

      // PDFプレビュー・ダウンロード
      await PdfService.previewPdf(
        pdfBytes,
        '乗務員台帳_${driver.employeeNumber}_${driver.name}.pdf',
      );
    } catch (e) {
      // ローディングを閉じる
      if (mounted) {
        Navigator.of(context).pop();
      }

      // エラー表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF生成に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('乗務員台帳'),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDrivers,
              child: const Text('再読み込み'),
            ),
          ],
        ),
      );
    }

    if (_drivers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '登録されている運転手がいません',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _drivers.length,
      itemBuilder: (context, index) {
        final driver = _drivers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue,
              child: Text(
                driver.name.isNotEmpty ? driver.name[0] : 'U',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              driver.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('社員番号: ${driver.employeeNumber}'),
                if (driver.email.isNotEmpty)
                  Text('メール: ${driver.email}'),
              ],
            ),
            trailing: ElevatedButton.icon(
              onPressed: () => _generateCrewRegisterPdf(driver),
              icon: const Icon(Icons.picture_as_pdf, size: 20),
              label: const Text('PDF出力'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
