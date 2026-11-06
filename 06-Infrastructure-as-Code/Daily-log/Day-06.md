# Day 06. 새 서버 재구축 검증 — 플레이북으로 서버 찍어내기 (2026-11-06)

## 오늘의 목표
- 아무 설정도 하지 않은 **새 서버(web02)** 를 만들고, Ansible 플레이북 한 번으로 기존 서버와 **같은 상태**로 만들기
- 자기 자신(`localhost`)만 관리하던 구조에서 **SSH로 다른 서버를 원격 관리**하는 구조로 확장하기
- 두 서버에 플레이북을 다시 실행해 **둘 다 `changed=0`** 인지 확인해 재현성 증명하기

---

## 실습 환경
```
노트북 (PowerShell)
  │ SSH 127.0.0.1:2222
  ▼
ubuntu-server  192.168.56.101   ← 제어 노드 (Ansible 실행)
  │ SSH 키 접속 (Host-only 네트워크)
  ▼
web02          192.168.56.102   ← 관리 대상 (새로 설치, 손으로 설정하지 않음)
```

| 항목 | 내용 |
|---|---|
| 네트워크 | VirtualBox 어댑터 1 NAT(인터넷) + 어댑터 2 Host-only(`192.168.56.0/24`, DHCP) |
| 플레이북 | [`day4-ansible/playbook.yml`](../day4-ansible/playbook.yml) (Day 04~05와 동일, 수정 없음) |
| 절차서 | [`day6-rebuild/README.md`](../day6-rebuild/README.md) |

| | Day 04~05 | Day 06 |
|---|---|---|
| 관리 대상 | 자기 자신 (`ansible_connection=local`) | 다른 서버 (SSH) |
| 의미 | 손으로 만든 서버를 코드로 정의 | **코드만으로 같은 서버를 몇 대든 재현** |

---

## 실습 기록 상세

### [실습 1] VM 간 통신용 Host-only 네트워크
NAT는 VM마다 격리되어 VM끼리 통신할 수 없어서, VirtualBox의 Host-only 네트워크(`192.168.56.1/24`, DHCP 사용)를 두 번째 어댑터로 추가했습니다.

- 기존 서버에 어댑터 2를 추가하자 `enp0s8`이 부팅 시 자동으로 `192.168.56.101`을 받음 (별도 netplan 설정 불필요)

```bash
ip -br a
# enp0s3  UP  10.0.2.15/24       ← NAT
# enp0s8  UP  192.168.56.101/24  ← Host-only
```

<!-- 📸 VirtualBox 호스트 전용 네트워크 (192.168.56.1/24, DHCP 사용함) -->
<!-- 📸 ubuntu-server ip -br a -->

### [실습 2] 새 서버 web02 설치
설치 전에 어댑터 2를 켜두어 설치 프로그램이 두 랜카드를 모두 DHCP로 잡도록 했습니다. 플레이북과 맞추기 위해 사용자 이름은 `www`, 서버 이름은 `web02`로 지정했고, 그 외에는 **아무 설정도 하지 않았습니다.**

| 설치 항목 | 값 | 이유 |
|---|---|---|
| 서버 이름 | `web02` | 페이지 템플릿에 서버 이름이 들어가는지 확인용 |
| 사용자 | `www` | 플레이북의 폴더 소유자(`web_owner`) |
| OpenSSH | 설치 | Ansible 원격 접속 |

```bash
ip -br a     # enp0s8  192.168.56.102/24
```

<!-- 📸 web02 ip -br a -->

### [실습 3] 제어 노드 → web02 SSH 키 등록
플레이북이 web02의 비밀번호 로그인을 막기 때문에, **적용 전에 키를 먼저** 등록했습니다. Day 01은 노트북 → 서버였고, 이번엔 서버 → 서버입니다.

```bash
ssh-keygen -t ed25519 -C "ansible@ubuntu-server"
ssh-copy-id www@192.168.56.102
ssh www@192.168.56.102 hostname      # web02 (비밀번호 없이)
```

<!-- 📸 ssh-keygen / ssh-copy-id / hostname -->

### [실습 4] 인벤토리 확장
```ini
[web]
localhost ansible_connection=local
web02 ansible_host=192.168.56.102 ansible_user=www
```

```bash
ansible web -m ping     # localhost, web02 모두 pong
```
`web02`는 `ansible_connection`이 없으므로 기본값인 SSH로 접속하며, 대상 서버의 파이썬(`/usr/bin/python3.14`)을 자동으로 찾았습니다.

<!-- 📸 ansible web -m ping -->

### [실습 5] 플레이북으로 web02 찍어내기
```bash
ansible-playbook playbook.yml -K --limit web02
```
- `--limit web02`로 새 서버에만 적용
- 빈 서버에는 `--check`를 쓰지 않음 — "Nginx 설치 → Nginx 실행"처럼 앞 단계 결과에 기대는 태스크는 드라이런으로 예측할 수 없기 때문
- 한 번 더 실행했을 때 `web02 : ok=17 changed=0 failed=0`

<!-- 📸 web02 첫 적용 PLAY RECAP -->
<!-- 📸 web02 재실행 PLAY RECAP (changed=0) -->

### [실습 6] web02 결과 확인
```bash
curl http://192.168.56.102
# <h1>Iac - built by Ansible</h1>
# <p>host: web02 / managed by playbook.yml</p>

ssh -o PubkeyAuthentication=no www@192.168.56.102   # Permission denied (publickey)
ansible web02 -b -K -m command -a "ufw status"      # OpenSSH LIMIT / Nginx HTTP ALLOW
```
같은 템플릿이 서버마다 이름을 다르게 채워 넣어, web02에서는 `host: web02`가 출력됩니다. Day 01의 SSH 보안 설정과 Day 02의 방화벽도 그대로 적용되었습니다.

<!-- 📸 curl / Permission denied / ufw status -->
<!-- 📸 노트북 브라우저 http://192.168.56.102 -->

### [실습 7] 두 서버 동시 실행 — 재현성 검증
```bash
ansible-playbook playbook.yml -K
```
```
localhost : ok=17 changed=0 unreachable=0 failed=0
web02     : ok=17 changed=0 unreachable=0 failed=0
```
**손으로 만들고 코드화한 서버(localhost)** 와 **코드만으로 만든 서버(web02)** 가 같은 플레이북 기준으로 완전히 같은 상태임을 확인했습니다.

<!-- 📸 두 서버 PLAY RECAP -->

---

## Troubleshooting (장애 대응 기록)

### 문제 1. 인벤토리 파싱 실패
- **상황**: `Failed to parse inventory: Expected key=value host variable assignment, got: ansible_connection`
- **원인**: 편집 중 `ansible_connection=local`에서 `=local`이 떨어져 나감. 인벤토리 변수는 `이름=값`이 한 덩어리여야 함
- **해결**: 파일 전체를 `printf`로 다시 작성 후 `cat`으로 확인

### 문제 2. `connection plugin 'localX' was not found`
- **상황**: web02는 `pong`, localhost만 실패
- **원인**: `local` 뒤에 `X`가 붙어 존재하지 않는 접속 방식으로 인식
- **해결**: `sed -i 's/localX/local/' inventory.ini`
- **배운 점**: 같은 인벤토리 안에서도 호스트별로 성공/실패가 갈리므로, 결과를 호스트 단위로 읽어야 함

### 문제 3. `ssh-copy-id` 대상 오류
- **상황**: `Could not resolve hostname 192.168.56.y` / `Too many arguments`
- **원인**: 안내 문서의 자리표시(`y`)를 그대로 입력, 확인용 명령(`hostname`)을 같은 줄에 붙임
- **해결**: 실제 IP(`192.168.56.102`)로, `ssh-copy-id`와 `ssh ... hostname`을 따로 실행

---

## 프로젝트 정리 (Day 01 ~ 06)

| Day | 한 일 | 결과물 |
|---|---|---|
| 01 | SSH 키 인증, 비밀번호·root 로그인 차단 | `10-hardening.conf` |
| 02 | Nginx·UFW 수동 구성, 절차 기록 | `lab`, `manual-steps.md` |
| 03 | systemd timer 백업, 복구 훈련 | `lab-backup.sh/.service/.timer` |
| 04 | 위 구성을 Ansible 플레이북으로 코드화 | `playbook.yml` |
| 05 | 드리프트 생성 → 탐지 → 복구, Ansible의 한계 확인 | `break-server.sh` |
| 06 | 새 서버를 플레이북으로 재구축, 두 서버 `changed=0` | 재구축 절차서 |

**배운 점**
- 서버 설정은 **사람의 기억이 아니라 코드(Git)** 에 남겨야 같은 서버를 언제든 다시 만들 수 있음
- 선언형 도구는 "어떤 상태여야 하는가"를 적기 때문에 여러 번 실행해도 안전함 (멱등성)
- 단, 코드에 **적지 않은 것은 지켜주지 않음** → 서버를 손으로 고치지 않는 운영 습관이 함께 필요함

---

## 핵심 명령어 요약
- **`ip -br a`**: 랜카드별 IP 요약
- **`ssh-copy-id user@host`**: 공개키를 대상 서버 `authorized_keys`에 등록
- **`ansible web -m ping`**: 인벤토리 전체 접속 확인
- **`ansible-playbook <파일> -K --limit <호스트>`**: 특정 호스트에만 적용
- **`ansible <호스트> -b -K -m command -a "<명령>"`**: 원격 서버에 sudo 명령 하나 실행

---

## 🇯🇵 오늘의 일본어 엔지니어링
- **단어 1:** **再現性 (さいげんせい, 사이겐세-)** - 재현성 (Reproducibility)
- **단어 2:** **管理対象 (かんりたいしょう, 칸리타이쇼-)** - 관리 대상 (Managed node)
- **단어 3:** **構築手順 (こうちくてじゅん, 코-치쿠테쥰)** - 구축 절차 (Build procedure)
