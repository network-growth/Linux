# 11일차: 로그(Log) 분석 및 장애 상황 재현(Troubleshooting) (2026.02.26)

## 오늘의 목표
- 서버 로그의 생성 원리를 이해하고, 인위적인 부하 및 에러 상황을 만들어 로그 분석 능력을 키우기

---

## 실습 기록 상세

### [실습 1] 테스트용 대량 로그 생성 (Traffic Generation)
실무 환경처럼 로그가 계속 쌓이는 상황을 재현하기 위해 `while` 루프를 사용했습니다. 별도의 터미널 창에서 무한 루프 쉘 스크립트를 실행하여 웹 서버에 지속적인 트래픽을 발생시켰고, `tail -f`를 통해 실시간으로 데이터가 쌓이는 것을 확인했습니다.
<img width="1295" height="287" alt="1" src="https://github.com/user-attachments/assets/d03d0a58-e152-4e8e-8a17-3ad8941804e6" />
<img width="1312" height="724" alt="2" src="https://github.com/user-attachments/assets/6ae55faf-40e1-4d64-b928-3b31cd2d99f7" />

### [실습 2] 인위적 에러 발생 및 필터링 (Error Simulation)
로그 필터링 연습을 위해 일부러 존재하지 않는 페이지(`secret_file.html`)를 반복 호출했습니다. 이후 `grep "404"` 명령어를 통해 수많은 접속 기록 중 실제 에러가 발생한 지점만 정확히 찾아내는 연습을 수행했습니다.
<img width="1292" height="202" alt="3" src="https://github.com/user-attachments/assets/aa8be9dc-e7a9-44b6-98e5-b07e69b922d9" />
<img width="1302" height="654" alt="4" src="https://github.com/user-attachments/assets/d2e0bee3-e0a4-4cc9-9a24-af2663907534" />

---

## Troubleshooting (장애 대응 및 배운 점)

### 문제 상황
- `tail -f`를 실행했으나 화면에 아무런 변화가 없어 서버가 멈춘 것으로 오해함.
- 명령어 실행 중 `sudo` 비밀번호를 묻지 않아 보안 설정에 의문을 가짐.

### 원인 분석 및 해결
1. **로그 생성 원리**: 로그는 '사건'이 발생해야 기록됨. 클라이언트(나)가 접속하지 않으면 로그는 찍히지 않음 → `curl` 루프를 돌려 해결함.
2. **Sudo 권한 유지**: 리눅스는 한 번 `sudo` 인증을 하면 일정 시간(약 5~15분) 동안 세션을 유지함. 이는 오류가 아니라 사용자 편의를 위한 기능임을 학습함.

---

## 핵심 명령어 요약
- **`sudo tail -f /var/log/nginx/access.log`**: Nginx 접속 로그 실시간 모니터링
- **`while true; do curl localhost; sleep 0.5; done`**: 0.5초마다 접속을 시도하여 대량의 로그 생성 (트래픽 시뮬레이션) 
   -> 개인서버로 실습을 할때 로그를 만들어내기 위한것
- **`curl localhost/non-existent-page`**: 없는 페이지를 호출하여 `404 Not Found` 에러 유도
- **`sudo grep "404" /var/log/nginx/access.log`**: 특정 에러 코드만 필터링하여 확인
- **`sudo journalctl -u nginx`**: Nginx 서비스 자체의 시스템 로그 확인
- **`du -sh /var/log/*: 로그 파일이 차지하는 용량 확인

---

## 🇯🇵 오늘의 일본어 엔지니어링
- **단어 1:** **発生 (はっせい, 핫세이)** - 발생 (로그나 장애가 생김)
