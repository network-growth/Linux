# 5일차: 권한 관리(chmod) 및 패키지 설치(apt) (2026.02.10)
  
## 오늘의 목표
- 관리자 권한(`sudo`)을 이해하고, 필요한 프로그램을 설치 및 파일 권한 제어하기

---

## 실습 기록 상세

### [실습 1] 패키지 매니저를 통한 프로그램 설치
`sudo apt update`로 목록을 갱신한 뒤, 시스템 정보 출력 도구인 `neofetch`를 설치했습니다. 리눅스 환경에서 외부 소프트웨어를 안전하게 가져오는 과정을 익혔습니다.
<img width="1292" height="809" alt="sudo apt install neofetch" src="https://github.com/user-attachments/assets/420b6c80-35cd-4e0d-970b-3434bd8a49e5" />
<img width="1285" height="808" alt="apt list --upgradable" src="https://github.com/user-attachments/assets/642d327c-7bef-4a15-ae4c-02165263a880" />

### [실습 2] 파일 권한 제어 (`chmod`)
`ls -l` 명령어로 파일의 현재 권한 상태를 확인하고, `chmod`를 사용해 권한 숫자를 바꿔보았습니다. 보안의 핵심인 접근 제어 개념을 실습했습니다.
<img width="655" height="516" alt="chmod 777 study" src="https://github.com/user-attachments/assets/01fe1d48-dfc7-4153-848b-2cb944e64dbe" />

### [실습 3] 시스템 사양 확인
설치한 `neofetch` 명령어를 실행하여 현재 운영 중인 우분투 서버의 환경을 한눈에 확인했습니다.
<img width="711" height="410" alt="neofetch" src="https://github.com/user-attachments/assets/108a43d9-9d54-4f89-a780-a40b4a5c32d9" />

---


## 핵심 명령어 상세 가이드
- `sudo`: 관리자 권한으로 명령어 실행 (SuperUser DO)
- `apt update`: 패키지 매니저의 프로그램 목록 업데이트
- `apt install [이름]`: 새로운 프로그램 설치
- `chmod [숫자] [파일명]`: 파일의 읽기/쓰기/실행 권한 변경
- `neofetch`: 시스템 정보(OS, 커널, CPU 등)를 시각적으로 출력

---

## 🇯🇵 오늘의 일본어 엔지니어링
- **단어 1:** **許可 (きょか, 쿄카)** - 허가 (Permission/권한)
