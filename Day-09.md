# 9일차: Nginx 웹 서버 설치 및 환경 설정 (2026.02.21)

## 오늘의 목표
- 웹 서버 소프트웨어(Nginx)를 설치하고, 직접 작성한 HTML 페이지를 호스팅하기

---

## 실습 기록 상세

### [실습 1] Nginx 설치 및 데몬(Daemon) 관리
패키지 매니저를 통해 Nginx를 설치했습니다. `systemctl` 명령어를 사용하여 서버 부팅 시 자동으로 실행되도록 설정하고, 현재 프로세스가 정상 작동 중인지 점검했습니다.
<img width="1289" height="804" alt="sudo nginx" src="https://github.com/user-attachments/assets/aff2060c-9c85-4b1e-99c3-881b8ccdb5a4" />
<img width="1282" height="798" alt="states" src="https://github.com/user-attachments/assets/f133cefd-bbc4-4c27-b3db-e322b36ab38d" />

### [실습 2] 웹 콘텐츠 커스터마이징
웹 서버의 기본 경로인 `/var/www/html`로 이동하여 기존의 기본 페이지를 수정했습니다. VI 에디터를 사용하여 나만의 메시지가 담긴 HTML 파일을 생성했습니다.
<img width="1281" height="794" alt="index" src="https://github.com/user-attachments/assets/e308bf42-ab04-4f99-9982-6936ab1d5cb3" />

### [실습 3] HTTP 응답 확인
터미널에서 `curl` 명령어를 사용하여 내가 만든 웹 페이지의 소스 코드가 정상적으로 반환되는지 확인했습니다. 외부 브라우저 접속을 위한 기초 설정을 완료했습니다.
<img width="1279" height="154" alt="localhost" src="https://github.com/user-attachments/assets/5a59398f-a955-4a96-993d-7d5e50fd18da" />

---

## Troubleshooting (장애 대응 기록)

### 문제 상황
- `sudo vi index.html`을 통해 웹 페이지 내용을 수정했음에도 불구하고, `curl localhost` 실행 시 수정된 내용이 반영되지 않고 기본 Nginx 페이지가 출력됨.
- `ls -l /var/www/html/index.html` 확인 시 파일이 존재하지 않는다는 에러 메시지 발생.

### 원인 분석
- **파일 경로의 오해**: 리눅스 터미널에서 경로를 지정하지 않고 파일을 생성하면 현재 작업 디렉토리(Home)에 저장됨.
- Nginx 웹 서버는 기본적으로 `/var/www/html/` 경로에 있는 파일을 서비스하기 때문에, 엉뚱한 위치의 파일을 수정하고 있었음.

### 해결 방법
1. **절대 경로 사용**: `sudo vi /var/www/html/index.html` 명령어를 사용하여 Nginx의 Root 디렉토리에 직접 파일을 생성함.
2. **서비스 재시작**: 변경 사항을 확실히 반영하기 위해 `sudo systemctl restart nginx` 실행.
3. **최종 확인**: `curl localhost`를 통해 내가 작성한 Hello, Linux 문구가 출력되는 것을 확인함.

### 배운 점
- 리눅스 설정 시에는 **상대 경로**보다 **절대 경로**를 명확히 지정하는 습관이 중요하다는 것을 깨달음.

---

## 핵심 명령어 요약
- **`apt install nginx`**: Nginx 웹 서버 설치
- **`systemctl status nginx`**: 서비스 실행 상태 확인 (Active/Inactive)
- **`systemctl restart nginx`**: 설정 변경 후 서버 재시작
- **`sudo vi /var/www/html/index.html`**: Nginx 웹 서버의 기본 루트 디렉토리에 접근하여 메인 페이지 내용을 직접 수정 (index.html)
- **`curl localhost`**: 로컬 환경에서 웹 응답 테스트
  
---

## 🇯🇵 오늘의 일본어 엔지니어링
- **단어 1:** **構築 (こうちく, 코-치쿠)** - 구축 (Build/Setup)
