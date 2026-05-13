# 29일차: WAF 실시간 로그 수집 및 호스트 동기화 환경 구축 (2026.05.13)

## 오늘의 목표
- **로그 영속성 확보**: 컨테이너 내부의 보안 로그를 호스트 시스템으로 실시간 동기화한다.
- **감사(Audit) 기능 활성화**: ModSecurity의 상세 감사 로그 엔진을 설정하여 공격 정보를 수집한다.

---

## 기술 선택 이유 (Why Log Synchronization?)
컨테이너는 휘발성 환경이므로, 컨테이너가 삭제되거나 재시작되면 내부의 공격 로그도 사라집니다. 보안 사고 발생 시 사후 분석(Forensics)을 수행하고, 향후 ELK Stack과 같은 통합 로그 분석 시스템으로 데이터를 전달하기 위해 호스트와의 로그 공유 환경을 구축했습니다.

---

## 실습 기록 상세

### [실습 1] 로그 볼륨 마운트 및 환경 변수 설정
`docker-compose-waf.yml`을 수정하여 컨테이너의 `/var/log/nginx` 경로를 호스트의 `./logs/waf` 디렉토리와 연결했습니다. 또한 상세 분석을 위해 `MODSEC_AUDIT_ENGINE` 설정을 활성화했습니다.

- **핵심 설정**:
  - `volumes`: `./logs/waf:/var/log/nginx` (실시간 로그 공유)
  - `MODSEC_AUDIT_ENGINE=On` (상세 공격 로그 수집 활성화)

<img width="514" height="523" alt="스크린샷 2026-05-13 215842" src="https://github.com/user-attachments/assets/50d773c7-1bca-4822-88dc-935f7cb1071a" />

### [실습 2] 트러블슈팅: Permission Denied(권한 거부) 문제 해결
로그 폴더 연결 후 Nginx가 로그 파일을 쓰지 못해 컨테이너가 즉시 종료되는 현상이 발생했습니다. 이는 호스트 폴더의 소유권/권한 문제로 판명되었습니다.

- **원인**: WAF 컨테이너의 비특권 사용자 권한이 호스트의 `logs/waf` 폴더에 대한 쓰기 권한이 없음.
- **해결**: `chmod -R 777 ~/my_work/logs/waf` 명령을 통해 폴더 권한을 일시적으로 개방하여 로그 기록이 가능하도록 조치했습니다.

<img width="804" height="91" alt="스크린샷 2026-05-13 215959" src="https://github.com/user-attachments/assets/3dcc0f24-d650-49c1-a281-5129c4de8734" />

<img width="1058" height="41" alt="스크린샷 2026-05-13 220051" src="https://github.com/user-attachments/assets/d2ca59df-c1c1-4d3e-a830-967a1c72874b" />

<img width="654" height="195" alt="스크린샷 2026-05-13 220254" src="https://github.com/user-attachments/assets/a14519c0-4457-49e7-ba2c-e1faa7e77192" />

<img width="1279" height="145" alt="스크린샷 2026-05-13 220305" src="https://github.com/user-attachments/assets/039241a0-12b7-48e3-8877-7a9e5addbf3f" />

### [실습 3] 실시간 로그 데이터 검증
실제 공격 페이로드를 포함한 `curl` 요청을 전송한 후, 호스트 디렉토리에서 로그 파일 생성을 확인했습니다.

- **명령어**: `tail -n 20 ~/my_work/logs/waf/modsec_audit.log`
- **결과**: `access.log`, `error.log`, `modsec_audit.log`가 정상 생성되었으며, 공격자의 IP, 요청 시간, 차단된 규칙 정보가 상세히 기록됨을 확인했습니다.

<img width="783" height="178" alt="스크린샷 2026-05-13 220311" src="https://github.com/user-attachments/assets/23944c48-3ff0-4420-b7b8-64001f5c7b65" />

<img width="525" height="109" alt="스크린샷 2026-05-13 220346" src="https://github.com/user-attachments/assets/8070e290-d6b2-46fb-9363-b9e264d69bf7" />

<img width="1287" height="144" alt="스크린샷 2026-05-13 220931" src="https://github.com/user-attachments/assets/d671bdd6-d58f-4477-9a3e-2c99c4101cae" />

---

## 핵심 명령어 요약
- **`mkdir -p ~/my_work/logs/waf`**: 로그 저장을 위한 호스트 디렉토리 생성
- **`chmod -R 777 ~/my_work/logs/waf`**: 로그 파일 쓰기 권한 이슈 해결
- **`tail -f ~/my_work/logs/waf/error.log`**: 실시간 차단 로그 모니터링
- **`ls -l ~/my_work/logs/waf`**: 로그 파일 동기화 상태 확인

---

## 배운 점 & 트러블슈팅
- **데이터 영속성의 중요성**: 인프라 아키텍트로서 컨테이너의 생명주기와 별개로 데이터를 보존하는 전략(Volume Mount)의 필요성을 깊이 이해함.
- **권한 관리의 복잡성**: Docker 컨테이너와 호스트 OS 간의 권한(UID/GID) 불일치로 인한 장애 상황을 경험하고, 이를 로그 분석(`docker logs`)을 통해 해결하는 능력을 배양함.
