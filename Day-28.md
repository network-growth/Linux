# 28일차: WAF(Web Application Firewall) 구축 및 보안 차단 검증 (2026.05.08)

## 오늘의 목표
- **보안 인프라 강화**: Nginx 앞단에 WAF(ModSecurity)를 배치하여 웹 공격을 필터링한다.
- **차단 성능 검증**: SQL Injection 등 실제 공격 페이로드를 전송하여 WAF의 정상 작동 여부를 확인한다.

---

## 기술 선택 이유 (Why WAF?)
로드밸런서만으로는 SQL Injection, XSS 등 애플리케이션 계층(L7)의 정교한 공격을 막기 어렵습니다. 따라서 오픈소스 웹 보안 엔진인 **ModSecurity**와 **OWASP CRS(Core Rule Set)**를 도입하여, 알려진 보안 위협을 사전에 차단하고 백엔드 서버의 안전성을 보장하고자 했습니다.

---

## 실습 기록 상세

### [실습 1] ModSecurity 기반 WAF 컨테이너 구축
`owasp/modsecurity-crs:nginx` 이미지를 활용하여 보안 기능을 탑재한 프록시 서버를 구축했습니다. 보안 권한 이슈를 고려하여 내부 포트를 `8080`으로 매핑하고 환경 변수를 통해 백엔드 서버를 지정했습니다.

- **핵심 설정**: `PARANOIA=1` 수준의 보안 정책 적용 및 `BACKEND` 환경 변수를 통한 트래픽 전달.

<img width="949" height="477" alt="스크린샷 2026-05-08 145859" src="https://github.com/user-attachments/assets/d618968c-663d-4ed8-9458-e18385e4e9c0" />

<img width="1313" height="123" alt="스크린샷 2026-05-08 144244" src="https://github.com/user-attachments/assets/be6ad199-08ad-4766-8ea2-38cd3468f33a" />

<img width="1282" height="617" alt="스크린샷 2026-05-08 144401" src="https://github.com/user-attachments/assets/515929de-4222-4b12-a600-cbe1e0bfb61f" />

### [실습 2] 트러블슈팅: 권한 충돌(Non-root User) 및 포트 설정 해결
WAF 컨테이너가 실행 직후 계속 `Restarting` 되는 문제를 발견했습니다. `docker logs` 분석 결과, 최신 ModSecurity 이미지는 루트 권한이 없어 `80`번 포트를 사용할 수 없음을 확인했습니다.

- **해결 방법**: `docker-compose-waf.yml` 내의 내부 포트 및 `PORT` 환경 변수를 `8080`으로 변경하여 권한 충돌을 해결하고 정상 작동을 확인했습니다.

<img width="1264" height="788" alt="스크린샷 2026-05-08 145336" src="https://github.com/user-attachments/assets/19ced7fe-2410-4398-83ce-aae2a05778a9" />

<img width="1258" height="120" alt="스크린샷 2026-05-08 145615" src="https://github.com/user-attachments/assets/b9541337-9594-4295-a6b0-ad0343b028f9" />

### [실습 3] 보안 공격 시나리오 테스트 및 차단 검증
WAF가 정상적으로 공격을 인지하고 차단하는지 확인하기 위해 `curl` 명령어로 악성 쿼리를 전송했습니다.

- **정상 요청**: `curl -I localhost:8080` -> `200 OK` 확인.
- **SQL Injection 시도**: `curl -I "localhost:8080/?id='OR'1'='1'"` -> **`403 Forbidden`** 응답 확인.
- **결과**: WAF 엔진이 비정상적인 패턴을 탐지하여 백엔드 서버에 도달하기 전 즉시 차단함을 증명했습니다.

<img width="589" height="189" alt="스크린샷 2026-05-08 145757" src="https://github.com/user-attachments/assets/582e686a-3382-43b1-8cb8-011a12324b36" />

<img width="594" height="181" alt="스크린샷 2026-05-08 145842" src="https://github.com/user-attachments/assets/2e6db79f-60fb-4111-a883-b42f0d0d5dbd" />

---

## 핵심 명령어 요약
- **`docker compose -f docker-compose-waf.yml up -d`**: WAF 환경 전용 설정 파일 실행
- **`docker logs nginx-waf`**: 컨테이너 내부 에러 및 ModSecurity 탐지 로그 분석
- **`curl -I "localhost:8080/?id='OR'1'='1'"`**: SQL Injection 공격 시뮬레이션을 통한 차단 테스트
- **`docker ps`**: 컨테이너의 Up 상태 및 헬스체크 결과 확인

---

## 배운 점 & 트러블슈팅
- **최소 권한의 원칙 이해**: 보안 이미지가 왜 80번 포트 대신 높은 번호의 포트를 사용하는지, 비특권 사용자(Unprivileged user) 환경의 중요성을 체감함.
- **로그 중심의 문제 해결**: 컨테이너가 반복적으로 재시작될 때 추측하기보다 `docker logs`를 통해 정확한 원인을 파악하는 습관을 기름.
- **심층 방어(Defense in Depth)**: 로드밸런싱을 통한 가용성 확보에 이어, WAF를 통한 보안성까지 추가하며 완성도 높은 인프라 구조를 이해함.
