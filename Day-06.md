# 6일차: 로그 추적 및 프로세스 관리 (실무 핵심) (2026.02.12)

## 오늘의 목표
- 서버의 일지(Log)를 실시간으로 확인하고, 실행 중인 프로세스를 제어 및 파일 검색하기

---

## 실습 기록 상세

### [실습 1] 실시간 로그 및 시스템 모니터링 (`top`)
서버의 자원 상태를 확인하고 시스템 로그를 관찰하며 서버가 정상적으로 작동하고 있는지 확인하는 방법을 익혔습니다.
<img width="1282" height="273" alt="ww" src="https://github.com/user-attachments/assets/815d228e-a614-41f7-9732-5d69f6f506a4" />

### [실습 2] 프로세스 관리 (`ps`, `kill`)
`sleep` 명령어로 생성한 연습용 프로세스를 `ps`로 찾아내고, `kill -9` 명령어로 안전하게 강제 종료하는 전체 과정을 실습했습니다.
<img width="796" height="203" alt="grep" src="https://github.com/user-attachments/assets/39a131b1-91a2-471a-ab40-b11befc40cc5" />
<img width="771" height="107" alt="kill" src="https://github.com/user-attachments/assets/9c54c8e1-3161-4e9b-85e0-ebf53132d83e" />

### [실습 3] 파일 검색 (`find`)
어디에 있는지 모르는 파일을 이름만으로 빠르게 찾아내는 `find` 명령어를 실습했습니다. 

<img width="369" height="48" alt="화면 캡처 2026-02-12 151707" src="https://github.com/user-attachments/assets/6e8f85bd-9904-46a0-9805-0414869e4139" />

---

## 핵심 명령어 요약
- `tail -f /var/log/syslog`: 시스템 로그 실시간 모니터링
- `ps aux | grep [단어]`: 실행 중인 프로세스 검색
- `sleep 1000 &` : 1000초 동안 아무것도 안하고 잠만 자는 프로그램을 실행 / & : 백그라운드에서 실행
- `kill -9 [PID]`: 프로세스 강제 종료
- `find . -name "[파일명]"`: 파일 위치 검색

---

## 🇯🇵 오늘의 일본어 엔지니어링
- **단어:** **追跡 (ついせき, 츠이세키)** - 추적
