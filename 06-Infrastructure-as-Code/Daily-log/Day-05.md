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

<img width="1134" height="216" alt="스크린샷 2026-11-05 130341" src="https://github.com/user-attachments/assets/4c3e0285-1100-47b4-b57b-9b5a8a627f3e" />

<img width="730" height="43" alt="스크린샷 2026-11-05 130404" src="https://github.com/user-attachments/assets/675707e8-e10d-4ee0-bbb1-fb0ebab6dd78" />

<img width="789" height="43" alt="스크린샷 2026-11-05 130420" src="https://github.com/user-attachments/assets/0f2ccb48-d0a0-4089-bd5c-d6684436d402" />

<img width="1065" height="59" alt="스크린샷 2026-11-05 130444" src="https://github.com/user-attachments/assets/293e38b2-8597-45b5-9a92-3dc6d3d7692b" />

<img width="752" height="155" alt="스크린샷 2026-11-05 130505" src="https://github.com/user-attachments/assets/7df8ca76-2460-4b6f-ba38-8a2d49a61b56" />

<img width="1015" height="48" alt="스크린샷 2026-11-05 130545" src="https://github.com/user-attachments/assets/4bac370f-8261-4def-b868-49cfd6e92332" />

<img width="958" height="40" alt="스크린샷 2026-11-05 130602" src="https://github.com/user-attachments/assets/ecbfb65a-3595-41bf-aeeb-be9a190580bc" />

<img width="1916" height="1030" alt="스크린샷 2026-11-05 130632" src="https://github.com/user-attachments/assets/3c9cd32b-e4a5-4572-ac67-9b56c6dd2071" />

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

<img width="1099" height="576" alt="스크린샷 2026-11-05 130852" src="https://github.com/user-attachments/assets/8e4410f0-5c1a-419a-86ae-da00468d9abd" />

### [실습 4] 플레이북으로 복구
```bash
ansible-playbook playbook.yml -K
```
- 6개 항목이 한 번의 실행으로 원래 상태로 돌아옴 (`failed=0`)
- SSH 설정이 바뀌어 `check sshd` → `restart sshd service` 핸들러 실행
- default 링크를 **먼저 삭제한 뒤** `check nginx`(`nginx -t`)가 실행되어 검사를 통과하고 reload까지 정상 진행 → 태스크와 핸들러 실행 순서의 의미를 확인

<img width="1102" height="585" alt="스크린샷 2026-11-05 131412" src="https://github.com/user-attachments/assets/af9711e3-5d3f-471e-97d9-b6e91d1b840b" />

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

<img width="739" height="62" alt="스크린샷 2026-11-05 131033" src="https://github.com/user-attachments/assets/2e620c00-69c7-42b5-9bfd-84297d31a44d" />

<img width="780" height="44" alt="스크린샷 2026-11-05 131044" src="https://github.com/user-attachments/assets/17a192d7-c4cc-4155-96ce-2c5962c33705" />

<img width="748" height="60" alt="스크린샷 2026-11-05 131059" src="https://github.com/user-attachments/assets/8dac65b1-0728-462f-9110-5c96289107b8" />

<img width="759" height="188" alt="스크린샷 2026-11-05 131111" src="https://github.com/user-attachments/assets/63e8852d-9f08-46fa-9459-d2342a096196" />

<img width="1004" height="46" alt="스크린샷 2026-11-05 131133" src="https://github.com/user-attachments/assets/c86eafc2-3e94-4db6-adf9-888cf2f131c1" />

<img width="945" height="45" alt="스크린샷 2026-11-05 131154" src="https://github.com/user-attachments/assets/15382a08-e9cd-4a40-a75f-713a494f32b4" />

<img width="1914" height="942" alt="스크린샷 2026-11-05 131205" src="https://github.com/user-attachments/assets/0cfd38db-c409-489a-9cef-2087d21ac6d3" />

<img width="1102" height="585" alt="스크린샷 2026-11-05 131412" src="https://github.com/user-attachments/assets/62880ee8-f28a-4a8b-b3fd-c4b8e157bf5f" />

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


<img width="1113" height="183" alt="image" src="https://github.com/user-attachments/assets/f475bb07-ec3a-4ca8-a106-047bcf101d80" />

<img width="1020" height="118" alt="image" src="https://github.com/user-attachments/assets/a85faf27-4263-4782-8d20-d38970f00b0c" />

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
