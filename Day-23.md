# 23일차: 실무형 Multi-stage Docker 빌드 및 서비스 컨테이너화 (2026.04.03)

## 오늘의 목표
- **이미지 최적화**: Multi-stage Build 기법을 사용하여 보안성과 효율성을 높인 도커 이미지를 제작한다.
- **컨테이너 가상화**: 애플리케이션을 환경에 독립적인 컨테이너로 패키징하고 배포하는 실무 프로세스를 익힌다.

---

## 기술 선택 이유 (Why Multi-stage & Nginx?)
실무 클라우드 환경에서는 컨테이너의 **용량**과 **보안**이 매우 중요합니다. 빌드에 필요한 도구(`Python`, `pip` 등)를 최종 이미지에 남겨두면 용량이 커질 뿐만 아니라 보안상 취약점(Attack Surface)이 늘어납니다. 이를 해결하기 위해 빌드 단계와 실행 단계를 분리하는 **Multi-stage Build**를 채택했고, 실행 환경은 가장 가볍고 성능이 뛰어난 **Nginx:alpine**을 선택하여 최적화된 인프라를 구축했습니다.

---

## 실습 기록 상세

### [실습 1] Multi-stage Dockerfile 설계 및 작성
빌드 전용 레이어(`builder`)에서 필요한 파일을 준비하고, 최종 실행 레이어(`nginx:alpine`)로 결과물만 복사하는 설계도를 작성했습니다. 이를 통해 수백 MB에 달하는 이미지를 수십 MB 수준으로 경량화했습니다.

<img wid<img width="1283" height="810" alt="스크린샷 2026-04-03 185935" src="https://github.com/user-attachments/assets/0f1a6f7c-eccc-4416-8fd7-9521d5b8e344" />

<img width="647" height="626" alt="스크린샷 2026-04-03 190116" src="https://github.com/user-attachments/assets/e25d2e14-df32-4b06-ad04-200901b55fef" />

<img width="1283" height="805" alt="스크린샷 2026-04-03 190528" src="https://github.com/user-attachments/assets/1b56677a-f968-4bde-a7d7-ff0b4f2428f4" />

<img width="1282" height="803" alt="스크린샷 2026-04-03 191139" src="https://github.com/user-attachments/assets/f5011d9a-bf0f-4879-bfd8-b6b5f4ef6e7f" />

<img width="1281" height="807" alt="스크린샷 2026-04-03 191150" src="https://github.com/user-attachments/assets/698dfa3e-7bb9-49e3-867d-6bbad73ac8d4" />

### [실습 2] 이미지 빌드 및 권한 트러블슈팅
작성한 설계도를 바탕으로 `docker build`를 수행했습니다. 실습 도중 발생한 도커 그룹 권한 문제(`permission denied`)를 `newgrp docker` 명령어를 통해 세션 권한을 갱신하며 해결하여 인프라 운영 중 발생할 수 있는 권한 체계를 이해했습니다.

<img <img width="650" height="797" alt="스크린샷 2026-04-03 191328" src="https://github.com/user-attachments/assets/2486f9a0-4a61-454f-86a9-cab6b3408ff4" />

<img width="1282" height="810" alt="스크린샷 2026-04-03 191434" src="https://github.com/user-attachments/assets/c13c77ba-04c5-4220-9e6c-b42f54240fa1" />

<img width="1285" height="804" alt="스크린샷 2026-04-03 191536" src="https://github.com/user-attachments/assets/2952ed83-aaae-4383-abb0-f1f375a4e1e2" />

### [실습 3] 서비스 배포 및 가용성 검증
포트 포워딩(`-p 8080:80`) 옵션을 사용하여 컨테이너를 실행했습니다. 로컬 호스트의 8080 포트를 통해 컨테이너 내부의 Nginx 서버에 정상적으로 접속되는 것을 `curl` 명령어로 확인하며 서비스를 성공적으로 배포했습니다.

<img width="1282" height="809" alt="스크린샷 2026-04-03 191736" src="https://github.com/user-attachments/assets/7bd8cdc3-e9f5-484f-9d11-0ae82f6aea60" />

<img width="1285" height="804" alt="스크린샷 2026-04-03 191751" src="https://github.com/user-attachments/assets/906f6528-564b-4825-99b5-84efca2e51ce" />

<img width="1285" height="810" alt="스크린샷 2026-04-03 191923" src="https://github.com/user-attachments/assets/e34935c8-ba90-4105-b637-9fd34f234edb" />

<img width="652" height="806" alt="스크린샷 2026-04-03 191950" src="https://github.com/user-attachments/assets/c57f90d1-1b93-48b7-b247-43dfc7b304f6" />

---

## 핵심 명령어 요약
- **`docker build -t [이름] .`**: 현재 디렉토리의 Dockerfile을 읽어 이미지 생성
- **`docker run -d -p 8080:80 [이름]`**: 컨테이너를 백그라운드에서 실행하고 포트 연결
- **`docker ps`**: 현재 실행 중인 컨테이너 목록 및 상태 확인
- **`newgrp docker`**: 로그아웃 없이 현재 세션에 도커 그룹 권한 적용

---

## 배운 점 & 트러블슈팅
- **이미지 최적화의 가치**: 일반 빌드 대비 압도적으로 작아진 이미지 용량을 확인하며, 클라우드 네이티브 환경에서의 배포 효율성(CI/CD) 향상 방안을 터득함.
- **공격 표면(Attack Surface) 최소화**: 실행 환경에서 불필요한 빌드 도구를 제거함으로써 보안 사고 발생 가능성을 원천적으로 차단하는 보안 내재화(Security by Design)를 실천함.
- **로그 및 모니터링**: `tmux`를 활용해 빌드 과정과 실시간 로그를 동시에 모니터링하며 인프라 엔지니어링의 실무적 협업 환경을 경험함.

---

## 🇯🇵 오늘의 실무 일본어
- **単語: 軽量化 (けいりょうか, 케이료오카)** - 경량화 (용량을 줄여 최적화함)
