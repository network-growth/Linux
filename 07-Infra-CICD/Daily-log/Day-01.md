# Day 01. GitHub Actions 기초 — 첫 워크플로 실행 (2026-11-09)

## 오늘의 목표
- `.github/workflows/`에 YAML 파일을 만들어 GitHub Actions 워크플로 실행해 보기
- **무엇이 워크플로를 깨우는지**(push, 수동 실행)와 **언제 실행되지 않는지**(경로 필터) 확인하기
- 실패한 step이 이후 작업에 어떤 영향을 주는지 확인하기

---

## 실습 환경
| 항목 | 내용 |
|---|---|
| 작업 위치 | GitHub 웹 (브라우저) |
| 워크플로 파일 | [`.github/workflows/day01-hello.yml`](../../.github/workflows/day01-hello.yml) |
| 실행 컴퓨터 | GitHub이 제공하는 클라우드 runner (`ubuntu-latest`) |

---

## 실습 기록 상세

### [실습 1] 첫 워크플로 작성
워크플로 파일은 반드시 저장소 최상위의 `.github/workflows/` 안에 있어야 동작합니다. 처음엔 Actions 탭에 "Get started" 화면만 나와 파일이 아직 인식되지 않은 상태였고, `set up a workflow yourself`로 파일을 만들어 해결했습니다.

```yaml
name: Day01 Hello

on:
  push:
    branches: [main]
    paths:
      - "07-Infra-CICD/**"
      - ".github/workflows/day01-hello.yml"
  workflow_dispatch:

jobs:
  hello:
    runs-on: ubuntu-latest
    steps:
      - name: 누가, 무엇으로 실행했나
        run: |
          echo "이벤트: ${{ github.event_name }}"
          echo "실행한 사람: ${{ github.actor }}"
          echo "브랜치: ${{ github.ref_name }}"
          echo "커밋: ${{ github.sha }}"
      - name: 이 작업이 돌고 있는 컴퓨터
        run: |
          hostname
          head -2 /etc/os-release
          nproc
          free -h
          pwd
          ls -la
      - name: 저장소 코드 받기
        uses: actions/checkout@v5
      - name: 받은 뒤 다시 보기
        run: |
          pwd
          ls
          ls 07-Infra-CICD

  second:
    needs: hello
    runs-on: ubuntu-latest
    steps:
      - name: 두 번째 작업
        run: |
          hostname
          ls -la
```

| 키 | 의미 |
|---|---|
| `on` | 워크플로를 깨우는 이벤트 (`push`, `workflow_dispatch`) |
| `paths` | 이 경로가 바뀐 push일 때만 실행 |
| `jobs` | 작업 단위 (`hello`, `second`) |
| `runs-on` | 작업을 실행할 컴퓨터 종류 |
| `steps` | 작업 안에서 순서대로 실행할 명령 |
| `uses` | 미리 만들어진 액션 가져다 쓰기 (`actions/checkout`) |
| `needs` | 앞 작업이 성공해야 시작 |

### [실습 2] push로 실행
커밋하자 자동으로 실행되어 `hello`(4s) → `second`(3s) 순서로 완료되었습니다. 그래프 위에는 `on: push`가 표시됩니다.

<!-- 📸 hello → second 그래프 -->
<!-- 📸 hello 로그 (이벤트·컴퓨터 정보·checkout 전후) -->
<!-- 📸 second 로그 -->

실행 결과 하단에 `ubuntu-latest` 라벨이 Ubuntu 26으로 바뀐다는 안내(notice)가 표시되었습니다. 에러가 아닌 GitHub runner 이미지 변경 공지입니다.

### [실습 3] 버튼으로 실행 (`workflow_dispatch`)
Actions → `Day01 Hello` → **Run workflow**로 실행했습니다. 같은 파일·같은 작업이지만 그래프 위가 `on: workflow_dispatch`, 실행 목록엔 `Manually run by ...`로 기록되어 **무엇이 깨웠는지**가 남는 것을 확인했습니다.

- 실행 상세 화면의 `Re-run all jobs`는 **같은 실행을 원래 이벤트 그대로 다시** 돌리는 것이고, `Run workflow`는 **새 실행**을 만드는 버튼이라 서로 다름

<!-- 📸 on: workflow_dispatch -->

### [실습 4] 경로 필터 확인
| 커밋 | 수정한 파일 | 결과 |
|---|---|---|
| `day01 test1` | 최상위 `README.md` (07 밖) | 실행 **안 됨** |
| `day01 test2` | `07-Infra-CICD/Daily-log/.gitkeep` (07 안) | 실행 **됨** |

`test2` 실행은 목록에 잠시 `Queued`(노란 점)로 표시된 뒤 실행되었습니다. 실행 번호는 지운 실행(#2)의 번호를 다시 쓰지 않았습니다.

<!-- 📸 실행 목록 (test1 없음, test2 Queued) -->

### [실습 5] 일부러 실패시키기
`저장소 코드 받기` 위에 `exit 1` step을 넣어 커밋했습니다 (`day01 fail`).

| 위치 | 결과 |
|---|---|
| `일부러 실패` | ❌ `Process completed with exit code 1.` |
| 그 아래 step들 | 실행 안 됨 |
| `second` job | 실행 안 됨 (`needs: hello`) |

해당 step을 지우고 다시 커밋(`day01 fix`)해 정상으로 돌렸습니다.

<!-- 📸 실패 그래프 / 실패 step 로그 -->
<!-- 📸 fix 후 초록 -->

---

## 👀 관찰 포인트 (원리 정리 때 사용)
1. `hello`와 `second`의 **hostname이 같았는지**, `second`의 `ls -la`에 저장소 코드가 있었는지
2. 실행 목록의 `Queued` → 실행 시작까지 걸린 시간

---

## Troubleshooting (장애 대응 기록)

### 문제 1. Actions 탭에 "Get started with GitHub Actions"만 표시
- **원인**: `.github/workflows/` 아래에 워크플로 파일이 아직 없어서 GitHub이 인식하지 못함
- **해결**: `set up a workflow yourself`에서 파일 이름을 `day01-hello.yml`로 바꿔 생성

### 문제 2. `Run workflow` 버튼을 찾지 못함
- **원인**: 실행 상세 화면에는 `Re-run all jobs`만 있음
- **해결**: 상단 `← Day01 Hello`로 워크플로 화면에 나가면 `Run workflow` 버튼이 있음

---

## 핵심 정리
- **`on`**: 무엇이 실행시키나 / **`paths`**: 언제는 실행하지 않나
- **`jobs` → `steps`**: 작업 묶음과 그 안의 순서
- **`needs`**: 작업 간 순서와 의존 관계 — 앞이 실패하면 뒤는 실행되지 않음
- **step 실패(`exit 1`)**: 그 job의 나머지 step과 의존하는 job이 모두 멈춤

---

## 🇯🇵 오늘의 일본어 엔지니어링
- **단어 1:** **ワークフロー (와-쿠후로-)** - 워크플로 (Workflow)
- **단어 2:** **自動化 (じどうか, 지도-카)** - 자동화 (Automation)
- **단어 3:** **トリガー (토리가-)** - 트리거, 실행 계기 (Trigger)
