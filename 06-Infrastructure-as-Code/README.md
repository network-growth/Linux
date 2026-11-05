# 06. Infrastructure as Code (2026-11 ~)

손으로 쳐서 만들던 서버 환경을 **코드로 정의하고, 언제든 똑같이 재현**하는 프로젝트.

## 목표
- Day 01 ~ 34에서 수동으로 구축한 환경(UFW, Nginx, Crontab, Docker 등)을 코드로 옮기기
- 같은 코드로 서버를 몇 번이고 동일하게 다시 만들 수 있는지 검증
- 실무에서 쓰는 IaC 흐름(선언형 구성, 멱등성, Git 기반 변경 관리) 이해

## 기술 스택 (예정)
| 영역 | 도구 |
|---|---|
| 구성 관리 | Ansible |
| 인프라 프로비저닝 | Terraform |
| 버전 관리 | Git / GitHub |

## 구조
```
06-Infrastructure-as-Code/
├── README.md
├── Daily-log/
├── day1-ssh-hardening/   # SSH 보안 설정
├── day2-manual-setup/    # 수동 구성 기록
├── day3-systemd-backup/  # systemd 타이머 백업
├── day4-ansible/         # Ansible로 코드화
├── day5-idempotency/     # 멱등성·드리프트 테스트
└── day6-rebuild/         # 새 서버 재구축 검증
```

## 진행 기록
| Day | 주제 | 폴더 | 기록 |
|---|---|---|---|
| Day 01 | SSH 보안 설정 | [day1-ssh-hardening](day1-ssh-hardening) | [Day-01](Daily-log/Day-01.md) · 2026-11-03 |
| Day 02 | Nginx·UFW 수동 구성 | [day2-manual-setup](day2-manual-setup) | [Day-02](Daily-log/Day-02.md) · 2026-11-04 |
| Day 03 | systemd 타이머 백업·복구 | [day3-systemd-backup](day3-systemd-backup) | [Day-03](Daily-log/Day-03.md) · 2026-11-04 |
| Day 04 | Ansible 코드화 | [day4-ansible](day4-ansible) | [Day-04](Daily-log/Day-04.md) · 2026-11-05 |
| Day 05 | 멱등성·드리프트 테스트 | [day5-idempotency](day5-idempotency) | [Day-05](Daily-log/Day-05.md) · 2026-11-05 |
| Day 06 | 새 서버 재구축 검증 | [day6-rebuild](day6-rebuild) | |

> 매일 기록은 [Daily-log](Daily-log)에 작성
