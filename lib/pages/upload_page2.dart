// lib/pages/upload_page2.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 用於檢測平台
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:file_picker/file_picker.dart';
// 導入 Uint8List
import 'package:music_practice_app/pages/library_page.dart'; // <<== 確保這一行存在且正確導入 MidiFileManager

class UploadPage2 extends StatefulWidget {
  const UploadPage2({super.key});

  @override
  State<UploadPage2> createState() => _UploadPage2State();
}

class _UploadPage2State extends State<UploadPage2> {
  PlatformFile? _pickedFile;
  bool _isLoading = false;

  Future<void> _pickMidiFile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['midi', 'mid'],
        allowMultiple: false,
        withData: true, // 確保獲取檔案的位元組數據 (對 Web 和原生平台都適用)
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _pickedFile = file;
        });
        debugPrint('選擇的 MIDI 檔案: ${file.name}');
        debugPrint('檔案大小: ${file.size} bytes');

        if (file.bytes != null) {
          debugPrint('文件數據已載入 (${file.bytes!.length} bytes)');
        } else {
          debugPrint('警告: 無法獲取文件數據 (bytes)。');
        }
      } else {
        debugPrint('使用者取消檔案選擇');
      }
    } catch (e) {
      debugPrint('檔案選擇錯誤: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('選擇檔案時發生錯誤: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _saveToLibrary() {
    if (_pickedFile != null) {
      bool isValidFile =
          _pickedFile!.bytes != null && _pickedFile!.bytes!.isNotEmpty;

      if (isValidFile) {
        MidiFileManager.addMidiFile(_pickedFile!); // <<== 使用 MidiFileManager
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('MIDI檔案已成功儲存到樂庫！'),
            backgroundColor: Colors.green,
            duration: Duration(milliseconds: 800),
          ),
        );
        if (mounted) {
          context.go('/library');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('錯誤：無法讀取檔案內容，請重新選擇檔案。'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      appBar: AppBar(
        title: const Text('從本機上傳 MIDI',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/library'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '請選擇要上傳的 MIDI 檔案',
                style: TextStyle(
                  color: AppColors.dynamicTextDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                kIsWeb ? '支援格式：.mid, .midi (Web版本使用記憶體載入)' : '支援格式：.mid, .midi',
                style: TextStyle(
                  color: AppColors.dynamicTextLight,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),

              // 文件選擇區域
              Card(
                color: AppColors.dynamicCard,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        _pickedFile != null
                            ? Icons.music_note
                            : Icons.upload_file,
                        size: 64,
                        color: _pickedFile != null
                            ? AppColors.dynamicPrimary
                            : AppColors.dynamicTextLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _pickedFile != null ? _pickedFile!.name : '尚未選擇檔案',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _pickedFile != null
                              ? AppColors.dynamicTextDark
                              : AppColors.dynamicTextLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_pickedFile != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '檔案大小: ${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.dynamicTextLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          kIsWeb
                              ? '平台: Web (使用記憶體載入)'
                              : '平台: ${_pickedFile!.path != null ? "本機儲存" : "記憶體載入"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.dynamicTextLight,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _pickMidiFile,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.folder_open),
                        label: Text(_isLoading
                            ? '選擇中...'
                            : _pickedFile != null
                                ? '重新選擇'
                                : '選擇檔案'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.dynamicPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // 儲存按鈕
              if (_pickedFile != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _saveToLibrary, // 儲存到樂庫
                        icon: const Icon(Icons.save, size: 28),
                        label: const Text('儲存到樂庫',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
