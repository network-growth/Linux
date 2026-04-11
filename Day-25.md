# 25일차: Docker Healthcheck 및 Self-healing 인프라 구축 (2026.04.11)

## 오늘의 목표
- **가용성 자동화**: Docker의 `healthcheck` 기능을 활용하여 서비스의 이상 상태를 실시간으로 탐지한다.
- **Self-healing 구현**: 장애 발생 시 컨테이너를 자동으로 재시작하여 인프라의 무중단 운영(High Availability)을 실현한다.

---

## 기술 선택 이유 (Why Healthcheck?)
단순히 컨테이너 프로세스가 'Running' 상태라고 해서 서비스가 정상이라고 단정할 수 없습니다. 애플리케이션 내부 로직이 엉키거나 좀비 프로세스가 될 경우, 외부에서는 접속이 안 되지만 도커는 정상으로 판단할 수 있기 때문입니다. 이를 해결하기 위해 실제 서비스 응답을 체크하는 **Healthcheck**와 장애 시 자동 복구하는 **Restart Policy**를 결합하여 안정적인 시스템을 구축했습니다.

---

## 실습 기록 상세

### [실습 1] docker-compose.yml 헬스체크 설정
어제(24일차) 작성한 다중 서비스 환경에 5초마다 상태를 점검하고, 3번 이상 응답이 없으면 'Unhealthy'로 판단하는 로직을 추가했습니다. `restart: always` 옵션을 부여하여 자가 치유가 가능하도록 고도화했습니다.

<img width="650" height="794" alt="스크린샷 2026-04-11 091508" src="https://github.com/user-attachments/assets/e24cf3cf-3261-40a1-bd41-53422908317b" />

<img width="1283" height="800" alt="스크린샷 2026-04-11 091635" src="https://github.com/user-attachments/assets/78a4c264-ad15-4901-a3d0-6b6e04b4cf20" />

<img width="646" height="800" alt="스크린샷 2026-04-11 091720" src="https://github.com/user-attachments/assets/2e56eb19-25b1-497d-903a-38b5cf1eec99" />

<img width="638" height="392" alt="스크린샷 2026-04-11 091738" src="https://github.com/user-attachments/assets/63c5f21e-7289-4b57-828b-783cf678a7f7" />

### [실습 2] 장애 강제 발생 및 자동 복구 테스트
`pkill nginx` 명령어로 컨테이너 내부의 프로세스를 강제로 종료시킨 후, 도커 엔진이 이를 감지하여 컨테이너를 스스로 재시작(Restarting)하는 과정을 모니터링했습니다.

<img width="637" height="385" alt="스크린샷 2026-04-11 092111" src="https://github.com/user-attachments/assets/cced8efa-b4be-4fc7-b8ab-218e05b7ef8b" />


### [실습 3] 통합 모니터링 및 최종 정상화 확인
`docker compose ps`를 통해 상태값이 다시 `(healthy)`로 변하는 과정을 확인하고, `docker compose logs`를 통해 복구 시점의 로그를 분석하며 인프라 엔지니어의 장애 대응 동선을 익혔습니다.

<img width="647" height="413" alt="스크린샷 2026-04-11 092213" src="https://github.com/user-attachments/assets/225dab43-6e85-417f-aea1-1e9aa5677511" />

---

## 핵심 명령어 요약
- **`docker compose ps`**: 컨테이너의 단순 실행 여부를 넘어 Health 상태(healthy/unhealthy) 확인
- **`docker inspect [ID] | grep Health`**: 상세한 헬스체크 로그 및 실패 원인 분석
- **`restart: always`**: 어떠한 상황에서도 서비스가 유지되도록 강제하는 정책

---

## 배운 점 & 트러블슈팅
- **감시의 정밀도**: 프로세스 감시와 서비스 응답 감시의 차이를 이해하고, 실무 수준의 모니터링 설계를 경험함.
- **자동화의 가치**: 엔지니어의 개입 없이 시스템 스스로 장애를 인지하고 복구하는 '자가 치유' 인프라의 중요성을 체감함.

---

## 🇯🇵 오늘의 실무 일본어
- **単語: 復旧 (ふっきゅう, 훗큐우)** - 복구 (장애 상태에서 정상으로 돌림)<img width="650" height="794" alt="스크린샷 2026-04-11 091508" src="https://github.com/user-attachments/assets/410cb6b8-31f1-4dc9-a6da-50f340157546" />
