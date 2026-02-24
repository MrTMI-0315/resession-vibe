# CODEX_CONTEXT.md
작성 시점: 2026-02-24 (최근 세션 반영)

## Project Overview
- Resession은 `Home/Idle → Focus → Break → End → Save → Home` 루프로 운영되는 Flutter MVP다.
- 핵심 SSOT는 `SessionController` 1개(`ChangeNotifier`)이며, 상태/저장/복구 로직은 컨트롤러를 중심으로 유지한다.
- 현재 참조 범위는 `Resession MVP v0.3` 기준이며, 타이머/저장/복구 불변식은 유지한다.

## Current Status (Implemented)
- Session 플로우는 `Home/Idle -> Focus -> Break -> End -> Save -> Home` 동작 유지.
- Break 타이머가 0초에 도달하면 자동으로 Focus 복귀(입력 개입 최소화).
- 타이머 불변식:
  - remaining clamp
  - Break 중 Focus 동결
  - Break 공유 예산 유지(재진입 리셋 없음)
  - phaseStartedAt + baseRemaining 기반 재동기화
- 저장/복구:
  - 기록: `resession_session_records_v1`
  - 활성 상태: `resession_active_run_state_v1`
  - 앱 재시작 후에도 재개 상태 유지/복구 지원
- Preset/UX:
  - 프리셋 `25/5`, `50/10`, custom.
  - custom 라벨 표기 정규화(`Custom` 기준).
  - task 입력의 공백 허용 버그 보정.
- 기록/리스트/인사이트:
  - Home/History/End 최근 기록 노출 구조 유지.
  - Recent 2줄 요약(타이틀/메타) UI 정렬.
  - History 텍스트 로그형에서 리스트형으로 일관 정돈.
  - TabBar/Run Surface/토스트/라벨 톤 정렬 진행.
- 알림:
  - `flutter_local_notifications` 기반 알림 경로 구성.
  - Focus 완료 시 소리/배너/배지 동작이 iOS 기본 동작으로 연결되도록 정비.
  - 무음 모드/기기 음소거 설정은 알림 청각 동작에 영향(설정 의존성)으로 분리 안내.

## Verification 상태
- 품질 게이트(최근 상태):
  - `dart format .` 통과
  - `flutter analyze` 통과 (`No issues found!`)
  - `flutter test` 통과 (기본 테스트 스위트 통과)
  - `flutter build ios --debug --no-codesign` 통과
- 실기기 확인:
  - iPhone 유선 디버그/릴리즈 실행 루틴 실행 완료.
  - 알림(배너/배지/사운드) 사용자 검증 완료(사운드 미재생 이슈는 기기 무음 모드/알림 설정으로 정리).

## Repo Context
- 기준 경로: `/Users/mrtmi/Desktop/Mr_TMI/repos/resession`
- 실행 루틴:
  - `flutter clean`
  - `flutter pub get`
  - `dart format .`
  - `flutter analyze`
  - `flutter test`
  - `flutter build ios --debug --no-codesign`
  - `flutter run -d <UDID or device>`
- `cd` 기준이 잘못된 경우 과거 문서 경로(`.../vibe/apps/resession`)로 혼선이 있었음.

## Workflow Rules
- 1 micro-task = 1 commit = 1 push.
- 최소 변경/요청 범위 준수.
- `context.md`(문서) 자체는 스테이징/커밋 금지.
- 실기기 실증 실패 시 release install 반복 금지(원인 로그 확보 후 조정).

## Known Risks
- 실기기 인식/설치는 iOS Developer Mode, 잠금 해제, 연결 안정성, 신뢰할 수 있는 인증/권한 의존.
- 알림은 기기 시스템 정책/방해금지 설정에 영향을 받음.
- iOS 탭/오디오/포그라운드 알림 동작은 OS 상태에 따라 차이 존재.

## Next Tasks (Priority for V0.3)
1) 실기기 릴리즈 경로에서 AC(백그라운드/잠금/알림) 로그 1회 더 고정(비회귀 증빙).
2) History/Insight의 가독성/해석성(완료율/필터)을 최소 기능 단위로 분할해 재정의.
3) iOS tone/contrast 접근성 점검(텍스트 대비·간격·가독성) 수치 기반 정리.

