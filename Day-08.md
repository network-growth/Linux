# 8일차: 네트워크 경로 추적 및 트러블슈팅(Troubleshooting) (2026.02.20)

## 오늘의 목표
- 네트워크의 연결 유무를 넘어, 패킷의 이동 경로와 인프라의 응답 상태를 정밀 진단하기

---

## 실습 기록 상세

### [실습 1] 네트워크 경로 추적 (`traceroute`)
`google.com`으로 향하는 패킷이 어떤 관문을 거치는지 추적했습니다. 게이트웨이(`10.0.2.2`)를 지나 외부망으로 나가는 경로를 확인하며, 네트워크 장애 시 어느 지점에서 병목이 발생하는지 판단하는 기술을 익혔습니다.
<img width="807" height="235" alt="apt traceroute" src="https://github.com/user-attachments/assets/85c98ffe-7ffd-4c92-ade0-4e1c7b2e4d0f" />
<img width="1287" height="797" alt="google" src="https://github.com/user-attachments/assets/a451801f-66dd-4a3a-9e93-54800529184f" />

### [실습 2] 시스템 및 네트워크 정보 통합 분석
`ip addr`로 서버 주소를 확인하고, `top` 명령어로 실시간 프로세스 상태를 점검했습니다. 네트워크와 시스템 자원은 밀접하게 연결되어 있음을 이해하고 종합적인 진단을 수행했습니다.
<img width="1279" height="119" alt="zv" src="https://github.com/user-attachments/assets/e93bd958-28b2-4497-b30b-b7588eeea85a" />

### [실습 3] 파일 위치 검색 및 관리
`find` 명령어를 사용하여 시스템 내 산재한 파일을 검색하고, 앞서 배운 쉘 스크립트(`backup.sh`)와의 연계 가능성을 검토했습니다.
<img width="1279" height="273" alt="linjk" src="https://github.com/user-attachments/assets/88d11b2a-0dd7-4834-8f5f-403955b5324a" />

---

## 핵심 명령어 요약
- **`traceroute`**: 목적지까지 거치는 모든 경로(Hop)를 추적하여 지연 구간 파악
- **`ip addr`**: 서버의 내부 IP 및 네트워크 인터페이스 상태 확인
- **`top`**: 시스템 자원 사용량 모니터링
- **`find`**: 파일 시스템 내에서 특정 데이터 위치 검색

---

## 🇯🇵 오늘의 일본어 엔지니어링
- **단어 1:** **障害 (しょうがい, 쇼-가이)** - 장애 (Error/Failure)
