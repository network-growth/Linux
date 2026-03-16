# 16일차: 서버 자가 치유(Self-Healing) 및 침입 탐지 시스템 구축 (2026.03.14)

## 오늘의 목표
- 쉘 스크립트의 조건문(if)을 활용하여 장애 발생 시 서비스를 자동으로 복구하고, 실시간 트래픽을 감시하는 지능형 관리 시스템을 구축한다.

---

## 실습 기록 상세

### [실습 1] 영문 서버 가디언 스크립트(`guardian.sh`) 작성
터미널 환경의 호환성을 위해 모든 출력 메시지를 영어로 구성한 지능형 스크립트를 설계했습니다. 서비스 중단 시 자동 복구 로직과 접속자 수 임계치 초과 시 경고를 남기는 기능을 구현했습니다.

<img width="716" height="488" alt="Image" src="https://github.com/user-attachments/assets/2016bb53-46e6-4403-afc8-6d2bc4c765ed" />

### [실습 2] 실행 권한 부여 및 자동화 엔진 결합
작성한 스크립트가 관리자 개입 없이 24시간 독립적으로 동작하도록 설정했습니다. `chmod +x`로 실행 파일화한 뒤, Crontab에 등록하여 1분마다 시스템을 스스로 점검하도록 자동화했습니다.
<img width="1274" height="246" alt="Image" src="https://github.com/user-attachments/assets/bae5e0ef-6227-49e8-8122-f710e2e0afe3" />

### [실습 3] 장애 복구 시뮬레이션 및 최종 점검
`systemctl stop nginx`로 고의 장애를 발생시킨 후 스크립트의 성능을 검증했습니다. 1분 내에 영어로 된 로그가 기록되며 서비스가 자동으로 'Active' 상태로 복구되는 'Self-Healing' 과정을 최종 확인했습니다.
<img width="574" height="290" alt="Image" src="https://github.com/user-attachments/assets/7e764cb5-8ecb-4a58-96c4-a2c4178cb881" />
<img width="487" height="89" alt="Image" src="https://github.com/user-attachments/assets/5f6a95a0-3a3c-4957-b4db-f2011dda79fc" />
<img width="1280" height="186" alt="Image" src="https://github.com/user-attachments/assets/4e007235-9a27-4b13-8557-3c104929922a" />

---

## 배운 점 & 트러블슈팅
- **정밀한 디버깅**: 파일 저장 시 마침표 대신 쉼표(`,sh`)를 사용하거나, `sudo`, `start` 등의 명령어 오타가 발생하면 시스템이 파일을 인식하지 못하거나 실행 오류가 발생함을 확인하고 교정함.
- **문법의 엄격함**: 쉘 스크립트에서 따옴표(`""`)의 짝을 맞추지 않거나 조건문(`[ ]`) 내의 공백을 지키지 않으면 `EOF` 에러 등이 발생한다는 점을 배우고 실무적인 디버깅 감각을 익힘.

---

## 핵심 명령어 요약
- **`chmod +x [File]`**: 텍스트 파일에 실행 권한을 부여하여 프로그램으로 변환
- **`systemctl is-active`**: 특정 서비스(Nginx 등)의 정상 작동 여부를 확인
- **`netstat -an | grep :80`**: 웹 서버 포트에 연결된 현재 접속자 상태 확인
- **`tail -f ~/server_guardian.log`**: 자동 생성되는 로그 실시간 모니터링

---

## 🇯🇵 오늘의 일본어 엔지니어링
- **単語: 自動復旧 (じどうふっきゅう, 지도-훗큐)** - 자동 복구
