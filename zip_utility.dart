import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// دالة لفك ضغط ملف ZIP
///
/// [zipFilePath] هو المسار الكامل لملف الـ ZIP
/// [destinationDir] هو المجلد الذي سيتم فك ضغط الملفات فيه
Future<void> unzip(String zipFilePath, Directory destinationDir) async {
  List<String> extractedFilePaths = [];
  // تأكد من أن مجلد الوجهة موجود
  if (!await destinationDir.exists()) {
    await destinationDir.create(recursive: true);
  }

  // قراءة ملف ZIP من القرص
  final bytes = await File(zipFilePath).readAsBytes();

  // فك تشفير الأرشيف
  final archive = ZipDecoder().decodeBytes(bytes);

  // استخراج محتويات الأرشيف إلى القرص
  for (final file in archive) {
    final filename = file.name;
    final filePath = p.join(destinationDir.path, filename);

    if (file.isFile) {
      final data = file.content as List<int>;
      final outFile = File(filePath);
      // التأكد من وجود المجلد الأب للملف
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(data);
      print('✓  تم استخراج الملف: ${outFile.path}');
      extractedFilePaths.add(outFile.path);
    } else { // إذا كان مجلداً
      final dir = Directory(filePath);
      await dir.create(recursive: true);
      print('✓  تم إنشاء المجلد: ${dir.path}');
    }
  }
  print('✨ اكتمل فك الضغط بنجاح!');
  return extractedFilePaths;
}