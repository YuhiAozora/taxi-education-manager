import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/crew_register.dart';
import '../models/education_register.dart';

/// PDF生成サービス（乗務員台帳・教育記録簿）
class PdfService {
  /// 乗務員台帳PDFを生成
  static Future<Uint8List> generateCrewRegisterPdf(CrewRegister register) async {
    final pdf = pw.Document();
    
    // 日本語フォントを読み込み
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // タイトル
            pw.Center(
              child: pw.Text(
                '乗務員台帳',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            
            // 基本情報セクション
            _buildSectionTitle('基本情報', fontBold),
            _buildInfoTable(
              font: font,
              fontBold: fontBold,
              data: [
                ['社員番号', register.user.employeeNumber],
                ['氏名', register.user.name],
                ['生年月日', register.user.birthDate != null 
                    ? DateFormat('yyyy年M月d日').format(register.user.birthDate!) 
                    : '未登録'],
                ['年齢', register.user.birthDate != null
                    ? '${DateTime.now().year - register.user.birthDate!.year}歳'
                    : '-'],
                ['性別', register.user.gender ?? '未登録'],
                ['メールアドレス', register.user.email],
                ['電話番号', register.user.phone ?? '未登録'],
                ['住所', register.user.address ?? '未登録'],
              ],
            ),
            pw.SizedBox(height: 20),
            
            // 健康診断記録セクション
            _buildSectionTitle('健康診断記録', fontBold),
            _buildMedicalCheckupTable(register.medicalCheckups, font, fontBold),
            pw.SizedBox(height: 20),
            
            // 教育履歴サマリーセクション
            _buildSectionTitle('教育履歴', fontBold),
            _buildEducationSummaryTable(register.educationSummary, font, fontBold),
            pw.SizedBox(height: 20),
            
            // 事故履歴サマリーセクション
            _buildSectionTitle('事故履歴', fontBold),
            _buildAccidentSummaryTable(register.accidentSummary, font, fontBold),
            pw.SizedBox(height: 30),
            
            // フッター
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '発行日: ${DateFormat('yyyy年M月d日').format(register.generatedAt)}',
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
                pw.Text(
                  'タクシー教育管理システム',
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// セクションタイトルの構築
  static pw.Widget _buildSectionTitle(String title, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue300),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: font,
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
    );
  }

  /// 基本情報テーブルの構築
  static pw.Widget _buildInfoTable({
    required pw.Font font,
    required pw.Font fontBold,
    required List<List<String>> data,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
      },
      children: data.map((row) {
        return pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              color: PdfColors.grey200,
              child: pw.Text(
                row[0],
                style: pw.TextStyle(font: fontBold, fontSize: 11),
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                row[1],
                style: pw.TextStyle(font: font, fontSize: 11),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  /// 健康診断テーブルの構築
  static pw.Widget _buildMedicalCheckupTable(
    List<dynamic> checkups,
    pw.Font font,
    pw.Font fontBold,
  ) {
    if (checkups.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
        ),
        child: pw.Text(
          '健康診断記録がありません',
          style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey600),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
      },
      children: [
        // ヘッダー
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('診断日', font: fontBold),
            _buildTableCell('身長(cm)', font: fontBold),
            _buildTableCell('体重(kg)', font: fontBold),
            _buildTableCell('血圧', font: fontBold),
            _buildTableCell('視力', font: fontBold),
          ],
        ),
        // データ行（最新5件まで）
        ...checkups.take(5).map((checkup) {
          return pw.TableRow(
            children: [
              _buildTableCell(
                DateFormat('yyyy/M/d').format(checkup.checkupDate),
                font: font,
              ),
              _buildTableCell('${checkup.height?.toStringAsFixed(1) ?? '-'}', font: font),
              _buildTableCell('${checkup.weight?.toStringAsFixed(1) ?? '-'}', font: font),
              _buildTableCell(
                checkup.bloodPressureSystolic != null && checkup.bloodPressureDiastolic != null
                    ? '${checkup.bloodPressureSystolic}/${checkup.bloodPressureDiastolic}'
                    : '-',
                font: font,
              ),
              _buildTableCell(
                checkup.visionLeft != null && checkup.visionRight != null
                    ? '${checkup.visionLeft?.toStringAsFixed(1)}/${checkup.visionRight?.toStringAsFixed(1)}'
                    : '-',
                font: font,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  /// 教育履歴サマリーテーブルの構築
  static pw.Widget _buildEducationSummaryTable(
    EducationSummary summary,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
      },
      children: [
        _buildInfoRow('総受講項目数', '${summary.totalCompletedItems}件', font, fontBold),
        _buildInfoRow('総受講時間', '${summary.totalMinutes}分', font, fontBold),
        _buildInfoRow('平均点', '${summary.averageScore.toStringAsFixed(1)}点', font, fontBold),
        _buildInfoRow(
          '最終受講日',
          summary.lastLearningDate != null
              ? DateFormat('yyyy年M月d日').format(summary.lastLearningDate!)
              : '未受講',
          font,
          fontBold,
        ),
        _buildInfoRow('今年度受講項目', '${summary.itemsThisYear}件', font, fontBold),
        _buildInfoRow('今年度受講時間', '${summary.minutesThisYear}分', font, fontBold),
      ],
    );
  }

  /// 事故履歴サマリーテーブルの構築
  static pw.Widget _buildAccidentSummaryTable(
    AccidentSummary summary,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
      },
      children: [
        _buildInfoRow('総事故件数', '${summary.totalAccidents}件', font, fontBold),
        _buildInfoRow('軽微な事故', '${summary.minorAccidents}件', font, fontBold),
        _buildInfoRow('中程度の事故', '${summary.moderateAccidents}件', font, fontBold),
        _buildInfoRow('重大な事故', '${summary.seriousAccidents}件', font, fontBold),
        _buildInfoRow(
          '最終事故日',
          summary.lastAccidentDate != null
              ? DateFormat('yyyy年M月d日').format(summary.lastAccidentDate!)
              : 'なし',
          font,
          fontBold,
        ),
        _buildInfoRow('今年度事故件数', '${summary.accidentsThisYear}件', font, fontBold),
      ],
    );
  }

  /// テーブル行の構築
  static pw.TableRow _buildInfoRow(
    String label,
    String value,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          color: PdfColors.grey200,
          child: pw.Text(
            label,
            style: pw.TextStyle(font: fontBold, fontSize: 11),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            style: pw.TextStyle(font: font, fontSize: 11),
          ),
        ),
      ],
    );
  }

  /// テーブルセルの構築
  static pw.Widget _buildTableCell(String text, {required pw.Font font}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 10),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// 教育記録簿PDFを生成
  static Future<Uint8List> generateEducationRegisterPdf(EducationRegisterSummary summary) async {
    final pdf = pw.Document();
    
    // 日本語フォントを読み込み
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape, // 横向き
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // タイトルヘッダー
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '教育記録簿',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      '対象年度: ${summary.year}年度',
                      style: pw.TextStyle(font: font, fontSize: 14),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      '発行日: ${DateFormat('yyyy年M月d日').format(summary.generatedAt)}',
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'タクシー教育管理システム',
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            
            // サマリー情報
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('対象乗務員数', '${summary.totalDrivers}名', font, fontBold),
                  _buildSummaryItem('実施回数', '${summary.totalSessions}回', font, fontBold),
                  _buildSummaryItem('総教育時間', '${summary.totalDurationHours.toStringAsFixed(1)}時間', font, fontBold),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            
            // 教育記録一覧テーブル
            _buildEducationRecordsTable(summary.records, font, fontBold),
            
            pw.SizedBox(height: 20),
            
            // カテゴリー別集計
            pw.Text(
              'カテゴリー別集計',
              style: pw.TextStyle(font: fontBold, fontSize: 14),
            ),
            pw.SizedBox(height: 8),
            _buildCategorySummaryTable(summary.categorySummary, font, fontBold),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// サマリー項目の構築
  static pw.Widget _buildSummaryItem(String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(font: fontBold, fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  /// 教育記録一覧テーブルの構築
  static pw.Widget _buildEducationRecordsTable(List<EducationRegister> records, pw.Font font, pw.Font fontBold) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FixedColumnWidth(60),  // No.
        1: const pw.FixedColumnWidth(80),  // 実施日
        2: const pw.FixedColumnWidth(80),  // 社員番号
        3: const pw.FixedColumnWidth(100), // 氏名
        4: const pw.FlexColumnWidth(2),    // 教育内容
        5: const pw.FixedColumnWidth(80),  // カテゴリー
        6: const pw.FixedColumnWidth(60),  // 時間
        7: const pw.FixedColumnWidth(100), // 指導者
      },
      children: [
        // ヘッダー行
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableHeader('No.', font),
            _buildTableHeader('実施日', font),
            _buildTableHeader('社員番号', font),
            _buildTableHeader('氏名', font),
            _buildTableHeader('教育内容', font),
            _buildTableHeader('カテゴリー', font),
            _buildTableHeader('時間', font),
            _buildTableHeader('指導者', font),
          ],
        ),
        // データ行
        ...records.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final record = entry.value;
          return pw.TableRow(
            children: [
              _buildTableCell('$index', font),
              _buildTableCell(DateFormat('M/d').format(record.date), font),
              _buildTableCell(record.driverId, font),
              _buildTableCell(record.driverName, font),
              _buildTableCell(record.content, font),
              _buildTableCell(EducationRegister.getCategoryLabel(record.category), font),
              _buildTableCell(record.formattedDuration, font),
              _buildTableCell(record.instructor, font),
            ],
          );
        }).toList(),
      ],
    );
  }

  /// テーブルヘッダーセルの構築
  static pw.Widget _buildTableHeader(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(font: font, fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  /// テーブルデータセルの構築
  static pw.Widget _buildTableCell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 7),
        maxLines: 2,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  /// カテゴリー別集計テーブルの構築
  static pw.Widget _buildCategorySummaryTable(Map<String, int> summary, pw.Font font, pw.Font fontBold) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FixedColumnWidth(100),
      },
      children: [
        // ヘッダー行
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableHeader('カテゴリー', font),
            _buildTableHeader('実施回数', font),
          ],
        ),
        // データ行
        ...summary.entries.map((entry) {
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  entry.key,
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Center(
                  child: pw.Text(
                    '${entry.value}回',
                    style: pw.TextStyle(font: fontBold, fontSize: 10),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  /// PDFプレビュー・ダウンロード
  static Future<void> previewPdf(Uint8List pdfBytes, String filename) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: filename,
    );
  }
}
