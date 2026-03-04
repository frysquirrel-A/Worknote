# WorkNote 인증 개편 패치 보고서

## 적용 목표
- Local-First + Google Multi-Profile(5슬롯) 인증 구조 도입
- 기존 `AuthProvider.currentUser` 호환 유지
- 기존 폴더 구조/기능 최대 보존

## 수정 파일
- `lib/core/models/work_profile.dart`
- `lib/features/auth/state/auth_provider.dart`
- `lib/features/auth/ui/login_page.dart`
- `lib/features/auth/ui/profile_setup_page.dart` (신규)
- `lib/features/auth/ui/profile_selection_page.dart` (신규)
- `lib/app/worknote_app.dart`
- `lib/app/main_shell.dart`
- `lib/app/widgets/master_drawer.dart`
- `lib/features/team/state/team_provider.dart`
- `lib/features/team/ui/team_management_page.dart`
- `lib/core/theme/app_theme.dart`
- `lib/data/services/app_reset_service.dart`

## 핵심 변경 요약
1. 로컬 프로필 생성 시 이름이 비어 있으면 `ProfileSetupPage`로 진입
2. 구글 로그인 시 이메일 기준 슬롯 5개 관리
3. 로컬 프로필을 그대로 구글 슬롯으로 승격하는 브릿지 구현(기존 profile id 유지)
4. Drawer 상단에 현재 프로필/빠른 전환 UI 추가
5. 프로필 관리 페이지에서 전환/이름 수정/삭제/구글 연결 해제 가능
6. 팀 초대/Drive 관련 기능 접근 시 로컬 프로필이면 구글 연결 유도
7. 루트 화면 전환에 AnimatedSwitcher 적용
8. 앱 초기화 시 auth profile settings 보존

## 확인 포인트
- `google_sign_in` 실제 동작 여부
- Google Drive client 연결 여부
- 구글 계정 1개로 슬롯 5개 제한 확인
- 로컬 -> 구글 연결 후 현재 프로필 id 유지 여부
- 프로필 삭제 후 fallback 전환 정상 여부
- 로그아웃 후 "저장된 프로필 선택" 동작 여부

## 주의
- 이 패치는 구조 보존을 우선한 인증 계층 패치이며, 기존 업무/일지/채팅 데이터 모델 전체를 auth-aware하게 재설계한 것은 아님
- Flutter/Dart 컴파일러가 현재 컨테이너에 없어 실제 `flutter analyze` / `flutter run` 검증은 수행하지 못함
