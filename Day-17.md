# 17일차: 실시간 보안 로그 분석 및 침입 탐지 시스템 구축 (2026.03.16)


## 오늘의 목표
- 리눅스 인증 로그(`/var/log/auth.log`)를 분석하여 무단 접근 시도를 탐지하고, 공격자의 IP를 자동으로 요약하는 보안 리포트 스크립트를 구현한다.

---

## 실습 기록 상세

### [실습 1] 침입 탐지 스크립트(`intruder_alert.sh`) 작성
서버의 보안 로그를 스캔하여 외부 침입 시도를 리포트화하는 스크립트를 설계했습니다. `auth.log` 파일의 접근 권한 문제를 고려하여 `sudo` 환경에서 동작하도록 구성하였으며, `intruder_report.txt`로 결과를 자동 저장하도록 구현했습니다.

<img width="1284" height="380" alt="Image" src="https://github.com/user-attachments/assets/d4877530-45e5-472b-a769-4e13ba301b9d" />

### [실습 2] 가짜 침입 시뮬레이션 및 데이터 검증
스크립트의 성능을 확인하기 위해 `ssh intruder_test@localhost` 명령어로 의도적인 로그인 실패 로그를 생성했습니다. 이후 스크립트가 해당 로그를 감지하여 리포트에 `127.0.0.1`과 시도 횟수를 정확히 기록하는지 검증했습니다.

<img width="1281" height="100" alt="Image" src="https://github.com/user-attachments/assets/a6a8a0ba-d2db-48ad-966a-696f2d36a851" />
<img width="1281" height="478" alt="Image" src="https://github.com/user-attachments/assets/a2d24d6a-a97b-47a4-8db8-97986007f896" />

### [실습 3] 권한 및 환경 트러블슈팅
로그 파일 접근 시 발생하는 `Permission denied`와 실행 파일 경로 인식 문제(`command not found`)를 해결했습니다. `chmod +x`를 통한 실행 권한 부여와 절대 경로 사용의 중요성을 실무적으로 학습했습니다.

<img width="1270" height="146" alt="Image" src="https://github.com/user-attachments/assets/c8c38956-7c9e-4489-b437-4faf2cebf906" />

---

## 핵심 명령어 요약
- **`sudo tail -f /var/log/auth.log`**: 실시간으로 쌓이는 보안 로그를 모니터링하여 침입 시도 확인
- **`grep "Failed password"`**: 수많은 로그 중 로그인 실패 기록만 필터링
- **`awk '{print $(NF-3)}'`**: 문장의 뒤에서 4번째 단어(IP 주소)를 정확히 추출하는 기법
- **`sort | uniq -c | sort -nr`**: 침입 시도 횟수를 계산하고 가장 위험한 IP 순으로 정렬

---

## 배운 점 & 트러블슈팅
- **권한 관리의 엄격함**: `/var/log/auth.log`와 같은 보안 민감 파일은 관리자(root) 권한 없이 접근이 불가능함을 체감하고, `sudo`를 적절히 활용하는 법을 익힘.
- **로그 정규화 역량**: 방대한 텍스트 데이터 속에서 `grep`과 `awk`를 조합해 의미 있는 보안 데이터(공격 IP 등)만 골라내는 데이터 가공 능력을 습득함.

---

## 🇯🇵 오늘의 일본어 엔지니어링
- **単語: 侵入検知 (しんにゅうけんち, 신뉴-켄치)** - 침입 탐지
