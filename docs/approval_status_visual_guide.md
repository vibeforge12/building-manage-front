> ⚠️ **폐기 예정 문서 (2026-08-21)**
> 이 문서는 현재 코드와 일치하지 않습니다. 참고하지 마세요.
> 유효한 문서: `docs/프론트엔드_구조_및_문제점_분석.md`, `CLAUDE.md`

# Resident Approval Status - Visual Guide

## Complete User Journey Map

```
┌─────────────────────────────────────────────────────────────────┐
│                      RESIDENT LOGIN FLOW                        │
└─────────────────────────────────────────────────────────────────┘

   ┌────────────────────────────────────────────────────────┐
   │  1. RESIDENT ENTERS LOGIN CREDENTIALS                  │
   │  Screen: UserLoginScreen                              │
   │  Files: user_login_screen.dart                        │
   │  Input: username (주민ID), password                   │
   └────────────────┬─────────────────────────────────────┘
                    │
                    ▼
   ┌────────────────────────────────────────────────────────┐
   │  2. TAP LOGIN BUTTON                                    │
   │  Method: _attemptLogin() [Line 32]                    │
   │  Action: Validates form input                         │
   └────────────────┬─────────────────────────────────────┘
                    │
                    ▼
   ┌────────────────────────────────────────────────────────┐
   │  3. EXECUTE LOGIN USECASE                              │
   │  UseCase: LoginResidentUseCase.execute()              │
   │  Files: login_resident_usecase.dart                  │
   │  Action: API call with username/password             │
   └────────────────┬─────────────────────────────────────┘
                    │
                    ▼
   ┌────────────────────────────────────────────────────────┐
   │  4. BACKEND VALIDATION                                 │
   │  API Endpoint: /api/v1/resident/login                │
   │  Returns:                                             │
   │  {                                                     │
   │    "accessToken": "eyJ...",                           │
   │    "user": {                                          │
   │      "id": "resident_123",                            │
   │      "name": "Park Min-jun",                          │
   │      "role": "resident",                              │
   │      "approvalStatus": "PENDING"    ←── KEY FIELD    │
   │    }                                                   │
   │  }                                                     │
   └────────────────┬─────────────────────────────────────┘
                    │
                    ▼
   ┌────────────────────────────────────────────────────────┐
   │  5. UPDATE AUTH STATE                                   │
   │  Method: loginSuccess() [auth_state_provider.dart]   │
   │  Action:                                              │
   │  • Create User entity with approvalStatus            │
   │  • Set AuthState.authenticated                       │
   │  • Store in currentUserProvider                      │
   └────────────────┬─────────────────────────────────────┘
                    │
                    ▼ CHECK APPROVAL STATUS
    ┌───────────────┴──────────────┬──────────────┐
    │                              │              │
    ▼ REJECTED                 PENDING         APPROVED
                                   │              │
    ┌──────────────────────────┐   │              │
    │ REJECTED FLOW            │   ▼              ▼
    │ ═════════════════════    │   ┌──────────────────────────┐
    │ approvalStatus == 'R'    │   │ APPROVED/PENDING FLOW    │
    │                          │   │ ════════════════════════ │
    │ 1. Clear form            │   │ approvalStatus != 'R'    │
    │ 2. Show error snackbar:  │   │                          │
    │    "가입이 거부되었습니다" │   │ Navigate to:             │
    │                          │   │ ResidentApprovalPending  │
    │ 3. Navigate to:          │   │ Screen [Line 80]         │
    │    Home (/)              │   │                          │
    │                          │   │ File: resident_approval_ │
    │ 4. User can retry login  │   │        pending_screen.dart
    │                          │   │                          │
    │                          │   └──────────┬───────────────┘
    │                          │              │
    │                          │              ▼
    │                          │   ┌──────────────────────────┐
    │                          │   │ SHOW PENDING SCREEN      │
    │                          │   │ ═════════════════════    │
    │                          │   │ Title: "관리자 승인 대기중" │
    │                          │   │ Message: "건물 관리자의     │
    │                          │   │ 승인을 기다리고 있습니다"   │
    │                          │   │ Icon: Loading animation   │
    │                          │   │ Timer: "3초 후 이동..."    │
    │                          │   │                          │
    │                          │   └──────────┬───────────────┘
    │                          │              │
    │                          │ (3 seconds)  │
    │                          │              ▼
    │                          │   ┌──────────────────────────┐
    │                          │   │ AUTO REDIRECT TO         │
    │                          │   │ DASHBOARD                │
    │                          │   │ ═════════════════════    │
    │                          │   │ initState() [Line 19]:   │
    │                          │   │ Future.delayed(3 sec)    │
    │                          │   │                          │
    │                          │   │ Navigate: userDashboard  │
    │                          │   └──────────┬───────────────┘
    │                          │              │
    └──────────────────────────┼──────────────┤
                               │              ▼
                               │   ┌──────────────────────────┐
                               │   │ USER DASHBOARD SCREEN    │
                               │   │ ═════════════════════    │
                               │   │ Screen: UserDashboardS.  │
                               │   │ Route: '/user/dashboard' │
                               │   │ User can now access:     │
                               │   │ • View notices           │
                               │   │ • File complaints        │
                               │   │ • Access building info   │
                               │   └──────────────────────────┘
```

---

## File Structure & Navigation

```
lib/
├── domain/
│   └── entities/
│       └── user.dart
│           └── Field: approvalStatus [Line 29]
│
├── modules/
│   ├── auth/
│   │   └── presentation/providers/
│   │       └── auth_state_provider.dart
│   │           └── loginSuccess() [Line 46]
│   │
│   ├── resident/
│   │   ├── domain/usecases/
│   │   │   └── login_resident_usecase.dart
│   │   │       └── execute() - API call
│   │   │
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── user_login_screen.dart
│   │   │   │   │   └── _attemptLogin() [Line 32-93]
│   │   │   │   │       └── APPROVAL STATUS CHECK [Line 60-82]
│   │   │   │   │
│   │   │   │   ├── resident_approval_pending_screen.dart
│   │   │   │   │   └── 3-second auto-redirect [Line 16-25]
│   │   │   │   │
│   │   │   │   ├── resident_approval_completed_screen.dart
│   │   │   │   │   └── (Currently UNUSED)
│   │   │   │   │
│   │   │   │   └── resident_approval_rejected_screen.dart
│   │   │   │       └── (Currently UNUSED - uses snackbar instead)
│   │   │   │
│   │   │   └── providers/
│   │   │       └── resident_providers.dart
│   │   │           └── loginResidentUseCaseProvider [Line 67]
│   │   │
│   │   └── data/repositories/
│   │       └── resident_auth_repository_impl.dart
│   │           └── login() - API execution
│   │
│   └── headquarters/
│       └── data/datasources/
│           └── (Other modules...)
│
└── core/
    ├── routing/
    │   └── router_notifier.dart
    │       ├── Route definitions [Line 216-238]
    │       └── residentApprovalPending route [Line 216-221]
    │
    ├── network/
    │   └── api_client.dart
    │       └── HTTP calls
    │
    └── constants/
        └── user_types.dart
            └── UserType enum
```

---

## State Transition Diagram

```
                    ┌──────────────┐
                    │ INITIAL      │
                    │ (Before Login)
                    └──────┬───────┘
                           │
                    LOGIN BUTTON TAP
                           │
                           ▼
                    ┌──────────────┐
                    │ LOADING      │
                    │ (API Call)   │
                    └──────┬───────┘
                           │
             ┌─────────────┴─────────────┐
             │                           │
    API ERROR ▼                           ▼ SUCCESS
             │                      ┌──────────────┐
             │                      │ GOT RESPONSE │
             │                      │ w/ status    │
             │                      └──────┬───────┘
             │                             │
             ▼                    ┌────────┴────────┐
        ┌──────────────┐          │                 │
        │ SHOW ERROR   │    'REJECTED'         NOT 'REJECTED'
        │ SNACKBAR     │          │                 │
        └──────┬───────┘          ▼                 ▼
               │            ┌──────────────┐   ┌──────────────┐
               │            │ SHOW ERROR   │   │ SHOW PENDING │
               │            │ SNACKBAR     │   │ SCREEN       │
               │            └──────┬───────┘   └──────┬───────┘
               │                   │                  │
               ▼                   ▼          3-SEC TIMER
        ┌──────────────┐     ┌──────────────┐  │
        │ REDIRECT TO  │     │ REDIRECT TO  │  ▼
        │ HOME (/)     │     │ HOME (/)     │  ┌──────────────┐
        └──────────────┘     └──────────────┘  │ REDIRECT TO  │
                                               │ DASHBOARD    │
                                               └──────────────┘
```

---

## Approval Status Values & Behaviors

```
┌──────────────────────────────────────────────────────────────┐
│ STATUS VALUE: "PENDING"                                      │
├──────────────────────────────────────────────────────────────┤
│ Description: Awaiting admin approval                         │
│ Screen Shown: ResidentApprovalPendingScreen                 │
│ UI: Loading animation + "관리자 승인 대기중" title           │
│ Navigation: Auto-redirect to dashboard after 3 seconds      │
│ Next State: Can change to APPROVED by admin action          │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ STATUS VALUE: "APPROVED"                                     │
├──────────────────────────────────────────────────────────────┤
│ Description: Admin has approved user                         │
│ Screen Shown: ResidentApprovalPendingScreen (currently)      │
│             (Could show CompletedScreen in future)          │
│ UI: Loading animation (same as PENDING)                     │
│ Navigation: Auto-redirect to dashboard after 3 seconds      │
│ Next State: User is now fully approved                       │
│ Note: Both PENDING and APPROVED use same flow currently     │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ STATUS VALUE: "REJECTED"                                     │
├──────────────────────────────────────────────────────────────┤
│ Description: Admin has rejected user registration            │
│ Screen Shown: Home screen (/), NOT DashBoard                 │
│ UI: Error snackbar + cleared form                            │
│ Message: "가입이 거부되었습니다. 관리자에게 문의해주세요."    │
│ Navigation: User is blocked from accessing app               │
│ Next State: User can retry login or contact admin            │
│ Note: Could be enhanced with rejection reason               │
└──────────────────────────────────────────────────────────────┘
```

---

## Data Structures

### User Entity Structure
```dart
class User {
  // ... other fields ...
  final String? approvalStatus;  // ← KEY FIELD
  // Possible values: 'PENDING', 'APPROVED', 'REJECTED', or null
}
```

### Login API Response
```json
{
  "data": {
    "accessToken": "...",
    "refreshToken": "...",
    "user": {
      "id": "resident_123",
      "name": "Park Min-jun",
      "role": "resident",
      "buildingId": "building_1",
      "dong": "A",
      "ho": "101",
      "approvalStatus": "PENDING"  ← HERE
    }
  }
}
```

---

## Provider Chain

```
┌─────────────────────────────────────────────────────────┐
│ USER INPUT (username, password)                         │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ loginResidentUseCaseProvider                            │
│ └─ LoginResidentUseCase.execute()                       │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ residentAuthRepositoryProvider                          │
│ └─ ResidentAuthRepository.login()                       │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ residentAuthRemoteDataSourceProvider                    │
│ └─ ResidentAuthRemoteDataSource.login()                 │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ apiClientProvider                                       │
│ └─ ApiClient.post("/resident/login")                    │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ BACKEND API RESPONSE                                    │
│ {                                                       │
│   "data": {                                            │
│     "user": { ..., approvalStatus: "PENDING" }        │
│   }                                                     │
│ }                                                       │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ authStateProvider.notifier.loginSuccess()               │
│ └─ Create User entity with approvalStatus               │
│ └─ Set AuthState.authenticated                          │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ currentUserProvider                                     │
│ └─ Returns: User(approvalStatus: "PENDING")            │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ ROUTING DECISION                                        │
│ if approvalStatus == 'REJECTED'                         │
│   → Go to /                                             │
│ else                                                     │
│   → Go to residentApprovalPending                       │
└─────────────────────────────────────────────────────────┘
```

---

## Debug Flow Chart

```
ISSUE: User stuck on login or wrong screen after login
│
├─ CHECK 1: Is approvalStatus in API response?
│  │
│  ├─ YES ─→ CHECK 2
│  │
│  └─ NO  ─→ Backend issue: Add approvalStatus to response
│
├─ CHECK 2: Is User.fromJson() parsing it correctly?
│  │
│  ├─ YES ─→ Look for log: 🔍 User.fromJson - Raw JSON
│  │        
│  ├─ NO  ─→ Fix: User.dart line 71
│
├─ CHECK 3: Is AuthStateNotifier.loginSuccess() storing it?
│  │
│  ├─ YES ─→ Look for: 🔑 LOGIN SUCCESS
│  │        
│  ├─ NO  ─→ Fix: auth_state_provider.dart line 49
│
├─ CHECK 4: Is routing decision correct?
│  │
│  ├─ YES ─→ Look for: 🔐 APPROVAL STATUS
│  │        
│  ├─ NO  ─→ Fix: user_login_screen.dart lines 60-82
│
└─ CHECK 5: Is screen shown correctly?
   │
   ├─ PENDING  → Should see loading + 3-sec timer
   ├─ APPROVED → Should see loading + 3-sec timer  
   └─ REJECTED → Should see error snackbar + home screen
```

