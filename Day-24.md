# 24일차: Docker Compose를 활용한 다중 컨테이너 통합 관리 (2026.04.06)

## 오늘의 목표
- **인프라 코드화(IaC)**: `docker-compose.yml`을 작성하여 여러 개의 서비스를 하나의 설정 파일로 관리한다.
- **서비스 오케스트레이션**: 서로 다른 역할을 하는 컨테이너(메인 웹, 보조 서버)를 동시에 기동하고 네트워크를 연동한다.

---

##  기술 선택 이유 (Why Docker Compose?)
실무에서는 단일 컨테이너만 사용하는 경우가 드뭅니다. 웹 서버, DB, 캐시 등 복잡한 구성을 일일이 `docker run`으로 실행하면 관리가 어렵고 실수가 발생하기 쉽습니다. Docker Compose를 사용하면 서비스 간의 의존성을 정의하고, 명령어 한 줄로 전체 인프라를 동일한 상태로 복제 및 실행할 수 있어 운영 효율성이 극대화됩니다.

---

## 실습 기록 상세

### [실습 1] 다중 서비스 환경 설계 (YAML 정의)
어제 만든 `my-pro-web` 이미지와 경량 Nginx 이미지를 각각 8081, 8082 포트에 매핑하는 설정을 작성했습니다. YAML 형식의 엄격한 들여쓰기 규칙을 준수하며 인프라 구성을 명세화했습니다.

<img width="1283" height="807" alt="스크린샷 2026-04-06 185456" src="https://github.com/user-attachments/assets/2b3879a7-0131-4a4b-85a3-6ab81f31c93f" />

<img width="647" height="786" alt="스크린샷 2026-04-06 185550" src="https://github.com/user-attachments/assets/b658fdfa-0675-4f57-83b9-b508565a126c" />

<img width="647" height="722" alt="스크린샷 2026-04-06 190745" src="https://github.com/user-attachments/assets/ad89a61c-c544-45ca-b758-9be518df104d" />

### [실습 2] 통합 서비스 기동 및 가용성 확인
`docker compose up -d` 명령으로 두 개의 컨테이너를 동시에 생성했습니다. 각각의 포트(8081, 8082)로 접속 테스트를 수행하여 멀티 컨테이너 환경이 정상적으로 작동함을 검증했습니다.

<img width="641" height="785" alt="스크린샷 2026-04-06 190800" src="https://github.com/user-attachments/assets/46b5ccbc-00cd-4059-a4bd-e841826d08d1" />

<img width="651" height="789" alt="스크린샷 2026-04-06 190811" src="https://github.com/user-attachments/assets/f9169007-25cc-4fa3-ac8e-40befb839e9e" />

<img width="1281" height="783" alt="스크린샷 2026-04-06 190857" src="https://github.com/user-attachments/assets/f730c215-b623-45d2-a97e-c42e1cd0a8b9" />

<img width="518" height="145" alt="스크린샷 2026-04-06 190921" src="https://github.com/user-attachments/assets/78b493bf-7343-4a23-8794-bd2dd30f9099" />

<img width="1282" height="780" alt="스크린샷 2026-04-06 191020" src="https://github.com/user-attachments/assets/0b8764f0-891e-4bd6-a8eb-6dceafcb6ae8" />

<img width="646" height="786" alt="스크린샷 2026-04-06 191114" src="https://github.com/user-attachments/assets/ed7c5e2d-f7a1-4cf5-868f-c141a564d451" />

---

## 핵심 명령어 요약
- **`docker compose up -d`**: 설정 파일에 정의된 모든 서비스를 백그라운드에서 기동
- **`docker compose ps`**: 컴포즈로 관리되는 컨테이너들의 상태 확인
- **`docker compose logs -f`**: 여러 컨테이너의 로그를 실시간으로 통합 모니터링
- **`docker compose down`**: 모든 서비스를 정지하고 생성된 네트워크까지 일괄 정리

---

## 배운 점 & 트러블슈팅
- **YAML 문법의 정밀함**: 공백 한 칸이 시스템 전체의 동작 여부를 결정함을 확인하며, 설정 파일 관리의 꼼꼼함이 엔지니어의 핵심 역량임을 깨달음.
- **인프라 재현성**: `docker-compose.yml` 파일만 있으면 언제 어디서든 동일한 서버 환경을 띄울 수 있다는 점을 확인하며 클라우드 자동화의 기초를 다짐.

---

## 🇯🇵 오늘의 실무 일본어
- **単語: 連携 (れんけい, 렌케이)** - 연계 (서비스 간 연결)
