# 14일차: Crontab을 이용한 작업 자동화 (Scheduler) (2026.03.07)

## 오늘의 목표
- 가상머신 재설치 후 시스템 환경을 복구하고, Crontab 스케줄러를 통해 반복 작업을 자동화한다.

---

## 실습 기록 상세

### [실습 1] 가상머신 복구 및 환경 세팅
Windows 포맷으로 인해 유실된 실습 환경을 재구축했습니다. Ubuntu 설치 후 필수 패키지(`nginx`, `htop`, `gcc` 등)를 다시 설치하고 이전 실습 설정들을 복구했습니다.
<img width="1289" height="451" alt="image" src="https://github.com/user-attachments/assets/a88979a3-d7f5-4ebf-8832-d5c0b064a43d" />

### [실습 2] 1분 주기 자동 생존 신고
`crontab -e`를 활용해 시스템이 1분마다 스스로 로그를 남기도록 설정했습니다.
<img width="1279" height="818" alt="image" src="https://github.com/user-attachments/assets/8bc88dd4-6ae5-4c4d-8216-a18ffc48f103" />
<img width="1287" height="819" alt="image" src="https://github.com/user-attachments/assets/6f75c69f-832a-4957-9f02-373b11fbb8ad" />

---

## 핵심 명령어 요약
- **`crontab -e`**: 예약 작업 설정 편집 (Edit)
- **`crontab -l`**: 현재 예약된 목록 확인 (List)
- **`* * * * *`**: 스케줄 주기 설정 (분 시 일 월 요일)
- **`tail -f ~/restore_test.log`**: 자동 생성되는 로그 실시간 모니터링

---

## 🇯🇵 오늘의 일본어 엔지니어링
- **単語: 自動化 (じどうか, 지도-카)** - 자동화
