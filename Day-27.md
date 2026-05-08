# 27일차: Nginx 로드밸런서 구축 및 Failover 환경 검증 (2026.05.08)

## 오늘의 목표
- **부하 분산 구현**: Nginx를 리버스 프록시로 설정하여 다중 웹 서버 컨테이너로 트래픽을 분산시킨다.
- **가용성 검증**: 특정 서버 장애 시에도 로드밸런서가 정상 서버로 트래픽을 자동 우회(Failover)시키는지 확인한다.

---

## 기술 선택 이유 (Why Load Balancing?)
단일 서버 환경에서는 트래픽 급증이나 서버 장애 시 서비스 중단이 발생할 위험이 큽니다. 이를 방지하기 위해 상단에 로드밸런서를 배치하여 트래픽을 여러 노드로 나누고, 한 노드가 다운되더라도 서비스가 유지되는 **고가용성(High Availability)** 인프라를 구축하고자 했습니다.

---

## 실습 기록 상세

### [실습 1] Nginx 로드밸런서 및 다중 서비스 설정
`docker-compose.yml`을 통해 로드밸런서(`nginx-lb`) 1대와 백엔드 서버 2대(`main-web-service`, `secondary_service`)를 구축했습니다. 호스트의 80번 포트 점유 문제를 피하기 위해 외부 포트를 `8080`으로 매핑했습니다.

<img width="1274" height="66" alt="스크린샷 2026-04-30 105034" src="https://github.com/user-attachments/assets/09c636a2-fc1e-4323-bda1-21de5bf40325" />

<img width="1278" height="420" alt="스크린샷 2026-04-30 151828" src="https://github.com/user-attachments/assets/7d31f567-a7c2-473a-93a3-934ddb08755b" />

<img width="1288" height="79" alt="스크린샷 2026-04-30 151808" src="https://github.com/user-attachments/assets/31773e87-3ef1-4705-a7f1-266233fa6a89" />

- **설정 포인트**: `upstream` 설정을 통해 두 서버를 그룹화하고, `proxy_pass`로 요청을 전달함.

<img width="1282" height="299" alt="스크린샷 2026-04-30 151901" src="https://github.com/user-attachments/assets/e405eb9d-3da3-423e-8c3a-04f662ee9982" />

### [실습 2] 트러블슈팅: 설정 오타 및 포트 충돌 해결
Nginx 설정 파일(`default.conf`)에서 서비스 이름 오타(`main-web-services`)로 인해 컨테이너가 실행되지 않는 문제를 발견했습니다. `docker compose logs`를 통해 에러를 식별하고, 이름을 일치시켜 정상화했습니다. 또한 `address already in use` 에러 발생 시 포트 포워딩 설정을 변경하여 충돌을 해결했습니다.

### [실습 3] 장애 발생(Failover) 테스트 및 무중단 확인
`docker stop main-web-service` 명령어로 메인 서버를 강제로 종료했습니다. 이후 `curl localhost:8080` 요청 시, 로드밸런서가 살아있는 `secondary_service`로만 트래픽을 전송하여 서비스가 끊김 없이 유지되는 것을 확인했습니다.

<img width="1287" height="49" alt="스크린샷 2026-04-30 151922" src="https://github.com/user-attachments/assets/12d3e86f-66dd-480a-8935-a813c095d13c" />

<img width="1281" height="406" alt="스크린샷 2026-04-30 152103" src="https://github.com/user-attachments/assets/947a575a-bfc5-4400-960c-e73fbd841759" />

---

## 핵심 명령어 요약
- **`docker compose up -d --build`**: 변경된 설정 파일 반영 및 컨테이너 재빌드
- **`docker stop [Service_Name]`**: 장애 상황 시뮬레이션을 위한 특정 서비스 중단
- **`curl localhost:8080`**: 로드밸런서를 통한 서비스 응답 확인 및 트래픽 분산 테스트
- **`docker compose logs [Service_Name]`**: 설정 오류 및 서비스 상태 로그 분석

---

## 배운 점 & 트러블슈팅
- **이름 정의의 중요성**: `docker-compose.yml`과 `nginx.conf` 간의 호스트 이름이 100% 일치해야 통신이 가능함을 체감함.
- **유연한 대처**: 포트 충돌 상황에서 당황하지 않고 포트 매핑을 변경하여 환경을 구축하는 실무적 해결 능력을 기름.
- **로드밸런싱의 가치**: 인프라 설계 시 왜 다중화가 필수적인지 장애 조치 테스트를 통해 직접 증명함.

---

## 🇯🇵 오늘의 실무 일본어
- **単語: 負荷分散 (ふかぶんさん, 후카분산)** - 부하 분산 (로드밸런싱)
