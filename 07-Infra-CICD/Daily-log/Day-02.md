# Day 02. CI — push할 때마다 자동 코드 검사 (2026-11-09)

## 오늘의 목표
- 06에서 만든 Ansible 코드를 07 폴더로 옮겨 CI 검사 대상으로 만들기
- GitHub Actions로 **yamllint · ansible-lint · shellcheck** 를 push/PR마다 자동 실행하기
- CI가 잡아낸 문제를 로그로 읽고 고쳐서 **전부 통과**시키기

---

## 실습 환경
| 항목 | 내용 |
|---|---|
| 작업 위치 | GitHub 웹 (브라우저) |
| 워크플로 | [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) |
| 검사 대상 | [`07-Infra-CICD/ansible/`](../ansible) |

```
07-Infra-CICD/ansible/
├── playbook.yml        # 06 Day 04 플레이북 (파일 경로만 이 폴더 기준으로 변경)
├── ansible.cfg / inventory.ini
├── requirements.yml    # 필요한 컬렉션 (community.general)
├── .yamllint           # YAML 작성 규칙
├── .ansible-lint       # ansible-lint 설정
├── files/              # 10-hardening.conf, lab, lab-backup.sh/.service/.timer
└── templates/          # index.html.j2
```

---

## 실습 기록 상세

### [실습 1] CI 워크플로 작성
```yaml
name: CI

on:
  push:
    branches: [main]
    paths:
      - "07-Infra-CICD/**"
      - ".github/workflows/ci.yml"
  pull_request:
    paths:
      - "07-Infra-CICD/**"
      - ".github/workflows/ci.yml"
  workflow_dispatch:

defaults:
  run:
    working-directory: 07-Infra-CICD/ansible

jobs:
  yamllint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - name: yamllint 설치
        run: pipx install yamllint
      - name: YAML 검사
        run: yamllint .

  ansible-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - name: ansible-lint 설치
        run: pipx install --include-deps ansible-lint
      - name: 컬렉션 설치
        run: ansible-galaxy collection install -r requirements.yml
      - name: 플레이북 문법 검사
        run: ansible-playbook playbook.yml --syntax-check
      - name: Ansible 규칙 검사
        run: ansible-lint playbook.yml

  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - name: shellcheck 설치
        run: sudo apt-get update && sudo apt-get install -y shellcheck
      - name: 셸 스크립트 검사
        run: shellcheck files/*.sh
```

| 검사기 | 잡는 것 |
|---|---|
| yamllint | YAML 문법·모양 (들여쓰기, 줄 길이, 빈 줄) |
| ansible-lint | Ansible 작성 규칙 (이름 규칙, 권장 모듈 등) + 문법 |
| shellcheck | 셸 스크립트의 실수·위험한 패턴 |

- job 3개에 `needs`가 없어 **동시에** 실행됨 (Day 01은 `needs`로 순서가 있었음)
- `pull_request` 트리거를 미리 넣어 Day 05의 PR 검사에 사용
- `defaults.run.working-directory`로 모든 `run`을 `07-Infra-CICD/ansible`에서 실행

### [실습 2] 첫 실행 — CI가 잡아낸 것
| job | 결과 | 잡은 것 |
|---|---|---|
| yamllint | ✅ | — |
| ansible-lint | ❌ | `couldn't resolve module/action 'community.general.ufw'` + `.yamllint` 설정 비호환 경고 |
| shellcheck | ❌ | `SC2012: Use find instead of ls` (`lab-backup.sh` 23행) |

<img width="600" height="252" alt="스크린샷 2026-11-09 112624" src="https://github.com/user-attachments/assets/32c3c3ed-7d40-45ec-a1a0-451a63fd6da7" />

<img width="1294" height="643" alt="스크린샷 2026-11-09 112641" src="https://github.com/user-attachments/assets/cce5a0af-b462-4e32-8802-2a5b89c7df8b" />

<img width="713" height="226" alt="스크린샷 2026-11-09 112649" src="https://github.com/user-attachments/assets/49e1dd40-56fa-4d03-9cc3-a2191eb94818" />

같은 job 안에서 **`플레이북 문법 검사` step은 통과했는데 `ansible-lint`만 컬렉션을 못 찾은** 것이 특징이었습니다.

### [실습 3] 1차 수정
**① shellcheck SC2012** — 백업 정리 부분이 `ls` 출력을 파싱해 파일을 지우고 있었음. `ls`는 출력 형식이 사람을 위한 것이라 파일 이름을 안전하게 다루지 못함

```bash
# 수정 전
ls -1t "$BACKUP_DIR"/lab-*.tar.gz | tail -n +$((KEEP + 1)) | xargs -r rm --

# 수정 후: 수정 시각과 경로를 함께 뽑아 정렬
find "$BACKUP_DIR" -maxdepth 1 -name 'lab-*.tar.gz' -printf '%T@ %p\n' \
    | sort -rn \
    | tail -n +$((KEEP + 1)) \
    | cut -d' ' -f2- \
    | xargs -r rm --
```
"최근 7개만 남기기" 동작은 그대로 유지됨 (06 폴더 원본은 기록용으로 그대로 둠)

**② ansible-lint 컬렉션 인식 실패** — ansible-lint는 프로젝트 기준 폴더를 **Git 저장소 최상위(`Linux/`)** 로 잡고 거기서 `requirements.yml`을 찾음. 파일은 `07-Infra-CICD/ansible/`에 있어 찾지 못함
- 해결: `07-Infra-CICD/ansible/.ansible-lint` 설정 파일 추가 → 설정 파일이 있는 폴더가 프로젝트 기준이 되어 `requirements.yml`을 인식

**③ `.yamllint` 비호환 경고** — ansible-lint가 요구하는 yamllint 규칙(comments, comments-indentation, braces, octal-values)을 `.yamllint`에 추가

### [실습 4] 2차 — 진짜 작성 규칙 위반
컬렉션 문제가 풀리자 ansible-lint가 실제 작성 규칙을 검사하기 시작했습니다.

```
name[casing]: All names should start with an uppercase letter.
playbook.yml:130 Task/Handler: check sshd
playbook.yml:135 Task/Handler: restart sshd service
playbook.yml:141 Task/Handler: check nginx
playbook.yml:146 Task/Handler: reload nginx service
Rating: 1/5 star (Last profile that met the validation criteria was 'basic')
```
- 한글 태스크 이름은 대소문자가 없어 통과, **영어 소문자로 시작하는 핸들러 이름 4개**만 걸림
- 직접 웹에서 첫 글자를 대문자로 수정 (`Check sshd`, `Restart sshd service`, `Check nginx`, `Reload nginx service`)
- `listen: restart ssh`, `listen: reload nginx`는 태스크의 `notify`와 짝을 맞추는 **신호 이름**이라 그대로 둠

<img width="1352" height="721" alt="스크린샷 2026-11-09 113147" src="https://github.com/user-attachments/assets/1f6baf0e-0d4f-4277-914a-96b914638629" />

### [실습 5] 전부 통과
커밋(`fix name casing`)과 동시에 CI가 자동 실행되어 **yamllint ✅ / ansible-lint ✅ / shellcheck ✅**

<img width="814" height="311" alt="스크린샷 2026-11-09 113815" src="https://github.com/user-attachments/assets/559cbac3-eec4-49a5-a9ff-a66810335dbb" />

---

## 👀 관찰 포인트 (원리 정리 때 사용)
1. job 3개의 **시작 시간이 거의 같았는지** (동시 실행)
2. job마다 **`checkout`과 도구 설치를 각각 따로** 했는지
3. 같은 job 안에서 **문법 검사는 통과, lint는 실패**했던 이유 (도구마다 보는 기준 위치가 다름)
4. 내가 고친 커밋에 **아무도 시키지 않았는데** CI가 붙어서 돌았다는 것

---

## Troubleshooting (장애 대응 기록)

| 문제 | 원인 | 해결 |
|---|---|---|
| `couldn't resolve module 'community.general.ufw'` (ansible-lint만) | ansible-lint의 프로젝트 기준 폴더가 저장소 최상위라 하위 폴더의 `requirements.yml`을 못 찾음 | 하위 폴더에 `.ansible-lint` 추가 |
| `incompatible custom yamllint configuration` | 직접 만든 `.yamllint`가 ansible-lint 요구 규칙과 다름 | 요구 규칙 4개 추가 |
| `SC2012` | `ls` 출력 파싱 | `find -printf` + `sort`로 교체 |
| `name[casing]` | 핸들러 이름이 소문자로 시작 | 첫 글자 대문자 |

---

## 핵심 정리
- CI = **코드가 바뀔 때마다 사람 대신 검사기가 자동으로 확인**하는 장치
- 검사기는 문제를 **줄 번호와 규칙 이름**으로 알려줌 → 로그를 읽는 것이 고치는 것의 절반
- 동작에 영향 없는 스타일 규칙(`name[casing]`)도 CI로 강제하면 팀 전체 코드 모양이 통일됨

---

## 🇯🇵 오늘의 일본어 엔지니어링
- **단어 1:** **静的解析 (せいてきかいせき, 세-테키카이세키)** - 정적 분석 (Static analysis)
- **단어 2:** **継続的インテグレーション (けいぞくてき, 케-조쿠테키 인테구레-숀)** - 지속적 통합 (CI)
- **단어 3:** **指摘 (してき, 시테키)** - 지적, 리뷰에서 문제를 짚음 (Finding)
