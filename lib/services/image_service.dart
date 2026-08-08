import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageService {
  Future<Directory> _getImagesDirectory(String date) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'daily_journal', 'images', date));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  Future<String?> pickAndSaveImage(String date) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    if (file.path == null) return null;

    final sourceFile = File(file.path!);
    final imagesDir = await _getImagesDirectory(date);

    // Generate unique filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = p.extension(file.name);
    final newFileName = 'img_$timestamp$extension';
    final destPath = p.join(imagesDir.path, newFileName);

    await sourceFile.copy(destPath);

    return destPath;
  }

  String getMarkdownImageLink(String imagePath, {String? altText}) {
    final fileName = p.basename(imagePath);
    return '![${altText ?? fileName}]($imagePath)';
  }
}
