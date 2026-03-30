# 22일차: NFS 기반 중앙 집중형 공유 스토리지 구축 실습 (2026.03.30)

## 오늘의 목표
- NFS(Network File System)를 활용하여 여러 서버가 동일한 데이터를 공유하는 환경을 설계한다.
- 다중 노드 환경에서 발생하는 데이터 불일치 문제를 해결하고 데이터 정합성을 확보한다.

---

## 기술 선택 이유 (Why NFS?)
**로드밸런싱(Nginx)** 환경에서는 트래픽이 여러 서버로 분산됩니다. 이때 각 서버가 개별 저장소를 사용하게 되면, 사용자가 접속하는 서버에 따라 파일이 보이지 않는 **데이터 불일치(Data Inconsistency)** 현상이 발생합니다. 
이를 해결하고 모든 서버가 실시간으로 동일한 파일을 바라보게 하기 위해, 유닉스 계열의 표준 공유 프로토콜인 **NFS**를 선택하여 중앙 집중형 저장소 아키텍처를 구현했습니다.

---

## 실습 기록 상세

### [실습 1] NFS 서버(Storage) 환경 설정 및 권한 부여
중앙 창고 역할을 할 `/srv/nfs_share` 디렉토리를 생성하고, 보안과 접근성을 위해 `nobody:nogroup` 권한을 부여했습니다. 이후 `/etc/exports` 파일을 수정하여 허용된 IP(`127.0.0.1`)만 접근할 수 있도록 네트워크 공유 설정을 완료했습니다.

<img width="1284" height="805" alt="스크린샷 2026-03-30 162952" src="https://github.com/user-attachments/assets/fbdf1fdb-1d06-4f3a-a353-3a57a2bd6def" />

<img width="1285" height="802" alt="스크린샷 2026-03-30 163024" src="https://github.com/user-attachments/assets/e664b794-55bb-4bee-8cec-9d3dfeb00995" />

<img width="1288" height="809" alt="스크린샷 2026-03-30 163133" src="https://github.com/user-attachments/assets/d4e075a9-ba21-414a-9889-30d6f13c3181" />

<img width="1284" height="817" alt="스크린샷 2026-03-30 163240" src="https://github.com/user-attachments/assets/a499eb01-5e21-415c-bef3-63cd618d9031" />

<img width="1285" height="802" alt="스크린샷 2026-03-30 163354" src="https://github.com/user-attachments/assets/62bf5694-aa2c-4ed5-97b9-6f5c1b065385" />

### [실습 2] 클라이언트 마운트(Mount) 및 네트워크 연결
클라이언트 환경에서 `mount` 명령어를 사용하여 원격 저장소를 로컬 디렉토리(`~/my_work`)처럼 사용할 수 있게 연결했습니다. `df -h` 명령을 통해 네트워크 경로가 시스템 파일 시스템에 정상적으로 인식되었음을 논리적으로 검증했습니다.

<img width="1282" height="806" alt="스크린샷 2026-03-30 163432" src="https://github.com/user-attachments/assets/72a29174-895e-42f3-9927-f24808d701cc" />

<img width="1293" height="808" alt="스크린샷 2026-03-30 163535" src="https://github.com/user-attachments/assets/4a12dc44-66f3-4156-9262-332855458e71" />

<img width="1281" height="807" alt="스크린샷 2026-03-30 163613" src="https://github.com/user-attachments/assets/d97ff6b6-462d-448a-a1e5-8ac5586dc132" />

---

## 핵심 명령어 요약
- **`sudo apt install nfs-kernel-server`**: NFS 서버 운영을 위한 패키지 설치
- **`/etc/exports`**: 공유할 디렉토리와 접근 권한을 정의하는 설정 파일
- **`sudo exportfs -a`**: 수정한 NFS 설정 내용을 즉시 시스템에 적용
- **`sudo mount [IP]:[경로] [마운트포인트]`**: 원격 저장소를 로컬 폴더로 연결

---

## 배운 점 & 트러블슈팅
- **데이터 정합성(Consistency) 확보**: 다중 서버 환경에서 데이터 일관성을 유지하는 중앙 저장소 설계의 중요성을 체득함.
- **인프라 통합 관점**: 로드밸런서(입구)와 공유 스토리지(창고)가 결합되어야 비로소 완전한 서버 클러스터 시스템이 완성된다는 것을 깨달음.

---

## 🇯🇵 오늘의 일본어 엔지니어링
- **単語: 共有ストレージ (きょうゆうすとれーじ, 쿄오유우스토레에지)** - 공유 스토리지 (Shared Storage)
