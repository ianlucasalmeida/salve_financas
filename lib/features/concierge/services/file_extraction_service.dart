import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:read_pdf_text/read_pdf_text.dart';

class FileExtractionResult {
  final String text;
  final String sourceType; // 'pdf' ou 'image'

  FileExtractionResult(this.text, this.sourceType);
}

class FileExtractionService {
  final ImagePicker _picker = ImagePicker();

  /// Abre a galeria/câmera para pegar uma foto da fatura
  Future<FileExtractionResult?> pickAndReadImage({bool fromCamera = false}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 80, // Otimiza memória
      );

      if (image == null) return null;

      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      
      // OCR Local (Google ML Kit)
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      await textRecognizer.close();

      return FileExtractionResult(recognizedText.text, 'image');
    } catch (e) {
      throw Exception("Erro ao ler imagem: $e");
    }
  }

  /// Abre o gerenciador de arquivos para pegar um PDF
  Future<FileExtractionResult?> pickAndReadPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.single.path == null) return null;

      String path = result.files.single.path!;
      
      // Extração de texto do PDF
      String text = await ReadPdfText.getPDFtext(path);
      
      // Limpeza básica (remove excesso de espaços)
      text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

      return FileExtractionResult(text, 'pdf');
    } catch (e) {
      throw Exception("Erro ao ler PDF: $e");
    }
  }
}