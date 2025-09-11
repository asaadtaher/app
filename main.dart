import 'package:flutter/material.dart';
import 'zip_utility.dart'; // استيراد الملف الذي أنشأناه
import 'dart:io'; // For Directory
import 'package:path_provider/path_provider.dart'; // For getApplicationDocumentsDirectory
import 'package:path/path.dart' as p; // For path manipulation
import 'package:archive/archive_io.dart'; // For ZipFileEncoder (for dummy zip creation)

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unzip Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const UnzipPage(),
    );
  }
}

class UnzipPage extends StatefulWidget {
  const UnzipPage({super.key});

  @override
  State<UnzipPage> createState() => _UnzipPageState();
}

class _UnzipPageState extends State<UnzipPage> {
  List<String> _unzippedFiles = [];
  bool _isUnzipping = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _checkExistingUnzippedFiles(); // التحقق من وجود ملفات مفكوكة مسبقاً عند بدء التطبيق
  }

  Future<void> _checkExistingUnzippedFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final destinationDir = Directory(p.join(appDir.path, 'my_files_unzipped'));

      if (await destinationDir.exists()) {
        final files = destinationDir.listSync(recursive: true).whereType<File>().map((e) => e.path).toList();
        setState(() {
          _unzippedFiles = files;
          _statusMessage = 'تم العثور على ملفات مفكوكة مسبقاً.';
        });
      }
    } catch (e) {
      print('Error checking existing files: $e');
    }
  }

  Future<void> _unzipFiles() async {
    setState(() {
      _isUnzipping = true;
      _statusMessage = 'بدء عملية فك الضغط...';
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final zipPath = p.join(appDir.path, 'my_files.zip');
      final destinationDir = Directory(p.join(appDir.path, 'my_files_unzipped'));

      // --- لغرض الاختبار: إنشاء ملف ZIP وهمي إذا لم يكن موجوداً ---
      if (!await File(zipPath).exists()) {
        print('ملف ZIP غير موجود، سيتم إنشاء ملف وهمي للاختبار...');
        final encoder = ZipFileEncoder();
        encoder.create(zipPath);
        encoder.addFile(File(p.join(appDir.path, 'readme.txt'))..writeAsStringSync('Hello from the ZIP file!'));
        encoder.addDirectory(Directory(p.join(appDir.path, 'my_folder')));
        encoder.addFile(File(p.join(appDir.path, 'my_folder/notes.txt'))..writeAsStringSync('These are my notes.'));
        encoder.close();
        print('تم إنشاء ملف ZIP وهمي في: $zipPath');
      }

      // مسح الملفات المفكوكة السابقة لضمان استخراج جديد
      if (await destinationDir.exists()) {
        await destinationDir.delete(recursive: true);
      }

      final extractedPaths = await unzip(zipPath, destinationDir);

      setState(() {
        _unzippedFiles = extractedPaths;
        _statusMessage = 'اكتمل فك الضغط بنجاح! تم استخراج ${_unzippedFiles.length} ملف.';
      });
    } catch (e, stackTrace) {
      setState(() {
        _statusMessage = 'حدث خطأ أثناء فك الضغط: $e';
      });
      print('حدث خطأ أثناء فك الضغط: $e');
      print('Stack trace: $stackTrace');
    } finally {
      setState(() {
        _isUnzipping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Unzip Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_statusMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: _statusMessage!.contains('خطأ') ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (_isUnzipping)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            const Text(
              'الملفات المفكوكة:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _unzippedFiles.isEmpty
                  ? const Center(child: Text('لا توجد ملفات مفكوكة لعرضها.'))
                  : ListView.builder(
                      itemCount: _unzippedFiles.length,
                      itemBuilder: (context, index) {
                        final filePath = _unzippedFiles[index];
                        final fileName = p.basename(filePath); // الحصول على اسم الملف فقط
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            leading: const Icon(Icons.insert_drive_file),
                            title: Text(fileName),
                            subtitle: Text(filePath), // عرض المسار الكامل كعنوان فرعي
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isUnzipping ? null : _unzipFiles, // تعطيل الزر أثناء فك الضغط
        tooltip: 'Unzip File',
        child: _isUnzipping ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.archive),
      ),
    );
  }
}