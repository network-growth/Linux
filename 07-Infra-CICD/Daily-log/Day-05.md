# Day 05. PR 흐름 — CI를 통과한 변경만 main에 들어가게 (2026-11-09)

## 오늘의 목표
- `main` 브랜치를 잠가 **누구도 직접 올리지 못하게** 하기
- 모든 변경은 **PR → CI 통과 → merge** 순서로만 들어가게 하기
- 좋은 PR은 merge 후 자동 배포까지, 틀린 PR은 **merge 자체가 막히는지** 확인하기

---

## 실습 환경
| 항목 | 내용 |
|---|---|
| 설정 | GitHub **Rulesets** (`protect-main`) |
| 검사 | `CI` 워크플로 (`pull_request`, `push` 둘 다 실행) |
| 배포 | `Deploy` 워크플로 (CI가 `push`로 성공했을 때만) |

| | Day 04까지 | Day 05 이후 |
|---|---|---|
| `main`에 올리는 법 | 바로 커밋 | **PR만** |
| CI 실패한 코드 | `main`에 들어감 (배포만 안 됨) | **merge 버튼이 잠김** |
| 배포되는 코드 | `main`에 들어간 것 | 검사 통과 + merge된 것만 |

---

## 실습 기록 상세

### [실습 1] Ruleset으로 main 잠그기
**Settings → Rules → Rulesets → New branch ruleset**

| 항목 | 값 |
|---|---|
| 이름 / 상태 | `protect-main` / Active |
| 대상 | 기본 브랜치 (`~DEFAULT_BRANCH`) |
| Restrict deletions | ✅ main 삭제 금지 |
| Block force pushes | ✅ 기록 덮어쓰기 금지 |
| Require a pull request before merging | ✅ (승인 수 0 — 혼자 진행) |
| Require status checks to pass | ✅ `yamllint`, `ansible-lint`, `shellcheck` |
| Bypass list | 비움 (관리자도 예외 없음) |

<img width="1912" height="1021" alt="스크린샷 2026-11-09 145323" src="https://github.com/user-attachments/assets/5fec99e1-43d8-4b44-af79-e243e39fc3c7" />

### [실습 2] 직접 커밋이 막히는지
웹에서 파일을 수정하고 커밋하자 `main`으로 바로 들어가지 않고 자동으로 새 브랜치(`network-growth-patch-2`)에 저장된 뒤 **PR 화면**으로 넘어갔습니다. 테스트용이라 PR은 만들지 않고 브랜치를 삭제했습니다.

<img width="1172" height="371" alt="스크린샷 2026-11-09 145429" src="https://github.com/user-attachments/assets/af7176d4-6fa3-4081-a871-5a17b0b16e21" />

### [실습 3] 좋은 PR — 검사 → merge → 자동 배포
페이지 템플릿 2번째 줄의 `managed by playbook.yml`을 `site.yml`로 수정하는 PR을 만들었습니다 (PR #1 `fix-template`).

| 순서 | 이벤트 | 결과 |
|---|---|---|
| 1 | PR 생성 → `CI` (`pull_request`) | ✅✅✅ — **Deploy는 실행되지 않음** |
| 2 | Merge | `main`에 반영 |
| 3 | `CI` (`push`) | ✅ |
| 4 | `Deploy` (CI 완료 후 자동, `workflow_run`) | ✅ |

```bash
curl localhost
# <h1>Iac - deployed by GitHub Actions</h1>
# <p>host: ubuntu-server / managed by site.yml</p>

curl http://192.168.56.102
# <h1>Iac - deployed by GitHub Actions</h1>
# <p>host: web02 / managed by site.yml</p>
```
서버에 접속하지 않고 **PR merge 하나로** 두 서버에 반영되었습니다.

<img width="823" height="293" alt="스크린샷 2026-11-09 145856" src="https://github.com/user-attachments/assets/9001b25d-85ef-4c2e-a872-181ad92d1309" />

<img width="1187" height="134" alt="스크린샷 2026-11-09 150015" src="https://github.com/user-attachments/assets/272046ca-49e8-43fe-888c-9403054b0f54" />

<img width="444" height="137" alt="스크린샷 2026-11-09 150247" src="https://github.com/user-attachments/assets/9829f8ca-1e86-447a-b553-36b18bf18ab8" />

### [실습 4] 틀린 PR — merge가 막히는지
`roles/firewall/tasks/main.yml`의 첫 태스크 이름을 `UFW 설치` → `ufw 설치`로 바꾼 PR을 만들었습니다 (PR #2, 브랜치 `bad-name`).

```
name[casing]: All names should start with an uppercase letter.
roles/firewall/tasks/main.yml:3:9 Task/Handler: ufw 설치
```

| 검사 | 결과 |
|---|---|
| `CI / ansible-lint (pull_request)` | ❌ **Required** |
| `CI / shellcheck`, `CI / yamllint` | ✅ Required |
| Merge pull request 버튼 | **회색 — 누를 수 없음** |
| Deploy | 실행되지 않음 |

PR을 merge하지 않고 **Close + 브랜치 삭제** → 틀린 코드는 `main`에도 서버에도 한 번도 들어가지 않았습니다.

<img width="1561" height="610" alt="스크린샷 2026-11-09 150637" src="https://github.com/user-attachments/assets/3859fecd-90ad-4d7a-add0-3f4a190b1195" />

<img width="1786" height="1012" alt="스크린샷 2026-11-09 150946" src="https://github.com/user-attachments/assets/a5f823e5-5615-4082-9458-797392b9dddd" />

| PR | 결과 |
|---|---|
| #1 `fix-template` | merged → 배포됨 |
| #2 `Update main.yml` (`bad-name`) | closed, merge 안 됨 |

---

## 👀 관찰 포인트 (원리 정리 때 사용)
1. PR 단계 CI(`pull_request`)에서는 **Deploy가 생기지 않고**, merge 후 CI(`push`)가 끝나야 Deploy가 생김
2. 틀린 PR의 merge 버튼을 잠근 것은 사람이 아니라 **CI 결과 + Ruleset의 필수 검사 설정**
3. merge 후 실행된 CI는 PR 때와 **같은 검사를 한 번 더** 함 (merge된 결과물 기준으로 다시 확인)

---

## Troubleshooting (장애 대응 기록)

### 문제 1. 브랜치 삭제 시 `Branch could not be deleted.`
- **상황**: 테스트용 브랜치 두 개를 지우려 했는데 하나에서 오류
- **원인**: 이미 삭제된 브랜치였는데 화면이 새로고침되지 않아 목록에 남아 있었음 (`patch-1`은 PR #1 merge 때 삭제됨)
- **확인**: API로 조회 시 `Branch not found`, Ruleset은 기본 브랜치에만 적용되어 있어 삭제를 막지 않음
- **해결**: 새로고침

### 문제 2. "이미 소문자인데?"
- **상황**: 태스크 이름을 소문자로 바꾸려는데 파일에 이미 `ufw`가 있었음
- **원인**: `- name: UFW 설치`(태스크 이름)와 그 아래 `name: ufw`(apt 패키지 이름)를 혼동. ansible-lint는 **태스크 이름만** 검사
- **배운 점**: 들여쓰기로 구분 — 맨 앞 `- name:`은 태스크 이름, 모듈 아래 `name:`은 모듈에 주는 값

### 문제 3. "merge 버튼을 못 누른다"
- **상황**: 틀린 PR에서 Merge 버튼이 회색
- **정리**: 이 실습의 **기대 결과**. 필수 검사가 실패하면 merge할 수 없고, 해당 PR은 Close로 버림

---

## 핵심 정리
- **Ruleset**: 브랜치에 규칙을 걸어 사람의 실수·습관과 상관없이 절차를 강제
- **Required status checks**: CI 결과가 merge 가능 여부를 결정
- **PR = 변경 요청서**: 무엇을 왜 바꾸는지 + 검사 결과가 한 화면에 모이고, merge가 곧 배포의 시작

---

## 🇯🇵 오늘의 일본어 엔지니어링
- **단어 1:** **プルリクエスト (푸루리쿠에스토)** - 풀 리퀘스트 (Pull request)
- **단어 2:** **マージ (마-지)** - 병합 (Merge)
- **단어 3:** **ブランチ保護 (ブランチほご, 브란치호고)** - 브랜치 보호 (Branch protection)
