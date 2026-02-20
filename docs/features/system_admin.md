# System / Admin 기능 설계 (features/system, pages)

이 문서는 시스템 모니터/관리자 기능의 목적과 코드 위치를 정리합니다.

## 목표

- 디버그/운영 관점에서 앱 상태(저장소/리소스/데이터)를 빠르게 확인한다.
- 샘플 데이터 생성/초기화 같은 “관리 작업”을 UI에서 수행할 수 있게 한다.
- 프로덕션 빌드에서는 노출을 최소화(또는 접근 제한)할 수 있도록 확장 여지를 둔다.

## 핵심 파일

- `lib/features/system/ui/system_monitor_page.dart`
  - Hive 박스/데이터 상태 확인
  - 간단한 진단 카드/지표

- `lib/features/admin/ui/admin_dashboard.dart`
  - 관리 대시보드(팀/사용자/데이터 등 확장 가능)

- `lib/app/widgets/master_drawer.dart`
  - “시스템 모니터”, “초기화/샘플 데이터” 등 진입점 제공

## 데이터 초기화/샘플

- `lib/data/services/app_reset_service.dart`
  - 샘플 팀/사용자/프로젝트/업무/일지/채팅 등을 대량 생성
  - UI 테스트(필터/스크롤/그리드)용 데이터 준비가 목적

## 운영 가이드

- 개발/테스트 단계에서는 Drawer에서 관리자 기능을 노출
- 향후
  - 권한(관리자 계정) 체크
  - 빌드 플래그(kReleaseMode) 기준으로 숨김 처리
  - 로그 출력(print) 제거/로거 전환
