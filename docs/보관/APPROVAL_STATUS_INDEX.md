> **보관 문서** · 2026-08-21 폐기. 현재 코드와 다릅니다. 참고하지 마십시오.
> 대체 문서: [앱 코드지도](../코드지도.md) · [기능정의서](../../../docs/2-사양서/기능정의서.md)
> 남겨 둔 이유: 입주민 승인 상태 문서군 5개의 색인. 당시 분기 설계를 왜 그렇게 잡았는지가 이 묶음에만 있음

---

# Resident Approval Status - Complete Documentation Index

This documentation covers how the resident user approval status is checked and processed after login in the VibeForge building management system.

## Documents Overview

### 1. Quick Reference Guide
**File:** `approval_status_quick_reference.md`

Start here for a fast understanding of:
- Three approval states (PENDING, APPROVED, REJECTED)
- Routing decisions for each state
- Key file locations
- Debug output patterns
- Flow diagram

**Best for:** Quick lookups, debugging, understanding the overall flow

---

### 2. Detailed Flow Analysis
**File:** `resident_approval_flow_analysis.md` (14 KB)

Comprehensive analysis including:
- User entity storage and structure
- Complete login flow with approval status handling
- Detailed screen descriptions (pending, completed, rejected)
- Routing configuration
- State flow diagrams
- Data flow from API to screen
- Provider dependency chain
- Current implementation status
- Debug print statements reference
- Potential improvements

**Best for:** Deep understanding, implementation details, troubleshooting

---

### 3. Code Snippets
**File:** `approval_status_code_snippets.md` (11 KB)

Complete, ready-to-reference code sections:
- Full `_attemptLogin()` method
- User entity field declarations
- Auth state management code
- Approval pending screen implementation
- Route definitions
- UseCase code
- Examples of accessing approval status in other screens
- Expected API response format

**Best for:** Implementation, copy-paste reference, understanding exact code

---

## Quick Start Navigation

### I want to understand...

**How the approval status is checked after login:**
1. Start with `approval_status_quick_reference.md` (Section: "Code Location Map")
2. See detailed implementation in `resident_approval_flow_analysis.md` (Section 2)
3. View actual code in `approval_status_code_snippets.md` (Section 1)

**Where the approval status is stored:**
1. Read `approval_status_quick_reference.md` (Section: "User Entity Storage")
2. See structure in `resident_approval_flow_analysis.md` (Section 1)
3. View code in `approval_status_code_snippets.md` (Section 2)

**What screens are shown for each status:**
1. Check `approval_status_quick_reference.md` (Section: "Three Approval States")
2. Read detailed descriptions in `resident_approval_flow_analysis.md` (Section 3)
3. See route definitions in `approval_status_code_snippets.md` (Section 5)

**How to debug approval status issues:**
1. See debug outputs in `approval_status_quick_reference.md` (Section: "Debug Output")
2. Read full analysis in `resident_approval_flow_analysis.md` (Section 9)
3. Use debug lines from `approval_status_code_snippets.md`

**How to access approval status in my screen:**
1. View code examples in `approval_status_code_snippets.md` (Section 7)
2. Understand providers in `resident_approval_flow_analysis.md` (Section 7)
3. See implementation patterns in `approval_status_code_snippets.md`

---

## Key Files Referenced

These are the actual source files mentioned in the documentation:

### Core Approval Logic
- **Login screen:** `lib/modules/resident/presentation/screens/user_login_screen.dart` (Lines 60-82)
- **User entity:** `lib/domain/entities/user.dart` (Lines 29, 71, 91, 119)
- **Auth state:** `lib/modules/auth/presentation/providers/auth_state_provider.dart` (Lines 46-59)

### Approval Status Screens
- **Pending screen:** `lib/modules/resident/presentation/screens/resident_approval_pending_screen.dart`
- **Completed screen:** `lib/modules/resident/presentation/screens/resident_approval_completed_screen.dart`
- **Rejected screen:** `lib/modules/resident/presentation/screens/resident_approval_rejected_screen.dart`

### Supporting Files
- **Routing:** `lib/core/routing/router_notifier.dart` (Lines 216-238)
- **Providers:** `lib/modules/resident/presentation/providers/resident_providers.dart` (Lines 67-70)
- **UseCase:** `lib/modules/resident/domain/usecases/login_resident_usecase.dart`

---

## The Approval Status Flow at a Glance

```
User Login
    ↓
LoginResidentUseCase.execute()
    ↓
API Response with approvalStatus
    ↓
AuthStateNotifier.loginSuccess() - stores User with approvalStatus
    ↓
Check approvalStatus value:
    ├─ "REJECTED"    → Show error + redirect to /
    ├─ "PENDING"     → Show ResidentApprovalPendingScreen (3-sec timer) → dashboard
    └─ "APPROVED"    → Show ResidentApprovalPendingScreen (3-sec timer) → dashboard
```

---

## Three Approval States Explained

### PENDING (대기중 - Awaiting Admin Approval)
- User has logged in but not yet approved by building admin
- **Screen:** ResidentApprovalPendingScreen
- **Behavior:** Shows loading animation, auto-redirects after 3 seconds
- **Next Action:** Admin approves → State becomes APPROVED
- **Message:** "관리자\n승인 대기중" (Awaiting Admin Approval)

### APPROVED (승인완료 - Approval Completed)
- User has been approved by the building admin
- **Screen:** ResidentApprovalPendingScreen (currently - could use ResidentApprovalCompletedScreen)
- **Behavior:** Shows loading animation, auto-redirects after 3 seconds
- **Next Action:** Redirects to user dashboard
- **Message:** Same as PENDING

### REJECTED (거부됨 - Rejected)
- User's registration has been rejected by the building admin
- **Screen:** Home screen (login page) with error snackbar
- **Behavior:** Shows error message, clears form
- **Next Action:** User can try to reapply or contact admin
- **Message:** "가입이 거부되었습니다. 관리자에게 문의해주세요." (Registration denied. Contact administrator.)

---

## What to Know About the Current Implementation

### Implemented Features
- Approval status is checked immediately after login
- REJECTED users are prevented from accessing the app
- PENDING and APPROVED users see a waiting screen
- 3-second auto-redirect timer to dashboard
- Approval status stored in User entity throughout the session
- Complete debug logging for troubleshooting

### Areas for Enhancement
- APPROVED users could show a success screen (ResidentApprovalCompletedScreen)
- REJECTED users could show a detailed rejection screen with reason
- Could add polling mechanism to check for approval status updates
- Could add logout/retry options during approval waiting

---

## How Approval Status Flows Through the App

### 1. API Response
The login API includes `approvalStatus` field in the user object:
```json
{
  "user": {
    "id": "123",
    "name": "John Doe",
    "role": "resident",
    "approvalStatus": "PENDING"
  },
  "accessToken": "..."
}
```

### 2. User Entity
The approvalStatus is stored as a field in the User entity:
```dart
class User {
  final String? approvalStatus; // 'PENDING', 'APPROVED', or 'REJECTED'
}
```

### 3. Auth State
After login, the User is stored in the auth state notifier:
```dart
AuthStateNotifier._currentUser = User(...approvalStatus: 'PENDING'...)
```

### 4. Current User Provider
The approval status is accessible via currentUserProvider:
```dart
final user = ref.read(currentUserProvider);
final status = user?.approvalStatus; // Access anytime
```

### 5. Routing Decision
The status determines which screen is shown:
```dart
if (approvalStatus == 'REJECTED') {
  context.go('/');
} else {
  context.goNamed('residentApprovalPending');
}
```

---

## Debug Checklist

When troubleshooting approval status issues, check:

1. **API Response Check**
   - Is `approvalStatus` field present in login response?
   - Is it one of: 'PENDING', 'APPROVED', 'REJECTED'?
   - Check network logs with `API_DEBUG=true`

2. **User Entity Check**
   - Look for log: `🔍 User.fromJson - Raw JSON: ...`
   - Verify approvalStatus was parsed correctly

3. **Auth State Check**
   - Look for log: `🔑 LOGIN SUCCESS - userData: ...`
   - Check if `approvalStatus` is in the userData

4. **Routing Decision Check**
   - Look for log: `🔐 APPROVAL STATUS: ... `
   - Check if condition matched (REJECTED vs PENDING/APPROVED)
   - Verify correct screen shown

5. **Screen Behavior Check**
   - For PENDING/APPROVED: Look for `⏳ PENDING 화면 표시 완료...` in logs
   - Check if 3-second timer was triggered
   - Verify redirect to userDashboard occurred

---

## Additional Resources

For more information about the VibeForge app architecture:
- See `CLAUDE.md` for complete project overview
- Check `lib/core/routing/router_notifier.dart` for routing configuration
- Review `lib/modules/auth/presentation/providers/auth_state_provider.dart` for auth state management

---

## Document Versions

- **Created:** November 13, 2025
- **Last Updated:** November 13, 2025
- **Applies to:** VibeForge Building Management Flutter App v1.0+
- **Status:** Complete analysis of resident approval status flow

---

## Questions or Issues?

Refer to the specific section in each document for detailed information:
- **Quick answers:** `approval_status_quick_reference.md`
- **Deep dives:** `resident_approval_flow_analysis.md`
- **Code samples:** `approval_status_code_snippets.md`

