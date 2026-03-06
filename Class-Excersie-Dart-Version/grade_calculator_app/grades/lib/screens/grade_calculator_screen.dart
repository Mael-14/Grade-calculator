import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import '../services/grade_service.dart';
import '../theme/app_theme.dart';

/// Main screen – upload Excel ▸ process ▸ show results ▸ download output.
class GradeCalculatorScreen extends StatefulWidget {
  const GradeCalculatorScreen({super.key});

  @override
  State<GradeCalculatorScreen> createState() => _GradeCalculatorScreenState();
}

class _GradeCalculatorScreenState extends State<GradeCalculatorScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────
  bool _isProcessing = false;
  String? _selectedFileName;
  String? _errorMessage;
  GradingResult? _result;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────
  Future<void> _pickAndProcess() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;

    final file = picked.files.first;
    if (file.bytes == null) {
      setState(() => _errorMessage = 'Could not read file data.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _result = null;
      _selectedFileName = file.name;
    });

    try {
      final result = await GradeService.processExcelBytes(
        file.bytes!,
        originalFileName: file.name,
      );
      setState(() {
        _result = result;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isProcessing = false;
      });
    }
  }

  Future<void> _openFile(String path) async => OpenFile.open(path);

  Future<void> _shareFile(String path) async => Share.shareXFiles([
    XFile(path),
  ], text: 'Graded Excel sheet from GradeGenie');

  Future<void> _downloadTemplate() async {
    try {
      final path = await GradeService.createTemplateFile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Template saved to: ${p.basename(path)}'),
          action: SnackBarAction(
            label: 'OPEN',
            onPressed: () => _openFile(path),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Grade Calculator'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(Icons.school_rounded, color: AppTheme.primary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: AppTheme.textMuted,
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ───────────────────────────────────────
            Text(
              'Hello, Professor 👋',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Ready to convert some scores today?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // ── Upload Card ────────────────────────────────────
            _buildUploadCard(),
            const SizedBox(height: 20),

            // ── Error Message ──────────────────────────────────
            if (_errorMessage != null) _buildErrorBanner(),

            // ── Processing Indicator ───────────────────────────
            if (_isProcessing) _buildProcessingIndicator(),

            // ── Results ────────────────────────────────────────
            if (_result != null) ...[
              _buildResultSummary(),
              const SizedBox(height: 16),
              _buildGradeDistribution(),
              const SizedBox(height: 16),
              _buildStudentList(),
              const SizedBox(height: 16),
              _buildOutputActions(),
            ],

            const SizedBox(height: 24),

            // ── Pro Tip Card ───────────────────────────────────
            _buildProTipCard(),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // ── Widget builders (kept as methods for clarity) ────────────────
  // ══════════════════════════════════════════════════════════════════

  Widget _buildUploadCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: AppTheme.radiusLg,
      boxShadow: AppTheme.cardShadow,
      border: Border.all(color: AppTheme.cardBorder),
    ),
    child: Column(
      children: [
        // Upload icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: AppTheme.softShadow,
          ),
          child: const Icon(
            Icons.cloud_upload_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Upload Excel Sheet',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'Drag & drop or tap to upload your\n100-point score sheet.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),

        // Select File button
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _pickAndProcess,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
            label: Text(
              _selectedFileName != null && _result != null
                  ? 'Select Another File'
                  : 'Select File',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusXl),
            ),
          ),
        ),

        // Show selected file name
        if (_selectedFileName != null) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insert_drive_file_rounded,
                size: 16,
                color: AppTheme.success,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _selectedFileName!,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.success),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  Widget _buildErrorBanner() => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.error.withValues(alpha: 0.08),
      borderRadius: AppTheme.radiusMd,
      border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _errorMessage!,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.error),
          ),
        ),
      ],
    ),
  );

  Widget _buildProcessingIndicator() => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: AppTheme.radiusMd,
      boxShadow: AppTheme.cardShadow,
    ),
    child: Column(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => Transform.scale(
            scale: 1.0 + _pulseController.value * 0.1,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 40,
              color: AppTheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Processing your scores…',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        const LinearProgressIndicator(),
      ],
    ),
  );

  Widget _buildResultSummary() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: AppTheme.primaryGradient,
      borderRadius: AppTheme.radiusMd,
      boxShadow: AppTheme.softShadow,
    ),
    child: Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 36),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Grading Complete!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_result!.totalStudents} students processed successfully',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildGradeDistribution() {
    final dist = _result!.gradeDistribution;
    // Fixed order
    const order = ['A', 'B+', 'B', 'C+', 'C', 'D+', 'D', 'F'];
    final maxCount = dist.values
        .fold<int>(0, (mx, v) => v > mx ? v : mx)
        .clamp(1, 9999);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.radiusMd,
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grade Distribution',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ...order.map((grade) {
            final count = dist[grade] ?? 0;
            final ratio = count / maxCount;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      grade,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: GradeService.gradeColor(grade),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: AppTheme.radiusSm,
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 22,
                        backgroundColor: AppTheme.background,
                        valueColor: AlwaysStoppedAnimation(
                          GradeService.gradeColor(grade),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '$count',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    final students = _result!.students;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.radiusMd,
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Student Results',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                '${students.length} students',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: AppTheme.radiusSm,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Name',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Score',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Grade',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Student rows – show max 20, use map for conciseness
          ...students
              .take(20)
              .map(
                (s) => Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 11,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.cardBorder.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          s.name,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textDark),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${s.score.toStringAsFixed(s.score.truncateToDouble() == s.score ? 0 : 1)}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: GradeService.gradeColor(
                              s.grade,
                            ).withValues(alpha: 0.12),
                            borderRadius: AppTheme.radiusSm,
                          ),
                          child: Text(
                            s.grade,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: GradeService.gradeColor(s.grade),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (students.length > 20)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: Text(
                  '+ ${students.length - 20} more students in the downloaded file',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOutputActions() => Row(
    children: [
      Expanded(
        child: SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _openFile(_result!.outputPath),
            icon: const Icon(Icons.folder_open_rounded, size: 20),
            label: const Text('Open File'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => _shareFile(_result!.outputPath),
            icon: const Icon(Icons.share_rounded, size: 20),
            label: const Text('Share'),
          ),
        ),
      ),
    ],
  );

  Widget _buildProTipCard() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFE0F2F1), Color(0xFFE8F5E9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: AppTheme.radiusMd,
      border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.15),
                borderRadius: AppTheme.radiusSm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    size: 14,
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'PRO TIP',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Ensure your Excel sheet has a header row with "Student Name" '
          'and "Score" for automatic detection.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textDark,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ElevatedButton(
            onPressed: _downloadTemplate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusSm),
              textStyle: const TextStyle(fontSize: 13),
            ),
            child: const Text('Download Template'),
          ),
        ),
      ],
    ),
  );
}
