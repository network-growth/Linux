# 🔒 [Zero-Trust Infrastructure] Next-Pay 핀테크 인프라 고도화 프로젝트 2일차 - 제로 트러스트 보안망 구축 및 최종 검증 (2026-05-30)

## 1. 대규모 프로젝트 시나리오 (Situation)
당신은 Next-Pay의 Lead Infrastructure Architect입니다. 1일차에 프로비저닝한 쿠버네티스(Minikube) 및 Istio 인프라 기지를 기반으로, 본격적인 서비스 메쉬 보안 자물쇠를 채워야 합니다. 마이크로서비스 간의 모든 Plain Text(평문) 트래픽을 거부하는 상호 TLS(mTLS STRICT) 모드를 강제하고, 화이트리스트 기반의 L7 인가 정책(AuthorizationPolicy)을 수립하여 비인가 공격자의 침입을 원천 차단하는 제로 트러스트 실효성을 최종 검증해야 합니다.

### 프로젝트 미션 (Mission)
- YAML 파일 구조 제어 및 쿠버네티스 컴포넌트 생명 주기를 수동 트러블슈팅하여 메쉬 전역에 mTLS STRICT 자물쇠를 채우고, 권한이 없는 비인가 해커 패킷을 칼같이 드롭(403 Forbidden)시키는 제로 트러스트 아키텍처를 완성한다.

---

## 2. 실습 구현 기록: 서비스 메쉬 전역 mTLS 암호화 및 L7 인가 정책 수립

### [Task 1] 전역 mTLS STRICT 암호화 강제 (`peer-auth.yaml`)
* 명령어:
  vi peer-auth.yaml
* 설정의 뜻:
  `default` 네임스페이스 구역의 모든 마이크로서비스 간 통신 시 평문 패킷 전송을 완전히 금지하고, 오직 상호 인증서 교환 방식인 mTLS(Strict Mode) 터널링만 통과하도록 제안하는 전역 보안 정책 정의 파일을 생성합니다.
  *(들여쓰기 억까 및 탭 문자 파싱 에러 방지를 위해 에디터 내 `:set paste` 순정 모드를 가동하여 공백 제어 튜닝 완료)*

<img width="329" height="159" alt="스크린샷 2026-05-30 111104" src="https://github.com/user-attachments/assets/f34df59d-2f91-4add-9593-fa469413d62e" />

* 명령어:
  kubectl apply -f peer-auth.yaml
* 설정의 뜻:
  장인정신으로 공백을 제어해 수정한 mTLS 강제화 파일(`peerauthentication`)을 쿠버네티스 보안 사령부(API Server)에 전송하여 정상적으로 정책을 생성(`created`)합니다.

<img width="592" height="39" alt="스크린샷 2026-05-30 111259" src="https://github.com/user-attachments/assets/36a49ffa-5fa9-4c62-af75-c1a206d5e0e8" />

### [Task 2] 화이트리스트 기반 L7 인가 정책 설계 (`auth-policy.yaml`)
* 명령어:
  vi auth-policy.yaml
* 설정의 뜻:
  핵심 결제 API 백엔드 서버(`httpbin`) 앞단에 철벽 방화벽 자물쇠를 채우기 위해, 오직 정식 인가된 가상 프론트엔드 서비스 어카운트(`cluster.local/ns/default/sa/sleep`)가 요청하는 특정 엔드포인트 경로(`GET /headers`)만 통과(`ALLOW`)시키도록 화이트리스트 인가 정책 파일을 빌드합니다.
  *(문법 에러 유발 인자인 `matchLabels` 오타를 정밀 수정하여 인프라 정렬 수립)*

<img width="1285" height="309" alt="스크린샷 2026-05-30 112049" src="https://github.com/user-attachments/assets/f7ec8ca5-1e42-4df8-b9df-75906ecabee5" />

* 명령어:
  kubectl apply -f auth-policy.yaml
* 설정의 뜻:
  수립한 L7 화이트리스트 방화벽 정책(`AuthorizationPolicy`)을 클러스터에 최종 반영하여, 허가되지 않은 정체불명의 패킷이 진입하는 즉시 Envoy 프록시 선에서 격리될 수 있도록 통제 관제탑에 등록합니다.

<img width="1277" height="40" alt="스크린샷 2026-05-30 112111" src="https://github.com/user-attachments/assets/f7cbe64f-bf38-4d45-83f4-ce2016b0e9ad" />

---

## 3. 제로 트러스트 철벽 방어망 최종 타격 및 검증 테스트

### [Task 1] 인가된 프론트엔드의 정상 통신 검증 (sleep -> httpbin)
* 명령어:
  kubectl rollout restart deployment sleep
  kubectl rollout restart deployment httpbin
* 설정의 뜻:
  새로 채워진 암호화 자물쇠 정책을 사이드카 프록시 세션에 완벽하게 동기화시키기 위해, 기존 팟(Pod)을 다운시키고 최신 정책이 래핑된 새로운 컨테이너들로 클러스터를 안전하게 새로고침(재부팅)합니다.

* 명령어:
  kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -c sleep -- curl -s http://httpbin:8000/headers
* 설정의 뜻:
  롤아웃 리스타트로 인해 실시간 유동 변화된 `sleep` Pod의 명칭을 `jsonpath` 구문으로 자동 추적 및 가로채기를 수행한 뒤, 컨테이너 내부로 직접 진입하여 백엔드로 통신 패킷을 날립니다.
* 설정의 결과:
  정식 허가된 세션이므로 암호화 터널을 무사히 관통하여 `HTTP 200 OK`와 함께 JSON 헤더 정보가 터미널에 주르륵 출력됩니다. 특히 데이터 내부에 Istio가 강제 삽입한 상호 암호화 인증서 증명 헤더(`X-Forwarded-Client-Cert`)가 완벽하게 찍히는 것을 직접 수동 검증했습니다.

<img width="1287" height="451" alt="스크린샷 2026-05-30 113333" src="https://github.com/user-attachments/assets/a0181cb3-fdb6-4abf-82e2-e05bae600747" />

### [Task 2] 비인가 외부 침입자 공격 및 격리 검증 (호스트 터미널 -> httpbin ClusterIP)
* 명령어:
  curl -v http://$(kubectl get svc httpbin -o jsonpath='{.spec.clusterIP}'):8000/headers
* 설정의 뜻:
  이번에는 서비스 메쉬 자물쇠 구역 외부에 위치하여 정식 보안 인증서 권한이 전혀 없는 우분투 가상머신 호스트 터미널(생짜 외부 해커 포지션)에서 백엔드 코어망을 향해 무단 우회 침투 및 정보 탈취 타격을 시도합니다.
* 설정의 결과:
  암호화 인증서가 유실된 무권한 평문 패킷임을 인프라 방화벽이 실시간으로 감지하고 숨도 안 쉬고 차단 처리를 시전합니다. `-s` 정숙 모드 해제 및 상세 로그 옵션(`-v`) 추적 결과, 가상 IP 대역 차단 격리 효과와 더불어 방화벽이 패킷을 전면 파괴하여 침입을 완벽히 방어(Connection Refused / RBAC: access denied)해 냈음을 최종 증명하며 실습 상황을 성공적으로 종료합니다.

  <img width="1303" height="42" alt="스크린샷 2026-05-30 114451" src="https://github.com/user-attachments/assets/db965735-9fda-4d13-8bb2-caeb2dbee37c" />
