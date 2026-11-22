import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/transaction_item.dart';
import 'report_calculations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Colour constants (teal accent, print-safe, white background)
// ─────────────────────────────────────────────────────────────────────────────

const _teal     = PdfColor.fromInt(0xFF00897B);
const _tealLight= PdfColor.fromInt(0xFFE3F1EF);
const _red      = PdfColor.fromInt(0xFFE53935);
const _green    = PdfColor.fromInt(0xFF2E9E5B);
const _black    = PdfColor.fromInt(0xFF12302D);
const _grey     = PdfColor.fromInt(0xFF5F7A76);
const _greyLine = PdfColor.fromInt(0xFFDCE6E4);
const _white    = PdfColors.white;
const _zebra    = PdfColor.fromInt(0xFFF7F9FA);

// ─────────────────────────────────────────────────────────────────────────────
// PDF service
// ─────────────────────────────────────────────────────────────────────────────

class ReportPdfService {
  /// Builds a PDF document and returns its bytes.
  ///
  /// [currencySymbol] – e.g. '৳' or 'BDT'
  /// [periodLabel]   – e.g. 'Monthly'
  /// [rangeLabel]    – e.g. '1 Nov – 30 Nov 2026'
  static Future<Uint8List> build({
    required ReportData data,
    required String currencySymbol,
    required String periodLabel,
    required String rangeLabel,
    required String userName,
    required String userEmail,
    required bool includeBudget,
    required bool includeCategoryBreakdown,
    required bool includeIncomeExpenses,
    required bool includeAllTransactions,
  }) async {
    // ── Load bundled fonts ───────────────────────────────────────────────────
    pw.Font? baseFont;
    pw.Font? boldFont;
    pw.Font? bengaliFont;

    try {
      final regularData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final boldData    = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
      final bengaliData = await rootBundle.load('assets/fonts/NotoSansBengali-Regular.ttf');
      baseFont   = pw.Font.ttf(regularData);
      boldFont   = pw.Font.ttf(boldData);
      bengaliFont= pw.Font.ttf(bengaliData);
    } catch (_) {
      // Font files missing — fall back to built-in Helvetica.
      // Caller should show BDT instead of ৳ symbol in that case.
    }

    final theme = pw.ThemeData(
      defaultTextStyle: pw.TextStyle(
        font: baseFont,
        fontFallback: bengaliFont != null ? [bengaliFont] : [],
        fontSize: 10,
        color: _black,
      ),
    );

    final nf = NumberFormat('#,##0');
    final dtf = DateFormat('d MMM yyyy');
    final nowStr = DateFormat('d MMM yyyy, h:mm a').format(DateTime.now());

    // Helper to format amounts
    String fmt(double v) => '$currencySymbol${nf.format(v.abs().toInt())}';

    final doc = pw.Document(theme: theme);

    // ── Page format ──────────────────────────────────────────────────────────
    const pf = PdfPageFormat.a4;

    // ── Build widgets ────────────────────────────────────────────────────────
    final content = <pw.Widget>[
      _header(
        boldFont: boldFont,
        baseFont: baseFont,
        periodLabel: periodLabel,
        rangeLabel: rangeLabel,
        userName: userName,
        userEmail: userEmail,
        nowStr: nowStr,
        currencySymbol: currencySymbol,
      ),
      pw.SizedBox(height: 16),
      _summarySection(data: data, fmt: fmt, boldFont: boldFont, baseFont: baseFont),
      pw.SizedBox(height: 16),
    ];

    if (includeBudget) {
      content.add(_budgetSection(data: data, fmt: fmt, boldFont: boldFont, baseFont: baseFont));
      content.add(pw.SizedBox(height: 16));
    }
    if (includeCategoryBreakdown) {
      content.add(_categorySection(data: data, fmt: fmt, boldFont: boldFont, baseFont: baseFont));
      content.add(pw.SizedBox(height: 16));
    }
    if (includeIncomeExpenses) {
      content.add(_incomeExpensesSection(data: data, fmt: fmt, boldFont: boldFont, baseFont: baseFont));
      content.add(pw.SizedBox(height: 16));
    }
    if (includeAllTransactions) {
      content.add(_transactionsSection(data: data, fmt: fmt, boldFont: boldFont, baseFont: baseFont, dtf: dtf));
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: pf,
        margin: const pw.EdgeInsets.all(32),
        theme: theme,
        footer: (ctx) => _footer(ctx, baseFont: baseFont),
        build: (_) => content,
      ),
    );

    return doc.save();
  }

  // ── Header band ────────────────────────────────────────────────────────────

  static pw.Widget _header({
    required pw.Font? boldFont,
    required pw.Font? baseFont,
    required String periodLabel,
    required String rangeLabel,
    required String userName,
    required String userEmail,
    required String nowStr,
    required String currencySymbol,
  }) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        color: _teal,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Where Did It Go?',
                  style: pw.TextStyle(font: boldFont, fontSize: 18, color: _white)),
              pw.Text('Expense Report',
                  style: pw.TextStyle(font: baseFont, fontSize: 12, color: _white)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text('$periodLabel · $rangeLabel',
              style: pw.TextStyle(font: baseFont, fontSize: 11, color: _white)),
          pw.SizedBox(height: 4),
          pw.Text('Prepared for: $userName ($userEmail)',
              style: pw.TextStyle(font: baseFont, fontSize: 10, color: _white)),
          pw.Text('Generated: $nowStr  ·  Currency: $currencySymbol',
              style: pw.TextStyle(font: baseFont, fontSize: 10, color: _white)),
        ],
      ),
    );
  }

  // ── Summary section ────────────────────────────────────────────────────────

  static pw.Widget _summarySection({
    required ReportData data,
    required String Function(double) fmt,
    required pw.Font? boldFont,
    required pw.Font? baseFont,
  }) {
    final savingsStr = data.savingsRatePct != null
        ? '${data.savingsRatePct!.toStringAsFixed(1)}%'
        : 'n/a';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Summary', boldFont: boldFont),
        pw.SizedBox(height: 8),
        // Four summary cards
        pw.Row(
          children: [
            pw.Expanded(child: _summaryCard('Earned', fmt(data.totalIncome), _green, boldFont: boldFont, baseFont: baseFont)),
            pw.SizedBox(width: 8),
            pw.Expanded(child: _summaryCard('Spent', fmt(data.totalExpenses), _red, boldFont: boldFont, baseFont: baseFont)),
            pw.SizedBox(width: 8),
            pw.Expanded(child: _summaryCard('Net', fmt(data.net), data.net >= 0 ? _green : _red, boldFont: boldFont, baseFont: baseFont)),
            pw.SizedBox(width: 8),
            pw.Expanded(child: _summaryCard('Transactions', '${data.transactionCount}', _teal, boldFont: boldFont, baseFont: baseFont)),
          ],
        ),
        pw.SizedBox(height: 10),
        // Insight lines
        if (data.topCategory != null)
          _insightLine('Top category: ${data.topCategory}  —  ${fmt(data.topCategoryAmount)} (${data.topCategorySharePct.toStringAsFixed(1)}%)', baseFont: baseFont),
        if (data.largestExpense != null)
          _insightLine('Largest expense: ${data.largestExpense!.title}  ${DateFormat('d MMM yyyy').format(data.largestExpense!.date)}  ${fmt(data.largestExpense!.amount)}', baseFont: baseFont),
        _insightLine('Avg daily spending: ${fmt(data.avgSpendingPerDay)}', baseFont: baseFont),
        _insightLine('Savings rate: $savingsStr', baseFont: baseFont),
      ],
    );
  }

  static pw.Widget _summaryCard(String label, String value, PdfColor accent, {pw.Font? boldFont, pw.Font? baseFont}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _greyLine),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(font: baseFont, fontSize: 9, color: _grey)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(font: boldFont, fontSize: 11, color: accent)),
        ],
      ),
    );
  }

  static pw.Widget _insightLine(String text, {pw.Font? baseFont}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          pw.Container(width: 4, height: 4, decoration: const pw.BoxDecoration(color: _teal, shape: pw.BoxShape.circle)),
          pw.SizedBox(width: 6),
          pw.Expanded(child: pw.Text(text, style: pw.TextStyle(font: baseFont, fontSize: 9, color: _grey))),
        ],
      ),
    );
  }

  // ── Budget section ─────────────────────────────────────────────────────────

  static pw.Widget _budgetSection({
    required ReportData data,
    required String Function(double) fmt,
    required pw.Font? boldFont,
    required pw.Font? baseFont,
  }) {
    pw.Widget body;
    switch (data.budgetStatus) {
      case BudgetStatus.multiMonth:
        body = pw.Text('Budget: not applicable to multi-month ranges.', style: pw.TextStyle(font: baseFont, fontSize: 10, color: _grey));
        break;
      case BudgetStatus.nobudget:
        body = pw.Text('No budget set for this period.', style: pw.TextStyle(font: baseFont, fontSize: 10, color: _grey));
        break;
      default:
        final statusLabel = data.budgetStatus == BudgetStatus.overBudget
            ? 'Over budget'
            : data.budgetStatus == BudgetStatus.nearLimit
                ? 'Near limit'
                : 'On track';
        final statusColor = data.budgetStatus == BudgetStatus.overBudget
            ? _red
            : data.budgetStatus == BudgetStatus.nearLimit
                ? PdfColors.orange
                : _green;
        final barFill = (data.budgetUsagePct / 100).clamp(0.0, 1.0);
        body = pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Limit: ${fmt(data.budgetLimit)}', style: pw.TextStyle(font: baseFont, fontSize: 10)),
                pw.Text('Spent: ${fmt(data.budgetSpent)}', style: pw.TextStyle(font: baseFont, fontSize: 10)),
                pw.Text('Remaining: ${fmt(data.budgetRemaining)}', style: pw.TextStyle(font: baseFont, fontSize: 10)),
                pw.Text('${data.budgetUsagePct.toStringAsFixed(1)}% used', style: pw.TextStyle(font: baseFont, fontSize: 10)),
              ],
            ),
            pw.SizedBox(height: 6),
            // Progress bar
            pw.LayoutBuilder(
              builder: (_, constraints) {
                final maxW = constraints?.maxWidth ?? 400.0;
                final barW = (maxW * barFill).clamp(0.0, maxW);
                return pw.Stack(
                  children: [
                    pw.Container(height: 8, width: maxW, decoration: pw.BoxDecoration(color: _greyLine, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)))),
                    pw.Container(height: 8, width: barW, decoration: pw.BoxDecoration(color: statusColor, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)))),
                  ],
                );
              },
            ),
            pw.SizedBox(height: 4),
            pw.Text(statusLabel, style: pw.TextStyle(font: boldFont, fontSize: 10, color: statusColor)),
          ],
        );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Budget Overview', boldFont: boldFont),
        pw.SizedBox(height: 8),
        body,
      ],
    );
  }

  // ── Category breakdown ─────────────────────────────────────────────────────

  static pw.Widget _categorySection({
    required ReportData data,
    required String Function(double) fmt,
    required pw.Font? boldFont,
    required pw.Font? baseFont,
  }) {
    if (data.categoryRows.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle('Spending by Category', boldFont: boldFont),
          pw.SizedBox(height: 8),
          pw.Text('No expense data.', style: pw.TextStyle(font: baseFont, fontSize: 10, color: _grey)),
        ],
      );
    }

    final headers = ['Category', 'Transactions', 'Amount', 'Share %', 'Bar'];
    final rows = data.categoryRows.map((r) => [
      r.name,
      '${r.transactionCount}',
      fmt(r.amount),
      '${r.sharePct.toStringAsFixed(1)}%',
      '',
    ]).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Spending by Category', boldFont: boldFont),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: _greyLine, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(3),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _tealLight),
              children: headers.map((h) => _cell(h, boldFont: boldFont, isHeader: true)).toList(),
            ),
            ...List.generate(rows.length, (i) {
              final r = data.categoryRows[i];
              final fill = (r.sharePct / 100).clamp(0.0, 1.0);
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: i.isOdd ? _zebra : _white),
                children: [
                  _cell(r.name, baseFont: baseFont),
                  _cell('${r.transactionCount}', baseFont: baseFont),
                  _cell(fmt(r.amount), baseFont: baseFont),
                  _cell('${r.sharePct.toStringAsFixed(1)}%', baseFont: baseFont),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: pw.LayoutBuilder(
                      builder: (_, constraints) {
                        final maxW = constraints?.maxWidth ?? 100.0;
                        final barW = (maxW * fill).clamp(0.0, maxW);
                        return pw.Stack(
                          children: [
                            pw.Container(height: 6, width: maxW, decoration: pw.BoxDecoration(color: _greyLine, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)))),
                            pw.Container(height: 6, width: barW, decoration: pw.BoxDecoration(color: _teal, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)))),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  // ── Income vs Expenses ─────────────────────────────────────────────────────

  static pw.Widget _incomeExpensesSection({
    required ReportData data,
    required String Function(double) fmt,
    required pw.Font? boldFont,
    required pw.Font? baseFont,
  }) {
    if (data.bucketRows.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle('Income vs Expenses', boldFont: boldFont),
          pw.SizedBox(height: 8),
          pw.Text('No data.', style: pw.TextStyle(font: baseFont, fontSize: 10, color: _grey)),
        ],
      );
    }

    final maxVal = data.bucketRows.fold(0.0, (m, r) => [m, r.income, r.expenses].reduce((a, b) => a > b ? a : b));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Income vs Expenses', boldFont: boldFont),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: _greyLine, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(3),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _tealLight),
              children: ['Period', 'Income', 'Expenses', 'Net', 'Bar']
                  .map((h) => _cell(h, boldFont: boldFont, isHeader: true))
                  .toList(),
            ),
            ...List.generate(data.bucketRows.length, (i) {
              final r = data.bucketRows[i];
              final inFill = maxVal > 0 ? (r.income / maxVal).clamp(0.0, 1.0) : 0.0;
              final exFill = maxVal > 0 ? (r.expenses / maxVal).clamp(0.0, 1.0) : 0.0;
              final netColor = r.net >= 0 ? _green : _red;
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: i.isOdd ? _zebra : _white),
                children: [
                  _cell(r.label, baseFont: baseFont),
                  _cell(fmt(r.income), baseFont: baseFont, color: _green),
                  _cell(fmt(r.expenses), baseFont: baseFont, color: _red),
                  _cell(fmt(r.net), baseFont: baseFont, color: netColor),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _miniBar(inFill, _green),
                        pw.SizedBox(height: 2),
                        _miniBar(exFill, _red),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  // ── All transactions ───────────────────────────────────────────────────────

  static pw.Widget _transactionsSection({
    required ReportData data,
    required String Function(double) fmt,
    required pw.Font? boldFont,
    required pw.Font? baseFont,
    required DateFormat dtf,
  }) {
    final txns = List<TransactionItem>.from(data.transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalIncome   = txns.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final totalExpenses = txns.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final totalNet      = totalIncome - totalExpenses;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('All Transactions', boldFont: boldFont),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: _greyLine, width: 0.5),
          headerDecoration: const pw.BoxDecoration(color: _tealLight),
          headerStyle: pw.TextStyle(font: boldFont, fontSize: 9, color: _black),
          cellStyle: pw.TextStyle(font: baseFont, fontSize: 9, color: _black),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerLeft,
            3: pw.Alignment.center,
            4: pw.Alignment.centerLeft,
            5: pw.Alignment.centerRight,
          },
          columnWidths: {
            0: const pw.FlexColumnWidth(1.8),
            1: const pw.FlexColumnWidth(2.5),
            2: const pw.FlexColumnWidth(1.8),
            3: const pw.FlexColumnWidth(1.2),
            4: const pw.FlexColumnWidth(2.5),
            5: const pw.FlexColumnWidth(1.5),
          },
          headers: ['Date', 'Title', 'Category', 'Type', 'Note', 'Amount'],
          data: [
            ...List.generate(txns.length, (i) {
              final t = txns[i];
              return [
                dtf.format(t.date),
                t.title,
                t.categoryId, // caller passes resolved name? We use categoryId here (service has no category map)
                t.isIncome ? 'Income' : 'Expense',
                t.note ?? '',
                '${t.isIncome ? '+' : '-'}${fmt(t.amount)}',
              ];
            }),
            // Totals row
            ['', '', '', '', 'TOTALS',
              'In: ${fmt(totalIncome)} | Out: ${fmt(totalExpenses)} | Net: ${totalNet >= 0 ? '+' : ''}${fmt(totalNet)}'],
          ],
          oddRowDecoration: const pw.BoxDecoration(color: _zebra),
        ),
      ],
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  static pw.Widget _footer(pw.Context ctx, {pw.Font? baseFont}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Where Did It Go?', style: pw.TextStyle(font: baseFont, fontSize: 9, color: _grey)),
        pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: pw.TextStyle(font: baseFont, fontSize: 9, color: _grey)),
      ],
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  static pw.Widget _sectionTitle(String text, {pw.Font? boldFont}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(text, style: pw.TextStyle(font: boldFont, fontSize: 13, color: _teal)),
        pw.Divider(color: _tealLight, thickness: 1),
      ],
    );
  }

  static pw.Widget _cell(
    String text, {
    pw.Font? boldFont,
    pw.Font? baseFont,
    bool isHeader = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: isHeader ? boldFont : baseFont,
          fontSize: 9,
          color: color ?? (isHeader ? _black : _black),
        ),
      ),
    );
  }

  static pw.Widget _miniBar(double fill, PdfColor color) {
    return pw.LayoutBuilder(
      builder: (_, constraints) {
        final maxW = constraints?.maxWidth ?? 60.0;
        final barW = (maxW * fill).clamp(0.0, maxW);
        return pw.Stack(
          children: [
            pw.Container(height: 5, width: maxW, decoration: pw.BoxDecoration(color: _greyLine, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)))),
            pw.Container(height: 5, width: barW, decoration: pw.BoxDecoration(color: color, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)))),
          ],
        );
      },
    );
  }
}
