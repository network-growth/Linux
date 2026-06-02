# 🔒 [Container Supply Chain Security] 공급망 보안 고도화 프로젝트 1일차 - 스캔 엔진 구축 및 베이스 이미지 정밀 타격 (2026-06-02)

## 1. 대규모 프로젝트 시나리오 (Situation)
당신은 대규모 가상 핀테크(금융 결제) 기업인 'Next-Pay'의 Lead Infrastructure Architect입니다. 최근 사내 보안 관제소로부터 긴급 경보가 울렸습니다. 해커들이 내부 마이크로서비스 통신망을 직접 스니핑하는 대신, 개발자들이 사용하는 소스코드 빌드 및 배포 파이프라인(CI/CD) 자체에 침투하여 악성코드(Backdoor)가 심어진 오염된 도커 이미지를 정식 앱으로 위장해 클러스터에 강제 주입하려는 움직임이 포착되었습니다. 

아무리 내부 인프라망에 mTLS 자물쇠를 잘 채워두어도, 배포되는 애플리케이션 컨테이너 자체가 내부 스파이라면 금융 인프라 전체가 무너집니다. 이에 경영진은 외부 소스에서 가져오는 모든 베이스 이미지의 알려진 취약점(CVE)을 빌드 단계에서 원천 차단하는 '컨테이너 공급망 보안(Container Supply Chain Security)' 체계 수립을 명령했습니다.

### 프로젝트 미션 (Mission)
- 글로벌 인프라 표준 이미지 취약점 스캔 엔진인 Trivy를 하부 OS에 수동 구축하고, 향후 핀테크 코어 앱의 뼈대가 될 베이스 이미지를 정밀 타격하여 잠재적 보안 결함을 사전에 탐지 및 필터링한다.

---

## 2. 실습 구현 기록: 공급망 보안 스캔 엔진 Trivy 수동 구축

### [Task 1] 이미지 취약점 스캔 관제 레포지토리 등록 및 설치
* 명령어:
  sudo apt-get install wget apt-transport-https gnupg lsb-release -y
* 설정의 뜻:
  Trivy를 안전하게 다운로드하기 위해 암호화 통신 채널에 필요한 리눅스 환경의 기초 패키지 도구들을 먼저 커널에 수동 설치합니다.

<img width="1283" height="92" alt="스크린샷 2026-06-02 221241" src="https://github.com/user-attachments/assets/a08b2016-b7b3-417a-ac5e-97531c0e13c6" />

* 명령어:
  wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
* 설정의 뜻:
  해커가 위조한 악성 패키지가 다운로드되는 것을 방지하기 위해, Aqua Security 공식 저장소에서 발급한 정식 보안 검증 키를 시스템 키링 파일에 등록합니다.
  *(중간에 wget 옵션 타이핑 오타로 알파벳 대문자 `O` 대신 숫자 `0`이 입력되어 `invalid option -- '0'` 에러와 함께 세션이 일시 폭발했으나, 리눅스 표준 인자 구문을 정밀 재수정하여 깔끔하게 트러블슈팅 완료)*

<img width="1285" height="67" alt="스크린샷 2026-06-02 221645" src="https://github.com/user-attachments/assets/c65965b4-f278-4de5-82e2-ddec29d39a63" />

* 명령어:
  echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list
* 설정의 뜻:
  우분투 시스템 패키지 주소록 파일(`trivy.list`)에 공식 원격 저장소 주소를 동적 주입합니다. 이때 현재 사용 중인 우분투 최신 버전의 코드네임인 `noble(24.04)`을 시스템이 자동 감지(`lsb_release -sc`)하여 정렬을 수립합니다.

<img width="1283" height="71" alt="스크린샷 2026-06-02 221840" src="https://github.com/user-attachments/assets/c5caa332-642f-4eaf-b3d0-2716967aad3e" />

<img width="862" height="17" alt="스크린샷 2026-06-02 221846" src="https://github.com/user-attachments/assets/6a4059c0-85e4-47bd-8d55-262be5ad4827" />

* 명령어:
  sudo apt-get update
* 설정의 뜻:
  새로운 Trivy 주소가 주소록에 명시되었으므로, 우분투 패키지 매니저가 해당 원격 서버에 접속해서 설치 가능한 최신 인프라 파일 목록을 동기화(새로고침)합니다.

<img width="1285" height="273" alt="스크린샷 2026-06-02 221916" src="https://github.com/user-attachments/assets/c7e9a8f5-56d9-4186-8bb9-bc47e88d79e4" />

* 명령어:
  sudo apt-get install trivy -y
* 설정의 뜻:
  동기화된 최신 패키지 정보를 기반으로 Next-Pay의 이미지 공급망 보안을 상시 감시할 Trivy 스캔 엔진 본체를 인프라 전역 경로에 수동 설치(`installed`) 가동합니다.

<img width="1286" height="248" alt="스크린샷 2026-06-02 221935" src="https://github.com/user-attachments/assets/f0dd061e-805f-468d-a03d-670ea5ec92f7" />

---

## 3. Next-Pay 가상 금융 앱 베이스 이미지 보안 결함(CVE) 정밀 타격 및 검증 테스트

### [Task 1] 가상 결제 API 베이스 이미지 취약점 스캔 테스트
* 명령어:
  trivy image python:3.9-alpine
* 설정의 뜻:
  향후 Next-Pay 결제 서비스의 중심이 될 마이크로서비스 앱을 빌드할 때 뼈대로 사용할 기본 베이스 이미지(`python:3.9-alpine`)를 지정하여 인프라 배포 전에 결함 분석을 가동합니다.
* 설정의 결과:
  Trivy 스캔 엔진이 실시간 취약점 데이터베이스와 대조 분석한 결과, 전 세계 개발자들이 흔히 사용하는 파이썬 핵심 라이브러리(`pip`, `wheel`) 내부에서 다수의 결함이 감지되었습니다. 
  특히 `wheel (METADATA)` 구역에서 해커가 악성 파일을 업로드하여 관리자 권한을 강제 탈취하고 임의 코드를 실행할 수 있는 위험도 **`HIGH`** 등급의 최신 취약점(**`CVE-2026-24049`**)을 포함하여, `pip` 내부의 경로 트래버설(`CVE-2026-1703`), 심볼릭 링크 악용 결함(`CVE-2025-8869`)들을 배포 전 단계에서 완벽하게 사전에 탐지 및 발본색원해 내는 성과를 거두며 1일차 실습 상황을 성공적으로 종료합니다.

<img width="1287" height="148" alt="스크린샷 2026-06-02 222010" src="https://github.com/user-attachments/assets/727d6093-e1dd-4e14-9a0c-551e0cbed0ab" />

<img width="1280" height="769" alt="스크린샷 2026-06-02 222030" src="https://github.com/user-attachments/assets/04105983-f549-428c-a843-409e5bccb5ac" />
