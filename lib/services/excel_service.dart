import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/grading_result.dart';

class ExcelService {
  final GradeScale _gradeScale = const GradeScale();

  Future<Map<String, dynamic>> processExcelFile(Uint8List fileBytes) async {
    try {
      final excel = Excel.decodeBytes(fileBytes);
      
      if (excel.tables.isEmpty) {
        throw Exception('No worksheets found in the Excel file');
      }

      final sheet = excel.tables.values.first;
      if (sheet == null) {
        throw Exception('Unable to read worksheet');
      }

      List<StudentGrade> students = [];
      int nameColumnIndex = -1;
      int scoreColumnIndex = -1;

      // Find header row and column indices
      bool headerFound = false;
      for (var row in sheet.rows) {
        if (!headerFound) {
          for (int i = 0; i < row.length; i++) {
            final cellValue = row[i]?.value?.toString().toLowerCase() ?? '';
            if (cellValue.contains('student') && cellValue.contains('name')) {
              nameColumnIndex = i;
            } else if (cellValue.contains('score')) {
              scoreColumnIndex = i;
            }
          }
          if (nameColumnIndex >= 0 && scoreColumnIndex >= 0) {
            headerFound = true;
            continue;
          }
        } else {
          // Process data rows
          if (row.length > nameColumnIndex && row.length > scoreColumnIndex) {
            final nameCell = row[nameColumnIndex]?.value;
            final scoreCell = row[scoreColumnIndex]?.value;

            if (nameCell != null && scoreCell != null) {
              final name = nameCell.toString().trim();
              if (name.isNotEmpty) {
                try {
                  final score = double.parse(scoreCell.toString());
                  final grade = _gradeScale.calculateGrade(score);
                  students.add(StudentGrade(
                    name: name,
                    score: score,
                    grade: grade,
                  ));
                } catch (e) {
                  // Skip rows with invalid scores
                  continue;
                }
              }
            }
          }
        }
      }

      if (students.isEmpty) {
        throw Exception('No valid student data found. Ensure your file has "Student Name" and "Score" columns.');
      }

      // Calculate grade distribution
      final distribution = <String, int>{
        'A': 0,
        'B': 0,
        'C': 0,
        'D': 0,
        'F': 0,
      };

      for (final student in students) {
        distribution[student.grade] = (distribution[student.grade] ?? 0) + 1;
      }

      return {
        'filename': 'uploaded_file.xlsx',
        'students': students.map((s) => s.toJson()).toList(),
        'distribution': distribution,
        'processedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Error processing Excel file: $e');
    }
  }

  Future<void> exportResults(Map<String, dynamic> results) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Graded Results'];

      // Add headers
      sheet.cell(CellIndex.indexByString('A1')).value = 'Student Name';
      sheet.cell(CellIndex.indexByString('B1')).value = 'Score';
      sheet.cell(CellIndex.indexByString('C1')).value = 'Grade';

      // Style headers
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: '#2563EB',
        fontColorHex: '#FFFFFF',
      );

      sheet.cell(CellIndex.indexByString('A1')).cellStyle = headerStyle;
      sheet.cell(CellIndex.indexByString('B1')).cellStyle = headerStyle;
      sheet.cell(CellIndex.indexByString('C1')).cellStyle = headerStyle;

      // Add data
      final students = results['students'] as List;
      for (int i = 0; i < students.length; i++) {
        final student = students[i];
        final rowIndex = i + 2;
        
        sheet.cell(CellIndex.indexByString('A$rowIndex')).value = student['name'];
        sheet.cell(CellIndex.indexByString('B$rowIndex')).value = student['score'];
        sheet.cell(CellIndex.indexByString('C$rowIndex')).value = student['grade'];

        // Style grade cells based on grade
        final gradeCell = sheet.cell(CellIndex.indexByString('C$rowIndex'));
        final grade = student['grade'] as String;
        
        CellStyle gradeStyle;
        switch (grade) {
          case 'A':
            gradeStyle = CellStyle(
              backgroundColorHex: '#10B981',
              fontColorHex: '#FFFFFF',
              bold: true,
            );
            break;
          case 'B':
            gradeStyle = CellStyle(
              backgroundColorHex: '#3B82F6',
              fontColorHex: '#FFFFFF',
              bold: true,
            );
            break;
          case 'C':
            gradeStyle = CellStyle(
              backgroundColorHex: '#F59E0B',
              fontColorHex: '#FFFFFF',
              bold: true,
            );
            break;
          case 'D':
            gradeStyle = CellStyle(
              backgroundColorHex: '#EAB308',
              fontColorHex: '#FFFFFF',
              bold: true,
            );
            break;
          case 'F':
            gradeStyle = CellStyle(
              backgroundColorHex: '#EF4444',
              fontColorHex: '#FFFFFF',
              bold: true,
            );
            break;
          default:
            gradeStyle = CellStyle();
        }
        gradeCell.cellStyle = gradeStyle;
      }

      // Add summary section
      final summaryStartRow = students.length + 4;
      sheet.cell(CellIndex.indexByString('A$summaryStartRow')).value = 'Grade Distribution';
      sheet.cell(CellIndex.indexByString('A$summaryStartRow')).cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
      );

      final distribution = results['distribution'] as Map<String, dynamic>;
      int distributionRow = summaryStartRow + 2;
      
      for (final entry in distribution.entries) {
        sheet.cell(CellIndex.indexByString('A$distributionRow')).value = 'Grade ${entry.key}';
        sheet.cell(CellIndex.indexByString('B$distributionRow')).value = entry.value;
        distributionRow++;
      }

      // Get Downloads directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/graded_results_$timestamp.xlsx');

      // Save file
      final fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        
        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Graded results exported from Grade Calculator',
        );
      } else {
        throw Exception('Failed to generate Excel file');
      }
    } catch (e) {
      throw Exception('Error exporting results: $e');
    }
  }

  Future<String> generateTemplate() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Grade Template'];

      // Add headers
      sheet.cell(CellIndex.indexByString('A1')).value = 'Student Name';
      sheet.cell(CellIndex.indexByString('B1')).value = 'Score';

      // Style headers
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: '#2563EB',
        fontColorHex: '#FFFFFF',
      );

      sheet.cell(CellIndex.indexByString('A1')).cellStyle = headerStyle;
      sheet.cell(CellIndex.indexByString('B1')).cellStyle = headerStyle;

      // Add sample data
      final sampleData = [
        ['Emma Thompson', 94],
        ['Liam Johnson', 88],
        ['Olivia Williams', 76],
        ['Noah Brown', 91],
        ['Ava Jones', 82],
      ];

      for (int i = 0; i < sampleData.length; i++) {
        final rowIndex = i + 2;
        sheet.cell(CellIndex.indexByString('A$rowIndex')).value = sampleData[i][0];
        sheet.cell(CellIndex.indexByString('B$rowIndex')).value = sampleData[i][1];
      }

      // Get Downloads directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/grade_template.xlsx');

      // Save file
      final fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        return file.path;
      } else {
        throw Exception('Failed to generate template');
      }
    } catch (e) {
      throw Exception('Error generating template: $e');
    }
  }
}