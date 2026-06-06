# 🔒 [Container Supply Chain Security] 공급망 보안 고도화 프로젝트 2일차 - Cosign 디지털 서명 키페어 생성 및 오프라인 무결성 검증 (2026-06-06)

## 1. 대규모 프로젝트 시나리오 (Situation)
당신은 대규모 가상 핀테크(금융 결제) 기업인 'Next-Pay'의 Lead Infrastructure Architect입니다. 1일차에 글로벌 표준 이미지 취약점 스캔 엔진인 **Trivy**를 하부 OS에 수동 구축하고, 베이스 이미지를 정밀 타격하여 숨겨진 보안 결함을 사전에 발본색원하는 관제 기지를 가동했습니다.

그러나 사내 화이트해커 팀의 모의 해킹 결과, 또 다른 치명적인 우회 경로가 포착되었습니다. 해커가 이미지 자체의 보안 결함을 건드리는 대신, 취약점 스캔이 통과된 정식 도커 이미지와 이름 및 태그(`python:3.9-alpine`)는 완벽하게 똑같지만 내부에 금융 정보 탈취용 백도어를 교묘하게 숨겨둔 **'위·변조 오염 이미지'**를 빌드 중간 파이프라인(CI/CD)에서 바꿔치기(Man-in-the-Middle) 형식으로 주입하는 시나리오가 성립된 것입니다.

컨테이너의 '이름'과 '태그'만 신뢰하고 클러스터에 배포하는 방식은 제로 트러스트 보안 철학에 위배됩니다. 이에 경영진은 검증이 완료된 정식 이미지에 아키텍트 고유의 비밀키로 암호화된 **디지털 서명(Digital Signing)**을 각인하고, 배포 시점에 무결성을 검증하는 강력한 위·변조 방지 체계 수립을 명령했습니다.

### 프로젝트 미션 (Mission)
- 글로벌 표준 컨테이너 서명 도구인 **Cosign**을 인프라 하부에 안착시키고, 아키텍트 전용 비대칭 암호화 키페어(비밀키/공개키)를 수동 생성한다.
- 외부망이 차단되거나 권한이 제한된 **폐쇄망(Air-Gapped) 실무 환경을 가정**하여, 원격 레지스트리 의존성 없이 오직 로컬 자원만을 활용해 컨테이너 이미지 무결성을 최종 증명한다.

---

## 2. 실습 구현 기록: 이미지 서명 도구 Cosign 구축 및 키페어 생성

### [Task 1] 이미지 서명 엔진 Cosign 바이너리 수동 설치 및 버전 검증
* 명령어:
  wget [https://github.com/sigstore/cosign/releases/download/v2.2.3/cosign-linux-amd64](https://github.com/sigstore/cosign/releases/download/v2.2.3/cosign-linux-amd64)
  sudo mv cosign-linux-amd64 /usr/local/bin/cosign
  sudo chmod +x /usr/local/bin/cosign
  cosign version
* 설정의 뜻:
  글로벌 오픈소스 보안 재단(Sigstore)의 공식 깃허브 레포지토리로부터 리눅스 환경 전용으로 빌드된 최신 `cosign` 정식 바이너리 파일을 가상머신 커널 내부로 격리 다운로드한 뒤, 환경 변수 표준 경로인 `/usr/local/bin` 구역으로 이관하여 전역 가동 인프라를 수립합니다.

<img width="1279" height="38" alt="스크린샷 2026-06-05 180612" src="https://github.com/user-attachments/assets/cef50a79-1535-48d4-9446-1c324a51f914" />

<img width="1279" height="38" alt="스크린샷 2026-06-05 180612" src="https://github.com/user-attachments/assets/c330680e-37d9-4bd4-a94c-28f42b052930" />

<img width="1286" height="40" alt="스크린샷 2026-06-05 180638" src="https://github.com/user-attachments/assets/9c0b04e6-e3d2-44b2-9239-93a44940df06" />

<img width="1280" height="266" alt="스크린샷 2026-06-05 180649" src="https://github.com/user-attachments/assets/e2fa5c5b-f08a-4ad7-9c98-d63389ec4b74" />

### [Task 2] 아키텍트 전용 비대칭 암호화 서명 키페어(Key-Pair) 생성
* 명령어:
  cosign generate-key-pair
* 설정의 뜻:
  Next-Pay 공급망 전체의 신뢰성을 통제할 고유의 비대칭 암호화 키 쌍을 생성합니다. 아키텍트가 정의한 비밀번호 보안을 기반으로 서명 도장 본체인 비밀키(`cosign.key`)와 인감 증명서 역할을 할 공개키(`cosign.pub`)를 로컬 디렉토리에 빌드합니다.
  *(중간에 generate-key-pair 명령어 타이핑 과정에서 알파벳 't'를 'g'로 입력하는 `generage` 오타 억까가 발생했으나, Cosign 가이드 로그를 역추적하여 교정 타격 완료)*

<img width="1282" height="87" alt="스크린샷 2026-06-05 180817" src="https://github.com/user-attachments/assets/5a196422-972e-4f4e-a83f-56eaf1b2a4e8" />

* 명령어:
  ls -l cosign.key cosign.pub
* 설정의 뜻:
  패스워드 보안 통제를 관통한 뒤 현재 작업 디렉토리에 도장 파일인 `cosign.key`와 검증용 파일인 `cosign.pub`가 누락 없이 완벽하게 생성 및 정렬되었는지 리스트를 뿜어내어 육안으로 확인합니다.

<img width="1282" height="52" alt="스크린샷 2026-06-05 180843" src="https://github.com/user-attachments/assets/b13b4d00-8794-4c3d-b3f9-f58de6d95264" />

---

## 3. 대규모 엔지니어링 억까 연쇄 폭발 및 디버깅 로그 (Troubleshooting)

정순 구조로 서명 및 검증을 타격했을 당시, 실무 환경에서 마주할 수 있는 모든 형태의 하드코어 인프라 억까가 연쇄적으로 폭발했습니다. 본 프로젝트는 이를 정석적인 아키텍처 우회 기법으로 파쇄한 과정을 기록합니다.

### 🚨 억까 1: 외부 투명성 로그(Rekor) 서버 세션 단절 에러
* **현상**: `cosign sign --key cosign.key python:3.9-alpine` 타격 시 외부 원격 로그 서버와의 세션이 만료되거나 차단되는 현상 발생 (`read tcp ...->34.36.47.134:443: read: connection reset by peer`).
* **조치**: 외부망 업로드 프로세스를 명시적으로 거부하는 플래그(`--tlog-upload=false`)를 바인딩하여 1차 우회 성공.

### 🚨 억까 2: 공용 레지스트리(Docker Hub) 권한 거부 에러
* **현상**: 로그 서버 우회 후, 공식 `python` 이미지 저장소에 서명 메타데이터를 직접 업로드(`POST/push`)하려다 보니 당연하게도 쓰기 권한이 없어 자물쇠가 걸림 (`UNAUTHORIZED: authentication required`).
* **조치**: Cosign이 자꾸 외부 인터넷망 및 원격 도커허브 서버를 참조하려는 성질을 강제로 무력화하기 위해, 원격 이미지가 아닌 순수 로컬의 독립된 정적 대상을 서명하는 **`sign-blob` 아키텍처 노선**으로 전격 선회함.

<img width="1281" height="192" alt="스크린샷 2026-06-05 181917" src="https://github.com/user-attachments/assets/bd1df9b0-7b29-4cbb-92ab-f9c6120d7696" />

### 🚨 억까 3: 실시간 데이터 스트림 파이프라인 규격(ASN.1) 불일치 에러
* **현상**: 프로세스 치환 구조(`<(docker save ...)`)를 이용해 실시간 데이터 스트림 방식으로 서명을 처리하자, 서명 시점과 검증 시점의 암호학적 데이터 구조가 미세하게 뒤틀려 검증이 폭발함 (`Error: invalid signature when validating ASN.1 encoded signature`).
* **조치**: 실시간 스트림 방식의 불안정성을 배제하기 위해, 도커 이미지를 가상머신 내부에 완전한 정적 타르볼 파일(`.tar`)로 먼저 인출한 뒤, 고정된 바이너리 파일을 타격하는 방식으로 데이터 무결성을 완벽하게 통제함.

<img width="1285" height="115" alt="스크린샷 2026-06-06 113651" src="https://github.com/user-attachments/assets/185643b9-54cf-4502-a9f1-ca38b4e5ede5" />

---

## 4. 최종 성공 구현 스크립트 (Pure Offline Sign & Verify)

모든 원격 의존성과 파이프라인 규격 오차를 제거한 최종 성공 자동화 스크립트 프로세스입니다.

* 명령어:
  docker save -o python-image.tar python:3.9-alpine
* 설정의 뜻:
  파이프라인 데이터 인입 시 발생하는 데이터 손실 및 규격 왜곡을 원천 차단하기 위해, 베이스 이미지를 파일 본체(`python-image.tar`) 형태로 로컬 스토리지에 완전 격리 인출합니다.

<img width="1291" height="113" alt="스크린샷 2026-06-06 113751" src="https://github.com/user-attachments/assets/46bffede-01c9-487c-87cb-e277f57637f8" />

* 명령어:
  cosign sign-blob --key cosign.key --tlog-upload=false --output-signature python-sign.sig python-image.tar
* 설정의 뜻:
  도커허브 원격 서버에 서명을 푸시하는 대신, 아키텍트의 비밀키(`cosign.key`)를 활용하여 오직 인출된 정적 이미지 파일만을 타격해 디지털 도장 본체 데이터(`python-sign.sig`)를 로컬 디렉토리에 강제 생성합니다.

<img width="1280" height="96" alt="스크린샷 2026-06-06 113932" src="https://github.com/user-attachments/assets/5d49a716-bb91-42fe-874a-7bbd5b780231" />

* 명령어:
  cosign verify-blob --key cosign.pub --insecure-ignore-tlog --signature python-sign.sig python-image.tar

  <img width="1285" height="137" alt="스크린샷 2026-06-06 113957" src="https://github.com/user-attachments/assets/b2b9963b-0b96-450d-bb94-2d04a9c1bc14" />

* 설정의 뜻:
  외부 레포지토리나 원격 검증 서버를 일절 참조하지 않고, 오직 아키텍트의 공개 인감 증명서인 공개키(`cosign.pub`)와 방금 추출한 로컬 서명 파일(`python-sign.sig`)만을 결합 대조하여 데이터의 위·변조 여부를 최종 검증합니다.
* 설정의 결과:
  정적 파일 기반의 완벽한 폐쇄망 우회 기법을 적용한 결과, 문법 규격 오류(ASN.1)를 완벽하게 분쇄하며 터미널 화면에 보안 위·변조가 일절 없음을 암호학적으로 증명하는 **영롱한 `Verified OK` 사인**을 뿜어내며 공급망 보안 고도화 2일차 미션을 성공적으로 완료합니다.
