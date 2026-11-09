# Day 04. CD — CI 통과하면 내 VM에 자동 배포 (2026-11-09)

## 오늘의 목표
- ubuntu-server에 **GitHub Actions self-hosted runner**를 설치해, GitHub의 작업을 내 VM이 받아 실행하게 하기
- sudo 비밀번호를 **GitHub Secret**으로 전달해 코드·로그에 남지 않게 하기
- `main`에 push → **CI 통과 → 자동 배포**까지 사람 손 없이 이어지게 만들기 (GitOps)

---

## 실습 환경
```
GitHub: main에 push
   → CI 워크플로 (GitHub 클라우드 runner)
   → 성공하면 Deploy 워크플로가 깨어남
         ↓  ubuntu-server의 runner가 GitHub에 "할 일 있어?" 하고 받아옴
ubuntu-server [self-hosted runner, 라벨: lab] ── ansible-playbook ──> localhost, web02
```

| 항목 | 내용 |
|---|---|
| 워크플로 | [`.github/workflows/deploy.yml`](../../.github/workflows/deploy.yml) |
| runner | ubuntu-server, 서비스 실행 계정 `www`, 라벨 `self-hosted`, `lab` |
| Secret | `BECOME_PASSWORD` (sudo 비밀번호) |

---

## 실습 기록 상세

### [실습 1] Secret 등록과 공개 저장소 보안 설정
- **Settings → Secrets and variables → Actions** → `BECOME_PASSWORD` 등록 (저장 후 값은 다시 볼 수 없음)
- **Settings → Actions → General** → 외부 기여자의 fork PR 워크플로는 **승인해야 실행**되도록 설정

공개 저장소에 self-hosted runner를 붙이면 남이 올린 PR로 **내 VM에서 코드가 실행**될 수 있어 이를 막는 설정입니다. 배포 워크플로 자체도 PR로는 실행되지 않게 작성했습니다.

<!-- 📸 Secret 목록 / Actions 보안 설정 -->

### [실습 2] self-hosted runner 설치 (ubuntu-server)
GitHub의 **New self-hosted runner** 화면에 나온 다운로드·설정 명령을 ubuntu-server에서 실행했습니다.

| 설정 질문 | 입력 |
|---|---|
| runner 이름 | `ubuntu-server` |
| 추가 라벨 | `lab` |

```bash
cd ~/actions-runner
sudo ./svc.sh install www     # systemd 서비스로 등록, www 계정으로 실행
sudo ./svc.sh start
sudo ./svc.sh status          # active (running)
```
`www` 계정으로 실행해야 Day 06에 만든 SSH 키(`~/.ssh/id_ed25519`)와 Ansible을 그대로 사용해 web02에 접속할 수 있습니다.

<!-- 📸 svc.sh status / Runners 화면 Idle -->

### [실습 3] 배포 워크플로
```yaml
name: Deploy

on:
  workflow_run:
    workflows: [CI]
    types: [completed]
    branches: [main]
  workflow_dispatch:
    inputs:
      target:
        description: 배포 대상
        type: choice
        options: [all, localhost, web02]
        default: all

concurrency:
  group: deploy
  cancel-in-progress: false

jobs:
  deploy:
    if: >-
      github.event_name == 'workflow_dispatch' ||
      (github.event.workflow_run.conclusion == 'success' &&
       github.event.workflow_run.event == 'push')
    runs-on: [self-hosted, lab]
    defaults:
      run:
        working-directory: 07-Infra-CICD/ansible
    steps:
      - uses: actions/checkout@v5
        with:
          ref: ${{ github.event.workflow_run.head_sha || github.sha }}
      - name: 어디서 실행 중인지
        run: |
          hostname
          whoami
          pwd
      - name: 컬렉션 확인
        run: ansible-galaxy collection install -r requirements.yml
      - name: 배포
        env:
          ANSIBLE_BECOME_PASS: ${{ secrets.BECOME_PASSWORD }}
          ANSIBLE_FORCE_COLOR: "1"
          TARGET: ${{ inputs.target || 'all' }}
        run: ansible-playbook site.yml --limit "$TARGET"
```

| 부분 | 역할 |
|---|---|
| `workflow_run: [CI] completed` | CI가 끝나면 깨어남 (CI → CD 연결) |
| `conclusion == 'success'` & `event == 'push'` | CI가 **성공**했고, **push**로 실행된 경우만 배포 (PR 검사는 배포하지 않음) |
| `runs-on: [self-hosted, lab]` | GitHub 컴퓨터가 아니라 `lab` 라벨이 붙은 내 runner에서 실행 |
| `concurrency: deploy` | 배포가 동시에 두 개 겹치지 않도록 줄 세움 |
| `head_sha` | CI가 검사한 **바로 그 커밋**을 배포 |
| `ANSIBLE_BECOME_PASS` | Secret을 환경변수로만 전달 (`-K` 입력 대신) |
| `TARGET` | 수동 실행 시 고른 대상을 환경변수로 넘김 (입력값을 명령에 직접 끼워 넣지 않음) |

### [실습 4] 수동 배포 — 비밀번호 오류 해결
| 실행 | 대상 | 결과 |
|---|---|---|
| 1차 | web02 | ❌ `Incorrect sudo password` |
| 2차 | localhost | ❌ `Incorrect sudo password` |
| 3차 (Secret 수정 후) | web02 | ✅ `web02 : ok=18 changed=0 failed=0` |

모든 실행에서 `어디서 실행 중인지` step이 `ubuntu-server` / `www` / `/home/www/actions-runner/_work/Linux/Linux/07-Infra-CICD/ansible`을 출력 → **GitHub의 작업이 내 VM에서 실행**된 것을 확인했습니다.

<!-- 📸 Incorrect sudo password 로그 -->
<!-- 📸 어디서 실행 중인지 (ubuntu-server / www) -->
<!-- 📸 3차 성공 PLAY RECAP -->

### [실습 5] GitOps — 코드 수정만으로 배포
`roles/nginx_site/templates/index.html.j2` 첫 줄을 웹에서 수정해 커밋했습니다 (`day04 gitops`).

```html
<h1>Iac - deployed by GitHub Actions</h1>
```

| 순서 | 워크플로 | 이벤트 | 결과 |
|---|---|---|---|
| 1 | CI | `push` | ✅ |
| 2 | Deploy | `workflow_run` (CI 완료 후 자동) | ✅ |

```
TARGET: all
changed: [localhost]
changed: [web02]
localhost : ok=18 changed=1 unreachable=0 failed=0
web02     : ok=18 changed=1 unreachable=0 failed=0
```
- 바뀐 템플릿 하나만 두 서버에 반영 (`changed=1`)
- **사람이 서버에 접속하지 않고**, 커밋 하나로 검사부터 배포까지 끝남

```bash
curl localhost
curl http://192.168.56.102
# <h1>Iac - deployed by GitHub Actions</h1>
```

<!-- 📸 Actions 목록 (CI push → Deploy workflow_run) -->
<!-- 📸 Deploy 로그 changed=1 (두 서버) -->
<!-- 📸 curl / 브라우저 -->

### [실습 6] Secret 마스킹
Deploy 로그의 `env:` 부분에서 `ANSIBLE_BECOME_PASS: ***`로 표시되어 비밀번호가 노출되지 않는 것을 확인했습니다.

<!-- 📸 env ANSIBLE_BECOME_PASS: *** -->

---

## 👀 관찰 포인트 (원리 정리 때 사용)
1. `hostname`이 GitHub 컴퓨터가 아니라 **`ubuntu-server`** — 같은 워크플로 문법인데 실행 장소가 바뀜
2. 버튼을 누르자 VM의 runner 로그가 바로 움직임 — VM이 GitHub에 **계속 물어보고(폴링)** 있었다는 증거
3. CI가 끝나기 전에는 Deploy가 시작되지 않음 — `workflow_run`으로 **CI 결과에 묶인 배포**
4. 비밀번호가 틀려도 로그엔 `***`만 보임 — Secret은 **틀려도 눈으로 확인할 수 없고**, 실패 로그로만 알 수 있음

---

## Troubleshooting (장애 대응 기록)

### 문제 1. `Incorrect sudo password` (web02, localhost 모두)
- **확인 순서**: web02만이 아니라 localhost도 실패 → 서버별 비밀번호 차이가 아니라 **Secret 값 자체**의 문제. 메시지가 `Missing`이 아니라 `Incorrect`이므로 값은 전달됨
- **원인**: Secret에 `아이디 + 공백 + 비밀번호`를 입력함. sudo는 이 전체를 비밀번호로 받음
- **해결**: Secret을 **비밀번호만** 넣어 Update → 성공
- **배운 점**: Secret은 저장 후 내용을 볼 수 없으므로, 입력 시 한/영·Caps Lock·앞뒤 공백까지 주의. 아이디는 인벤토리(`ansible_user`)가 따로 처리

---

## 핵심 정리
- **self-hosted runner**: 내 서버가 GitHub에 작업을 받으러 가는 구조 → NAT 뒤의 VM에도 방화벽을 열지 않고 배포 가능
- **`workflow_run`**: CI 성공을 조건으로 CD를 실행해 검사와 배포를 연결
- **Secrets**: 비밀 값은 코드가 아닌 저장소 설정에 두고, 실행 시 환경변수로만 전달·로그에서 마스킹
- **GitOps**: 서버를 바꾸고 싶으면 서버가 아니라 **Git을 바꾼다**

---

## 🇯🇵 오늘의 일본어 엔지니어링
- **단어 1:** **継続的デリバリー (けいぞくてき, 케-조쿠테키 데리바리-)** - 지속적 배포 (CD)
- **단어 2:** **機密情報 (きみつじょうほう, 키미츠죠-호-)** - 기밀 정보 (Secret)
- **단어 3:** **自動デプロイ (じどう, 지도- 데푸로이)** - 자동 배포 (Auto deploy)
