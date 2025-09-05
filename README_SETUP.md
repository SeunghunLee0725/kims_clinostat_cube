# S25007 IoT Platform 설정 가이드

## 개요
이 플랫폼은 HiveMQ에서 MQTT 데이터를 주기적으로 수집하여 Supabase에 저장하고, 웹 대시보드를 통해 실시간 모니터링 및 명령 전송이 가능한 IoT 솔루션입니다.

## 주요 기능
- **자동 데이터 수집**: 30초 간격으로 HiveMQ에서 상태 데이터 자동 수집
- **실시간 대시보드**: Supabase Realtime을 활용한 실시간 데이터 표시
- **명령 전송**: 웹 대시보드에서 MQTT 명령 직접 전송
- **데이터 저장**: 모든 데이터와 명령을 Supabase DB에 기록

## 설정 방법

### 1. Supabase 설정

1. [Supabase](https://supabase.com)에서 새 프로젝트 생성
2. SQL Editor에서 `supabase_schema.sql` 파일의 내용 실행
3. Project Settings > API에서 다음 정보 확인:
   - Project URL
   - anon/public key

### 2. 환경 변수 설정

`lib/services/supabase_service.dart` 파일 수정:
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 3. HiveMQ 연결 정보 확인

현재 설정된 HiveMQ 연결 정보 (`lib/services/mqtt_service.dart`):
- Broker: `d29c4d0bbdb946beae4aafdfc0e6e342.s1.eu.hivemq.cloud`
- Port: `8884` (WebSocket over TLS)
- Username: `s25007cmd`
- Password: `s25007Pine`

### 4. 의존성 설치

```bash
flutter pub get
```

### 5. 앱 실행

```bash
# iOS/Android
flutter run

# 웹
flutter run -d chrome
```

## 아키텍처

### 서비스 구조
```
lib/
├── services/
│   ├── mqtt_service.dart         # HiveMQ MQTT 연결 관리
│   ├── supabase_service.dart     # Supabase DB 연동
│   └── data_collector_service.dart # 주기적 데이터 수집
├── screens/
│   ├── home_screen.dart          # 기존 홈 화면
│   └── dashboard_screen.dart     # IoT 대시보드
└── main.dart                      # 앱 진입점
```

### 데이터 흐름
1. **데이터 수집**: DataCollectorService가 30초마다 MQTT로 'GET_STATUS' 명령 전송
2. **응답 수신**: MQTT Service가 's25007/board1/status' 토픽 구독
3. **DB 저장**: 수신된 데이터를 Supabase의 mqtt_data 테이블에 저장
4. **실시간 표시**: Dashboard가 Supabase Realtime으로 데이터 구독 및 표시

### 데이터베이스 테이블
- **mqtt_data**: MQTT 메시지 저장
- **commands**: 전송된 명령 기록
- **device_status**: 디바이스 상태 정보
- **alert_settings**: 알림 설정 (향후 확장용)

## 사용 방법

### 대시보드 기능
1. **연결 상태 확인**: 상단에서 MQTT 연결 상태 실시간 확인
2. **명령 전송**: 
   - 텍스트 필드에 명령 입력 후 Send 버튼 클릭
   - 빠른 명령 버튼 (Get Status, Reset, Start, Stop)
3. **실시간 데이터**: 하단에서 수신된 데이터 실시간 확인

### 지원 명령
- `GET_STATUS`: 현재 상태 요청
- `RESET`: 시스템 리셋
- `START`: 작업 시작
- `STOP`: 작업 중지
- 사용자 정의 명령 입력 가능

## 확장 가능성
- 웹 대시보드 별도 구축 (React/Vue.js)
- 데이터 분석 및 시각화 기능
- 알림 시스템 구현
- 다중 디바이스 지원
- 사용자 인증 및 권한 관리

## 문제 해결

### MQTT 연결 실패
- 인터넷 연결 확인
- HiveMQ Cloud 서비스 상태 확인
- 인증 정보 확인

### Supabase 연결 실패
- API 키 확인
- Supabase 프로젝트 상태 확인
- RLS 정책 확인

## 보안 고려사항
- 프로덕션 환경에서는 환경 변수 사용
- API 키를 코드에 하드코딩하지 않기
- HTTPS/WSS 프로토콜 사용
- Row Level Security 적절히 설정