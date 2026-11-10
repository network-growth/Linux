# Day 06. 새 서버 추가 자동화 — PR 한 줄로 web03 배포 (2026-11-10)

## 오늘의 목표
- 아무 설정도 하지 않은 **새 서버(web03)** 를 만들고, **인벤토리 한 줄 PR**만으로 다른 서버와 같은 상태로 만들기
- 사람이 서버에서 하는 일은 **처음 한 번 SSH 키 등록**뿐이고, 나머지(검사·설치·설정)는 전부 CI/CD가 하게 하기
- 서버 3대에 다시 배포해 **모두 `changed=0`** 인지 확인해 재현성 증명하기

---

## 실습 환경
```
GitHub: inventory.ini에 web03 한 줄 → PR → CI(pull_request) ✅ → merge
   → CI(push) ✅ → Deploy(workflow_run)
         ↓ ubuntu-server의 runner가 받아서 실행
ubuntu-server 192.168.56.101 ── ansible-playbook ──> localhost, web02(.102), web03(.104)
```

| VM | 이름 | IP | 역할 |
|---|---|---|---|
| 1 | ubuntu-server | 192.168.56.101 | 제어 노드 + self-hosted runner |
| 2 | web02 | 192.168.56.102 | 관리 대상 (06 Day 06에 Ansible로 구축) |
| 3 | **web03** | **192.168.56.104** | 관리 대상 (오늘 새로 설치, PR로 구축) |

| | 06 Day 06 (web02) | 07 Day 06 (web03) |
|---|---|---|
| 키 등록 | 명령 여러 개를 손으로 | 스크립트 / 명령 몇 줄 |
| 인벤토리 수정 | VM에서 `nano` | GitHub **PR** |
| 배포 | `ansible-playbook -K` 직접 실행 | **merge하면 자동** |
| sudo 비밀번호 | 매번 `-K` 입력 | GitHub Secret |
| 기록 | 내 터미널 | PR · Actions 로그 |

---

## 실습 기록 상세

### [실습 1] web03 설치
web02와 같은 방식으로 VirtualBox에 새 VM을 만들었습니다. 이름·계정 외에는 **아무것도 설치·설정하지 않았습니다.**

| 항목 | 값 | 이유 |
|---|---|---|
| 어댑터 1 | NAT | 인터넷 (apt 설치) |
| 어댑터 2 | 호스트 전용 어댑터 (web02와 같은 이름) | ubuntu-server가 SSH로 접속할 길 |
| 서버 이름 | `web03` | 페이지에 `host: web03`이 찍히는지 확인 |
| 사용자 | `www` (다른 서버와 같은 비밀번호) | Secret `BECOME_PASSWORD` 하나로 sudo |
| OpenSSH | 설치 | Ansible 원격 접속 |

```bash
ip -br a
# enp0s3  UP  10.0.2.15/24       ← NAT
# enp0s8  UP  192.168.56.104/24  ← Host-only (DHCP)
```

<img width="1236" height="783" alt="image" src="https://github.com/user-attachments/assets/3c93b373-bf27-4c68-b1c5-b2f26c7303ec" />

<img width="1281" height="131" alt="스크린샷 2026-11-10 133542" src="https://github.com/user-attachments/assets/23def936-1317-4ab6-b450-a1a2580697ee" />

### [실습 2] 제어 노드 → web03 SSH 키 등록 (사람이 하는 유일한 서버 작업)
플레이북이 비밀번호 로그인을 막기 때문에 **배포 전에 키를 먼저** 넣어야 합니다. 처음 들어가는 비밀번호는 코드에도 Secret에도 두지 않으므로 이 단계만 사람이 합니다.

```bash
# ubuntu-server (www 계정 = runner 실행 계정)
ssh-keygen -R 192.168.56.104
ssh-copy-id www@192.168.56.104          # web03 비밀번호 1회
ssh -o BatchMode=yes www@192.168.56.104 hostname    # web03 (비밀번호 없이)
```

처음엔 준비해 둔 `scripts/bootstrap-host.sh`로 하려 했지만 [2/4]에서 멈췄습니다 → Troubleshooting 2

<img width="794" height="61" alt="스크린샷 2026-11-10 134249" src="https://github.com/user-attachments/assets/9087deca-7bcc-4266-9afc-8519669ec8e9" />

<img width="1287" height="101" alt="스크린샷 2026-11-10 134803" src="https://github.com/user-attachments/assets/7c362132-9f09-4137-b603-d29713659c32" />

### [실습 3] 인벤토리 한 줄 PR
`main`은 Day 05 Ruleset으로 잠겨 있어 **PR로만** 수정할 수 있습니다. GitHub 웹에서 `inventory.ini` 마지막에 한 줄을 추가하고 새 브랜치 `add-web03`으로 PR을 만들었습니다.

```ini
[web]
localhost ansible_connection=local
web02 ansible_host=192.168.56.102 ansible_user=www
web03 ansible_host=192.168.56.104 ansible_user=www
```

| 순서 | 이벤트 | 결과 |
|---|---|---|
| 1 | CI (`pull_request`, add-web03) | ✅ 3개 통과 |
| 2 | **PR #5 merge** | ✅ |
| 3 | CI (`push`, main) | ✅ |
| 4 | Deploy (`workflow_run`) | ✅ |

Day 03에서 role을 분리해 둔 덕분에 **서버 추가 = 인벤토리 한 줄**로 끝났습니다.

<img width="1234" height="533" alt="스크린샷 2026-11-10 141427" src="https://github.com/user-attachments/assets/fa82728c-9b86-4407-9460-5aebe440c438" />

### [실습 4] 자동 배포 결과 — web03만 바뀜
```
TARGET: all
localhost : ok=18 changed=0  unreachable=0 failed=0
web02     : ok=18 changed=0  unreachable=0 failed=0
web03     : ok=22 changed=15 unreachable=0 failed=0
```

| 서버 | 의미 |
|---|---|
| localhost, web02 | 이미 원하는 상태 → 아무것도 바꾸지 않음 |
| web03 | 빈 서버 → SSH 보안·Nginx·방화벽·백업 **15개 작업 새로 적용** |

- `ok=22`가 18보다 4개 많은 이유: 변경이 생겨 **핸들러 4개**(sshd 검사·재시작, nginx 검사·reload)가 추가로 실행됨
- 같은 플레이북, 같은 한 번의 실행인데 **서버마다 필요한 만큼만** 바꿈 (멱등성)

<img width="834" height="142" alt="스크린샷 2026-11-10 135938" src="https://github.com/user-attachments/assets/1103d586-1b1a-474d-a374-96a5b0b84217" />

### [실습 5] web03 결과 확인
```bash
curl http://192.168.56.104
# <h1>Iac - deployed by GitHub Actions</h1>
# <p>host: web03 / managed by site.yml</p>

ssh -o PubkeyAuthentication=no www@192.168.56.104   # Permission denied (publickey)
```
같은 템플릿이 서버 이름만 다르게 채워 `host: web03`이 출력되고, SSH 비밀번호 로그인 차단까지 적용되었습니다.

<img width="532" height="65" alt="스크린샷 2026-11-10 140113" src="https://github.com/user-attachments/assets/884826e7-9fef-4843-be72-8d4615eef797" />

### [실습 6] 재현성 검증 — 서버 3대 모두 `changed=0`
**Actions → Deploy → Run workflow → `all`**

```
localhost : ok=18 changed=0 unreachable=0 failed=0
web02     : ok=18 changed=0 unreachable=0 failed=0
web03     : ok=18 changed=0 unreachable=0 failed=0
```

| 서버 | 만든 방법 |
|---|---|
| localhost | 06에서 **손으로** 만들고 코드화 |
| web02 | 06에서 **Ansible을 직접 실행**해 구축 |
| web03 | 07에서 **PR 한 줄 + 자동 배포**로 구축 |

만든 방법이 전부 다른 서버 3대가 **같은 코드 기준으로 완전히 같은 상태**임을 확인했습니다.

<img width="1331" height="710" alt="스크린샷 2026-11-10 140518" src="https://github.com/user-attachments/assets/d0575926-1467-4e3b-8455-0653d64ef17c" />

### [실습 7] 마무리 수정 (이 기록과 같은 PR)
| 파일 | 수정 |
|---|---|
| `scripts/bootstrap-host.sh` | 호스트 키를 **한 번만**(`-t ed25519`) 받고, 실패하면 이유를 출력하고 종료 |
| `.github/workflows/deploy.yml` | 수동 실행 대상에 `web03` 추가 → `options: [all, localhost, web02, web03]` |
| `inventory.ini` | Day 06 주석 추가 |

---

## 👀 관찰 포인트 (원리 정리 때 사용)
1. 서버를 추가했는데 **서버에 접속해서 한 일은 키 등록뿐** — 설치·설정은 전부 merge가 일으킴
2. 같은 Deploy 실행에서 **web03만 `changed=15`, 나머지는 0** — 배포 = "명령 실행"이 아니라 "원하는 상태로 맞추기"
3. Actions 목록에서 CI(push), Day01 Hello, Deploy가 **몇 초 차이로** 떠서 순서가 섞여 보임 — 하나의 push가 여러 워크플로를 동시에 깨움
4. PR 단계 CI(`pull_request`)와 merge 후 CI(`push`)가 **두 번** 돎 — 배포는 push 쪽 결과에만 묶여 있음

---

## Troubleshooting (장애 대응 기록)

### 문제 1. `cd: /home/www/linux: No such file or directory`
- **원인**: 명령을 **web03 창**에서 실행. web03은 받기만 하는 빈 서버라 Git 저장소가 없음 (없는 게 정상)
- **해결**: ubuntu-server(1번 VM)에서 실행
- **배운 점**: 프롬프트(`www@ubuntu-server` / `www@web03`)로 **지금 어느 서버인지** 먼저 확인

### 문제 2. `bootstrap-host.sh`가 [2/4]에서 메시지 없이 종료
- **상황 ①**: IP를 `.103`으로 입력 → 해당 IP에 서버가 없어 호스트 키를 못 받음 → `set -e`로 조용히 종료
- **상황 ②**: `.104`로 다시 실행했더니 [3/4]에서 `Connection closed by 192.168.56.104 port 22`, 이후 재실행은 계속 [2/4]에서 종료
- **원인**: 스크립트가 `ssh-keyscan`을 **두 번**(키 등록용 + 지문 출력용) 실행했고, 재시도까지 겹쳐 **로그인 없이 끊는 접속**이 여러 번 쌓임 → 최신 OpenSSH의 **PerSourcePenalties**가 ubuntu-server IP를 일시 차단
- **해결**: web03에서 `sudo systemctl restart ssh`(차단 기록 초기화) → `ssh-copy-id`로 직접 등록
- **재발 방지**: 스크립트를 keyscan 1회 + 실패 이유 출력으로 수정 ([실습 7])
- **배운 점**: `set -e`는 안전장치지만 **실패 이유를 말해주지 않음** → 스크립트는 멈출 때 원인도 출력해야 함

### 문제 3. `curl: (7) Failed to connect to 192.168.56.103`
- **원인**: web03 IP는 `.104`인데 `.103`으로 접속 (안내 문서의 IP가 실제 확인 전 추측값이었음)
- **해결**: `ip -br a`로 확인한 실제 IP `.104`로 접속
- **배운 점**: IP는 **추측하지 말고 서버에서 확인한 값**만 사용

---

## 프로젝트 정리 (07 Day 01 ~ 06)

| Day | 한 일 | 결과물 |
|---|---|---|
| 01 | GitHub Actions 기초 (이벤트, job, step, needs) | `day01-hello.yml` |
| 02 | CI — yamllint · ansible-lint · shellcheck 자동 검사 | `ci.yml` |
| 03 | 배포하기 쉬운 구조로 role 분리 | `roles/`, `site.yml`, `group_vars/` |
| 04 | CD — self-hosted runner, Secret, CI 성공 시 자동 배포 | `deploy.yml` |
| 05 | PR 흐름 — main 잠금, CI 통과해야 merge | Ruleset `protect-main` |
| 06 | 새 서버를 PR 한 줄로 추가, 3대 `changed=0` | web03, `bootstrap-host.sh` |

**배운 점**
- 서버를 바꾸고 싶으면 서버가 아니라 **Git을 바꾼다** (GitOps)
- CI는 "틀린 코드가 들어오지 못하게", CD는 "들어온 코드가 서버에 반영되게" — 둘을 이어 **사람 손이 빠질수록** 실수와 서버 간 차이가 줄어듦
- 처음 접속 열쇠(SSH 키)처럼 **자동화가 시작되기 위한 한 번**은 사람이 해야 하고, 그 이후를 전부 코드로 만드는 것이 목표

---

## 🇯🇵 오늘의 일본어 엔지니어링
- **단어 1:** **スケールアウト (스케-루아우토)** - 스케일 아웃, 서버 대수를 늘려 확장 (Scale-out)
- **단어 2:** **再現性 (さいげんせい, 사이겐세-)** - 재현성 (Reproducibility)
- **단어 3:** **公開鍵 (こうかいかぎ, 코-카이카기)** - 공개키 (Public key)
