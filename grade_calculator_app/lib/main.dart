import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const GradeCalculatorApp());
}

class GradeCalculatorApp extends StatelessWidget {
  const GradeCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grade Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const GradeCalculatorScreen(),
    );
  }
}

class GradeCalculatorScreen extends StatefulWidget {
  const GradeCalculatorScreen({super.key});

  @override
  State<GradeCalculatorScreen> createState() => _GradeCalculatorScreenState();
}

class _GradeCalculatorScreenState extends State<GradeCalculatorScreen> {
  String? _selectedFilePath;
  List<StudentGrade>? _processedGrades;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _pickAndProcessFile() async {
    try {
      setState(() {
        _errorMessage = null;
        _successMessage = null;
        _isProcessing = true;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        _selectedFilePath = result.files.single.path;
        await _processExcelFile(_selectedFilePath!);
      }

      setState(() {
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  Future<void> _processExcelFile(String filePath) async {
    try {
      // Read the Excel file
      var bytes = await File(filePath).readAsBytes();
      var excel = Excel.decodeBytes(bytes);

      // Find the first sheet with data
      Sheet? inputSheet;
      for (var table in excel.tables.keys) {
        if (excel.tables[table] != null && excel.tables[table]!.maxRows > 0) {
          inputSheet = excel.tables[table];
          break;
        }
      }

      if (inputSheet == null) {
        throw Exception('No data found in the Excel file.');
      }

      // Find header row and 'Mark' column index
      int markColumnIndex = -1;
      int headerRowIndex = 0;

      // Look for "Mark" or "Score" in first few rows
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
            break;
          }
        }
        if (markColumnIndex != -1) break;
      }

      if (markColumnIndex == -1) {
        throw Exception(
          'Could not find a column named "Mark", "Score", "Grade", or "Points".',
        );
      }

      // Process rows
      List<StudentGrade> grades = [];
      for (int i = headerRowIndex + 1; i < inputSheet.maxRows; i++) {
        var row = inputSheet.row(i);
        if (row.isEmpty) continue;

        // Get student name (first column)
        String studentName = '';
        if (row[0] != null) {
          studentName = _cellValueToString(row[0]!);
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
            String cellStr = _cellValueToString(markCell);
            mark = double.tryParse(cellStr);
          }

          if (mark != null) {
            String grade = _calculateGrade(mark);
            grades.add(
              StudentGrade(
                name: studentName.isNotEmpty ? studentName : 'Unknown',
                mark: mark,
                grade: grade,
              ),
            );
          }
        }
      }

      if (grades.isEmpty) {
        throw Exception('No valid student grades found.');
      }

      // Save results to a new Excel file
      String outputPath = await _saveGradesToExcel(grades, filePath);

      setState(() {
        _processedGrades = grades;
        _successMessage =
            'Successfully processed ${grades.length} students.\n\nOutput saved to: $outputPath';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing file: ${e.toString()}';
      });
    }
  }

  Future<String> _saveGradesToExcel(
    List<StudentGrade> grades,
    String inputPath,
  ) async {
    try {
      var outputExcel = Excel.createExcel();
      outputExcel.rename('Sheet1', 'Grades');
      var outputSheet = outputExcel['Grades'];

      // Add headers
      outputSheet.appendRow([
        TextCellValue('Student Name'),
        TextCellValue('Mark'),
        TextCellValue('Grade'),
      ]);

      // Add data
      for (var grade in grades) {
        outputSheet.appendRow([
          TextCellValue(grade.name),
          DoubleCellValue(grade.mark),
          TextCellValue(grade.grade),
        ]);
      }

      // Save to Downloads or Documents
      String? outputDir;
      if (Platform.isAndroid) {
        outputDir = '/sdcard/Download';
      } else if (Platform.isIOS) {
        outputDir = (await getApplicationDocumentsDirectory()).path;
      } else {
        outputDir =
            (await getDownloadsDirectory())?.path ??
            (await getApplicationDocumentsDirectory()).path;
      }

      String outputFileName =
          'graded_${p.basenameWithoutExtension(inputPath)}.xlsx';
      String outputPath = '$outputDir/$outputFileName';

      var fileBytes = outputExcel.save();
      if (fileBytes != null) {
        await File(outputPath).writeAsBytes(fileBytes);
      }

      return outputPath;
    } catch (e) {
      throw Exception('Error saving Excel file: $e');
    }
  }

  String _cellValueToString(dynamic cell) {
    if (cell is IntCellValue) {
      return cell.value.toString();
    } else if (cell is DoubleCellValue) {
      return cell.value.toString();
    } else if (cell is TextCellValue) {
      return cell.value.toString();
    }
    return '';
  }

  String _calculateGrade(double mark) {
    if (mark >= 90) return 'A';
    if (mark >= 85) return 'B+';
    if (mark >= 80) return 'B';
    if (mark >= 75) return 'C+';
    if (mark >= 70) return 'C';
    if (mark >= 65) return 'D+';
    if (mark >= 60) return 'D';
    return 'F';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grade Calculator'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How to Use:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Tap "Select File" to choose an Excel file',
                      style: TextStyle(fontSize: 14),
                    ),
                    const Text(
                      '2. The file must contain a "Mark" column',
                      style: TextStyle(fontSize: 14),
                    ),
                    const Text(
                      '3. Grades will be calculated automatically',
                      style: TextStyle(fontSize: 14),
                    ),
                    const Text(
                      '4. Results will be saved to a new Excel file',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Grade Scale:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('A: 90-100', style: TextStyle(fontSize: 12)),
                    const Text('B+: 85-89', style: TextStyle(fontSize: 12)),
                    const Text('B: 80-84', style: TextStyle(fontSize: 12)),
                    const Text('C+: 75-79', style: TextStyle(fontSize: 12)),
                    const Text('C: 70-74', style: TextStyle(fontSize: 12)),
                    const Text('D+: 65-69', style: TextStyle(fontSize: 12)),
                    const Text('D: 60-64', style: TextStyle(fontSize: 12)),
                    const Text('F: Below 60', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // File Selection Button
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickAndProcessFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Select Excel File'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),

            // Selected File Info
            if (_selectedFilePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected File:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.basename(_selectedFilePath!),
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Error Message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ),
              ),

            // Success Message
            if (_successMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      _successMessage!,
                      style: TextStyle(color: Colors.green.shade700),
                    ),
                  ),
                ),
              ),

            // Results Table
            if (_processedGrades != null && _processedGrades!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Results:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Student Name')),
                          DataColumn(label: Text('Mark')),
                          DataColumn(label: Text('Grade')),
                        ],
                        rows: _processedGrades!
                            .map(
                              (grade) => DataRow(
                                cells: [
                                  DataCell(Text(grade.name)),
                                  DataCell(Text(grade.mark.toStringAsFixed(2))),
                                  DataCell(
                                    Text(
                                      grade.grade,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _getGradeColor(grade.grade),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),

            // Loading Indicator
            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B+':
      case 'B':
        return Colors.blue;
      case 'C+':
      case 'C':
        return Colors.orange;
      case 'D+':
      case 'D':
        return Colors.deepOrange;
      case 'F':
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}

class StudentGrade {
  final String name;
  final double mark;
  final String grade;

  StudentGrade({required this.name, required this.mark, required this.grade});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
