# Resident Approval Status - Code Snippets

## 1. Login Flow - Approval Status Check

**File:** `lib/modules/resident/presentation/screens/user_login_screen.dart` (Lines 32-93)

### Complete _attemptLogin() Method

```dart
Future<void> _attemptLogin() async {
  if (!_formKey.currentState!.validate()) {
    setState(() => _loginFailed = false);
    return;
  }
  FocusScope.of(context).unfocus();
  setState(() { _loading = true; _loginFailed = false; });

  try {
    // UseCase를 통한 로그인 (비즈니스 로직 포함)
    final loginUseCase = ref.read(loginResidentUseCaseProvider);
    final res = await loginUseCase.execute(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    final data = res['data'] ?? res;
    final accessToken = data['accessToken'] as String?;
    final user = data['user'] as Map<String, dynamic>?;
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('토큰이 응답에 없습니다.');
    }

    await ref.read(authStateProvider.notifier).loginSuccess(
      user ?? <String, dynamic>{},
      accessToken,
    );

    // ==================== CRITICAL: APPROVAL STATUS CHECK ====================
    // approvalStatus에 따른 조건부 라우팅
    final approvalStatus = user?['approvalStatus'] as String?;
    print('🔐 APPROVAL STATUS: $approvalStatus (type: ${approvalStatus.runtimeType})');
    if (mounted) {
      if (approvalStatus == 'REJECTED') {
        // 거부됨만: 홈 화면(로그인 페이지)로 리다이렉트
        print('❌ REJECTED: 홈 화면으로 이동');
        _usernameController.clear();
        _passwordController.clear();
        setState(() => _loginFailed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('가입이 거부되었습니다. 관리자에게 문의해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
        context.go('/');
      } else {
        // PENDING, APPROVED 모두: 승인 대기 화면으로 이동 (3초 후 자동 대시보드 이동)
        print('✅ PENDING 또는 APPROVED: 승인 대기 화면으로 이동');
        context.goNamed('residentApprovalPending');
      }
    }
    // =========================================================================
  } catch (e) {
    setState(() => _loginFailed = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패: $e')),
      );
    }
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}
```

---

## 2. User Entity - Approval Status Field

**File:** `lib/domain/entities/user.dart`

### Field Declaration
```dart
class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.userType,
    this.buildingId,
    this.dong,
    this.ho,
    this.phoneNumber,
    this.permissions = const {},
    this.profileImageUrl,
    this.approvalStatus,  // ← LINE 16
  });

  final String id;
  final String email;
  final String name;
  final UserType userType;
  final String? buildingId;
  final String? dong;
  final String? ho;
  final String? phoneNumber;
  final Map<String, dynamic> permissions;
  final String? profileImageUrl;
  final String? approvalStatus; // PENDING, APPROVED, REJECTED ← LINE 29
```

### fromJson() Method
```dart
factory User.fromJson(Map<String, dynamic> json) {
  print('🔍 User.fromJson - Raw JSON: $json');

  UserType userType;

  // role 필드를 UserType enum으로 변환
  switch (json['role'] as String?) {
    case 'headquarters':
      userType = UserType.headquarters;
      break;
    case 'admin':
      userType = UserType.admin;
      break;
    case 'manager':
    case 'staff':  // API가 staff로 반환
      userType = UserType.manager;
      break;
    case 'resident':
    case 'user':
      userType = UserType.user;
      break;
    default:
      userType = UserType.user;
  }

  final phoneNumber = json['phoneNumber'] as String?;
  print('📞 User.fromJson - Extracted phoneNumber: $phoneNumber');

  final user = User(
    id: json['id'] as String,
    email: json['email'] as String? ?? '',
    name: json['name'] as String,
    userType: userType,
    buildingId: json['buildingId'] as String?,
    dong: json['dong'] as String?,
    ho: json['ho'] as String?,
    phoneNumber: phoneNumber,
    permissions: (json['permissions'] as Map<String, dynamic>?) ?? {},
    profileImageUrl: json['profileImageUrl'] as String?,
    approvalStatus: json['approvalStatus'] as String?,  // ← LINE 71
  );

  print('✅ User.fromJson - Created user with phoneNumber: ${user.phoneNumber}');
  return user;
}
```

### copyWith() Method
```dart
User copyWith({
  String? id,
  String? email,
  String? name,
  UserType? userType,
  String? buildingId,
  String? dong,
  String? ho,
  String? phoneNumber,
  Map<String, dynamic>? permissions,
  String? profileImageUrl,
  String? approvalStatus,  // ← LINE 119
}) {
  return User(
    id: id ?? this.id,
    email: email ?? this.email,
    name: name ?? this.name,
    userType: userType ?? this.userType,
    buildingId: buildingId ?? this.buildingId,
    dong: dong ?? this.dong,
    ho: ho ?? this.ho,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    permissions: permissions ?? this.permissions,
    profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    approvalStatus: approvalStatus ?? this.approvalStatus,
  );
}
```

---

## 3. Auth State Management - Login Success

**File:** `lib/modules/auth/presentation/providers/auth_state_provider.dart` (Lines 46-59)

### loginSuccess() Method
```dart
Future<void> loginSuccess(Map<String, dynamic> userData, String accessToken) async {
  try {
    print('🔑 LOGIN SUCCESS - userData: $userData');
    final user = User.fromJson(userData);  // ← Creates User with approvalStatus
    _currentUser = user;
    _accessToken = accessToken;
    state = AuthState.authenticated;
    print('✅ USER SET - userType: ${user.userType}, name: ${user.name}, id: ${user.id}');
  } catch (e) {
    print('❌ LOGIN ERROR: $e');
    setError();
    throw Exception('사용자 정보 처리 중 오류가 발생했습니다.');
  }
}
```

### Provider Exposure
```dart
final currentUserProvider = Provider<User?>((ref) {
  // authStateProvider의 상태를 감시하여 상태 변경 시 자동으로 재계산
  ref.watch(authStateProvider);
  final authNotifier = ref.read(authStateProvider.notifier);
  return authNotifier.currentUser;  // ← Returns User with approvalStatus
});
```

---

## 4. Approval Pending Screen - Auto Redirect

**File:** `lib/modules/resident/presentation/screens/resident_approval_pending_screen.dart` (Lines 16-25)

```dart
class _ResidentApprovalPendingScreenState
    extends ConsumerState<ResidentApprovalPendingScreen> {
  @override
  void initState() {
    super.initState();
    // 3초 후 자동으로 대시보드로 이동
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        print('⏳ PENDING 화면 표시 완료 - 대시보드로 이동');
        context.goNamed('userDashboard');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // UI 구축...
  }
}
```

---

## 5. Route Definitions

**File:** `lib/core/routing/router_notifier.dart` (Lines 216-238)

```dart
// 입주민 승인 대기 화면
GoRoute(
  path: '/resident-approval-pending',
  name: 'residentApprovalPending',
  builder: (context, state) => const ResidentApprovalPendingScreen(),
),

// 입주민 승인 완료 화면 (currently unused)
GoRoute(
  path: '/resident-approval-completed',
  name: 'residentApprovalCompleted',
  builder: (context, state) => const ResidentApprovalCompletedScreen(),
),

// 입주민 승인 거부 화면 (currently unused)
GoRoute(
  path: '/resident-approval-rejected',
  name: 'residentApprovalRejected',
  builder: (context, state) {
    final reason = state.uri.queryParameters['reason'];
    return ResidentApprovalRejectedScreen(reason: reason);
  },
),
```

---

## 6. Login UseCase

**File:** `lib/modules/resident/domain/usecases/login_resident_usecase.dart`

```dart
class LoginResidentUseCase {
  final ResidentAuthRepository _repository;

  LoginResidentUseCase(this._repository);

  /// 로그인 실행
  ///
  /// [username] 사용자 ID
  /// [password] 비밀번호
  ///
  /// Returns: User 데이터와 Access Token
  /// Throws: Exception if validation or login fails
  Future<Map<String, dynamic>> execute({
    required String username,
    required String password,
  }) async {
    // 비즈니스 규칙: 유효성 검증
    if (username.trim().isEmpty) {
      throw Exception('아이디를 입력해 주세요.');
    }

    if (password.isEmpty) {
      throw Exception('비밀번호를 입력해 주세요.');
    }

    if (password.length < 4) {
      throw Exception('비밀번호는 최소 4자 이상이어야 합니다.');
    }

    // Repository를 통한 로그인
    try {
      final result = await _repository.login(
        username: username.trim(),
        password: password,
      );

      return result;
    } catch (e) {
      // 에러 메시지를 사용자 친화적으로 변환
      if (e.toString().contains('401')) {
        throw Exception('아이디 또는 비밀번호가 일치하지 않습니다.');
      }
      rethrow;
    }
  }
}
```

---

## 7. How to Access Approval Status in Other Screens

### Option 1: Use currentUserProvider
```dart
final user = ref.read(currentUserProvider);
final approvalStatus = user?.approvalStatus;

print('Current approval status: $approvalStatus');
if (approvalStatus == 'APPROVED') {
  // User is approved
}
```

### Option 2: Watch for Changes (in ConsumerWidget)
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final user = ref.watch(currentUserProvider);
  final approvalStatus = user?.approvalStatus;
  
  if (approvalStatus == 'PENDING') {
    return Text('Waiting for approval...');
  }
  
  return UserDashboard();
}
```

### Option 3: Listen for Auth State Changes
```dart
ref.listen<AuthState>(authStateProvider, (previous, next) {
  if (next == AuthState.authenticated) {
    final user = ref.read(currentUserProvider);
    print('Login complete with status: ${user?.approvalStatus}');
  }
});
```

---

## 8. API Response Example

### Expected Login API Response
```json
{
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "resident_123",
      "email": "user@example.com",
      "name": "Park Min-jun",
      "role": "resident",
      "buildingId": "building_1",
      "dong": "A",
      "ho": "101",
      "phoneNumber": "01012345678",
      "approvalStatus": "PENDING"
    }
  }
}
```

### Possible approvalStatus Values
- `"PENDING"` - Awaiting admin approval
- `"APPROVED"` - Admin has approved
- `"REJECTED"` - Admin has rejected

