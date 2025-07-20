import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:file_picker/file_picker.dart'; // 導入 file_picker 套件

class UploadPage2 extends StatefulWidget {
  const UploadPage2({super.key});

  @override
  State<UploadPage2> createState() => _UploadPage2State();
}

class _UploadPage2State extends State<UploadPage2> {
  String? _fileName; // 用於顯示選擇的檔案名稱
  bool _isFilePicked = false; // 判斷是否已選擇檔案

  // 處理檔案上傳的邏輯
  Future<void> _pickMidiFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['midi', 'mid'], // 允許的檔案類型
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        setState(() {
          _fileName = file.name;
          _isFilePicked = true;
        });
        // 這裡可以處理選擇到的 MIDI 檔案，例如讀取內容、上傳到伺服器等
        debugPrint('選擇的 MIDI 檔案: ${file.name}');
        debugPrint('檔案路徑: ${file.path}');
        // TODO: 在這裡加入讀取或處理 MIDI 檔案的邏輯
      } else {
        // 使用者取消了選擇
        debugPrint('取消檔案選擇');
        setState(() {
          _fileName = null;
          _isFilePicked = false;
        });
      }
    } catch (e) {
      debugPrint('檔案選擇錯誤: $e');
      // 顯示錯誤訊息給使用者
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('選擇檔案時發生錯誤: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('從本機上傳 MIDI'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/upload'); // 返回到上一個上傳頁面
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '請選擇要上傳的 MIDI 檔案：',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickMidiFile, // 呼叫檔案選擇器
                    icon: const Icon(Icons.upload_file, color: Colors.white),
                    label: const Text(
                      '選擇 MIDI 檔案',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _fileName != null // 根據是否有檔案名稱來顯示訊息
                      ? Text(
                          '已選擇檔案: $_fileName',
                          style: const TextStyle(fontSize: 16, color: AppColors.textDark),
                          textAlign: TextAlign.center,
                        )
                      : const Text(
                          '尚未選擇檔案',
                          style: TextStyle(fontSize: 16, color: AppColors.textLight),
                          textAlign: TextAlign.center,
                        ),
                  const SizedBox(height: 30),
                  // 如果已選擇檔案，則顯示上傳按鈕
                  if (_isFilePicked)
                    ElevatedButton(
                      onPressed: () {
                        // TODO: 在這裡加入實際的檔案上傳邏輯
                        // 例如：將 _fileName 或檔案內容傳遞給處理邏輯
                        debugPrint('開始處理或上傳檔案: $_fileName');
                        // 上傳成功後，可以導航到其他頁面，例如播放頁面
                        // context.go('/playback');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('檔案已選取，待處理/上傳: $_fileName')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '確認上傳',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}