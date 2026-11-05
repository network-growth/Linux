# Day 04. Ansible로 서버 구성 코드화 (2026-11-05)

## 오늘의 목표
- Day 01~03에서 손으로 만든 서버 구성(SSH 보안, Nginx, UFW, systemd 백업)을 **Ansible 플레이북 하나로 정의**하기
- 적용 전에 `--check --diff`로 **코드와 실제 서버의 차이(드리프트)** 를 미리 확인하기
- 같은 플레이북을 다시 실행했을 때 아무것도 바뀌지 않는 **멱등성** 확인하기

---

## 실습 환경
| 항목 | 내용 |
|---|---|
| 서버 | Ubuntu Server 26.04 LTS (VirtualBox, NAT) |
| 제어 노드 | 같은 VM (`ansible_connection=local`) — 회사 노트북에는 Ansible 설치 불가 |
| 결과물 | [`day4-ansible/`](../day4-ansible) — `playbook.yml`, `inventory.ini`, `ansible.cfg`, `templates/index.html.j2` |

### 명령형 vs 선언형
| | 셸 스크립트 (명령형) | Ansible (선언형) |
|---|---|---|
| 적는 방식 | "nginx를 설치해라" | "nginx가 설치되어 있어야 한다" |
| 이미 그 상태면 | 다시 실행 | 아무것도 하지 않음 |
| 여러 번 실행 | 결과 보장 어려움 | 항상 같은 결과 (멱등성) |

---

## 실습 기록 상세

### [실습 1] Ansible 설치
`ufw` 모듈이 `community.general` 컬렉션에 있어서, 본체만 있는 `ansible-core`가 아니라 컬렉션까지 포함된 `ansible` 패키지를 설치했습니다.

```bash
sudo apt install -y ansible
ansible --version
ansible-galaxy collection list community.general
```

<img width="941" height="165" alt="image" src="https://github.com/user-attachments/assets/e2efa292-3e04-416a-ab15-06fde5402b63" />

### [실습 2] 인벤토리와 연결 확인
```ini
# inventory.ini
[web]
localhost ansible_connection=local
```

```bash
ansible-inventory --graph
ansible web -m ping        # localhost | SUCCESS => "ping": "pong"
```

<img width="733" height="128" alt="image" src="https://github.com/user-attachments/assets/363570d4-1cb9-4db1-9d52-85f06ea09ff7" />

### [실습 3] 플레이북 구조
Day 01~03 폴더의 설정 파일을 그대로 가져다 쓰도록 작성해, **설정 원본은 한 곳**에만 두었습니다.

| 구간 | 태스크 | 사용 모듈 | 원본 |
|---|---|---|---|
| SSH | 보안 설정 배치 | `copy` | Day 01 `10-hardening.conf` |
| Nginx | 패키지 / 사이트 폴더 / 페이지 / 사이트 설정 / default 끄기 / lab 켜기 / 실행 | `apt`, `file`, `template`, `copy`, `systemd_service` | Day 02 `lab` |
| UFW | 기본 정책 2개 → SSH limit → HTTP allow → enable | `community.general.ufw` | Day 02 |
| 백업 | 스크립트 / service·timer / 타이머 켜기 | `copy`, `systemd_service` | Day 03 |

**핸들러**: 설정이 바뀌었을 때만 실행되며, 같은 이름(`listen`)으로 묶어 **검사 → 반영** 순서로 동작하게 했습니다. Day 01~02에서 손으로 하던 `sshd -t && restart`, `nginx -t && reload`를 코드로 옮긴 것입니다.

```yaml
handlers:
  - name: check nginx
    ansible.builtin.command: nginx -t
    changed_when: false
    listen: reload nginx

  - name: reload nginx service
    ansible.builtin.systemd_service:
      name: nginx
      state: reloaded
    listen: reload nginx
```

```bash
ansible-playbook playbook.yml --syntax-check
ansible-playbook playbook.yml --list-tasks     # 태스크 16개
```

<img width="1021" height="421" alt="image" src="https://github.com/user-attachments/assets/0a31817c-48d7-49af-aabc-af4148cfe597" />

### [실습 4] 드라이런으로 드리프트 확인
```bash
ansible-playbook playbook.yml -K --check --diff
```
- 결과: `ok=19 changed=5 failed=0`
- 바뀔 예정으로 나온 항목: SSH 설정(저장소 파일에 주석 추가됨), Nginx 사이트 설정(주석 추가됨), 웹 페이지(`manual setup` → `built by Ansible`) 등
- 손으로 만든 서버와 Git의 코드가 **어디가 다른지 실제로 바꾸기 전에** 줄 단위로 확인할 수 있었음
- 드라이런에서는 `command` 모듈이 실행되지 않아 `check sshd`, `check nginx` 핸들러가 `skipping`으로 표시됨

<img width="1105" height="575" alt="image" src="https://github.com/user-attachments/assets/2c77ab34-5440-4dee-b88c-8d7f475e92ce" />

### [실습 5] 실제 적용
```bash
ansible-playbook playbook.yml -K
curl localhost
```
페이지가 템플릿으로 생성되어 서버 이름이 자동으로 채워진 것을 확인했습니다.

```html
<h1>Iac - built by Ansible</h1>
<p>host: ubuntu-server / managed by playbook.yml</p>
```

| | Day 02 | Day 04 |
|---|---|---|
| 페이지 | `Iac - manual setup` | `Iac - built by Ansible` |
| 만든 방법 | `printf`로 직접 작성 | `template` 모듈 + 변수 |

<img width="1108" height="575" alt="스크린샷 2026-11-05 110821" src="https://github.com/user-attachments/assets/4ce452f8-ce18-409a-a078-d7a25821c651" />

<img width="1916" height="936" alt="스크린샷 2026-11-05 110622" src="https://github.com/user-attachments/assets/f3c57e1b-3a45-46d7-9932-abb225417166" />

### [실습 6] 멱등성 확인
같은 플레이북을 한 번 더 실행해, 서버가 이미 코드와 같은 상태이므로 **아무것도 바뀌지 않는 것**(`changed=0`)을 확인했습니다. 바뀐 것이 없으니 핸들러도 실행되지 않습니다.

```bash
ansible-playbook playbook.yml -K   # changed=0 failed=0
```

<img width="1105" height="575" alt="스크린샷 2026-11-05 111611" src="https://github.com/user-attachments/assets/a6d95c8a-acf6-4b52-850a-b50f005eded7" />

---

## Troubleshooting (장애 대응 기록)

### 문제 1. become 비밀번호 프롬프트 대기 시간 초과
- **상황**: `ansible-playbook -K` 실행 시 `Timed out waiting for become success or become password prompt` → `unreachable=1`
- **원인**: Ubuntu 26.04는 기본 `sudo`가 Rust로 새로 작성된 **sudo-rs**로 바뀜. Ansible은 자신이 지정한 비밀번호 프롬프트 문구를 보고 비밀번호를 입력하는데, sudo-rs가 그 문구를 `[sudo: [sudo via ansible, key=...] password:] Password:`처럼 감싸서 출력해 Ansible이 프롬프트를 인식하지 못함
- **확인**
  ```bash
  sudo --version | head -1   # sudo-rs 0.2.13
  ls -l /usr/bin/sudo.ws     # 기존 sudo도 함께 설치되어 있음
  ```
- **해결**: 시스템 기본 sudo는 그대로 두고 **Ansible만** 기존 sudo를 쓰도록 `ansible.cfg`에 지정
  ```ini
  [privilege_escalation]
  become_exe = sudo.ws
  ```
- **배운 점**: OS의 기본 도구가 바뀌면 그 도구를 감싸서 쓰는 자동화 도구가 영향을 받을 수 있음. 바꿀 범위를 최소로(이 프로젝트의 설정 파일에만) 두는 것이 안전함
  
<img width="1334" height="315" alt="스크린샷 2026-11-05 105636" src="https://github.com/user-attachments/assets/c10bcd31-3e9a-430c-9e93-e62f269d9bb4" />

<img width="877" height="41" alt="image" src="https://github.com/user-attachments/assets/78d02a52-96d0-4918-bb32-eb92d5ff9f01" />

### 문제 2. `Duplicate become password prompt` / `Sorry, try again`
- **상황**: VirtualBox 콘솔 창에서 실행 시 sudo가 비밀번호를 다시 묻고 Ansible이 실패 처리
- **원인**: `BECOME password`에 비밀번호가 잘못 입력됨. VM 콘솔은 노트북과 한/영·키보드 상태가 다르게 잡힐 수 있음. 같은 명령을 SSH 창에서 실행하면 정상 동작
- **해결**: 작업은 노트북 터미널의 SSH 접속 창에서만 진행 (한글 출력도 정상)

### 문제 3. VM 콘솔에서 한글 주석·태스크 이름이 깨짐
- **원인**: 리눅스 텍스트 콘솔에는 한글 폰트가 없음 (파일 내용은 정상)
- **해결**: SSH 접속 창에서 확인·캡처

### 문제 4. `Unable to locate package anisble`
- **원인**: 패키지 이름 오타 (`anisble` → `ansible`)

---

## 핵심 명령어 요약
- **`ansible-inventory --graph`**: 관리 대상 서버 목록 확인
- **`ansible <그룹> -m ping`**: Ansible이 대상 서버에서 작업할 수 있는지 확인
- **`ansible-playbook <파일> --syntax-check`**: 문법 검사
- **`ansible-playbook <파일> --list-tasks`**: 실행될 태스크 목록
- **`ansible-playbook <파일> -K --check --diff`**: 실제 변경 없이 바뀔 내용만 미리보기
- **`ansible-playbook <파일> -K`**: 실제 적용 (`-K`: sudo 비밀번호 입력)
- **`become_exe`**: Ansible이 권한 상승에 쓸 실행 파일 지정
