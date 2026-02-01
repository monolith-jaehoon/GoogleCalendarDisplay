Google Calendar Display
=======================

캘린더 일정을 화면에 표시하는 Flutter 앱입니다.

이 프로젝트는 GitHub Copilot으로 GPT-5.2-Codex 모델과 협업하여 만들었습니다.



---------
주요 기능
---------

- Google Calendar OAuth 연동
- 단일/3분할 레이아웃
- 과거/미래 시간 범위 타임라인 표시
- 일정 제목, 시간, 작성자 표시
- 화면 크기에 따른 UI 스케일링



-----------
설정 (YAML)
-----------

설정 파일: assets/config.yaml

필드 설명:
- layout: single / tripleHorizontal / tripleVertical
- headerTitle: 상단 제목(비어 있으면 기본 제목 사용)
- displayCalendarIndices: 표시할 캘린더 인덱스 목록
  - single일 경우 0번 인덱스를 사용
- calendars: roomName과 googleCalendarId 목록
- oauth: OAuth 클라이언트 정보
- refreshIntervalMinutes: 새로고침 주기(분)
- timezone: 표시 타임존
- use24HourFormat: 24시간제 여부 (기본 false)
- startInFullscreen: 프로그램 실행 시 기본값을 fullscreen으로 할 지 여부
- pastMinutes / futureMinutes: 표시 시간 범위

예시:
```yaml
layout: tripleHorizontal
headerTitle: 캘린더 일정
displayCalendarIndices: [0, 1, 2]
calendars:
  - roomName: Schedule 1
    googleCalendarId: resource1@resource.calendar.google.com
  - roomName: Schedule 2
    googleCalendarId: resource2@resource.calendar.google.com
  - roomName: Schedule 3
    googleCalendarId: resource3@resource.calendar.google.com
oauth:
  webClientId: DUMMY_WEB_CLIENT_ID
  androidClientId: DUMMY_ANDROID_CLIENT_ID
  desktopClientId: DUMMY_DESKTOP_CLIENT_ID
  desktopClientSecret: DUMMY_DESKTOP_CLIENT_SECRET
refreshIntervalMinutes: 1
timezone: Asia/Seoul
use24HourFormat: false
startInFullscreen: true
pastMinutes: 60
futureMinutes: 300
```



----
실행
----

Flutter 환경에서 실행합니다.

- flutter run (필요 플랫폼 선택)



----
참고
----

- OAuth 설정이 누락되면 로그인 단계에서 실패할 수 있습니다.
- displayCalendarIndices가 비어 있으면 첫 번째 캘린더를 사용합니다.
