# 10일차: 서버 보안의 기초, 방화벽(UFW) 설정 (2026.02.24)

## 오늘의 목표
- 방화벽(UFW)의 개념을 이해하고, 서비스에 필요한 특정 포트(80, 443, 22)만 선별적으로 허용하여 서버 보안 강화하기

---

## 핵심 명령어 요약
- **`sudo ufw status`**: 방화벽의 현재 활성 상태 및 규칙 확인
- **`sudo ufw allow [Port]`**: 특정 포트(예: 80, 22)의 접속을 허용
- **`sudo ufw deny [Port]`**: 특정 포트의 접속을 차단
- **`sudo ufw enable / disable`**: 방화벽 서비스를 시작하거나 중지
- **`sudo ufw status numbered`**: 적용된 규칙을 번호와 함께 리스트 형태로 출력

---

## 실습 기록 상세

### [실습 1] 기본 보안 정책 수립
보안의 기본 원칙인 '최소 권한의 법칙'에 따라, 일단 외부에서 들어오는 모든 접속을 차단(`deny incoming`)하도록 기본 정책을 설정했습니다.
<img width="1297" height="162" alt="rule" src="https://github.com/user-attachments/assets/ccacd989-7b7d-422e-8022-5f94b0e1a4d5" />

### [실습 2] 서비스별 포트 개방
9일차에 구축한 Nginx 웹 서버에 접속할 수 있도록 **80번 포트(HTTP)와 443번 포트(HTTPS)**를 허용했습니다. 또한, 추후 원격 관리를 위해 **22번 포트(SSH)**를 허용 목록에 추가했습니다.
<img width="1288" height="212" alt="allow" src="https://github.com/user-attachments/assets/ee227024-7dbf-4d70-984b-244ceafeae52" />

### [실습 3] 방화벽 활성화 및 최종 점검
`ufw enable`을 통해 정책을 실시간으로 적용했습니다. `status numbered` 명령어로 우리가 설정한 규칙이 순서대로 잘 적용되었는지 최종 확인했습니다.
<img width="1292" height="322" alt="firewall" src="https://github.com/user-attachments/assets/48e61b40-3269-441e-aa42-afd1638c84c8" />

---

## 핵심 명령어 요약
- **`sudo ufw status`**: 방화벽의 현재 활성 상태 및 규칙 확인
- **`sudo ufw allow [Port]`**: 특정 포트(예: 80, 22)의 접속을 허용
- **`sudo ufw deny [Port]`**: 특정 포트의 접속을 차단
- **`sudo ufw enable / disable`**: 방화벽 서비스를 시작하거나 중지
- **`sudo ufw status numbered`**: 적용된 규칙을 번호와 함께 리스트 형태로 출력
  
---

## 🇯🇵 오늘의 일본어 엔지니어링
- **단어 1:** **脆弱性 (ぜいじゃくせい, 제이자쿠세이)** - 취약점
