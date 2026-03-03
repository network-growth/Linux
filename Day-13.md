# 13일차: 프로세스 관리 - 서버의 자원 도둑 검거하기 (2026.03.03)

## 오늘의 목표
- 현재 서버에서 실행 중인 프로그램(프로세스)들을 확인하고, 리소스를 과다 점유하는 프로세스를 제어한다.

---

## 실습 기록 상세

### [실습 1] 실시간 시스템 모니터링 (`htop`)
기본 `top`보다 가독성이 좋은 `htop`을 설치하여 실행했습니다. CPU 코어별 사용량과 메모리 점유율을 그래프로 확인하고, 어떤 프로세스가 가장 상단(리소스 최다 사용)에 있는지 분석했습니다.
<img width="1280" height="801" alt="top" src="https://github.com/user-attachments/assets/ccfd8a7e-bb09-4899-91a5-f0fe569c8d9f" />
<img width="1279" height="800" alt="htop" src="https://github.com/user-attachments/assets/ebd885f2-b6c2-4068-8fe5-bd24f1baee12" />

### [실습 2] Nginx 프로세스 추적
`ps aux | grep nginx`를 통해 웹 서버가 몇 개의 자식 프로세스를 띄워 동작하고 있는지 확인했습니다. 각 프로세스에 부여된 고유 번호인 PID를 확인하는 법을 익혔습니다.
<img width="1282" height="130" alt="grep " src="https://github.com/user-attachments/assets/bbb4f3fe-354b-4fb4-96f6-3f1c27d86fe9" />

### [실습 3] 프로세스 강제 종료 테스트
불필요한 프로세스가 자원을 낭비하는 상황을 가정하여 `kill` 명령어를 실습했습니다. `-9` 옵션이 '강제 종료(SIGKILL)'를 의미하며, 신중하게 사용해야 한다는 점을 배웠습니다.
<img width="1288" height="161" alt="화면 캡처 2026-03-03 215218" src="https://github.com/user-attachments/assets/04c05ff8-57e2-4968-b904-b7350a213f8d" />

---

## 핵심 명령어 요약
- **`top` / `htop`**: CPU 및 메모리 사용량을 실시간으로 모니터링
- **`ps aux`**: 시스템에서 실행 중인 모든 프로세스의 상세 목록 출력
- **`kill -9 [PID]`**: 응답하지 않는 프로세스를 프로세스 ID(PID)를 이용해 강제 종료
- **`yes "I am a bad process" > /dev/null&`**: kill 실습을 할때 필요없는 프로세스를 만들고 PID 알기위한 명령어 (실습용)
    yes: 특정 문자열을 무한히 출력하는 명령어
    > /dev/null: 화면에 글자가 쏟아지면 터미널을 못쓰므로, 쓰레기통으로 결과를 버리기
    &: 이 명령어를 백그라운드에서 돌리겠다
    
---

## 🇯🇵 오늘의 일본어 엔지니어링
- **単語: 負荷 (ふか, 후카)** - 부하 (Load)
