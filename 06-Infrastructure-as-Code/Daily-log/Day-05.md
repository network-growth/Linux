# Day 05. 드리프트 탐지와 플레이북 복구, 멱등성 검증 (2026-11-05)

## 오늘의 목표
- 서버 설정을 일부러 망가뜨려 **드리프트**(코드와 실제 서버의 차이)를 만들기
- `--check --diff`로 무엇이 틀어졌는지 **탐지**하고, 플레이북 한 번으로 **복구**하기
- 플레이북에 **적혀 있지 않은 변경**은 Ansible도 지키지 못한다는 한계 확인하기

---

## 실습 환경
| 항목 | 내용 |
|---|---|
| 서버 | Ubuntu Server 26.04 LTS (VirtualBox, NAT) |
| 플레이북 | [`day4-ansible/playbook.yml`](../day4-ansible/playbook.yml) |
| 드리프트 스크립트 | [`day5-idempotency/break-server.sh`](../day5-idempotency/break-server.sh) |

실무에서는 누군가 장애 대응 중에 서버에 직접 들어가 설정을 바꾸고 기록을 남기지 않으면 드리프트가 생깁니다. 오늘은 그 상황을 의도적으로 재현하고 **코드 기준으로 되돌리는** 과정을 연습했습니다.

---

## 실습 기록 상세

### [실습 1] 기준 상태 확인
망가뜨리기 전, 서버가 코드와 같은 상태인지 먼저 확인했습니다.

```bash
cd ~/linux/06-Infrastructure-as-Code/day4-ansible
ansible-playbook playbook.yml -K     # changed=0
```

<!-- 📸 기준 상태 PLAY RECAP (changed=0) -->

### [실습 2] 드리프트 6개 만들기
```bash
sudo bash ../day5-idempotency/break-server.sh
```

| # | 드리프트 | 증상 확인 명령 | 망가진 결과 |
|---|---|---|---|
| 1 | 웹 페이지 변조 | `curl localhost` | `<h1>hacked</h1>` |
| 2 | 웹 폴더 권한 777 | `ls -ld /var/www/lab` | `drwxrwxrwx` |
| 3 | default 사이트 다시 켜짐 | `sudo nginx -t` | `duplicate default server` |
| 4 | 방화벽 HTTP 규칙 삭제 | `sudo ufw status` | `Nginx HTTP` 규칙 없음, 브라우저 접속 불가 |
| 5 | SSH 비밀번호 로그인 허용 | `sudo sshd -T \| grep passwordauthentication` | `yes` |
| 6 | 백업 타이머 꺼짐 | `systemctl is-enabled lab-backup.timer` | `disabled` |

3번은 `lab`과 `default`가 둘 다 `default_server`를 선언해 충돌한 것입니다. reload를 하지 않았기 때문에 Nginx는 **이전 설정으로 계속 동작**하고, `nginx -t`는 "지금 반영하면 실패한다"는 경고 역할을 합니다.

<!-- 📸 break-server.sh 실행 -->
<!-- 📸 증상 확인 (curl / ls / nginx -t / ufw / sshd -T / is-enabled) -->
<!-- 📸 브라우저 접속 불가 -->

### [실습 3] 드리프트 탐지
```bash
ansible-playbook playbook.yml -K --check --diff
```
실제로 바꾸지 않고, 코드와 다른 곳을 태스크 단위로 찾아냈습니다.

| changed로 표시된 태스크 | 탐지한 차이 |
|---|---|
| SSH 보안 설정 배치 | `PasswordAuthentication yes` → `no` |
| 사이트 폴더 | 권한 `0777` → `0755` |
| 페이지 | `hacked` → `built by Ansible` |
| 기본 사이트 끄기 | default 링크 존재 → 삭제 |
| HTTP 허용 | 규칙 없음 → 추가 |
| 백업 타이머 켜기 | disabled → enabled |

<!-- 📸 --check --diff 결과 -->

### [실습 4] 플레이북으로 복구
```bash
ansible-playbook playbook.yml -K
```
- 6개 항목이 한 번의 실행으로 원래 상태로 돌아옴 (`failed=0`)
- SSH 설정이 바뀌어 `check sshd` → `restart sshd service` 핸들러 실행
- default 링크를 **먼저 삭제한 뒤** `check nginx`(`nginx -t`)가 실행되어 검사를 통과하고 reload까지 정상 진행 → 태스크와 핸들러 실행 순서의 의미를 확인

<!-- 📸 복구 PLAY RECAP + RUNNING HANDLER -->

### [실습 5] 복구 확인과 멱등성 재확인
```bash
curl localhost                                    # built by Ansible
ls -ld /var/www/lab                               # drwxr-xr-x
sudo nginx -t                                     # syntax is ok
sudo ufw status                                   # Nginx HTTP ALLOW
sudo sshd -T | grep passwordauthentication        # no
systemctl is-enabled lab-backup.timer             # enabled
ansible-playbook playbook.yml -K                  # changed=0
```

<!-- 📸 복구 후 증상 확인 -->
<!-- 📸 브라우저 접속 복구 -->
<!-- 📸 다시 실행 PLAY RECAP (changed=0) -->

### [실습 6] 코드가 모르는 변경 — Ansible의 한계
플레이북이 관리하지 않는 **새 파일**로 SSH 비밀번호 로그인을 열어 보았습니다.

```bash
printf 'PasswordAuthentication yes\n' | sudo tee /etc/ssh/sshd_config.d/00-bad.conf
sudo systemctl restart ssh
sudo sshd -T | grep passwordauthentication     # yes

ansible-playbook playbook.yml -K --check       # changed=0
```
- `00-bad.conf`가 `10-hardening.conf`보다 먼저 읽혀(Day 01의 "먼저 읽은 값 우선") 비밀번호 로그인이 다시 허용됨
- 그런데 플레이북은 **`changed=0`**, 즉 "정상"으로 판단함 → `10-hardening.conf` 자체는 그대로이기 때문
- **Ansible은 플레이북에 적힌 상태만 지킨다**는 것을 확인

실험 후 반드시 원래대로 되돌렸습니다.
```bash
sudo rm /etc/ssh/sshd_config.d/00-bad.conf
sudo systemctl restart ssh
sudo sshd -T | grep passwordauthentication     # no
```

| 배운 점 | 실무 대응 |
|---|---|
| 코드에 없는 변경은 탐지 못 함 | 서버를 직접 수정하지 않고, 바꿀 것은 코드로 바꾸기 |
| 설정 디렉터리에 파일 하나만 추가해도 보안이 무력화됨 | 중요한 디렉터리는 "허용된 파일만 존재해야 함"까지 코드로 관리하는 방안 고려 |

<!-- 📸 00-bad.conf 실험 (sshd -T yes / --check changed=0) -->
<!-- 📸 원복 후 sshd -T no -->

---

## Troubleshooting (장애 대응 기록)

### 문제 1. `Command 'pritf' not found`
- **원인**: `printf` 오타
- **참고**: 파이프 왼쪽이 실패해도 오른쪽 `sudo tee`는 실행되어 **빈 `00-bad.conf`** 가 생성됨. 내용이 비어 영향은 없었고 올바른 명령으로 덮어씀
- **배운 점**: 파이프는 왼쪽이 실패해도 오른쪽이 실행되므로, 파일을 만드는 명령은 결과 파일을 `cat`으로 꼭 확인

---

## 핵심 명령어 요약
- **`ansible-playbook <파일> -K --check --diff`**: 드리프트 탐지 (변경 없이 차이만 출력)
- **`ansible-playbook <파일> -K`**: 코드 기준으로 복구
- **`nginx -t`**: 반영 전 설정 충돌 확인 (`duplicate default server`)
- **`sshd -T`**: SSH 데몬이 실제로 적용 중인 최종 설정
- **`systemctl is-enabled`**: 부팅 시 자동 시작 여부

---

## 🇯🇵 오늘의 일본어 엔지니어링
- **단어 1:** **構成ドリフト (こうせいドリフト, 코-세-도리후토)** - 구성 드리프트 (Configuration drift)
- **단어 2:** **差分 (さぶん, 사분)** - 차분, 변경 차이 (Diff)
- **단어 3:** **復旧 (ふっきゅう, 훗큐-)** - 복구 (Recovery)
