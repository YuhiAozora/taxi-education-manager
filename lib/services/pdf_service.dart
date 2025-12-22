import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/education_record.dart';

/// 教育台帳PDF生成サービス（監査対応）
class PdfService {
  /// 教育台帳PDFを生成（詳細版・A4 5-10ページ）
  static Future<Uint8List> generateEducationRecordPdf(
    EducationRecord record,
  ) async {
    final pdf = pw.Document();
    final dateFormatter = DateFormat('yyyy年MM月dd日');
    final timeFormatter = DateFormat('yyyy/MM/dd HH:mm');

    // フォント読み込み（日本語対応）
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    // ページ1: 表紙・基本情報
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // タイトル
              pw.Center(
                child: pw.Text(
                  '運転手教育台帳',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),

              // 基本情報
              _buildSectionTitle('【基本情報】', boldFont),
              pw.SizedBox(height: 10),
              _buildInfoRow('氏名', record.userName, font),
              _buildInfoRow('社員番号', record.userId, font),
              _buildInfoRow('会社ID', record.companyId, font),
              _buildInfoRow('入社日', dateFormatter.format(record.joinDate), font),
              _buildInfoRow('経験年数', '${record.experienceYears}年', font),
              _buildInfoRow('運転免許証', record.licenseType, font),
              if (record.licenseExpiry != null)
                _buildInfoRow(
                  '免許有効期限',
                  dateFormatter.format(record.licenseExpiry!),
                  font,
                ),
              pw.SizedBox(height: 20),

              // 作成日
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                '作成日：${dateFormatter.format(DateTime.now())}',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                '最終更新：${record.lastUpdated != null ? timeFormatter.format(record.lastUpdated!) : "未更新"}',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
            ],
          );
        },
      ),
    );

    // ページ2: 教育実績
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('【1. 教育実績】', boldFont),
              pw.SizedBox(height: 10),
              
              if (record.educationHistory.isEmpty)
                pw.Text(
                  '教育実績なし',
                  style: pw.TextStyle(font: font, fontSize: 10),
                )
              else
                _buildEducationTable(record.educationHistory, font, boldFont),
              
              pw.SizedBox(height: 20),
              
              // 統計情報
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '教育統計',
                      style: pw.TextStyle(font: boldFont, fontSize: 12),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '総受講回数：${record.educationHistory.length}回',
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                    pw.Text(
                      '総学習時間：${record.educationHistory.fold<int>(0, (sum, item) => sum + item.durationMinutes)}分',
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                    if (record.educationHistory.isNotEmpty)
                      pw.Text(
                        '平均スコア：${(record.educationHistory.fold<int>(0, (sum, item) => sum + item.score) / record.educationHistory.length).toStringAsFixed(1)}点',
                        style: pw.TextStyle(font: font, fontSize: 10),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // ページ3: 健康診断記録
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('【2. 健康診断記録】', boldFont),
              pw.SizedBox(height: 10),
              
              if (record.medicalCheckups.isEmpty)
                pw.Text(
                  '健康診断記録なし',
                  style: pw.TextStyle(font: font, fontSize: 10),
                )
              else
                ..._buildMedicalCheckupList(
                  record.medicalCheckups,
                  font,
                  boldFont,
                  dateFormatter,
                ),
            ],
          );
        },
      ),
    );

    // ページ4: 整備点検記録
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('【3. 整備点検記録】', boldFont),
              pw.SizedBox(height: 10),
              
              if (record.vehicleInspections.isEmpty)
                pw.Text(
                  '整備点検記録なし',
                  style: pw.TextStyle(font: font, fontSize: 10),
                )
              else
                _buildVehicleInspectionTable(
                  record.vehicleInspections,
                  font,
                  boldFont,
                  timeFormatter,
                ),
            ],
          );
        },
      ),
    );

    // ページ5: 休暇・勤怠記録
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('【4. 休暇・勤怠記録】', boldFont),
              pw.SizedBox(height: 10),
              
              if (record.leaveRecords.isEmpty)
                pw.Text(
                  '休暇記録なし',
                  style: pw.TextStyle(font: font, fontSize: 10),
                )
              else
                _buildLeaveRecordTable(
                  record.leaveRecords,
                  font,
                  boldFont,
                  dateFormatter,
                ),
            ],
          );
        },
      ),
    );

    // ページ6: 事故報告記録
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('【5. 事故報告記録】', boldFont),
              pw.SizedBox(height: 10),
              
              if (record.accidentRecords.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    border: pw.Border.all(color: PdfColors.green),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Text(
                    '事故報告なし（優良運転手）',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 12,
                      color: PdfColors.green900,
                    ),
                  ),
                )
              else
                _buildAccidentRecordTable(
                  record.accidentRecords,
                  font,
                  boldFont,
                  timeFormatter,
                ),
            ],
          );
        },
      ),
    );

    // ページ7: 特記事項・管理者コメント
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('【6. 特記事項・管理者コメント】', boldFont),
              pw.SizedBox(height: 10),
              
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Text(
                  record.adminNotes ?? '特記事項なし',
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
              ),
              
              pw.Spacer(),
              
              // 署名欄
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '確認者署名：',
                        style: pw.TextStyle(font: font, fontSize: 10),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: PdfColors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '確認日：',
                        style: pw.TextStyle(font: font, fontSize: 10),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: PdfColors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ヘルパー関数群

  static pw.Widget _buildSectionTitle(String title, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: boldFont,
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              '$label：',
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildEducationTable(
    List<EducationHistory> history,
    pw.Font font,
    pw.Font boldFont,
  ) {
    final dateFormatter = DateFormat('yyyy/MM/dd');
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        // ヘッダー
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('実施日', boldFont, isHeader: true),
            _buildTableCell('教育項目', boldFont, isHeader: true),
            _buildTableCell('時間', boldFont, isHeader: true),
            _buildTableCell('理解度', boldFont, isHeader: true),
          ],
        ),
        // データ行
        ...history.map((item) => pw.TableRow(
          children: [
            _buildTableCell(dateFormatter.format(item.completedAt), font),
            _buildTableCell(item.itemTitle, font),
            _buildTableCell('${item.durationMinutes}分', font),
            _buildTableCell('${item.score}点', font),
          ],
        )),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static List<pw.Widget> _buildMedicalCheckupList(
    List<MedicalCheckupRecord> checkups,
    pw.Font font,
    pw.Font boldFont,
    DateFormat dateFormatter,
  ) {
    return checkups.map((checkup) {
      final resultColor = checkup.result == '適性あり'
          ? PdfColors.green50
          : checkup.result == '要注意'
              ? PdfColors.orange50
              : PdfColors.red50;

      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 10),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: resultColor,
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '実施日：${dateFormatter.format(checkup.checkupDate)}',
              style: pw.TextStyle(font: boldFont, fontSize: 10),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              '判定：${checkup.result}',
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
            if (checkup.nextScheduled != null) ...[
              pw.SizedBox(height: 3),
              pw.Text(
                '次回予定：${dateFormatter.format(checkup.nextScheduled!)}',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
            ],
            if (checkup.notes != null) ...[
              pw.SizedBox(height: 3),
              pw.Text(
                '備考：${checkup.notes}',
                style: pw.TextStyle(font: font, fontSize: 9),
              ),
            ],
          ],
        ),
      );
    }).toList();
  }

  static pw.Widget _buildVehicleInspectionTable(
    List<VehicleInspectionRecord> inspections,
    pw.Font font,
    pw.Font boldFont,
    DateFormat timeFormatter,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('点検日時', boldFont, isHeader: true),
            _buildTableCell('OK件数', boldFont, isHeader: true),
            _buildTableCell('NG件数', boldFont, isHeader: true),
            _buildTableCell('備考', boldFont, isHeader: true),
          ],
        ),
        ...inspections.map((item) => pw.TableRow(
          children: [
            _buildTableCell(timeFormatter.format(item.inspectionDate), font),
            _buildTableCell('${item.okCount}件', font),
            _buildTableCell('${item.ngCount}件', font),
            _buildTableCell(item.notes ?? '-', font),
          ],
        )),
      ],
    );
  }

  static pw.Widget _buildLeaveRecordTable(
    List<LeaveRecord> leaves,
    pw.Font font,
    pw.Font boldFont,
    DateFormat dateFormatter,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('期間', boldFont, isHeader: true),
            _buildTableCell('種別', boldFont, isHeader: true),
            _buildTableCell('状態', boldFont, isHeader: true),
            _buildTableCell('承認者', boldFont, isHeader: true),
          ],
        ),
        ...leaves.map((item) => pw.TableRow(
          children: [
            _buildTableCell(
              '${dateFormatter.format(item.startDate)}～${dateFormatter.format(item.endDate)}',
              font,
            ),
            _buildTableCell(item.leaveType, font),
            _buildTableCell(item.status, font),
            _buildTableCell(item.approver ?? '-', font),
          ],
        )),
      ],
    );
  }

  static pw.Widget _buildAccidentRecordTable(
    List<AccidentRecord> accidents,
    pw.Font font,
    pw.Font boldFont,
    DateFormat timeFormatter,
  ) {
    return pw.Column(
      children: accidents.map((accident) {
        final severityColor = accident.severity == '軽微'
            ? PdfColors.yellow50
            : accident.severity == '通常'
                ? PdfColors.orange50
                : PdfColors.red50;

        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 10),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: severityColor,
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '発生日時：${timeFormatter.format(accident.accidentDate)}',
                style: pw.TextStyle(font: boldFont, fontSize: 10),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                '場所：${accident.location}',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                '種別：${accident.type}　重大度：${accident.severity}',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                '処理状況：${accident.status}',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
              if (accident.processingNotes != null) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  '処理メモ：${accident.processingNotes}',
                  style: pw.TextStyle(font: font, fontSize: 9),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  /// PDFをプレビュー・印刷
  static Future<void> previewPdf(Uint8List pdfData, String fileName) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdfData,
      name: fileName,
    );
  }

  /// PDFをダウンロード（Web用）
  static Future<void> downloadPdf(Uint8List pdfData, String fileName) async {
    await Printing.sharePdf(
      bytes: pdfData,
      filename: fileName,
    );
  }
}
