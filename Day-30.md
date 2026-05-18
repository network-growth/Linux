# [Zero-Trust Infrastructure] Next-Pay 핀테크 인프라 고도화 프로젝트 1일차 - 환경 설정 (2026-05-18)

## 1. 대규모 프로젝트 시나리오 (Situation)
당신은 대규모 가상 핀테크(금융 결제) 기업인 'Next-Pay'의 Lead Infrastructure Architect입니다. 최근 사내망에 침입한 해커가 내부 마이크로서비스 간의 패킷을 훔쳐보는 스니핑(Sniffing) 공격으로 결제 요청 데이터를 평문 상태로 탈취하는 대형 보안 사고가 발생했습니다. 이에 경영진은 외부 방화벽만 믿는 경계 보안의 한계를 인정하고, 내부망의 그 어떤 서비스도 신뢰하지 않는 'Zero Trust(제로 트러스트)' 보안 아키텍처 도입을 명령했습니다.

### 프로젝트 미션 (Mission)
- VM(가상머신) 자원 최적화 및 리눅스 커널 튜닝을 통해 대규모 마이크로서비스 및 서비스 메쉬를 수용할 수 있는 쿠버네티스(K8s) 기반 인프라 기지를 안전하게 프로비저닝한다.

---

## 2. 실습 구현 기록: 하부 인프라 OS 튜닝 및 가상화 최적화

### [Task 1] 리눅스 스왑(Swap) 메모리 영구 비활성화
* 명령어:
  sudo swapoff -a
* 설정의 뜻:
  현재 가동 중인 리눅스 시스템의 스왑(가상 메모리) 공간을 즉시 비활성화하여 쿠버네티스가 메모리 자원을 직접 일관되게 제어할 수 있도록 유도합니다.

  <img width="1285" height="199" alt="스크린샷 2026-05-18 193124" src="https://github.com/user-attachments/assets/c94c87ca-95ce-4dc6-877b-9244c1140d01" />


* 명령어:
  sudo vi /etc/fstab
* 설정의 뜻:
  리눅스 파일 시스템 마운트 설정 파일을 열어 swap 행의 맨 앞에 '#'을 붙여 주석 처리합니다. 가상머신이 재부팅되더라도 스왑 메모리가 자동으로 다시 켜지는 것을 영구적으로 방지합니다.

<img width="1282" height="328" alt="스크린샷 2026-05-18 193104" src="https://github.com/user-attachments/assets/2cfe3b82-1704-42d3-a95f-9d95b8c22422" />


### [Task 2] L2/L3 네트워크 브릿지 커널 모듈 활성화
* 명령어:
  sudo vi /etc/modules-load.d/k8s.conf
* 설정의 뜻:
  리눅스가 부팅될 때 쿠버네티스 구동에 필수적인 네트워크 가상 브릿지 커널 모듈을 자동으로 로드하도록 설정 파일을 생성하고 내부에 'br_netfilter'를 입력합니다.

<img width="1278" height="284" alt="스크린샷 2026-05-18 193207" src="https://github.com/user-attachments/assets/19ea5e62-5c60-4e3d-9e96-b5325b1efbb3" />


* 명령어:
  sudo modprobe br_netfilter
* 설정의 뜻:
  가상머신 재부팅 과정을 거치지 않고, 위에서 선언한 브릿지 필터링 커널 모듈을 현재 커널 시스템에 실시간으로 즉시 로딩합니다.

### [Task 3] 네트워크 방화벽 패킷 전달 파라미터 튜닝
* 명령어:
  sudo vi /etc/sysctl.d/k8s.conf
* 설정의 뜻:
  리눅스 커널 파라미터 구성 파일을 생성하여 가상 브릿지를 통과하는 모든 IPv4 및 IPv6 트래픽이 리눅스 iptables 방화벽 규칙에 의해 투명하게 필터링되도록 강제하는 아래 설정을 입력합니다.

<img width="1282" height="291" alt="스크린샷 2026-05-18 193336" src="https://github.com/user-attachments/assets/daf0db08-038e-4246-b6e4-644b2921ed28" />


* 명령어:
  sudo sysctl --system
* 설정의 뜻:
  위에서 vi 에디터로 수정하고 저장한 커널 파라미터('k8s.conf') 설정값들을 가상머신 시스템에 실시간으로 즉시 반영합니다.

---

## 3. 쿠버네티스(Minikube) 및 서비스 메쉬(Istio) 인프라 기지 구축

### [Task 1] 오케스트레이터 및 명령 조종간(kubectl) 설치
* 명령어:
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  sudo install minikube-linux-amd64 /usr/local/bin/minikube
* 설정의 뜻:
  가상 환경에 싱글 노드 쿠버네티스를 구성해 주는 공식 minikube 실행 파일을 다운로드하고, 시스템 전역 경로인 '/usr/local/bin'에 권한과 함께 안전하게 설치합니다.

<img width="1278" height="69" alt="스크린샷 2026-05-18 193509" src="https://github.com/user-attachments/assets/a9e7c7da-1ec3-40d2-be8e-dd642aa3c87c" />

* 명령어:
  curl -LO "[https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl](https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl)"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
* 설정의 뜻:
  생성된 쿠버네티스 클러스터 인프라에 통제 명령을 내리는 전용 조종간 도구인 'kubectl'을 다운로드하여 시스템 실행 경로에 안착시킵니다.

<img width="1285" height="134" alt="스크린샷 2026-05-18 193632" src="https://github.com/user-attachments/assets/9798beb0-07b8-4828-a95e-04849135f1b7" />

* 명령어:
  minikube start --driver=docker --cpus=2 --memory=4096
* 설정의 뜻:
  수많은 마이크로서비스와 사이드카 보안 프록시 엔진들을 부하 없이 감당할 수 있도록, 핀테크 가용량 표준인 CPU 2 Core, Memory 4GB 자원을 명시적으로 할당하여 격리된 도커 가상화 환경 기반의 쿠버네티스 클러스터를 기동합니다.

<img width="1280" height="613" alt="스크린샷 2026-05-18 195053" src="https://github.com/user-attachments/assets/4d4ddab5-ea63-42ec-9432-53701ebb90f0" />

### [Task 2] Istio 보안 관제소(Control Plane) 수동 구축
* 명령어:
  cd istio-1.29.2
  export PATH=$PWD/bin:$PATH
* 설정의 뜻:
  다운로드된 Istio 패키지 폴더 내부로 이동한 뒤, 내부 'bin' 폴더에 위치한 istioctl 도구를 터미널 어디서나 즉시 호출할 수 있도록 현재 세션의 환경 변수(PATH)에 수동 등록합니다.

<img width="521" height="72" alt="스크린샷 2026-05-18 195255" src="https://github.com/user-attachments/assets/17107c1d-486e-497b-ad37-25edb63d230d" />

* 명령어:
  istioctl install --set profile=demo -y
* 설정의 뜻:
  다양한 마이크로서비스 제어 및 트래픽 검증 기능을 포함하는 데모 프로파일 옵션을 지정하여, 클러스터 전역의 mTLS 인증서 발급과 통제를 담당할 중앙 집중식 보안 관제탑인 'istiod'를 배포합니다.

<img width="1278" height="338" alt="스크린샷 2026-05-18 195640" src="https://github.com/user-attachments/assets/bd5c02f8-f3b1-499c-92fd-056fd659a538" />

* 명령어:
  kubectl get namespace --show-labels
* 설정의 뜻:
  현재 가상 금융 서비스들이 기동될 'default' 구역(Namespace)의 인프라 태그(Labels) 상태를 수동으로 조회합니다. 이를 통해 해당 구역에 애플리케이션 컨테이너가 배포될 때 Istio 보안 요원(Envoy Proxy)이 자동으로 한 몸처럼 결합되도록 유도하는 'istio-injection=enabled' 정책이 인프라에 이미 올바르게 수립되어 활성화되어 있음을 직접 검증합니다.

<img width="1280" height="116" alt="스크린샷 2026-05-18 195819" src="https://github.com/user-attachments/assets/731c29ee-3643-404f-a012-6397a360c1cb" />

### [Task 3] Next-Pay 가상 금융 서비스 배포
* 명령어:
  kubectl apply -f samples/sleep/sleep.yaml
  kubectl apply -f samples/httpbin/httpbin.yaml
* 설정의 뜻:
  Istio 공식 패키지 내부에 내장된 표준 가용 소스 파일을 활용하여, 향후 제로 트러스트 보안 통신망 테스트를 수행할 가상 프론트엔드 클라이언트(sleep) 서비스와 코어 결제 API 백엔드 서버(httpbin)를 인프라 상에 배포 및 구동합니다.

  <img width="1274" height="126" alt="스크린샷 2026-05-18 195940" src="https://github.com/user-attachments/assets/4e1813fc-6e57-4476-8bf5-745847d59519" />

* 명령어:
  kubectl get pods
* 설정의 뜻:
  배포된 가상 금융 서비스 Pod들이 정상적으로 가동되었는지 확인하고, 활성화된 주입 정책에 의해 각 Pod 내부에 2개의 컨테이너(앱 컨테이너 1개 + Envoy 보안 프록시 컨테이너 1개)가 안전하게 READY 2/2 및 Running 상태로 결합되었는지를 최종 검증합니다.

  <img width="1285" height="65" alt="스크린샷 2026-05-18 195959" src="https://github.com/user-attachments/assets/29b4690f-068a-4962-bb9b-b9cdcba14af2" />
