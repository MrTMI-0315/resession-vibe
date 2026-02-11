# CODEX_CONTEXT.md — Resession MVP (Flutter)
작성 시점: 2026-02-11 (KST)
목적: Codex 컨텍스트윈도우(CW) 절약 + 반복 설명 제거 + 안전한 변경 규칙 고정

---

## 0) TL;DR (Codex가 제일 먼저 읽어야 하는 10줄)
- Resession은 “Home/Idle → Focus → Break → End → Save → Home” MVP 슬라이스가 동작한다.
- 상태관리는 ChangeNotifier 기반 `SessionController` 1개가 단일 소스 오브 트루스(SSOT)다.
- 타이머 로직은 **phase 시작 시각 + 기준 잔여시간(baseRemaining)** 계산 방식이다.
- Break 동안 Focus 잔여시간은 줄지 않는다(동결).
- Break는 “공유 예산”이며 재진입 시 리셋되지 않는다(남은 값에서 차감).
- UI는 공통 위젯(상태 카드/프리셋 칩/CTA 버튼)을 중심으로 단순하게 유지한다.
- 의존성 추가는 “필요할 때만 최소로” 허용(기본은 무추가).
- 모든 변경은 `dart format`, `flutter analyze`, `flutter test` 통과가 필수다.
- “증거 기반 문구” 원칙: README/문서는 단정 대신 실행 명령 + 기대 결과 + 작성 시점 라벨링.
- 큰 리팩토링 금지: 기능은 마이크로태스크 단위로 쪼개서 안전하게 누적한다.

---

## 1) 프로젝트 목표 / 범위
### Goal
- 사용자가 “시작/유지/이탈/복귀/회고”를 최소 부담으로 반복하게 만드는 재시작(Resession) 루프 앱.

### MVP Scope (현재)
- 프리셋: 25/5, 50/10, Custom(선택 가능; Custom 입력 UI는 별도 태스크로 확장 가능)
- 타이머: Focus ↔ Break 전환 + End + Save
- 기록: 현재 인메모리 `SessionRecord` (영속화는 다음 작업)

### Non-goal (MVP)
- 고급 통계/긴 저널/공유/AI 코칭 풀옵션/동기화

---

## 2) UX 플로우(고정)
- Home(Idle) : 프리셋 선택 + Start
- Focus : 진행 / Pause → Break
- Break : Resume → Focus (Break는 예산 차감)
- End : Log/Save → Home
- Home : 최근 기록(있으면) 표시

---

## 3) 핵심 불변 규칙(Invariants)
### Timer invariants
- Focus 시간은 Break 동안 감소하면 안 됨.
- Break는 공유 예산이며, Break 재진입 시 full reset 금지.
- 남은 시간은 getter로 “live 계산”하며, 화면은 getter를 사용한다.
- 남은 시간은 항상 0 이상으로 clamp한다.

### State invariants
- `SessionController`가 SSOT.
- 화면은 Controller 상태를 반영만 하고, 로직은 Controller에 둔다.
- phase 전환은 단방향(Idle → Focus → Break ↔ Focus → End → Idle).

---

## 4) 코드 구조(요약)
> 실제 파일명/구조는 프로젝트 내 유지. 새 파일은 명확한 이유가 있을 때만 추가.

- `lib/app.dart` : 앱 루트/라우팅/최상위 위젯
- `lib/session_controller.dart` : 상태머신/타이머/액션(SSOT)
- `lib/models/*` 또는 인근: `SessionPreset`, `SessionRunState`, `SessionRecord`
- `lib/screens/*` : home/session/break/end
- `lib/widgets/*` : status card / preset chips / CTA button 등 공통 UI

---

## 5) 작업 원칙(변경 규칙)
### “최소 변경/최대 체감” 룰
- 한 PR(커밋)은 “마이크로태스크 1개”만.
- UI 변경은 컴포넌트 재사용/스타일 최소로.
- 리팩토링은 **기능 추가/버그 픽스에 필요한 범위까지만**.

### 의존성 룰
- 기본은 무추가.
- 단, 영속화 단계에서 `shared_preferences` 1개는 허용 가능(결정 시 문서에 기록).

### 테스트/품질 게이트
반드시 실행:
- `dart format .`
- `flutter analyze`
- `flutter test`

가능하면 추가(스모크):
- `flutter run -d chrome --no-resident` (1회 실행 로그 남김)

---

## 6) 문서(README) 작성 규칙
- “증거 기반 문구” 우선: 실행 명령 + 기대 결과 중심.
- 깨지는 이미지/외부 링크 의존은 금지(기본은 텍스트 placeholder).
- 작성 시점은 라벨링(예: 2026-02-11 기준).
- 섹션 최상단에 “3분 실행” 명령을 배치한다.

---

## 7) Codex 협업 프롬프트 규칙(필수)
Codex에게 매번 아래 포맷으로 요청한다.

### Request format
1) Goal (한 줄)
2) Constraints (3~5개)
3) Acceptance Criteria (체크리스트)
4) Files allowed to change (명시)
5) Commands to run (analyze/test/run)
6) Output format (변경 요약 + 수정 파일 + 실행 로그)

### Do / Don’t
- Do: 작은 diff, 명시적 AC, getter 기반 계산 유지, 테스트 추가(최소).
- Don’t: 구조 전면 개편, 파일 대량 생성, 컨트롤러 분산, 무근거 단정(문서/요약).

---

## 8) 현재 상태 스냅샷(업데이트 필요 시 여기만 고치기)
- MVP vertical slice: 동작
- 프리셋: 25/5, 50/10, custom 선택 가능
- 타이머 예산: Focus 동결/Break 공유 예산 유지(phaseStartAt+baseRemaining)
- 테스트: `flutter test` 3개 통과(작성 시점 기준)
- 스모크: `flutter run -d chrome --no-resident` 성공(작성 시점 기준)

---

## 9) 다음 마이크로태스크 큐(우선순위)
1) SessionRecord 영속화(local persistence)
2) Custom preset 입력 UI(bottom sheet)
3) Lifecycle 하드닝(포커스/슬립/리줌)
4) UI/UX 마감(선택 강조/End 요약/CTA guardrails)

각 태스크는 “Action Prompt” 1개로 분리해서 수행한다.

---
