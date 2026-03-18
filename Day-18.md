# 18일차: 자동 IP 차단 시스템(Auto-Ban) 구축 (2026.03.18)


## 오늘의 목표
- `intruder_report.txt`에 기록된 공격 의심 IP를 자동으로 파싱한다.
- 리눅스 방화벽(`UFW`)을 제어하여 임계치를 넘긴 IP를 즉시 차단(DENY)하는 자동화 시스템을 완성한다.

---

## 실습 기록 상세

### [실습 1] 자동 차단 스크립트(`auto_ban.sh`) 작성
리포트 파일에서 실패 횟수가 기준치(THRESHOLD)를 넘긴 IP만 골라내어 방화벽 규칙에 자동으로 추가하는 로직을 설계했습니다.
<img width="774" height="288" alt="스크린샷 2026-03-18 193056" src="https://github.com/user-attachments/assets/4ec725dc-eae7-40b1-895a-d70019050681" />

### [실습 2] 환경 변수 및 경로 트러블슈팅
`sudo` 실행 시 `$HOME` 변수가 `/root`로 인식되어 파일을 찾지 못하는 문제를 발견했습니다. 이를 해결하기 위해 `/home/growth/`와 같은 **절대 경로**를 할당하여 스크립트의 안정성을 확보했습니다.
<img width="643" height="96" alt="스크린샷 2026-03-18 191627" src="https://github.com/user-attachments/assets/ad4248ff-598d-4b45-8ca9-e6c4b67654f0" />
<img width="552" height="85" alt="스크린샷 2026-03-18 192136" src="https://github.com/user-attachments/assets/85b2b5a4-de1d-4ca4-8bd3-4b76395390ac" />

### [실습 3] 방화벽(UFW) 연동 및 차단 검증
스크립트 실행 후 `sudo ufw status` 명령어를 통해 공격 IP(`127.0.0.1`)가 실제로 **DENY** 목록에 추가되었는지 최종 확인했습니다.
<img width="649" height="166" alt="스크린샷 2026-03-18 193403" src="https://github.com/user-attachments/assets/88f6567d-4f78-40b9-8c75-706b0bc5f278" />
<img width="583" height="280" alt="스크린샷 2026-03-18 193417" src="https://github.com/user-attachments/assets/e968b4bc-2094-4b49-a5b4-ad7afec29919" />
<img width="573" height="325" alt="스크린샷 2026-03-18 193428" src="https://github.com/user-attachments/assets/d282dee6-af41-4a9d-aabd-1f6419636465" />


---

## 핵심 명령어 요약
- **`sudo ufw enable`**: 리눅스 방화벽(UFW) 활성화
- **`sudo ufw deny from [IP]`**: 특정 IP로부터 오는 모든 접속을 즉시 차단
- **`awk -v limit=$THRESHOLD '$1 >= limit {print $2}'`**: 변수를 사용하여 특정 조건 이상의 데이터만 필터링
- **`sudo ufw status`**: 현재 적용된 방화벽 규칙 리스트 확인

---

## 🇯🇵 오늘의 일본어 엔지니어링
- **単語: 防火壁 (ぼうかへき, 보-카헤키)** - 방화벽 (Firewall)
