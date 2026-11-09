# Day 03. 배포하기 쉬운 구조로 — role 분리 (2026-11-09)

## 오늘의 목표
- 플레이북 한 덩어리를 **역할(role) 4개**로 나눠, 서버가 늘거나 일부만 다를 때 **고칠 곳이 한 곳**이 되게 하기
- 값(group_vars)·작업(roles)·조합(site.yml)을 분리하기
- 구조를 바꿔도 **CI 통과 + 서버 결과 동일(`changed=0`)** 인지 검증하기

---

## 실습 환경
| 항목 | 내용 |
|---|---|
| 코드 | [`07-Infra-CICD/ansible/`](../ansible) |
| 검증 | GitHub Actions CI + ubuntu-server에서 `ansible-playbook` 실행 |
| 대상 | `localhost`(ubuntu-server), `web02` |

---

## 실습 기록 상세

### [실습 1] 기존 구조의 문제
| 문제 | 실제로 생기는 일 |
|---|---|
| 한 파일에 작업·값·순서가 섞임 | 150줄 파일에서 원하는 부분을 찾아 스크롤 |
| 부품을 따로 못 씀 | 일부만 필요한 서버가 생기면 파일을 복사해 잘라야 함 → 원본이 둘이 되어 어긋남 |
| 값이 코드에 박힘 | 서버마다 값을 다르게 하려면 플레이북 자체를 수정 |
| 파일 경로가 저장소 구조에 묶임 | `{{ repo_root }}/day1-ssh-hardening/...` → 폴더 이동 시 전부 수정 (06 → 07로 옮길 때 실제로 발생) |

### [실습 2] 새 구조
```
07-Infra-CICD/ansible/
├── site.yml              # 어떤 서버에 어떤 role을 어떤 순서로
├── group_vars/web.yml    # web 그룹 공통 값
├── inventory.ini
└── roles/
    ├── ssh_hardening/  tasks/ handlers/ files/(10-hardening.conf)
    ├── nginx_site/     tasks/ handlers/ files/(lab) templates/(index.html.j2) defaults/
    ├── firewall/       tasks/
    └── backup/         tasks/ files/(lab-backup.sh/.service/.timer)
```

```yaml
# site.yml
- name: Lab web server
  hosts: web
  become: true
  roles:
    - ssh_hardening
    - nginx_site
    - firewall
    - backup
```

| 질문 | 06 (한 파일) | 07 (roles) |
|---|---|---|
| 무엇을 하나 | 플레이북 `tasks:` | `roles/*/tasks/main.yml` |
| 어떤 값으로 | 플레이북 `vars:` | `group_vars` / `host_vars` / `defaults` |
| 어디에, 어떤 순서로 | 플레이북 | `site.yml` + `inventory.ini` |

### [실습 3] role 설계에서 신경 쓴 점
| 변경 | 이유 |
|---|---|
| `src: 10-hardening.conf`처럼 **파일 이름만** | role 안 `files/`·`templates/`를 Ansible이 자동으로 찾음 → role을 통째로 옮겨도 동작 |
| `apt: [nginx, ufw]` → nginx는 `nginx_site`, ufw는 `firewall`에서 설치 | 각 role이 자기가 쓰는 프로그램을 스스로 설치해야 **따로 떼어 써도** 동작 |
| 핸들러를 각 role 안으로 | 호출하는 태스크와 같은 폴더에 있어 추적이 쉬움 |
| 변수 이름 `web_root` → `nginx_site_root` | role이 늘면 같은 이름끼리 덮어쓰는 사고 방지 (ansible-lint `var-naming` 관례) |
| `nginx_site` → `firewall` 순서 | `ufw allow 'Nginx HTTP'`의 앱 프로필은 Nginx 설치 후 생김 |

**변수 우선순위 (약한 → 강한)**
| 위치 | 용도 |
|---|---|
| `roles/nginx_site/defaults/main.yml` | role 혼자서도 동작하게 하는 기본값 |
| `group_vars/web.yml` | 그룹 공통 값 |
| `host_vars/<호스트>.yml` | 특정 서버만 다르게 (role 코드 수정 없이) |
| `-e` | 실행 시 일회성 |

| 하고 싶은 일 | 고칠 곳 |
|---|---|
| 새 웹 서버 추가 | `inventory.ini` 한 줄 |
| 한 서버만 값 다르게 | `host_vars/<서버>.yml` |
| Nginx 설정 수정 | `roles/nginx_site/` |
| 다른 종류의 서버 (DB 등) | `site.yml`에 role 조합 추가 |

### [실습 4] CI 검증
CI 경로도 함께 수정했습니다 (`playbook.yml` → `site.yml`, `files/*.sh` → `roles/*/files/*.sh`, ansible-lint는 폴더 전체 검사).

- 결과: **yamllint ✅ / ansible-lint ✅ / shellcheck ✅** (첫 실행에 통과)

<!-- 📸 CI (ci site.yml) 셋 다 초록 -->

### [실습 5] 서버 결과 비교
```bash
git -C ~/linux pull
cd ~/linux/07-Infra-CICD/ansible
ansible-playbook site.yml -K --check --diff
ansible-playbook site.yml -K
ansible-playbook site.yml -K
```
- 드라이런에서 `백업 스크립트`만 변경 예정으로 표시 → Day 02에서 shellcheck 때문에 `ls`를 `find`로 고친 수정이 아직 서버에 반영되지 않았기 때문
- 적용 후 재실행에서 두 서버 모두 `changed=0`
- **코드 구조를 통째로 바꿨지만 서버 상태는 그대로**임을 확인

<!-- 📸 --check --diff (백업 스크립트 diff) -->
<!-- 📸 재실행 changed=0 (localhost, web02) -->

---

## 👀 관찰 포인트 (원리 정리 때 사용)
1. 구조를 크게 바꿨는데 CI와 실행 결과가 모두 그대로 — **구조(코드 정리)와 결과(서버 상태)는 별개**
2. Day 02 수정이 Day 03 실행에서 처음 서버에 들어감 — 코드가 바뀌어도 **누군가 실행하기 전까지 서버는 그대로**

---

## Troubleshooting (장애 대응 기록)

### 문제 1. `cd: ~/linux/07-Infra-CICD/ansible: No such file or directory`
- **원인**: VM의 저장소 복사본이 오래된 상태 (07 폴더가 생기기 전)
- **해결**: `git pull`로 최신화

### 문제 2. `git pull` 실패 — `Your local changes ... would be overwritten by merge`
- **상황**: `06-.../inventory.ini`를 06 Day 06에 VM에서 `nano`로 직접 수정해 두었고, 같은 내용이 GitHub에도 커밋되어 있었음
- **원인**: 커밋하지 않은 로컬 수정이 들어올 변경과 겹침
- **해결**: `git restore <파일>`로 VM 쪽 수정을 버리고 `git pull`
- **배운 점**: 서버에서 직접 고친 파일은 Git과 어긋남 → **코드는 GitHub에서만 고치고, 서버는 받기만** (GitOps 원칙)

### 문제 3. `web02: UNREACHABLE — No route to host`
- **원인**: 노트북을 새로 켜면서 web02 VM이 꺼져 있었음
- **해결**: web02 VM 시작 후 재실행
- **참고**: 한 서버가 연결 안 돼도 나머지 서버(`localhost`)는 계속 진행됨

---

## 🇯🇵 오늘의 일본어 엔지니어링
- **단어 1:** **リファクタリング (리화쿠타린구)** - 리팩터링, 동작은 그대로 두고 구조 개선 (Refactoring)
- **단어 2:** **再利用 (さいりよう, 사이리요-)** - 재사용 (Reuse)
- **단어 3:** **変数 (へんすう, 헨스-)** - 변수 (Variable)
