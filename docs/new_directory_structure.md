# 새로운 디렉토리 구조 설계

## 기존 문제점
- presentation 폴더 안에 auth, user, manager, headquarters 등이 혼재
- 각 사용자 타입별 기능이 명확하게 분리되지 않음
- API, 위젯, 화면들이 사용자 타입별로 정리되지 않아 복잡함

## 새로운 구조 설계

```
lib/
├── core/                          # 핵심 기능 (변경 없음)
│   ├── constants/
│   ├── network/
│   ├── routing/
│   └── providers/
├── domain/                        # 도메인 로직 (변경 없음)
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── data/                          # 데이터 레이어 (변경 없음)
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── shared/                        # 공통 컴포넌트 (기존 common을 shared로 변경)
│   ├── widgets/
│   ├── utils/
│   ├── constants/
│   └── themes/
├── modules/                       # 사용자 타입별 모듈 (새로운 구조)
│   ├── resident/                  # 입주민 모듈
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   ├── widgets/
│   │   │   └── providers/
│   │   └── routing/
│   ├── manager/                   # 담당자 모듈
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   └── routing/
│   ├── admin/                     # 관리자 모듈
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   └── routing/
│   ├── headquarters/              # 본사 모듈
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   └── routing/
│   └── auth/                      # 인증 모듈 (공통)
│       ├── data/
│       ├── domain/
│       ├── presentation/
│       └── routing/
└── app/                           # 앱 진입점 (변경 없음)
    └── app.dart
```

## 변경 사항

### 1. modules 폴더 생성
- 각 사용자 타입별로 완전히 독립된 모듈 구조
- 각 모듈은 자체적인 data, domain, presentation 레이어 보유

### 2. shared 폴더
- 기존 common을 shared로 변경
- 모든 모듈에서 공통으로 사용하는 위젯, 유틸리티 등

### 3. auth 모듈
- 모든 사용자 타입의 인증 로직을 통합 관리
- 로그인, 회원가입, 토큰 관리 등

## 장점
1. **모듈별 독립성**: 각 사용자 타입별 코드가 완전히 분리
2. **유지보수성**: 특정 사용자 타입 기능 수정시 해당 모듈만 수정
3. **확장성**: 새로운 사용자 타입 추가시 새 모듈만 생성
4. **명확성**: 코드의 위치를 쉽게 찾을 수 있음
5. **재사용성**: shared 폴더를 통한 공통 컴포넌트 관리