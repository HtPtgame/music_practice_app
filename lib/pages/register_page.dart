import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/services/firebase_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 註冊頁面 - Firebase 版本
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = FirebaseAuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 檢查本地是否有訪客模式數據
  Future<bool> _hasLocalGuestData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final checkInDates = prefs.getStringList('checked_dates') ?? [];
      final practiceDataJson = prefs.getString('practice_data');

      Map<String, int> practiceData = {};
      if (practiceDataJson != null && practiceDataJson.isNotEmpty) {
        try {
          practiceData = Map<String, int>.from(jsonDecode(practiceDataJson));
        } catch (e) {
          debugPrint('解析練習數據失敗: $e');
        }
      }

      return checkInDates.isNotEmpty || practiceData.isNotEmpty;
    } catch (e) {
      debugPrint('檢查本地數據失敗: $e');
      return false;
    }
  }

  /// 顯示數據保留選擇對話框
  Future<bool> _showDataRetentionDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('保留當前數據？'),
            content: const Text(
              '檢測到您在訪客模式下已有打卡記錄或練習時長。\n\n'
              '您希望將這些數據導入新帳號，還是重新開始？',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('重新開始'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('保留當前數據'),
              ),
            ],
          ),
        ) ??
        false; // 如果用戶按返回鍵，預設為不保留
  }

  /// 處理 Email/密碼註冊
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 檢查是否有本地數據
      final hasLocalData = await _hasLocalGuestData();
      bool importData = false;

      if (hasLocalData) {
        // 顯示對話框讓用戶選擇
        importData = await _showDataRetentionDialog();
      }

      await _authService.register(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        displayName: _usernameController.text.trim(), // 使用 username 作為顯示名稱
        importLocalData: importData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(importData ? '註冊成功！已保留您的打卡和練習記錄' : '註冊成功！歡迎加入'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        // 提取錯誤訊息（移除 "Exception: " 前綴）
        String errorMessage = e.toString().replaceFirst('Exception: ', '');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 處理 Google 登入/註冊
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      // 檢查是否有本地數據（在 Google 登入前）
      final hasLocalData = await _hasLocalGuestData();
      bool importData = false;

      if (hasLocalData) {
        // 顯示對話框讓用戶選擇
        importData = await _showDataRetentionDialog();
      }

      final success = await _authService.signInWithGoogle(
        importLocalData: importData,
      );

      if (mounted) {
        if (success) {
          // 登入/註冊成功
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(importData && hasLocalData
                  ? 'Google 登入成功！已保留您的打卡和練習記錄'
                  : 'Google 登入成功！'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/');
        } else {
          // 使用者取消登入,不顯示任何訊息
          debugPrint('使用者取消 Google 登入');
        }
      }
    } catch (e) {
      if (mounted) {
        // 提取錯誤訊息（移除 "Exception: " 前綴）
        String errorMessage = e.toString().replaceFirst('Exception: ', '');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('註冊'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Icon(
                  Icons.music_note,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  '建立新帳號',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '請輸入 Email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return '請輸入有效的 Email';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                // 使用者名稱（同時作為顯示名稱）
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: '使用者名稱',
                    prefixIcon: Icon(Icons.account_circle),
                    border: OutlineInputBorder(),
                    helperText: '3-20個字元，將作為您的顯示名稱',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '請輸入使用者名稱';
                    }
                    if (value.length < 3 || value.length > 20) {
                      return '使用者名稱長度需為 3-20 個字元';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                // 密碼
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: '密碼',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: const OutlineInputBorder(),
                    helperText: '至少 6 個字元',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '請輸入密碼';
                    }
                    if (value.length < 6) {
                      return '密碼至少需要 6 個字元';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                // 確認密碼
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: '確認密碼',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '請再次輸入密碼';
                    }
                    if (value != _passwordController.text) {
                      return '兩次輸入的密碼不一致';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 24),

                // 註冊按鈕
                FilledButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '註冊',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 24),

                // 分隔線
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '或',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // Google 登入按鈕
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(double.infinity, 50),
                    side: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  icon: Image.asset(
                    'assets/google_logo.png',
                    height: 24,
                    width: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.g_mobiledata, size: 24);
                    },
                  ),
                  label: const Text(
                    '使用 Google 帳號註冊',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 登入連結
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('已有帳號？'),
                    TextButton(
                      onPressed: _isLoading ? null : () => context.pop(),
                      child: const Text('立即登入'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
