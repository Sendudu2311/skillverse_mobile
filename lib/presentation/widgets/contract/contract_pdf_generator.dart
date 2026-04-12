import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import '../../../data/models/contract_models.dart';

/// Formal Vietnamese Labor-Law-Compliant PDF generator for Job Contracts.
///
/// Mirrors the Prototype's `ContractHTMLGenerator.ts` layout:
///   Page 1: Quốc hiệu → Title → Parties Table → Overview
///   Content: Clauses by contract type (PROBATION / FULL_TIME / PART_TIME)
///   Final:   Signature section
///   All:     3-column footer (Title | Contract Number | Page X)
class ContractPdfGeneratorWidget {
  ContractPdfGeneratorWidget._();

  // ==================== COLORS ====================
  static const _ink = PdfColor.fromInt(0xFF000000);
  static const _muted = PdfColor.fromInt(0xFF4A4A4A);
  static const _panelStrong = PdfColor.fromInt(0xFFF5F5F5);

  static final _currencyFmt =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  // ==================== PUBLIC API ====================

  static Future<Uint8List> generateContractPdf({
    required ContractResponse contract,
  }) async {
    final fontData = await rootBundle.load('assets/fonts/Roboto-Variable.ttf');
    final font = pw.Font.ttf(fontData);

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: font, italic: font),
    );

    // Fetch signature images
    final employerSigImg = await _fetchImage(
        contract.employerSignature?.signatureImageUrl);
    final candidateSigImg = await _fetchImage(
        contract.candidateSignature?.signatureImageUrl);

    final contractNumber = contract.contractNumber ??
        'HD-${DateTime.now().year}-${contract.id.toString().padLeft(4, '0')}';
    final contractTitle = _getContractTitle(contract.contractType);
    final contractTitleEn = _getContractTitleEn(contract.contractType);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.only(
            left: 40, right: 40, top: 45, bottom: 45),
        header: (_) => pw.SizedBox.shrink(),
        footer: (ctx) => _buildFooter(
            ctx, contractTitle, contractNumber),
        build: (ctx) => [
          // ===== PAGE 1: Header =====
          _buildQuocHieu(),
          pw.SizedBox(height: 8),
          _buildContractMeta(contractNumber),
          pw.Divider(thickness: 2, color: _ink),
          pw.SizedBox(height: 8),
          _buildTitle(contractTitle, contractTitleEn),
          pw.SizedBox(height: 14),
          _buildIntro(contract),
          pw.SizedBox(height: 10),
          _buildPartiesTable(contract),
          pw.SizedBox(height: 10),
          _buildOverviewSummary(contract),
          pw.SizedBox(height: 6),
          _buildSalaryBox(contract),
          pw.SizedBox(height: 14),

          // ===== CLAUSES =====
          ..._buildClauses(contract),

          // ===== SIGNATURE =====
          pw.SizedBox(height: 24),
          _buildSignatureSection(
              contract, employerSigImg, candidateSigImg),
        ],
      ),
    );

    return doc.save();
  }

  // ==================== HEADER & FOOTER ====================

  static pw.Widget _buildQuocHieu() {
    return pw.Center(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM',
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.5),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Độc lập - Tự do - Hạnh phúc',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildContractMeta(String contractNumber) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Số: $contractNumber',
            style: pw.TextStyle(
                fontSize: 11, fontStyle: pw.FontStyle.italic, color: _ink),
          ),
          pw.Text(
            'Ngày ký: ${_fmtDate(DateTime.now().toIso8601String())}',
            style: pw.TextStyle(
                fontSize: 11, fontStyle: pw.FontStyle.italic, color: _ink),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTitle(String title, String titleEn) {
    return pw.Center(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(height: 16),
          pw.Text(
            title,
            style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.5),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            titleEn,
            style: pw.TextStyle(
                fontSize: 12, fontStyle: pw.FontStyle.italic, color: _muted),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(
      pw.Context ctx, String title, String contractNumber) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _ink, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(title,
                style: const pw.TextStyle(fontSize: 9, color: _ink)),
          ),
          pw.Expanded(
            child: pw.Text('Số: $contractNumber',
                style: pw.TextStyle(
                    fontSize: 9,
                    fontStyle: pw.FontStyle.italic,
                    color: _ink),
                textAlign: pw.TextAlign.center),
          ),
          pw.Expanded(
            child: pw.Text(
                'Trang ${ctx.pageNumber}/${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 9, color: _ink),
                textAlign: pw.TextAlign.right),
          ),
        ],
      ),
    );
  }

  // ==================== INTRO & PARTIES ====================

  static pw.Widget _buildIntro(ContractResponse c) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _clauseText(
            'Căn cứ Bộ luật Lao động nước Cộng hòa xã hội chủ nghĩa Việt Nam năm 2019;'),
        _clauseText('Căn cứ nhu cầu và năng lực của hai bên,'),
        pw.SizedBox(height: 4),
        pw.RichText(
          text: pw.TextSpan(
            style: const pw.TextStyle(fontSize: 12, color: _ink),
            children: [
              const pw.TextSpan(text: 'Hôm nay, ngày '),
              pw.TextSpan(
                text: _fmtDate(DateTime.now().toIso8601String()),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              const pw.TextSpan(text: ', tại '),
              pw.TextSpan(
                text: _norm(c.employerAddress),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              const pw.TextSpan(text: ','),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        _clauseText('Chúng tôi gồm:'),
      ],
    );
  }

  static pw.Widget _buildPartiesTable(ContractResponse c) {
    return pw.Table(
      border: pw.TableBorder.all(color: _ink),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _panelStrong),
          children: [
            _tableHeaderCell('BÊN A - NGƯỜI SỬ DỤNG\nLAO ĐỘNG'),
            _tableHeaderCell('BÊN B - NGƯỜI LAO ĐỘNG'),
          ],
        ),
        // Data row
        pw.TableRow(
          children: [
            // Bên A
            pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _partyField('Tên công ty', _norm(c.employerCompanyName)),
                  _partyField('Địa chỉ', _norm(c.employerAddress)),
                  if (c.employerTaxId != null)
                    _partyField('Mã số thuế', c.employerTaxId!),
                  _partyField('Đại diện', _norm(c.employerName)),
                  _partyField('Email', _norm(c.employerEmail)),
                ],
              ),
            ),
            // Bên B
            pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _partyField('Họ và tên', _norm(c.candidateName)),
                  _partyField('Chức danh', _norm(c.candidatePosition)),
                  _partyField('Email', _norm(c.candidateEmail)),
                  if (c.candidatePhone != null)
                    _partyField('Điện thoại', c.candidatePhone!),
                  if (c.candidateDateOfBirth != null)
                    _partyField('Ngày sinh', _fmtDate(c.candidateDateOfBirth!)),
                  if (c.candidateIdCardNumber != null)
                    _partyField('Số CCCD', c.candidateIdCardNumber!),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildOverviewSummary(ContractResponse c) {
    final position = _norm(c.candidatePosition ?? c.jobTitle);
    final location = _norm(c.workingLocation);
    final startDate = c.startDate != null ? _fmtDate(c.startDate!) : '—';
    final endDate = c.endDate != null ? _fmtDate(c.endDate!) : '—';
    final probMonths =
        c.probationMonths != null ? '${c.probationMonths} tháng' : '—';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Điều khoản chung',
            style: pw.TextStyle(
                fontSize: 12, fontWeight: pw.FontWeight.bold, color: _ink)),
        pw.SizedBox(height: 6),
        _overviewRow('Công việc', position),
        _overviewRow('Địa điểm làm việc', location),
        _overviewRow('Ngày bắt đầu', startDate),
        _overviewRow('Ngày kết thúc', endDate),
        _overviewRow('Thời gian thử việc', probMonths),
      ],
    );
  }

  static pw.Widget _buildSalaryBox(ContractResponse c) {
    final sal = c.contractType == ContractType.probation
        ? (c.probationSalary ?? c.salary ?? 0)
        : (c.salary ?? 0);
    final salText = c.contractType == ContractType.probation
        ? (c.probationSalaryText ?? c.salaryText)
        : c.salaryText;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _ink, width: 2),
      ),
      child: pw.Column(
        children: [
          pw.Text('Mức lương hàng tháng',
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold, color: _ink)),
          pw.SizedBox(height: 8),
          pw.Text(
            _currencyFmt.format(sal),
            style: pw.TextStyle(
                fontSize: 18, fontWeight: pw.FontWeight.bold, color: _ink),
          ),
          if (salText != null && salText.trim().isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Bằng chữ: $salText',
              style: pw.TextStyle(
                  fontSize: 11, fontStyle: pw.FontStyle.italic, color: _ink),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== CLAUSES ====================

  static List<pw.Widget> _buildClauses(ContractResponse c) {
    switch (c.contractType) {
      case ContractType.probation:
        return _genProbClauses(c);
      case ContractType.fullTime:
        return _genFullClauses(c);
      case ContractType.partTime:
        return _genPartClauses(c);
      default:
        return _genFullClauses(c);
    }
  }

  // ===== PROBATION =====
  static List<pw.Widget> _genProbClauses(ContractResponse c) {
    final position = _norm(c.candidatePosition);
    final location = _norm(c.workingLocation);
    final startDate = c.startDate != null ? _fmtDate(c.startDate!) : '—';
    final endDate = c.endDate != null ? _fmtDate(c.endDate!) : '—';
    final probMonths = c.probationMonths ?? 1;
    final termDays = c.terminationNoticeDays ?? 30;

    return [
      _clauseTitle('Điều 1: Nội dung công việc'),
      _clauseText(
          'Bên B được giao thực hiện công việc với vị trí $position tại $location, thời gian thử việc tính từ ngày $startDate.'),
      if (c.jobDescription != null) _clauseBlock('Mô tả công việc', c.jobDescription!),
      if (c.probationObjectives != null)
        _clauseBlock('Mục tiêu thử việc', c.probationObjectives!),
      if (c.probationEvaluationCriteria != null)
        _clauseBlock('Tiêu chí đánh giá', c.probationEvaluationCriteria!),

      _clauseTitle('Điều 2: Thời hạn hợp đồng thử việc'),
      _clauseText(
          'Thời gian thử việc: $probMonths tháng, tối đa không quá 60 ngày (BLL 2019 Điều 27).'),
      _clauseText('Ngày bắt đầu: $startDate - Ngày kết thúc: $endDate.'),
      _clauseText(
          'Mỗi bên có quyền chấm dứt trước thời hạn với thời hạn báo trước là $termDays ngày làm việc.'),

      _clauseTitle('Điều 3: Tiền lương và thanh toán'),
      _clauseText(
          'Mức lương thử việc: ${_currencyFmt.format(c.probationSalary ?? c.salary ?? 0)} / tháng.'),
      _clauseText(
          'Hình thức trả lương: ${_paymentLabel(c.paymentMethod)}.'),
      _clauseText(
          'Ngày trả lương: Ngày ${c.salaryPaymentDate ?? 10} hàng tháng.'),

      _clauseTitle('Điều 4: Phụ cấp & Lợi ích trong thử việc'),
      _clauseText(
          'Lưu ý: Trong thời gian thử việc, Bên B không phải tham gia BHXH, BHTN theo quy định pháp luật hiện hành.'),
      _clauseText(
          'Bên B được hưởng chế độ nghỉ phép năm: ${c.annualLeaveDays ?? 0} ngày.'),

      _clauseTitle('Điều 5: Chấm dứt hợp đồng thử việc'),
      _clauseText(
          'Quyền của Bên A: Đơn phương chấm dứt nếu Bên B không đáp ứng yêu cầu công việc, với thời hạn báo trước $termDays ngày làm việc.'),
      _clauseText(
          'Quyền của Bên B: Đơn phương chấm dứt với thời hạn báo trước $termDays ngày làm việc.'),

      _clauseTitle('Điều 6: Điều khoản bổ sung'),
      if (c.legalText != null)
        _clauseText(c.legalText!)
      else
        _clauseText(
            'Các điều khoản bổ sung (nếu có) sẽ được ghi nhận tại Phụ lục hợp đồng đính kèm.'),
    ];
  }

  // ===== FULL TIME =====
  static List<pw.Widget> _genFullClauses(ContractResponse c) {
    final position = _norm(c.candidatePosition);
    final location = _norm(c.workingLocation);
    final sal = _fmtVnd(c.salary);
    final salText = c.salaryText ?? '—';
    final payDate = c.salaryPaymentDate ?? 10;
    final payMethod = _paymentLabel(c.paymentMethod);
    final whDay = c.workingHoursPerDay ?? 8;
    final whWeek = c.workingHoursPerWeek ?? 40;
    final annualLeave = c.annualLeaveDays ?? 12;
    final termDays = c.terminationNoticeDays ?? 30;
    final insurance =
        c.insurancePolicy ?? 'Theo quy định pháp luật hiện hành.';

    return [
      _clauseTitle('Điều 1. Nghĩa vụ của Người Lao động (Bên B)'),
      _clauseText('Vị trí công việc: $position. Địa điểm làm việc: $location.'),
      if (c.jobDescription != null) _clauseText(c.jobDescription!),
      _bulletList([
        'Thực hiện công việc đúng vị trí, chức danh, địa điểm đã thỏa thuận.',
        'Tuân thủ nội quy lao động, quy chế và các quy định nội bộ của Bên A.',
        'Hoàn thành công việc đúng tiến độ, đảm bảo chất lượng theo yêu cầu.',
        'Bảo vệ tài sản, bí quyết công nghệ và thông tin của Bên A.',
      ]),

      _clauseTitle('Điều 2. Nghĩa vụ của Người sử dụng Lao động (Bên A)'),
      _bulletList([
        'Cung cấp đầy đủ việc làm, điều kiện cần thiết để Bên B hoàn thành công việc.',
        'Trả lương đúng hạn, đầy đủ theo thỏa thuận tại Điều 4 hợp đồng này.',
        'Đóng BHXH, BHYT, BHTN theo quy định pháp luật. Chi tiết: $insurance',
        'Đảm bảo an toàn, vệ sinh lao động tại nơi làm việc.',
        'Tôn trọng danh dự, nhân phẩm của Bên B; không phân biệt đối xử.',
      ]),

      _clauseTitle('Điều 3. Thời giờ làm việc và thời giờ nghỉ ngơi'),
      _bulletList([
        'Thời giờ làm việc: $whDay giờ/ngày, $whWeek giờ/tuần (theo Điều 104 BLL 2019).',
        if (c.workingSchedule != null) 'Ca làm việc: ${c.workingSchedule}.',
        'Nghỉ hằng tuần: ít nhất 01 ngày vào cuối tuần.',
        'Nghỉ phép năm: $annualLeave ngày làm việc (theo Điều 113 BLL 2019).',
      ]),
      if (c.remoteWorkPolicy != null)
        _clauseBlock('Chính sách làm việc từ xa (WFH)', c.remoteWorkPolicy!),

      _clauseTitle('Điều 4. Tiền lương và phương thức thanh toán'),
      _clauseText('Mức lương: $sal${salText != '—' ? ' ($salText)' : ''}.'),
      _clauseText('Ngày thanh toán lương: Ngày $payDate hàng tháng.'),
      _clauseText('Phương thức thanh toán: $payMethod.'),
      _clauseText('Phụ cấp ăn: ${_fmtVnd(c.mealAllowance)}'),
      _clauseText('Phụ cấp đi lại: ${_fmtVnd(c.transportAllowance)}'),
      _clauseText('Phụ cấp nhà ở: ${_fmtVnd(c.housingAllowance)}'),
      if (c.bonusPolicy != null)
        _clauseBlock('Chính sách thưởng', c.bonusPolicy!),

      _clauseTitle('Điều 5. Đào tạo và phúc lợi'),
      if (c.trainingPolicy != null) _clauseText(c.trainingPolicy!),
      if (c.otherBenefits != null)
        _clauseBlock('Các phúc lợi khác', c.otherBenefits!),
      if (c.trainingPolicy == null && c.otherBenefits == null)
        _clauseText(
            'Các chế độ đào tạo, phúc lợi (nếu có) được thực hiện theo quy chế của Bên A.'),

      _clauseTitle('Điều 6. Bảo mật thông tin và sở hữu trí tuệ'),
      _clauseText(c.confidentialityClause ??
          'Bên B cam kết bảo mật mọi thông tin liên quan đến hoạt động kinh doanh, kỹ thuật, tài chính và khách hàng của Bên A. Nghĩa vụ bảo mật có hiệu lực trong thời gian làm việc và vô thời hạn sau khi chấm dứt hợp đồng lao động.'),
      _clauseText(c.ipClause ??
          'Các sáng chế, sáng kiến, thiết kế, bản quyền do Bên B tạo ra trong quá trình thực hiện công việc thuộc quyền sở hữu của Bên A.'),

      _clauseTitle('Điều 7. Trách nhiệm cạnh tranh'),
      if (c.nonCompeteClause != null)
        _clauseText(
            'Có điều khoản cạnh tranh.${c.nonCompeteDurationMonths != null ? ' Thời gian: ${c.nonCompeteDurationMonths} tháng.' : ''}')
      else
        _clauseText(
            'Trong thời gian làm việc và sau khi nghỉ việc, Bên B không được làm việc cho các tổ chức cạnh tranh trực tiếp với Bên A khi chưa được sự đồng ý bằng văn bản.'),

      _clauseTitle('Điều 8. Chấm dứt hợp đồng lao động'),
      _clauseText(
          'Thời hạn báo trước khi đơn phương chấm dứt hợp đồng: ít nhất $termDays ngày (theo Điều 35, Điều 36 BLL 2019).'),
      if (c.terminationClause != null) _clauseText(c.terminationClause!),
      _bulletList([
        'Hai bên thỏa thuận chấm dứt hợp đồng lao động.',
        'Đơn phương chấm dứt theo Điều 35 và Điều 36 BLL 2019.',
        'Bên A đơn phương chấm dứt do Bên B vi phạm kỷ luật lao động (Điều 125 BLL 2019).',
        'Hết thời hạn ghi trong hợp đồng (đối với hợp đồng xác định thời hạn).',
      ]),

      _clauseTitle('Điều 9. Giải quyết tranh chấp lao động'),
      _clauseText(
          'Tranh chấp phát sinh từ hợp đồng này được giải quyết thông qua thương lượng, hòa giải giữa hai bên trên tinh thần thiện chí và hợp tác. Trường hợp không thể thương lượng, các bên có quyền yêu cầu giải quyết tại Tòa án nhân dân có thẩm quyền theo quy định pháp luật.'),

      _clauseTitle('Điều 10. Điều khoản bổ sung'),
      if (c.legalText != null)
        _clauseText(c.legalText!)
      else
        _clauseText(
            'Các điều khoản bổ sung (nếu có) sẽ được ghi nhận tại Phụ lục hợp đồng đính kèm, có giá trị pháp lý như hợp đồng này.'),
    ];
  }

  // ===== PART TIME =====
  static List<pw.Widget> _genPartClauses(ContractResponse c) {
    final position = _norm(c.candidatePosition);
    final startDate = c.startDate != null ? _fmtDate(c.startDate!) : '—';
    final endDate = c.endDate != null ? _fmtDate(c.endDate!) : '—';
    final sal = _fmtVnd(c.salary);
    final salText = c.salaryText ?? '—';
    final payDate = c.salaryPaymentDate ?? 10;
    final payMethod = _paymentLabel(c.paymentMethod);
    final whDay = c.workingHoursPerDay ?? 4;
    final whWeek = c.workingHoursPerWeek != null
        ? (c.workingHoursPerWeek! / 2).round()
        : 20;
    final termDays = c.terminationNoticeDays ?? 15;

    return [
      _clauseTitle('Điều 1. Nội dung và thời hạn công việc'),
      _clauseText(
          'Bên B được giao thực hiện công việc với vị trí: $position.'),
      _clauseText('Thời gian: Từ ngày $startDate đến ngày $endDate.'),
      if (c.jobDescription != null) _clauseText(c.jobDescription!),

      _clauseTitle('Điều 2. Thời giờ làm việc'),
      _clauseText(
          'Bên B làm việc không quá $whWeek giờ/tuần và không quá $whDay giờ/ngày (theo Điều 143 BLL 2019).'),
      if (c.workingSchedule != null)
        _clauseText('Ca làm việc: ${c.workingSchedule}.'),

      _clauseTitle('Điều 3. Tiền lương và phương thức thanh toán'),
      _clauseText('Mức lương: $sal${salText != '—' ? ' ($salText)' : ''}.'),
      _clauseText('Ngày thanh toán lương: Ngày $payDate hàng tháng.'),
      _clauseText('Phương thức thanh toán: $payMethod.'),
      _clauseText('Phụ cấp ăn: ${_fmtVnd(c.mealAllowance)}'),
      _clauseText('Phụ cấp đi lại: ${_fmtVnd(c.transportAllowance)}'),

      _clauseTitle('Điều 4. Quyền và nghĩa vụ'),
      _clauseText(
          'Bên B được hưởng các quyền và thực hiện nghĩa vụ tương tự lao động toàn thời gian, phù hợp với tính chất công việc bán thời gian, theo quy định tại Chương XI BLL 2019.'),
      if (c.annualLeaveDays != null)
        _clauseText(
            'Nghỉ phép năm: ${c.annualLeaveDays} ngày/năm (tính theo tỷ lệ thời gian).'),

      _clauseTitle('Điều 5. Bảo mật thông tin và sở hữu trí tuệ'),
      _clauseText(c.confidentialityClause ??
          'Bên B cam kết bảo mật mọi thông tin liên quan đến hoạt động kinh doanh, kỹ thuật, tài chính và khách hàng của Bên A.'),

      _clauseTitle('Điều 6. Chấm dứt hợp đồng lao động'),
      _clauseText(
          'Thời hạn báo trước khi đơn phương chấm dứt hợp đồng: ít nhất $termDays ngày (theo Điều 35, Điều 36 BLL 2019).'),
      if (c.terminationClause != null) _clauseText(c.terminationClause!),

      _clauseTitle('Điều 7. Điều khoản bổ sung'),
      if (c.legalText != null)
        _clauseText(c.legalText!)
      else
        _clauseText(
            'Các điều khoản bổ sung (nếu có) sẽ được ghi nhận tại Phụ lục hợp đồng đính kèm.'),
    ];
  }

  // ==================== SIGNATURE ====================

  static pw.Widget _buildSignatureSection(
    ContractResponse c,
    pw.MemoryImage? employerSig,
    pw.MemoryImage? candidateSig,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _ink),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        children: [
          pw.Text(
            'XÁC NHẬN VÀ CHỮ KÝ CÁC BÊN',
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Hai bên đã đọc, hiểu rõ toàn bộ nội dung hợp đồng, cam kết thực hiện đúng các điều khoản đã thỏa thuận và chịu trách nhiệm trước pháp luật về cam kết của mình.',
            style: const pw.TextStyle(fontSize: 11, color: _ink),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Bên A
              pw.Expanded(
                child: _signatureColumn(
                  title: 'ĐẠI DIỆN BÊN A',
                  subtitle: _norm(c.employerCompanyName),
                  sigImage: employerSig,
                  name: _norm(c.employerName),
                  signedAt: c.employerSignature?.signedAt,
                ),
              ),
              pw.SizedBox(width: 20),
              // Bên B
              pw.Expanded(
                child: _signatureColumn(
                  title: 'NGƯỜI LAO ĐỘNG (BÊN B)',
                  subtitle: _norm(c.candidatePosition, fallback: 'Người lao động'),
                  sigImage: candidateSig,
                  name: _norm(c.candidateName),
                  signedAt: c.candidateSignature?.signedAt,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Hợp đồng được lập thành 02 bản có giá trị pháp lý như nhau, mỗi bên giữ 01 bản để thực hiện.',
            style: pw.TextStyle(
                fontSize: 10,
                fontStyle: pw.FontStyle.italic,
                color: _muted),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static pw.Widget _signatureColumn({
    required String title,
    required String subtitle,
    pw.MemoryImage? sigImage,
    required String name,
    String? signedAt,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(title,
            style: pw.TextStyle(
                fontSize: 12, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center),
        pw.SizedBox(height: 3),
        pw.Text(subtitle,
            style: pw.TextStyle(
                fontSize: 10,
                fontStyle: pw.FontStyle.italic,
                color: _muted),
            textAlign: pw.TextAlign.center),
        pw.SizedBox(height: 12),
        if (sigImage != null)
          pw.Container(
            height: 60,
            alignment: pw.Alignment.center,
            child: pw.Image(sigImage, fit: pw.BoxFit.contain),
          )
        else
          pw.Container(
            height: 60,
            alignment: pw.Alignment.center,
            child: pw.Container(
              width: 120,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                    top: pw.BorderSide(
                        color: _ink,
                        width: 0.5,
                        style: pw.BorderStyle.dashed)),
              ),
            ),
          ),
        pw.SizedBox(height: 8),
        pw.Text(name,
            style: pw.TextStyle(
                fontSize: 12, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center),
        if (signedAt != null) ...[
          pw.SizedBox(height: 3),
          pw.Text('Ngày ký: ${_fmtDate(signedAt)}',
              style: pw.TextStyle(fontSize: 10, color: _muted),
              textAlign: pw.TextAlign.center),
        ],
      ],
    );
  }

  // ==================== WIDGET HELPERS ====================

  static pw.Widget _clauseTitle(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
            fontSize: 13, fontWeight: pw.FontWeight.bold, color: _ink),
      ),
    );
  }

  static pw.Widget _clauseText(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 12, color: _ink),
        textAlign: pw.TextAlign.justify,
      ),
    );
  }

  static pw.Widget _clauseBlock(String label, String content) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4, bottom: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink)),
          pw.SizedBox(height: 2),
          pw.Text(content,
              style: const pw.TextStyle(fontSize: 12, color: _ink),
              textAlign: pw.TextAlign.justify),
        ],
      ),
    );
  }

  static pw.Widget _bulletList(List<String> items) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 12, top: 4, bottom: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: items
            .map((item) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('•  ',
                          style: const pw.TextStyle(
                              fontSize: 12, color: _ink)),
                      pw.Expanded(
                        child: pw.Text(item,
                            style: const pw.TextStyle(
                                fontSize: 12, color: _ink),
                            textAlign: pw.TextAlign.justify),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  static pw.Widget _tableHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
            fontSize: 12, fontWeight: pw.FontWeight.bold, color: _ink),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _partyField(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('$label: ',
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink)),
          pw.Expanded(
            child: pw.Text(value,
                style: const pw.TextStyle(fontSize: 11, color: _ink)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _overviewRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        children: [
          pw.Text('$label: ',
              style: const pw.TextStyle(fontSize: 12, color: _ink)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink)),
        ],
      ),
    );
  }

  // ==================== FORMAT HELPERS ====================

  static String _norm(String? v, {String fallback = '—'}) =>
      (v != null && v.trim().isNotEmpty) ? v.trim() : fallback;

  static String _fmtVnd(num? n) => n != null ? _currencyFmt.format(n) : '—';

  static String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  static String _paymentLabel(String? m) {
    if (m == null) return 'Chuyển khoản ngân hàng';
    return m == 'bank_transfer' ? 'Chuyển khoản ngân hàng' : m;
  }

  static String _getContractTitle(ContractType? type) {
    switch (type) {
      case ContractType.probation:
        return 'HỢP ĐỒNG THỬ VIỆC';
      case ContractType.partTime:
        return 'HỢP ĐỒNG LAO ĐỘNG BÁN THỜI GIAN';
      case ContractType.fullTime:
      default:
        return 'HỢP ĐỒNG LAO ĐỘNG';
    }
  }

  static String _getContractTitleEn(ContractType? type) {
    switch (type) {
      case ContractType.probation:
        return 'LABOR CONTRACT (PROBATION PERIOD)';
      case ContractType.partTime:
        return 'PART-TIME LABOR CONTRACT';
      case ContractType.fullTime:
      default:
        return 'LABOR CONTRACT';
    }
  }

  static Future<pw.MemoryImage?> _fetchImage(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return pw.MemoryImage(response.bodyBytes);
    } catch (_) {}
    return null;
  }
}
