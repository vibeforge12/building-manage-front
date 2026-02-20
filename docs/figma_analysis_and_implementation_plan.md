# Figma 디자인 분석 및 구현 계획

## 📊 Figma 디자인 전체 화면 목록

### 1. 유저용/화면 (25개)
1. ✅ 유저 홈화면 → `user_dashboard_screen.dart`
2. ✅ 로그인 → `user_login_screen.dart`
3. ✅ 회원가입/비밀번호 → `resident_signup_screen.dart` (Step 2)
4. ✅ 회원가입/입주자정보 → `resident_signup_screen.dart` (Step 1, 3)
5. ✅ 민원등록 → `complaint_create_screen.dart`
6. ✅ 민원 완료 → `complaint_complete_screen.dart`
7. ❌ 회원가입/건물찾기
8. ❌ 회원가입/관리자승인대기
9. ❌ 회원가입/관리자승인완료
10. ❌ 회원가입/관리자승인보류
11. ❌ 회원탈퇴 완료 팝업
12. ❌ 완료 팝업
13. ❌ 민원 상세 보기 (클릭시)
14. ❌ 내 민원 보기
15. ❌ 마이페이지
16. ❌ 마이페이지/회원수정
17. ❌ 회원탈퇴 팝업
18. ❌ 더보기-마이페이지
19. ❌ 더보기-알림
20. ❌ 공지사항 목록
21. ❌ 공지사항 자세히
22. ❌ 이벤트 목록
23. ❌ 이벤트 자세히

**구현률: 6/25 (24%)**

### 2. 관리자용/화면 (25개)
1. ✅ 관리자 홈화면 → `admin_dashboard_screen.dart`
2. ✅ 로그인 → `admin_login_screen.dart`
3. ✅ 입주민관리 → `resident_management_screen.dart`
4. ✅ 담당자 관리 → `staff_management_screen.dart`
5. ✅ 담당자 정보 수정 → `staff_edit_screen.dart`
6. ✅ 계정발급 (담당자) → `staff_account_issuance_screen.dart`
7. ✅ 건물 공지사항 → `notice_management_screen.dart`
8. ✅ 건물 공지사항/쓰기 → `notice_create_screen.dart`
13. ❌ 입주민관리/신규 가입자
14. ❌ 담당자 관리/부서별 목록
15. ❌ 담당자 관리/부서 삭제
16. ❌ 건물 이벤트 목록
17. ❌ 건물 이벤트/쓰기
18. ❌ 민원관리/전체
19. ❌ 민원보기/상세
20. ❌ 마이페이지/회원수정
21. ❌ 더보기
22. ❌ 알림/출퇴근
23. ❌ 로그인/실패 화면

**구현률: 8/25 (32%)**

### 3. 담당자용/화면 (10개)
1. ✅ 담당자 홈화면 → `manager_dashboard_screen.dart`
2. ✅ 로그인 → `manager_staff_login_screen.dart`
3. ✅ 출퇴근 조회 → `attendance_history_screen.dart`
4. ❌ 받은 민원 보기 (2개 버전)
5. ❌ 민원 상세/00민원
6. ❌ 로그인/실패
7. ❌ 더보기
8. ❌ 공지사항 목록
9. ❌ 공지사항 자세히

**구현률: 3/10 (30%)**

### 4. 본사/화면 (8개)
1. ✅ 본사 홈화면 → `headquarters_dashboard_screen.dart`
2. ✅ 로그인 → `headquarters_login_screen.dart`
3. ✅ 건물 등록 → `building_registration_screen.dart`
4. ✅ 건물 관리 → `building_management_screen.dart`
5. ✅ 부서 생성 → `department_creation_screen.dart`
6. ✅ 관리자 목록 → `manager_list_screen.dart`
7. ✅ 관리자 상세 → `manager_detail_screen.dart`
8. ✅ 계정발급 (관리자) → `admin_account_issuance_screen.dart`
9. ✅ 건물 목록 → `building_list_screen.dart`
10. ❌ 부서 삭제 화면
11. ❌ 리스트 없을 때 (Empty State)

**구현률: 9/11 (82%)**

### 5. 통합 화면 (2개)
1. ✅ 초입 로그인 화면 → `main_home_screen.dart`
2. ✅ 분기점 로그인 → `admin_login_selection_screen.dart`

**구현률: 2/2 (100%)**

---

## 📈 전체 구현 현황

- **총 Figma 디자인 화면**: 73개
- **현재 구현된 화면**: 28개
- **전체 구현률**: **38%**

---

## 🎯 우선순위별 구현 계획

### Phase 1: 긴급 (2주) - 핵심 사용자 플로우 완성
**목표**: 각 사용자 타입이 주요 기능을 사용할 수 있도록 함

#### 1.1 유저(입주민) 핵심 기능 (7일)
- [ ] 공지사항 목록 및 상세 보기
- [ ] 이벤트 목록 및 상세 보기
- [ ] 내 민원 목록 보기
- [ ] 민원 상세 보기
- [ ] 마이페이지
- [ ] 회원정보 수정
- [ ] 더보기 화면

#### 1.2 관리자 핵심 기능 (5일)
- [ ] 민원관리/전체 목록
- [ ] 민원 상세 보기 및 답변
- [ ] 입주민관리/신규 가입자 승인
- [ ] 이벤트 작성 및 관리

#### 1.3 담당자 핵심 기능 (2일)
- [ ] 받은 민원 목록
- [ ] 민원 상세 처리
- [ ] 공지사항 목록 및 상세

### Phase 2: 중요 (3주) - 사용자 경험 향상
**목표**: 완전한 사용자 경험 제공

#### 2.1 회원가입 플로우 개선 (5일)
- [ ] 유저: 건물 찾기 화면
- [ ] 유저: 관리자 승인 대기 화면
- [ ] 유저: 관리자 승인 완료 화면
- [ ] 유저: 관리자 승인 보류 화면
- [ ] 관리자: 회원가입 플로우

#### 2.2 알림 시스템 (4일)
- [ ] 유저: 더보기-알림
- [ ] 관리자: 알림/출퇴근
- [ ] 실시간 알림 기능

#### 2.3 에러 처리 및 Empty State (3일)
- [ ] 로그인 실패 화면 (유저/관리자/담당자)
- [ ] Empty State 화면들
- [ ] 에러 팝업 및 처리

#### 2.4 마이페이지 및 설정 (4일)
- [ ] 유저: 회원탈퇴 팝업
- [ ] 유저: 회원탈퇴 완료 팝업
- [ ] 관리자: 마이페이지/회원수정
- [ ] 담당자: 더보기 화면

### Phase 3: 개선 (2주) - 디테일 완성
**목표**: 사용성 및 완성도 향상

#### 3.1 담당자 관리 개선 (3일)
- [ ] 부서별 담당자 목록
- [ ] 부서 삭제 기능
- [ ] 담당자 통계 및 리포트

#### 3.2 팝업 및 다이얼로그 (3일)
- [ ] 완료 팝업 컴포넌트
- [ ] 확인 다이얼로그
- [ ] 커스텀 알림 다이얼로그

#### 3.3 UI/UX 개선 (4일)
- [ ] 로딩 상태 개선
- [ ] 애니메이션 추가
- [ ] 반응형 레이아웃 최적화

---

## 📋 상세 TDD (Todo-Driven Development)

### 🔴 Phase 1.1: 유저(입주민) 핵심 기능 (긴급)

#### 1. 공지사항 기능
**파일**: `lib/modules/resident/presentation/screens/notice_list_screen.dart`

**할 일**:
- [ ] 공지사항 목록 화면 생성
  - [ ] API: GET `/api/v1/notices` 연동
  - [ ] 리스트뷰 구현 (ListView.builder)
  - [ ] 공지사항 카드 위젯 생성
  - [ ] 날짜 포맷팅 (intl 사용)
  - [ ] 새 공지 뱃지 표시
- [ ] 공지사항 상세 화면 생성
  - [ ] 파일: `notice_detail_screen.dart`
  - [ ] API: GET `/api/v1/notices/:id` 연동
  - [ ] 이미지 표시 (cached_network_image)
  - [ ] HTML 컨텐츠 렌더링 고려
  - [ ] 이전/다음 공지 네비게이션
- [ ] 상태 관리
  - [ ] `noticeListProvider` 생성
  - [ ] 로딩/에러/빈 상태 처리
  - [ ] 페이지네이션 또는 무한 스크롤
- [ ] 라우팅
  - [ ] `/user/notices` 경로 추가
  - [ ] `/user/notices/:id` 경로 추가

**예상 소요 시간**: 1.5일

---

#### 2. 이벤트 기능
**파일**: `lib/modules/resident/presentation/screens/event_list_screen.dart`

**할 일**:
- [ ] 이벤트 목록 화면 생성
  - [ ] API: GET `/api/v1/events` 연동
  - [ ] 그리드 또는 카드 레이아웃
  - [ ] 이벤트 썸네일 이미지
  - [ ] 진행 중/종료 상태 표시
  - [ ] 필터링 (진행중/종료)
- [ ] 이벤트 상세 화면 생성
  - [ ] 파일: `event_detail_screen.dart`
  - [ ] API: GET `/api/v1/events/:id` 연동
  - [ ] 이벤트 이미지 슬라이더
  - [ ] 참여하기 버튼 (필요시)
  - [ ] 공유 기능 (필요시)
- [ ] 상태 관리
  - [ ] `eventListProvider` 생성
  - [ ] 필터 상태 관리
  - [ ] 로딩/에러/빈 상태 처리
- [ ] 라우팅
  - [ ] `/user/events` 경로 추가
  - [ ] `/user/events/:id` 경로 추가

**예상 소요 시간**: 1.5일

---

#### 3. 내 민원 목록 및 상세
**파일**: `lib/modules/resident/presentation/screens/my_complaint_list_screen.dart`

**할 일**:
- [ ] 내 민원 목록 화면 생성
  - [ ] API: GET `/api/v1/complaints/my` 연동
  - [ ] 민원 상태별 필터 (접수/처리중/완료)
  - [ ] 민원 카드 위젯
  - [ ] 상태별 색상 구분
  - [ ] 정렬 옵션 (최신순/오래된순)
- [ ] 민원 상세 화면 생성
  - [ ] 파일: `complaint_detail_screen.dart`
  - [ ] API: GET `/api/v1/complaints/:id` 연동
  - [ ] 민원 정보 표시 (제목, 내용, 이미지, 부서)
  - [ ] 답변 내역 표시
  - [ ] 처리 상태 타임라인
- [ ] 상태 관리
  - [ ] `myComplaintListProvider` 생성
  - [ ] 필터 상태 관리
  - [ ] 실시간 업데이트 고려
- [ ] 라우팅
  - [ ] `/user/my-complaints` 경로 추가
  - [ ] `/user/complaints/:id` 경로 추가

**예상 소요 시간**: 1.5일

---

#### 4. 마이페이지
**파일**: `lib/modules/resident/presentation/screens/my_page_screen.dart`

**할 일**:
- [ ] 마이페이지 메인 화면
  - [ ] 프로필 영역 (이름, 동/호수, 프로필 사진)
  - [ ] 메뉴 리스트
    - 회원정보 수정
    - 비밀번호 변경
    - 알림 설정
    - 로그아웃
    - 회원탈퇴
  - [ ] Section Divider 사용
- [ ] 회원정보 수정 화면
  - [ ] 파일: `profile_edit_screen.dart`
  - [ ] API: PUT `/api/v1/users/profile` 연동
  - [ ] 프로필 사진 업로드 (ImageUploadService)
  - [ ] 이름, 전화번호 수정
  - [ ] 유효성 검증
- [ ] 비밀번호 변경 화면
  - [ ] 파일: `password_change_screen.dart`
  - [ ] API: PUT `/api/v1/users/password` 연동
  - [ ] 현재 비밀번호 확인
  - [ ] 새 비밀번호 입력 및 확인
  - [ ] 비밀번호 강도 체크
- [ ] 회원탈퇴 기능
  - [ ] 회원탈퇴 확인 다이얼로그
  - [ ] API: DELETE `/api/v1/users/me` 연동
  - [ ] 탈퇴 완료 팝업
  - [ ] 로그인 화면으로 리다이렉트
- [ ] 라우팅
  - [ ] `/user/my-page` 경로 추가
  - [ ] `/user/profile-edit` 경로 추가
  - [ ] `/user/password-change` 경로 추가

**예상 소요 시간**: 2일

---

#### 5. 더보기 화면
**파일**: `lib/modules/resident/presentation/screens/more_screen.dart`

**할 일**:
- [ ] 더보기 메인 화면
  - [ ] 앱 정보 (버전, 개발사 등)
  - [ ] 공지사항 바로가기
  - [ ] 이벤트 바로가기
  - [ ] 고객센터
  - [ ] 약관 및 정책
    - 이용약관
    - 개인정보처리방침
  - [ ] 오픈소스 라이선스
- [ ] 약관 뷰어 화면
  - [ ] 파일: `terms_viewer_screen.dart`
  - [ ] HTML 또는 Markdown 렌더링
  - [ ] 스크롤 가능한 텍스트 뷰
- [ ] 라우팅
  - [ ] `/user/more` 경로 추가
  - [ ] `/user/terms` 경로 추가
  - [ ] `/user/privacy-policy` 경로 추가

**예상 소요 시간**: 1일

---

### 🟡 Phase 1.2: 관리자 핵심 기능 (긴급)

#### 6. 민원 관리 시스템
**파일**: `lib/modules/admin/presentation/screens/complaint_management_screen.dart`

**할 일**:
- [ ] 민원 관리 메인 화면
  - [ ] API: GET `/api/v1/admin/complaints` 연동
  - [ ] 필터 (전체/접수/처리중/완료)
  - [ ] Chips 위젯으로 필터 구현
  - [ ] 민원 카드 리스트
  - [ ] 검색 기능 (Search Bar)
  - [ ] 부서별 필터링
- [ ] 민원 상세 및 답변 화면
  - [ ] 파일: `admin_complaint_detail_screen.dart`
  - [ ] API: GET `/api/v1/admin/complaints/:id` 연동
  - [ ] 민원 정보 표시
  - [ ] 답변 작성 영역
  - [ ] API: POST `/api/v1/admin/complaints/:id/reply` 연동
  - [ ] 담당자 배정 기능
  - [ ] 상태 변경 (접수→처리중→완료)
- [ ] 상태 관리
  - [ ] `complaintManagementProvider` 생성
  - [ ] 필터 상태 관리
  - [ ] 실시간 업데이트
- [ ] 라우팅
  - [ ] `/admin/complaints` 경로 추가
  - [ ] `/admin/complaints/:id` 경로 추가

**예상 소요 시간**: 2일

---

#### 7. 입주민 승인 관리
**파일**: `lib/modules/admin/presentation/screens/resident_approval_screen.dart`

**할 일**:
- [ ] 신규 입주민 승인 화면
  - [ ] API: GET `/api/v1/admin/residents/pending` 연동
  - [ ] 대기 중인 입주민 리스트
  - [ ] 입주민 정보 확인 (동/호수, 이름, 전화번호)
  - [ ] 승인/보류 버튼
  - [ ] API: POST `/api/v1/admin/residents/:id/approve` 연동
  - [ ] API: POST `/api/v1/admin/residents/:id/reject` 연동
  - [ ] 보류 사유 입력 (다이얼로그)
- [ ] 승인 처리 결과 알림
  - [ ] 승인 완료 토스트 메시지
  - [ ] 입주민에게 푸시 알림 전송 (서버)
- [ ] 상태 관리
  - [ ] `residentApprovalProvider` 생성
  - [ ] 승인/보류 액션 처리
- [ ] 라우팅
  - [ ] `/admin/resident-approval` 경로 추가

**예상 소요 시간**: 1.5일

---

#### 8. 이벤트 작성 및 관리
**파일**: `lib/modules/admin/presentation/screens/event_create_screen.dart`

**할 일**:
- [ ] 이벤트 작성 화면
  - [ ] API: POST `/api/v1/admin/events` 연동
  - [ ] 제목 입력
  - [ ] 내용 입력 (텍스트 에디터)
  - [ ] 이미지 업로드 (여러 장)
  - [ ] 이벤트 기간 선택 (시작/종료)
  - [ ] 게시 여부 토글
- [ ] 이벤트 목록 화면
  - [ ] 파일: `admin_event_list_screen.dart`
  - [ ] API: GET `/api/v1/admin/events` 연동
  - [ ] 이벤트 카드 리스트
  - [ ] 수정/삭제 버튼
  - [ ] 진행 중/종료 상태 표시
- [ ] 이벤트 수정 화면
  - [ ] 파일: `event_edit_screen.dart`
  - [ ] API: PUT `/api/v1/admin/events/:id` 연동
  - [ ] 기존 데이터 로드
  - [ ] 수정 폼
- [ ] 상태 관리
  - [ ] `eventManagementProvider` 생성
  - [ ] 이미지 업로드 상태 관리
- [ ] 라우팅
  - [ ] `/admin/events` 경로 추가
  - [ ] `/admin/events/create` 경로 추가
  - [ ] `/admin/events/:id/edit` 경로 추가

**예상 소요 시간**: 1.5일

---

### 🟢 Phase 1.3: 담당자 핵심 기능 (긴급)

#### 9. 받은 민원 관리
**파일**: `lib/modules/manager/presentation/screens/received_complaint_list_screen.dart`

**할 일**:
- [ ] 받은 민원 목록 화면
  - [ ] API: GET `/api/v1/manager/complaints` 연동
  - [ ] 부서별로 배정된 민원 리스트
  - [ ] 상태별 필터 (미처리/처리중/완료)
  - [ ] 긴급도 표시 (아이콘 또는 색상)
  - [ ] 접수일 표시
- [ ] 민원 상세 처리 화면
  - [ ] 파일: `manager_complaint_detail_screen.dart`
  - [ ] API: GET `/api/v1/manager/complaints/:id` 연동
  - [ ] 민원 정보 표시
  - [ ] 답변 작성 영역
  - [ ] API: POST `/api/v1/manager/complaints/:id/reply` 연동
  - [ ] 이미지 첨부 (처리 전/후 사진)
  - [ ] 상태 변경 (처리중→완료)
- [ ] 상태 관리
  - [ ] `receivedComplaintListProvider` 생성
  - [ ] 필터 상태 관리
- [ ] 라우팅
  - [ ] `/manager/complaints` 경로 추가
  - [ ] `/manager/complaints/:id` 경로 추가

**예상 소요 시간**: 1.5일

---

#### 10. 공지사항 보기
**파일**: `lib/modules/manager/presentation/screens/manager_notice_list_screen.dart`

**할 일**:
- [ ] 공지사항 목록 화면
  - [ ] API: GET `/api/v1/notices` 연동 (관리자가 작성한 공지)
  - [ ] 리스트뷰 구현
  - [ ] 공지사항 카드 위젯 재사용
  - [ ] 새 공지 뱃지
- [ ] 공지사항 상세 화면
  - [ ] 파일: `manager_notice_detail_screen.dart`
  - [ ] API: GET `/api/v1/notices/:id` 연동
  - [ ] 유저용과 동일한 레이아웃
- [ ] 라우팅
  - [ ] `/manager/notices` 경로 추가
  - [ ] `/manager/notices/:id` 경로 추가

**예상 소요 시간**: 0.5일

---

## 🛠️ 공통 작업 (Phase 1과 병행)

### A. 공통 위젯 개발
**위치**: `lib/shared/widgets/`

**할 일**:
- [ ] `ComplaintCard`: 민원 카드 위젯
  - [ ] 제목, 상태, 날짜, 부서 표시
  - [ ] 상태별 색상 구분
  - [ ] 탭 이벤트 처리
- [ ] `NoticeCard`: 공지사항 카드 위젯
  - [ ] 제목, 날짜, 새글 뱃지
  - [ ] 이미지 썸네일 (옵셔널)
- [ ] `EventCard`: 이벤트 카드 위젯
  - [ ] 썸네일, 제목, 기간
  - [ ] 진행 중/종료 상태 뱃지
- [ ] `EmptyStateWidget`: 빈 상태 위젯
  - [ ] 아이콘, 메시지
  - [ ] 액션 버튼 (옵셔널)
- [ ] `LoadingOverlay`: 로딩 오버레이
  - [ ] 전체 화면 로딩
  - [ ] 부분 로딩
- [ ] `ConfirmDialog`: 확인 다이얼로그
  - [ ] 제목, 내용, 확인/취소 버튼
  - [ ] 커스터마이징 가능
- [ ] `StatusBadge`: 상태 뱃지 위젯
  - [ ] 민원/이벤트 상태 표시
  - [ ] 색상 매핑

**예상 소요 시간**: 2일

---

### B. API 엔드포인트 추가
**위치**: `lib/core/constants/api_endpoints.dart`

**할 일**:
- [ ] 유저 API
  ```dart
  // 공지사항
  static const String notices = '/notices';
  static const String noticeDetail = '/notices/:id';

  // 이벤트
  static const String events = '/events';
  static const String eventDetail = '/events/:id';

  // 내 민원
  static const String myComplaints = '/complaints/my';
  static const String complaintDetail = '/complaints/:id';

  // 프로필
  static const String profileUpdate = '/users/profile';
  static const String passwordChange = '/users/password';
  static const String deleteAccount = '/users/me';
  ```

- [ ] 관리자 API
  ```dart
  // 민원 관리
  static const String adminComplaints = '/admin/complaints';
  static const String adminComplaintReply = '/admin/complaints/:id/reply';

  // 입주민 승인
  static const String pendingResidents = '/admin/residents/pending';
  static const String approveResident = '/admin/residents/:id/approve';
  static const String rejectResident = '/admin/residents/:id/reject';

  // 이벤트 관리
  static const String adminEvents = '/admin/events';
  static const String adminEventCreate = '/admin/events';
  static const String adminEventUpdate = '/admin/events/:id';
  ```

- [ ] 담당자 API
  ```dart
  // 민원 관리
  static const String managerComplaints = '/manager/complaints';
  static const String managerComplaintReply = '/manager/complaints/:id/reply';
  ```

**예상 소요 시간**: 0.5일

---

### C. 라우팅 업데이트
**위치**: `lib/core/providers/router_provider.dart`

**할 일**:
- [ ] 유저 라우트 추가 (10개)
- [ ] 관리자 라우트 추가 (6개)
- [ ] 담당자 라우트 추가 (3개)
- [ ] 권한 검증 로직 확인

**예상 소요 시간**: 0.5일

---

## 📅 Phase 1 일정 요약

| 작업 | 예상 소요 시간 | 담당자 | 우선순위 |
|------|---------------|--------|----------|
| 1. 공지사항 기능 | 1.5일 | - | P0 |
| 2. 이벤트 기능 | 1.5일 | - | P0 |
| 3. 내 민원 목록 및 상세 | 1.5일 | - | P0 |
| 4. 마이페이지 | 2일 | - | P0 |
| 5. 더보기 화면 | 1일 | - | P1 |
| 6. 민원 관리 시스템 | 2일 | - | P0 |
| 7. 입주민 승인 관리 | 1.5일 | - | P0 |
| 8. 이벤트 작성 및 관리 | 1.5일 | - | P1 |
| 9. 받은 민원 관리 | 1.5일 | - | P0 |
| 10. 공지사항 보기 (담당자) | 0.5일 | - | P1 |
| A. 공통 위젯 개발 | 2일 | - | P0 |
| B. API 엔드포인트 추가 | 0.5일 | - | P0 |
| C. 라우팅 업데이트 | 0.5일 | - | P0 |
| **총 예상 시간** | **16일** | | |

---

## 🎨 Figma 디자인 시스템 추출

### 색상 팔레트
- **Primary**: `#006FFF` (파란색 - 버튼, 액센트)
- **White**: `#FFFFFF` (배경, 카드)
- **Background**: `#F2F8FC` (Separator, 섹션 배경)
- **Text Primary**: `#464A4D` (헤더, 중요 텍스트)
- **Border**: `#E8EEF2` (구분선, 카드 테두리)
- **Section Background**: `#EEEEEE` (섹션 배경)

### 타이포그래피
- **Font Family**: Pretendard
- **Button 2**:
  - Font Size: 14
  - Font Weight: 700 (Bold)
  - Line Height: 1.43em
- **Header**:
  - Font Size: 32
  - Font Weight: 700 (Bold)
  - Line Height: 1.25em
- **Body Text**:
  - Font Size: 12
  - Font Weight: 700 (Bold)
  - Line Height: 1.67em

### 컴포넌트 사이즈
- **Mobile Width**: 390px
- **Mobile Height**: 844px
- **Button Height (L)**: 56px
- **Button Height (M)**: 40px
- **Navigation Bar**: 48px
- **Status Bar**: 48px
- **Border Radius**: 8px (버튼), 12px (카드, 입력필드)

---

## 📝 개발 가이드라인

### 1. 화면 개발 체크리스트
- [ ] Figma 디자인 확인 및 분석
- [ ] API 엔드포인트 정의 및 확인
- [ ] 상태 관리 Provider 생성
- [ ] UI 레이아웃 구현
- [ ] API 연동
- [ ] 로딩/에러/빈 상태 처리
- [ ] 라우팅 연결
- [ ] 테스트 (수동/자동)
- [ ] 코드 리뷰
- [ ] Figma 디자인과 비교 검증

### 2. 코딩 규칙
- 모든 색상은 `lib/core/theme/app_colors.dart`에 정의
- 텍스트 스타일은 `lib/core/theme/app_text_styles.dart`에 정의
- 공통 위젯은 `lib/shared/widgets/`에 배치
- API 엔드포인트는 `lib/core/constants/api_endpoints.dart`에 정의
- Provider 명명: `[기능]Provider` (예: `noticeListProvider`)
- 화면 파일 명명: `[기능]_screen.dart` (예: `notice_list_screen.dart`)

### 3. 상태 관리 패턴
```dart
// Provider 정의
final noticeListProvider = StateNotifierProvider<NoticeListNotifier, NoticeListState>((ref) {
  final dataSource = ref.watch(noticeRemoteDataSourceProvider);
  return NoticeListNotifier(dataSource);
});

// State 정의
@freezed
class NoticeListState with _$NoticeListState {
  const factory NoticeListState.initial() = _Initial;
  const factory NoticeListState.loading() = _Loading;
  const factory NoticeListState.loaded(List<Notice> notices) = _Loaded;
  const factory NoticeListState.error(String message) = _Error;
}
```

### 4. API 연동 패턴
```dart
// RemoteDataSource
class NoticeRemoteDataSource {
  final ApiClient _apiClient;

  Future<List<Notice>> getNotices() async {
    final response = await _apiClient.get(ApiEndpoints.notices);
    return (response.data['data'] as List)
        .map((json) => Notice.fromJson(json))
        .toList();
  }
}

// Provider 등록
final noticeRemoteDataSourceProvider = Provider((ref) {
  return NoticeRemoteDataSource(ref.watch(apiClientProvider));
});
```

---

## 🚀 시작하기

### Phase 1 착수 순서
1. **공통 작업 우선 완료** (A, B, C)
2. **유저 핵심 기능** (1, 2, 3) - 가장 많은 사용자
3. **관리자 핵심 기능** (6, 7) - 승인 및 민원 처리 필수
4. **담당자 핵심 기능** (9) - 민원 처리 워크플로우 완성
5. **부가 기능** (4, 5, 8, 10)

### 개발 환경 설정
```bash
# 의존성 설치
flutter pub get

# 코드 생성
flutter pub run build_runner build --delete-conflicting-outputs

# 앱 실행
flutter run
```

### 브랜치 전략
- `main`: 프로덕션 브랜치
- `develop`: 개발 통합 브랜치
- `feature/[기능명]`: 기능 개발 브랜치
  - 예: `feature/user-notice-list`
  - 예: `feature/admin-complaint-management`

---

## 📊 진행 상황 추적

### 완료된 화면 (28개)
- [x] 본사: 9/11 화면 완료
- [x] 통합: 2/2 화면 완료
- [x] 관리자: 8/25 화면 완료
- [x] 유저: 6/25 화면 완료
- [x] 담당자: 3/10 화면 완료

### 진행 중
- [ ] Phase 1.1: 유저 핵심 기능 (0/7일)
- [ ] Phase 1.2: 관리자 핵심 기능 (0/5일)
- [ ] Phase 1.3: 담당자 핵심 기능 (0/2일)
- [ ] 공통 작업 (0/3일)

---

**작성일**: 2025-01-15
**최종 업데이트**: 2025-01-15
**버전**: 1.0
