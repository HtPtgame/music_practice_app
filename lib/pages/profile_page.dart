import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/core/services/auth_service_config.dart';
import 'package:music_practice_app/l10n/app_localizations.dart';
import 'package:music_practice_app/utils/error_handler.dart';

/// 個人資料頁面
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n?.profileTitle ?? '個人資料')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 100, color: Colors.grey),
              const SizedBox(height: 24),
              Text(l10n?.profilePleaseLogin ?? '請先登入',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.push('/login'),
                child: Text(l10n?.profileGoToLogin ?? '前往登入'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.profileTitle ?? '個人資料'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileDialog(),
            tooltip: l10n?.profileEdit ?? '編輯資料',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    user.username[0].toUpperCase(),
                    style: const TextStyle(fontSize: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.displayName ?? user.username,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('@${user.username}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: Text(l10n?.profileEmail ?? 'Email'),
            subtitle: Text(user.email),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(l10n?.profileRegistrationDate ?? '註冊日期'),
            subtitle: Text(
                '${user.createdAt.year}/${user.createdAt.month}/${user.createdAt.day}'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n?.profileChangePassword ?? '變更密碼'),
            onTap: () => _showChangePasswordDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.blue),
            title: Text(l10n?.profileLogout ?? '登出', style: const TextStyle(color: Colors.blue)),
            onTap: () => _handleLogout(),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(l10n?.profileDeleteAccount ?? '刪除帳號', style: const TextStyle(color: Colors.red)),
            onTap: () => _handleDeleteAccount(),
          ),
        ],
      ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final l10n = AppLocalizations.of(context);
    final user = authService.currentUser!;
    final controller = TextEditingController(text: user.displayName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.profileEditProfile ?? '編輯個人資料'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n?.profileDisplayName ?? '顯示名稱',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.cancel ?? '取消'),
          ),
          TextButton(
            onPressed: () async {
              await authService.updateProfile(
                  displayName: controller.text.trim());
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
                ErrorHandler.showSuccess(
                  context,
                  l10n?.profileDataUpdated ?? '資料已更新',
                );
              }
            },
            child: Text(l10n?.save ?? '儲存'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final l10n = AppLocalizations.of(context);
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.profileChangePassword ?? '變更密碼'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n?.profileOldPassword ?? '舊密碼',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n?.profileNewPassword ?? '新密碼',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n?.profileConfirmNewPassword ?? '確認新密碼',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.cancel ?? '取消'),
          ),
          TextButton(
            onPressed: () async {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ErrorHandler.showWarning(
                  context,
                  l10n?.profilePasswordMismatch ?? '新密碼不一致',
                );
                return;
              }
              try {
                await authService.changePassword(
                  oldPasswordController.text,
                  newPasswordController.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ErrorHandler.showSuccess(
                    context,
                    l10n?.profilePasswordChanged ?? '密碼已變更',
                  );
                }
              } catch (e) {
                if (mounted) {
                  ErrorHandler.show(
                    context,
                    '${l10n?.profileChangeFailed ?? '變更失敗'}: $e',
                  );
                }
              }
            },
            child: Text(l10n?.confirm ?? '確認'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.profileLogoutTitle ?? '確認登出'),
        content: Text(l10n?.profileLogoutMessage ?? '您確定要登出嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.cancel ?? '取消'),
          ),
          TextButton(
            onPressed: () async {
              await authService.logout();
              if (mounted) {
                Navigator.pop(context);
                context.go('/');
                ErrorHandler.showSuccess(
                  context,
                  l10n?.profileLoggedOut ?? '已登出',
                );
              }
            },
            child: Text(l10n?.confirm ?? '確認'),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount() {
    final l10n = AppLocalizations.of(context);
    final passwordController = TextEditingController();
    final isGoogleUser = authService.isGoogleSignIn();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.profileDeleteTitle ?? '刪除帳號'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.profileDeleteWarning ?? '⚠️ 此操作無法復原！\n所有資料將被永久刪除。',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (isGoogleUser)
              Text(
                l10n?.profileDeleteGoogleHint ?? '您使用 Google 帳號登入。\n點擊「確認刪除」後需要重新登入 Google 以確認身份。',
                style: const TextStyle(fontSize: 14),
              )
            else
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n?.profileDeletePasswordHint ?? '請輸入密碼確認',
                  border: const OutlineInputBorder(),
                  helperText: l10n?.profileDeletePasswordLabel ?? '需要輸入您的帳號密碼',
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.cancel ?? '取消'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Google 用戶不需要密碼,Email 用戶需要密碼
                await authService.deleteAccount(
                    isGoogleUser ? null : passwordController.text);

                if (mounted) {
                  // 先關閉對話框
                  Navigator.pop(context);

                  // 等待下一幀再執行導航,避免 Navigator 鎖定衝突
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      context.go('/');
                      ErrorHandler.showSuccess(
                        context,
                        l10n?.profileAccountDeleted ?? '帳號已刪除',
                      );
                    }
                  });
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ErrorHandler.show(
                    context,
                    '${l10n?.profileDeleteError ?? '刪除失敗'}: ${e.toString().replaceFirst("Exception: ", "")}',
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n?.profileDeleteButton ?? '確認刪除'),
          ),
        ],
      ),
    );
  }
}
