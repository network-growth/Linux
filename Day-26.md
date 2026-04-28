# Day 26: Docker Load Balancer & Container Troubleshooting

## 개요 (Overview)
- **주제**: Docker 컨테이너 웹 서비스 환경 구축 및 트러블슈팅
- **목표**: Nginx 로드밸런서 연동을 위한 컨테이너 환경 구성 및 빌드 오류 해결

## 발생한 문제 (Issue)
1. **Dockerfile 빌드 에러**: `no such file or directory` 에러 발생.
2. **Nginx 설정 미반영**: `nginx.conf` 수정 후에도 기본 "Welcome to nginx" 페이지가 출력됨.
3. **경로 오타**: Dockerfile 내 복사 경로 오타로 인한 웹 리소스 누락.

## 원인 분석 (Diagnosis)
1. **경로 문제**: Nginx의 웹 리소스 기본 경로가 `/usr/share/nginx/html`인데, Dockerfile에서 `/user/share/...`로 잘못 설정함.
2. **Docker 빌드 방식**: 멀티 스테이지 빌드에서 소스 파일 경로가 제대로 매핑되지 않음.
3. **환경 격리**: 호스트 포트(80)와 컨테이너 포트(8081/8082) 충돌로 인해 로컬 테스트 시 결과 확인 어려움.

<img width="1288" height="565" alt="스크린샷 2026-04-28 133557" src="https://github.com/user-attachments/assets/cbd61ac9-31d3-42b3-812b-4cc90047e012" />

## 해결책 (Solution)
- **경로 수정**: Dockerfile 내 복사 경로를 올바른 `/usr` 경로로 수정.
- **Dockerfile 단순화**: 멀티 스테이지 빌드 대신 `COPY` 명령어를 사용하여 현재 디렉토리의 파일을 직접 주입.
- **재빌드 명령어**: `docker compose down --rmi all`을 통해 캐시된 이미지를 삭제하고 `--build` 옵션으로 강제 재빌드 수행.

## 배운 점 (Key Learnings)
- Docker 빌드 시 `Dockerfile`의 경로 지정이 서비스 실행 여부에 결정적임을 확인.
- 컨테이너 포트와 호스트 포트의 매핑 관계를 명확히 이해함 (`curl localhost:8081` 확인).
- `!` 기호와 같은 쉘 예약어 처리 방식 숙지.

## 실행 커맨드 (Quick Start)
```bash
docker compose down --rmi all
docker compose up -d --build
curl localhost:8081
