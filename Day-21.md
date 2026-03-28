# [21일차] Nginx 로드밸런싱 및 고가용성(HA) 아키텍처 실습 (2026.03.28)

## 실습 목표
- **부하 분산(Load Balancing)**: Nginx를 활용해 트래픽을 여러 백엔드 서버로 분산 처리하는 구조 설계.
- **고가용성(High Availability)**: 특정 서버 장애 시에도 서비스가 중단되지 않는 **Failover(장애 극복)** 메커니즘 검증.
- **인프라 모니터링**: `tmux`를 활용한 다중 서버 인스턴스 실시간 로그 분석.

---

## 시스템 아키텍처 및 수행 과정

### 1. 백엔드 서버 이중화 (Node Clustering)
`tmux`를 활용하여 화면을 3분할하고, 각각 다른 포트(`8081`, `8082`)에서 독립된 두 개의 웹 서버를 구동했습니다. 이는 실제 운영 환경에서의 **서버 클러스터링**을 모사한 환경입니다.

<img width="1282" height="809" alt="스크린샷 2026-03-28 112037" src="https://github.com/user-attachments/assets/5875708a-9569-42c5-809c-9413b7343748" />

<img width="1296" height="812" alt="스크린샷 2026-03-28 112403" src="https://github.com/user-attachments/assets/27c75d41-99a1-4cf8-a1aa-c7230138cd65" />

### 2. Nginx 업스트림(Upstream) 구성
사용자의 요청을 받아 백엔드로 전달하는 로드밸런서 설정을 진행했습니다. 
- **설정 파일**: `/etc/nginx/sites-available/default`
- **알고리즘**: **라운드 로빈(Round Robin)** 방식을 적용하여 트래픽을 균등하게 분배했습니다.

<img width="1284" height="800" alt="스크린샷 2026-03-28 112940" src="https://github.com/user-attachments/assets/ecf67a31-c255-440c-b50f-777b4c3623df" />

<img width="637" height="409" alt="스크린샷 2026-03-28 112954" src="https://github.com/user-attachments/assets/231542af-9dd9-4620-a32f-5bca39424e48" />

### 3. 로드밸런싱 동작 및 Failover 검증 (핵심)
- **트래픽 분산 확인**: `curl` 요청 시 각 서버 로그에 번갈아 접속 기록이 남는 것을 확인했습니다.
- **장애 시뮬레이션**: 8081 포트 서버를 강제로 종료(`SIGINT`) 시켰으나, Nginx가 이를 즉시 감지하고 8082 포트로 모든 요청을 자동 전환하여 서비스가 정상 유지됨을 확인했습니다.

<img width="1282" height="804" alt="스크린샷 2026-03-28 113041" src="https://github.com/user-attachments/assets/e98c86e4-4c25-43ca-8e57-eda98b0de3c0" />

<img width="1282" height="803" alt="스크린샷 2026-03-28 113141" src="https://github.com/user-attachments/assets/9521399e-7a54-4efb-8d17-853c167d2ce9" />

---

## 배운 점 및 성과 (생기부 세특용)
1. **인프라 안정성 확보**: 단일 장애점(SPOF)의 위험성을 인지하고, 이를 해결하기 위한 이중화 아키텍처 설계 능력을 배양함.
2. **장애 대응 역량**: 서비스 가용성(Availability)의 중요성을 이해하고, 설정 오타 수정 및 `nginx -t`를 통한 환경 설정 디버깅 과정을 경험함.
3. **실무 도구 숙련**: `tmux`를 활용한 효율적인 서버 리소스 모니터링 및 터미널 환경 관리 기법을 익힘.

---

## 🇯🇵 오늘의 IT 일본어
- **負荷分散 (ふかぶんさん)**: 부하 분산 [후카분산]
- **可用性 (かようせい)**: 가용성 [카요오세이]
- **多중化 (たじゅうか)**: 다중화 [죠오쵸오카]
