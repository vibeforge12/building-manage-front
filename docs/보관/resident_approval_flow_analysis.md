> **보관 문서** · 2026-08-21 폐기. 현재 코드와 다릅니다. 참고하지 마십시오.
> 대체 문서: [앱 코드지도](../코드지도.md) · [기능정의서](../../../docs/2-사양서/기능정의서.md)
> 남겨 둔 이유: 입주민 승인 흐름 분석. 현재 로직과 어긋난 지점이 구조감사 2.4절에 기록됨

---

# Resident Approval Status Check Flow - Comprehensive Analysis

## Overview
The resident approval status is checked immediately after login and determines which screen the user is directed to. The system supports three approval states: **PENDING** (대기중), **APPROVED** (승인완료), and **REJECTED** (거부됨).

---

## 1. User Entity - Approval Status Storage

**File:** `lib/domain/entities/user.dart`

### Key Field:
```dart
final String? approvalStatus; // PENDING, APPROVED, REJECTED
```

### Properties:
- **Line 29:** `approvalStatus` field declaration
- **Line 71:** Extracted from API response in `User.fromJson()`
- **Line 91:** Included in `toJson()` serialization
- **Line 119:** Supports `copyWith()` for immutable updates

### Important Code Section:
```dart
class User extends Equatable {
  const User({
    // ... other fields ...
    this.approvalStatus,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    // ... other parsing ...
    approvalStatus: json['approvalStatus'] as String?,
  }
}
```

---

## 2. Login Flow - Approval Status Handling

**File:** `lib/modules/resident/presentation/screens/user_login_screen.dart`

### Entry Point:
**Lines 32-93:** `_attemptLogin()` method

### Step-by-Step Process:

#### Step 1: UseCase Execution (Lines 42-46)
```dart
final loginUseCase = ref.read(loginResidentUseCaseProvider);
final res = await loginUseCase.execute(
  username: _usernameController.text.trim(),
  password: _passwordController.text,
);
```

#### Step 2: Token Extraction (Lines 48-53)
```dart
final data = res['data'] ?? res;
final accessToken = data['accessToken'] as String?;
final user = data['user'] as Map<String, dynamic>?;
if (accessToken == null || accessToken.isEmpty) {
  throw Exception('토큰이 응답에 없습니다.');
}
```

#### Step 3: User Authentication (Lines 55-58)
```dart
await ref.read(authStateProvider.notifier).loginSuccess(
  user ?? <String, dynamic>{},
  accessToken,
);
```
This sets `AuthState.authenticated` and stores the user including their `approvalStatus`.

#### Step 4: **CRITICAL - Approval Status Routing (Lines 60-82)**

```dart
// approvalStatus에 따른 조건부 라우팅
final approvalStatus = user?['approvalStatus'] as String?;
print('🔐 APPROVAL STATUS: $approvalStatus (type: ${approvalStatus.runtimeType})');

if (mounted) {
  if (approvalStatus == 'REJECTED') {
    // REJECTED: Return to home (login screen) with error message
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
    // PENDING or APPROVED: Show approval pending screen
    print('✅ PENDING 또는 APPROVED: 승인 대기 화면으로 이동');
    context.goNamed('residentApprovalPending');
  }
}
```

### Key Logic:
- **REJECTED:** Clears form, shows error snackbar, redirects to `/` (home)
- **PENDING or APPROVED:** Both route to `residentApprovalPending` screen (shown for 3 seconds, then auto-redirect to dashboard)

---

## 3. Approval Status Screens

### 3.1 Pending/Processing Screen
**File:** `lib/modules/resident/presentation/screens/resident_approval_pending_screen.dart`

**Purpose:** Shown for users with PENDING or APPROVED status

**Key Features:**
- **Lines 16-25:** 3-second auto-redirect timer in `initState()`
- **Line 21:** Debug log: `'⏳ PENDING 화면 표시 완료 - 대시보드로 이동'`
- **Line 22:** Auto-routes to `userDashboard` after 3 seconds

**UI Elements:**
- Loading animation (circular progress indicator)
- Title: "관리자\n승인 대기중" (Awaiting Admin Approval)
- Description: "건물 관리자의 승인을 기다리고 있습니다.\n\n승인 시 입주민 서비스를 이용할 수 있습니다."
- Timer message: "3초 후 자동으로 이동합니다..."

### 3.2 Approval Completed Screen
**File:** `lib/modules/resident/presentation/screens/resident_approval_completed_screen.dart`

**Purpose:** Currently NOT used in the login flow (reserved for future use)

**Key Features:**
- **Line 49-54:** Blue checkmark icon (✓)
- **Title:** "승인이\n완료되었습니다"
- **Description:** "건물 관리자의 승인이 완료되었습니다.\n\n이제 입주민 서비스를 이용할 수 있습니다."
- **Line 102:** "홈으로 이동" button routes to `userDashboard`

### 3.3 Rejection Screen
**File:** `lib/modules/resident/presentation/screens/resident_approval_rejected_screen.dart`

**Purpose:** NOT currently shown after login (currently redirects to home with error snackbar instead)

**Key Features:**
- **Constructor Parameter:** `final String? reason;` (Line 6)
- **Lines 54-59:** Red rejection icon (✓)
- **Title:** "관리자\n승인 보류"
- **Description:** Shows rejection reason or default admin contact message
- **Line 151:** "돌아가기" button routes back to home `/`

---

## 4. Routing Configuration

**File:** `lib/core/routing/router_notifier.dart`

### Route Definitions (Lines 216-238):

```dart
// 입주민 승인 대기 화면
GoRoute(
  path: '/resident-approval-pending',
  name: 'residentApprovalPending',
  builder: (context, state) => const ResidentApprovalPendingScreen(),
),

// 입주민 승인 완료 화면
GoRoute(
  path: '/resident-approval-completed',
  name: 'residentApprovalCompleted',
  builder: (context, state) => const ResidentApprovalCompletedScreen(),
),

// 입주민 승인 거부 화면
GoRoute(
  path: '/resident-approval-rejected',
  name: 'residentApprovalRejected',
  builder: (context, state) {
    final reason = state.uri.queryParameters['reason'];
    return ResidentApprovalRejectedScreen(reason: reason);
  },
),
```

### Protected Route Check:
- **Lines 74-88:** `residentApprovalPending`, `residentApprovalCompleted`, and `residentApprovalRejected` are **NOT** in the protected routes list
- This means they are **publicly accessible** and don't require authentication
- Users on these screens are technically authenticated but shown a special status screen

---

## 5. Complete User Journey - State Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│ User enters credentials in UserLoginScreen              │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ LoginResidentUseCase.execute() - API Call              │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ API Response includes:                                  │
│ - accessToken                                           │
│ - user { id, name, approvalStatus: ... }              │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ AuthStateNotifier.loginSuccess(user, token)            │
│ - Creates User entity with approvalStatus              │
│ - Sets AuthState.authenticated                         │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
         ┌───────┴────────┬─────────────┐
         │                │             │
         ▼                ▼             ▼
    REJECTED         PENDING       APPROVED
         │                │             │
         │                └─────┬───────┘
         │                      │
         ▼                      ▼
    Home ('/') with      ResidentApprovalPending
    Error SnackBar       (3-second timer)
         │                      │
         │                      ▼
         │              UserDashboard
         │              ('/user/dashboard')
         │                      │
         └──────────┬───────────┘
                    │
                    ▼
            User enters app

```

---

## 6. Data Flow - API to Screen

### 1. Login API Response (Example)
```json
{
  "data": {
    "accessToken": "eyJhbGc...",
    "user": {
      "id": "123",
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

### 2. User Entity Creation
```dart
// In User.fromJson()
final user = User(
  id: json['id'],
  email: json['email'],
  name: json['name'],
  userType: UserType.user,  // from role: 'resident'
  buildingId: json['buildingId'],
  dong: json['dong'],
  ho: json['ho'],
  phoneNumber: json['phoneNumber'],
  approvalStatus: json['approvalStatus']  // 'PENDING', 'APPROVED', or 'REJECTED'
);
```

### 3. Authentication State Update
```dart
// In AuthStateNotifier.loginSuccess()
_currentUser = user;  // User with approvalStatus included
_accessToken = accessToken;
state = AuthState.authenticated;
```

### 4. Router Navigation Decision
```dart
// In UserLoginScreen._attemptLogin()
final approvalStatus = user?['approvalStatus'] as String?;

if (approvalStatus == 'REJECTED') {
  // Show error and return to home
  context.go('/');
} else {
  // PENDING or APPROVED both go to waiting screen
  context.goNamed('residentApprovalPending');
}
```

---

## 7. Provider Dependency Chain

```
loginResidentUseCaseProvider
  └── residentAuthRepositoryProvider
      └── residentAuthRemoteDataSourceProvider
          └── ApiClient (HTTP calls)
              └── AuthInterceptor (Token management)
```

**Provider Location:** `lib/modules/resident/presentation/providers/resident_providers.dart`

---

## 8. Current Implementation Status

### Implemented:
✅ **REJECTED** state detection and routing  
✅ **PENDING** state detection and auto-redirect  
✅ **APPROVED** state detection and auto-redirect (same as PENDING)  
✅ Approval pending screen with 3-second timer  
✅ User entity storage with approvalStatus  
✅ Error messaging for rejected users  

### Not Fully Utilized:
⚠️ **ResidentApprovalCompletedScreen** - Defined but not currently used  
⚠️ **ResidentApprovalRejectedScreen** - Defined but not currently used (instead, uses snackbar + home redirect)  
⚠️ **Query parameter support** - Rejection screen supports passing reason via URL param, but not used

---

## 9. Debug Print Statements

The following print statements help trace the approval status flow:

```dart
// In UserLoginScreen._attemptLogin() - Line 62
'🔐 APPROVAL STATUS: $approvalStatus (type: ${approvalStatus.runtimeType})'

// In UserLoginScreen._attemptLogin() - Lines 66, 79
'❌ REJECTED: 홈 화면으로 이동'
'✅ PENDING 또는 APPROVED: 승인 대기 화면으로 이동'

// In ResidentApprovalPendingScreen.initState() - Line 21
'⏳ PENDING 화면 표시 완료 - 대시보드로 이동'

// In User.fromJson() - Lines 33, 58, 74
'🔍 User.fromJson - Raw JSON: $json'
'📞 User.fromJson - Extracted phoneNumber: $phoneNumber'
'✅ User.fromJson - Created user with phoneNumber: ${user.phoneNumber}'
```

---

## 10. Key Files Summary

| File | Purpose | Key Lines |
|------|---------|-----------|
| `lib/domain/entities/user.dart` | User entity with approvalStatus | 29, 71, 91, 119 |
| `lib/modules/resident/presentation/screens/user_login_screen.dart` | Login and approval routing logic | 60-82 |
| `lib/modules/resident/presentation/screens/resident_approval_pending_screen.dart` | Waiting screen (3-sec timer) | 16-25 |
| `lib/modules/resident/presentation/screens/resident_approval_completed_screen.dart` | Completion screen (unused) | N/A |
| `lib/modules/resident/presentation/screens/resident_approval_rejected_screen.dart` | Rejection screen (unused) | N/A |
| `lib/core/routing/router_notifier.dart` | Route definitions | 216-238 |
| `lib/modules/resident/presentation/providers/resident_providers.dart` | Provider setup | 67-70 |
| `lib/modules/auth/presentation/providers/auth_state_provider.dart` | Auth state management | 46-59 |

---

## 11. Potential Improvements

1. **Utilize rejection screen:** Currently rejection uses snackbar + home redirect; could use `ResidentApprovalRejectedScreen` with reason parameter:
   ```dart
   context.pushNamed(
     'residentApprovalRejected',
     queryParameters: {'reason': approvalReason ?? ''}
   );
   ```

2. **Add completion screen display:** Could show `ResidentApprovalCompletedScreen` for APPROVED users before redirecting to dashboard

3. **Add polling mechanism:** Periodically check for approval status updates while on pending screen (requires backend polling/WebSocket support)

4. **Add logout option:** Allow users to logout from approval pending screen instead of waiting 3 seconds

5. **Add retry button:** For rejected users, offer a way to reapply or contact admin directly

