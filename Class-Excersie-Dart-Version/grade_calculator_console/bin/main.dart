import 'dart:io';
import 'package:excel/excel.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('input', abbr: 'i', help: 'Path to input Excel file (required)')
    ..addOption('output',
        abbr: 'o',
        help: 'Path to output Excel file (default: output_[input_filename])')
    ..addOption('column',
        abbr: 'c',
        help:
            'Column name or index (0-based) containing student marks (default: auto-detect Mark/Score/Grade/Points)')
    ..addFlag('list-columns',
        help: 'List all columns in the file and exit', negatable: false)
    ..addFlag('create-sample',
        help: 'Create a sample Excel file with dummy data', negatable: false);

  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    print(e);
    print(
        'Usage: dart run bin/main.dart -i <input_file> [-o <output_file>] [-c <column>]');
    print(parser.usage);
    exit(1);
  }

  final inputPath = argResults['input'];
  if (inputPath == null || (inputPath as String).isEmpty) {
    print('Error: Input file is required.');
    print(
        'Usage: dart run bin/main.dart -i <input_file> [-o <output_file>] [-c <column>]');
    print(parser.usage);
    exit(1);
  }

  String outputPath = argResults['output'] ?? 'graded_${p.basename(inputPath)}';
  final columnArg = argResults['column'];
  final listColumns = argResults['list-columns'] as bool;
  final createSample = argResults['create-sample'] as bool;

  // Handle --create-sample flag
  if (createSample) {
    final samplePath = inputPath ?? 'sample_students.xlsx';
    await _createSampleFile(samplePath);
    print('Sample file created: $samplePath');
    exit(0);
  }

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    print('Error: Input file "$inputPath" not found.');
    print('\nExample: Create a sample file with:');
    print('  dart run bin/main.dart -i sample.xlsx');
    exit(1);
  }

  print('Reading "$inputPath"...');
  var bytes = await inputFile.readAsBytes();
  var excel = Excel.decodeBytes(bytes);

  // Create output excel
  var outputExcel = Excel.createExcel();
  // Remove default sheet created by createExcel() if we want specific names, but here we'll just rename 'Sheet1'
  var outputSheetName = 'Grades';
  outputExcel.rename('Sheet1', outputSheetName);
  Sheet outputSheet = outputExcel[outputSheetName];

  // Try to find the first sheet with data
  Sheet? inputSheet;
  for (var table in excel.tables.keys) {
    if (excel.tables[table] != null && excel.tables[table]!.maxRows > 0) {
      inputSheet = excel.tables[table];
      break;
    }
  }

  if (inputSheet == null) {
    print('Error: No data found in "$inputPath".');
    exit(1);
  }

  // Find header row and 'Mark' column index
  int markColumnIndex = -1;
  int nameColumnIndex = -1; // Optional, try to find 'Name' or 'Student'
  int headerRowIndex = 0; // Assume row 0 by default

  // Simple heuristic: look for "Mark" or "Score" in first few rows
  for (int i = 0; i < inputSheet.maxRows && i < 5; i++) {
    var row = inputSheet.row(i);
    for (int j = 0; j < row.length; j++) {
      var cellValue = row[j]?.value?.toString().toLowerCase().trim();
      if (cellValue == 'mark' ||
          cellValue == 'score' ||
          cellValue == 'grade' ||
          cellValue == 'points') {
        markColumnIndex = j;
        headerRowIndex = i;
      }
      if (cellValue == 'name' || cellValue == 'student') {
        nameColumnIndex = j;
      }
    }
    if (markColumnIndex != -1) break;
  }

  // If user specified a column, override auto-detection
  if (columnArg != null && (columnArg as String).isNotEmpty) {
    final colStr = columnArg as String;
    // Try parsing as column index first
    final columnIndex = int.tryParse(colStr);
    if (columnIndex != null) {
      markColumnIndex = columnIndex;
      print('Using column index $columnIndex as specified.');
    } else {
      // Try finding column by name
      for (int i = 0; i < inputSheet.maxRows && i < 5; i++) {
        var row = inputSheet.row(i);
        for (int j = 0; j < row.length; j++) {
          var cellValue = row[j]?.value?.toString().toLowerCase().trim();
          if (cellValue == colStr.toLowerCase().trim()) {
            markColumnIndex = j;
            headerRowIndex = i;
            print('Found column "$colStr" at index $j.');
            break;
          }
        }
        if (markColumnIndex != -1) break;
      }
      if (markColumnIndex == -1) {
        print('Error: Column "$colStr" not found in file.');
        exit(1);
      }
    }
  }

  // List columns if requested
  if (listColumns) {
    print('\n=== Available Columns in "$inputPath" ===');
    var headerRow = inputSheet.row(headerRowIndex);
    for (int i = 0; i < headerRow.length; i++) {
      var cellValue = headerRow[i]?.value?.toString() ?? '';
      print('  [$i] $cellValue');
    }
    print(
        '\nUsage: dart run bin/main.dart -i $inputPath -c <column_index_or_name>');
    exit(0);
  }

  if (markColumnIndex == -1) {
    print(
        'Error: Could not find a column named "Mark", "Score", "Grade", or "Points".');
    print('Use --list-columns to see available columns:');
    print('  dart run bin/main.dart -i $inputPath --list-columns');
    print('Then specify the column with -c option:');
    print('  dart run bin/main.dart -i $inputPath -c <column_name_or_index>');
    exit(1);
  }

  print(
      'Found "Mark" column at index $markColumnIndex (Row ${headerRowIndex + 1})');

  // Prepare output header
  List<CellValue> headers = [];
  var headerRow = inputSheet.row(headerRowIndex);
  for (var cell in headerRow) {
    if (cell != null && cell.value != null) {
      headers.add(TextCellValue(cell.value.toString()));
    } else {
      headers.add(TextCellValue(""));
    }
  }

  // Checking if 'Grade' column already exists? If so, we'll overwrite or append?
  // Let's append if not present.
  bool gradeColumnExists = false;
  for (var h in headers) {
    String headerText = _cellValueToString(h);
    if (headerText.trim() == 'Calculated Grade') {
      gradeColumnExists = true;
    }
  }
  if (!gradeColumnExists) {
    headers.add(TextCellValue('Calculated Grade'));
  }

  outputSheet.appendRow(headers);

  // Process rows
  int processedCount = 0;
  for (int i = headerRowIndex + 1; i < inputSheet.maxRows; i++) {
    var row = inputSheet.row(i);
    if (row.isEmpty) continue;

    // Copy existing data
    List<CellValue> outputRow = [];
    for (var cell in row) {
      if (cell != null && cell.value != null) {
        // preserve type
        if (cell.value is IntCellValue)
          outputRow.add(IntCellValue((cell.value as IntCellValue).value));
        else if (cell.value is DoubleCellValue)
          outputRow.add(DoubleCellValue((cell.value as DoubleCellValue).value));
        else
          outputRow.add(TextCellValue(cell.value.toString()));
      } else {
        outputRow.add(TextCellValue(""));
      }
    }

    // Get mark
    if (markColumnIndex < row.length && row[markColumnIndex] != null) {
      var markCell = row[markColumnIndex];
      double? mark;

      if (markCell!.value is IntCellValue) {
        mark = (markCell.value as IntCellValue).value.toDouble();
      } else if (markCell.value is DoubleCellValue) {
        mark = (markCell.value as DoubleCellValue).value;
      } else {
        // Try parsing string representation
        if (markCell.value != null) {
          String cellStr = _cellValueToString(markCell.value!);
          mark = double.tryParse(cellStr);
        }
      }

      if (mark != null) {
        String grade = calculateGrade(mark);
        outputRow.add(TextCellValue(grade));
        processedCount++;
      } else {
        outputRow.add(TextCellValue("Invalid/Missing"));
      }
    } else {
      outputRow.add(TextCellValue("Missing"));
    }

    outputSheet.appendRow(outputRow);
  }

  // Save output
  var fileBytes = outputExcel.save();
  if (fileBytes != null) {
    File(outputPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes);
    print('Successfully processed $processedCount students.');
    print('Output saved to "$outputPath".');
  } else {
    print('Error saving file.');
  }
}

String calculateGrade(double mark) {
  if (mark >= 90) return 'A';
  if (mark >= 85) return 'B+';
  if (mark >= 80) return 'B';
  if (mark >= 75) return 'C+';
  if (mark >= 70) return 'C';
  if (mark >= 65) return 'D+';
  if (mark >= 60) return 'D';
  return 'F';
}

String _cellValueToString(CellValue cell) {
  if (cell is IntCellValue) {
    return cell.value.toString();
  } else if (cell is DoubleCellValue) {
    return cell.value.toString();
  } else if (cell is TextCellValue) {
    return cell.value.toString();
  }
  return '';
}

Future<void> _createSampleFile(String path) async {
  var excel = Excel.createExcel();
  var sheet = excel['Sheet1'];

  sheet.appendRow([TextCellValue('Student Name'), TextCellValue('Mark')]);
  sheet.appendRow([TextCellValue('Alice'), IntCellValue(95)]);
  sheet.appendRow([TextCellValue('Bob'), IntCellValue(88)]);
  sheet.appendRow([TextCellValue('Charlie'), IntCellValue(72)]);
  sheet.appendRow([TextCellValue('David'), IntCellValue(60)]);
  sheet.appendRow([TextCellValue('Eve'), IntCellValue(45)]);

  var bytes = excel.save();
  if (bytes != null)
    File(path)
      ..createSync()
      ..writeAsBytesSync(bytes);
}
