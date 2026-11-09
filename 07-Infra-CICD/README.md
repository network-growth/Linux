# 07. Infra CI/CD — GitOps (2026-11 ~)

[![CI](https://github.com/network-growth/Linux/actions/workflows/ci.yml/badge.svg)](https://github.com/network-growth/Linux/actions/workflows/ci.yml)

06에서 만든 Ansible 코드를 **GitHub에 올리면 자동으로 검사하고, 합쳐지면 자동으로 서버에 배포**하는 프로젝트.

## 목표
- GitHub Actions로 플레이북·스크립트를 자동 검사(CI)해서 틀린 코드가 서버에 닿기 전에 막기
- `main`에 merge되면 VM에 자동 배포(CD) — 사람이 서버에 들어가 `ansible-playbook`을 실행하지 않기
- 플레이북을 role 단위로 나눠 **새 VM은 인벤토리 한 줄 + 키 등록만으로** 배포되게 만들기
- Git이 서버 상태의 유일한 기준이 되는 GitOps 흐름 이해

## 기술 스택
| 영역 | 도구 |
|---|---|
| CI/CD | GitHub Actions |
| 배포 실행 | Self-hosted runner (ubuntu-server VM) |
| 구성 관리 | Ansible (roles, group_vars) |
| 코드 검사 | yamllint, ansible-lint, shellcheck |
| 비밀 관리 | GitHub Secrets |

## 구조
```
Linux/
├── .github/workflows/   # Actions 워크플로 (저장소 최상위에 있어야 동작)
└── 07-Infra-CICD/
    ├── README.md
    ├── Daily-log/       # 매일 기록
    ├── ansible/         # 06 코드를 role 구조로 발전
    └── scripts/         # 새 서버 준비 등 보조 스크립트
```

## 구성
```
GitHub (push / PR / merge)
   │  CI: GitHub 클라우드 runner에서 lint·문법 검사
   │
   ▲  CD: VM이 GitHub에 "할 일 있어?" 물어보고 작업을 받아옴 (밖으로 나가는 연결만 사용)
   │
ubuntu-server [self-hosted runner] ──Ansible/SSH──> web02, 새 VM ...
```

## 진행 기록
| Day | 주제 | 기록 |
|---|---|---|
| Day 01 | GitHub Actions 기초 | [Day-01](Daily-log/Day-01.md) · 2026-11-09 |
| Day 02 | CI — lint·문법 자동 검사 | [Day-02](Daily-log/Day-02.md) · 2026-11-09 |
| Day 03 | 배포하기 쉬운 구조로 변경 (roles, group_vars) | |
| Day 04 | CD — self-hosted runner, Secrets, 자동 배포 | |
| Day 05 | PR 흐름 — 브랜치 보호, CI 통과해야 merge | |
| Day 06 | 새 VM 추가 자동화 | |

> 매일 기록은 [Daily-log](Daily-log)에 작성
