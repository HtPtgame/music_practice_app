import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// 上傳模式元件
/// 
/// Phase 3 重構: 從 PracticePage 提取的 UI 元件
class UploadControlsWidget extends StatelessWidget {
  final String? audioPath;
  final VoidCallback? onUpload;

  const UploadControlsWidget({
    super.key,
    this.audioPath,
    this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Icon(
          audioPath != null ? Icons.check_circle : Icons.upload_file,
          size: 48,
          color: audioPath != null ? Colors.green : Colors.grey,
        ),
        const SizedBox(height: 12),
        Text(
          audioPath != null
              ? (l10n?.practiceFileUploaded ?? '已上傳檔案')
              : (l10n?.practiceSelectWavFile ?? '請選擇 WAV 檔案'),
          style: TextStyle(
            fontSize: 16,
            color: audioPath != null ? Colors.green : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (audioPath != null) ...[
          const SizedBox(height: 4),
          Text(
            audioPath!.split('/').last,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onUpload,
          icon: const Icon(Icons.upload_file),
          label: Text(
            audioPath != null
                ? (l10n?.practiceReupload ?? '重新上傳')
                : (l10n?.practiceSelectFile2 ?? '選擇檔案'),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.dynamicPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ],
    );
  }
}
