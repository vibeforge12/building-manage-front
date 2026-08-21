> ⚠️ **폐기 예정 문서 (2026-08-21)**
> 이 문서는 현재 코드와 일치하지 않습니다. 참고하지 마세요.
> 유효한 문서: `docs/프론트엔드_구조_및_문제점_분석.md`, `CLAUDE.md`

# Resident Approval Status - Quick Reference

## Three Approval States

### 1. PENDING (대기중)
- **Status:** Waiting for admin approval
- **Routing:** → ResidentApprovalPendingScreen
- **Behavior:** Shows loading animation, auto-redirects to dashboard after 3 seconds
- **File:** `resident_approval_pending_screen.dart`

### 2. APPROVED (승인완료)
- **Status:** Admin approved the resident
- **Routing:** → ResidentApprovalPendingScreen (same as PENDING)
- **Behavior:** Shows loading animation, auto-redirects to dashboard after 3 seconds
- **Note:** Could be enhanced to show ResidentApprovalCompletedScreen instead

### 3. REJECTED (거부됨)
- **Status:** Admin rejected the resident
- **Routing:** → Home screen (`/`) with error message
- **Behavior:** Shows error snackbar, clears login form
- **Message:** "가입이 거부되었습니다. 관리자에게 문의해주세요."
- **Note:** Could be enhanced to show ResidentApprovalRejectedScreen with rejection reason

---

## Code Location Map

### Where Approval Status is Checked
```
user_login_screen.dart
└── _attemptLogin() method
    ├── Lines 42-46: Call LoginResidentUseCase
    ├── Lines 48-53: Extract accessToken and user data
    ├── Lines 55-58: Update auth state
    └── Lines 60-82: CHECK APPROVAL STATUS AND ROUTE
```

### Approval Status Decision Logic (Lines 60-82)
```dart
final approvalStatus = user?['approvalStatus'] as String?;

if (approvalStatus == 'REJECTED') {
  // Show error and go to home
  context.go('/');
} else {
  // PENDING or APPROVED - both go to waiting screen
  context.goNamed('residentApprovalPending');
}
```

---

## User Entity Storage

**File:** `lib/domain/entities/user.dart` (Line 29)

```dart
final String? approvalStatus; // Stores: 'PENDING', 'APPROVED', or 'REJECTED'
```

---

## Related Screens

| Screen | Path | Route Name | Status | Purpose |
|--------|------|-----------|--------|---------|
| Pending | `/resident-approval-pending` | `residentApprovalPending` | USED | Show waiting screen |
| Completed | `/resident-approval-completed` | `residentApprovalCompleted` | UNUSED | Could show approval complete |
| Rejected | `/resident-approval-rejected?reason=...` | `residentApprovalRejected` | UNUSED | Could show rejection details |
| Dashboard | `/user/dashboard` | `userDashboard` | USED | Main resident screen |

---

## Debug Output

When user logs in, check these logs:

```
🔐 APPROVAL STATUS: PENDING (type: String)
✅ PENDING 또는 APPROVED: 승인 대기 화면으로 이동

// OR

🔐 APPROVAL STATUS: REJECTED (type: String)
❌ REJECTED: 홈 화면으로 이동
```

---

## Flow at a Glance

```
Login Credentials
       ↓
LoginResidentUseCase.execute()
       ↓
Receive API response with approvalStatus
       ↓
AuthState = authenticated
       ↓
       ├─ REJECTED? → Show error + Go to /
       │
       └─ PENDING/APPROVED? → Go to ResidentApprovalPendingScreen
                                    ↓
                                   (3 sec timer)
                                    ↓
                            Go to UserDashboard

```

---

## Key Files

1. **Authentication Check:** 
   - `lib/modules/resident/presentation/screens/user_login_screen.dart` (Lines 60-82)

2. **User Data Storage:**
   - `lib/domain/entities/user.dart` (Line 29, 71, 91, 119)

3. **Auth State Management:**
   - `lib/modules/auth/presentation/providers/auth_state_provider.dart` (Lines 46-59)

4. **Approval Screens:**
   - `lib/modules/resident/presentation/screens/resident_approval_pending_screen.dart`
   - `lib/modules/resident/presentation/screens/resident_approval_completed_screen.dart`
   - `lib/modules/resident/presentation/screens/resident_approval_rejected_screen.dart`

5. **Routing:**
   - `lib/core/routing/router_notifier.dart` (Lines 216-238)

---

## What Gets Stored in Auth State?

After successful login, the `currentUserProvider` stores:
```dart
User(
  id: "123",
  name: "Park Min-jun",
  userType: UserType.user,
  approvalStatus: "PENDING",  // ← THE KEY FIELD
  // ... other fields ...
)
```

This User object persists in memory and is accessible via:
```dart
final user = ref.read(currentUserProvider);
final status = user?.approvalStatus;  // Access approval status anytime
```

