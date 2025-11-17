import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_practice_app/services/auth_service.dart';

void main() {
  group('AuthService 測試', () {
    setUp(() async {
      // 每次測試前清空 SharedPreferences
      SharedPreferences.setMockInitialValues({});
      final authService = AuthService();
      await authService.initialize();
      await authService.logout(); // 確保每次測試都是未登入狀態
    });

    test('初始化後應該是未登入狀態', () async {
      final authService = AuthService();
      await authService.initialize();

      expect(authService.isAuthenticated, false);
      expect(authService.currentUser, null);
    });

    test('可以成功註冊新使用者', () async {
      final authService = AuthService();
      await authService.initialize();

      final result = await authService.register(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
        displayName: 'Test User',
      );

      expect(result, true);
      expect(authService.isAuthenticated, true);
      expect(authService.currentUser?.username, 'testuser');
      expect(authService.currentUser?.email, 'test@example.com');
      expect(authService.currentUser?.displayName, 'Test User');
    });

    test('不允許重複的使用者名稱', () async {
      final authService = AuthService();
      await authService.initialize();

      // 第一次註冊
      await authService.register(
        email: 'test1@example.com',
        username: 'testuser',
        password: 'password123',
      );

      // 登出
      await authService.logout();

      // 嘗試使用相同使用者名稱註冊
      expect(
        () => authService.register(
          email: 'test2@example.com',
          username: 'testuser',
          password: 'password456',
        ),
        throwsException,
      );
    });

    test('不允許重複的 Email', () async {
      final authService = AuthService();
      await authService.initialize();

      // 第一次註冊
      await authService.register(
        email: 'test@example.com',
        username: 'testuser1',
        password: 'password123',
      );

      // 登出
      await authService.logout();

      // 嘗試使用相同 Email 註冊
      expect(
        () => authService.register(
          email: 'test@example.com',
          username: 'testuser2',
          password: 'password456',
        ),
        throwsException,
      );
    });

    test('可以使用使用者名稱登入', () async {
      final authService = AuthService();
      await authService.initialize();

      // 註冊
      await authService.register(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
      );

      // 登出
      await authService.logout();
      expect(authService.isAuthenticated, false);

      // 使用使用者名稱登入
      final result = await authService.login(
        usernameOrEmail: 'testuser',
        password: 'password123',
      );

      expect(result, true);
      expect(authService.isAuthenticated, true);
      expect(authService.currentUser?.username, 'testuser');
    });

    test('可以使用 Email 登入', () async {
      final authService = AuthService();
      await authService.initialize();

      // 註冊
      await authService.register(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
      );

      // 登出
      await authService.logout();

      // 使用 Email 登入
      final result = await authService.login(
        usernameOrEmail: 'test@example.com',
        password: 'password123',
      );

      expect(result, true);
      expect(authService.isAuthenticated, true);
    });

    test('錯誤的密碼應該登入失敗', () async {
      final authService = AuthService();
      await authService.initialize();

      // 註冊
      await authService.register(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
      );

      // 登出
      await authService.logout();

      // 使用錯誤密碼登入
      expect(
        () => authService.login(
          usernameOrEmail: 'testuser',
          password: 'wrongpassword',
        ),
        throwsException,
      );
    });

    test('可以更新使用者資料', () async {
      final authService = AuthService();
      await authService.initialize();

      // 註冊
      await authService.register(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
      );

      // 更新資料
      await authService.updateProfile(
        displayName: 'New Display Name',
      );

      expect(authService.currentUser?.displayName, 'New Display Name');
    });

    test('可以變更密碼', () async {
      final authService = AuthService();
      await authService.initialize();

      // 註冊
      await authService.register(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
      );

      // 變更密碼
      await authService.changePassword(
        oldPassword: 'password123',
        newPassword: 'newpassword456',
      );

      // 登出
      await authService.logout();

      // 使用新密碼登入
      final result = await authService.login(
        usernameOrEmail: 'testuser',
        password: 'newpassword456',
      );

      expect(result, true);
    });

    test('變更密碼時舊密碼錯誤應該失敗', () async {
      final authService = AuthService();
      await authService.initialize();

      // 註冊
      await authService.register(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
      );

      // 使用錯誤的舊密碼變更密碼
      expect(
        () => authService.changePassword(
          oldPassword: 'wrongpassword',
          newPassword: 'newpassword456',
        ),
        throwsException,
      );
    });

    test('可以刪除帳號', () async {
      final authService = AuthService();
      await authService.initialize();

      // 註冊
      await authService.register(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
      );

      // 刪除帳號
      await authService.deleteAccount('password123');

      // 確認已登出
      expect(authService.isAuthenticated, false);

      // 嘗試登入應該失敗
      expect(
        () => authService.login(
          usernameOrEmail: 'testuser',
          password: 'password123',
        ),
        throwsException,
      );
    });

    test('登出後狀態應該正確', () async {
      final authService = AuthService();
      await authService.initialize();

      // 註冊
      await authService.register(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
      );

      expect(authService.isAuthenticated, true);

      // 登出
      await authService.logout();

      expect(authService.isAuthenticated, false);
      expect(authService.currentUser, null);
    });
  });
}
