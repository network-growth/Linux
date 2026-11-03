# Day 01. SSH 키 인증 및 서버 접속 보안 설정 (2026-11-03)

## 오늘의 목표
- 비밀번호 대신 **SSH 키**로 서버에 접속하도록 바꾸기
- 비밀번호 로그인과 root 로그인을 막아 무차별 대입 공격을 원천 차단하기
- 이후 Ansible 자동화(Day 04)의 기반이 되는 **키 기반 원격 접속 환경** 만들기

---

## 실습 환경
| 항목 | 내용 |
|---|---|
| 서버 | Ubuntu Server 26.04 LTS (VirtualBox, NAT) |
| 접속 | Windows PowerShell → `127.0.0.1:2222` → VM `22` (포트 포워딩) |
| 계정 | `www` |

---

## 실습 기록 상세

### [실습 1] SSH 키 쌍 생성 및 공개키 등록
노트북(Windows)에서 `ed25519` 방식의 키 쌍을 만들고, 공개키만 서버의 `~/.ssh/authorized_keys`에 등록했습니다.
개인키는 노트북 밖으로 나가지 않고, 서버는 공개키(자물쇠)만 가지고 있는 구조입니다.

```powershell
ssh-keygen -t ed25519 -C "laptop"
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub | ssh www@127.0.0.1 -p 2222 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

| 파일 | 권한 | 이유 |
|---|---|---|
| `~/.ssh` | `700` | 권한이 느슨하면 sshd가 키 인증을 거부함 |
| `~/.ssh/authorized_keys` | `600` | 소유자만 읽기·쓰기 |

<!-- 📸 키 생성 / authorized_keys 확인 캡처 -->

### [실습 2] 변경 전 설정 확인
설정을 바꾸기 전에 sshd가 **실제로 적용 중인 값**을 먼저 기록했습니다. `sshd -T`는 설정 파일 여러 개를 합친 최종 결과를 보여줍니다.

```bash
sudo sshd -T | grep -E 'passwordauthentication|permitrootlogin|kbdinteractive'
```

<!-- 📸 Before 캡처 -->

### [실습 3] 드롭인(drop-in) 방식으로 보안 설정 추가
본 설정 파일(`/etc/ssh/sshd_config`)을 직접 수정하지 않고, `sshd_config.d/` 폴더에 별도 파일을 추가했습니다.
패키지 업데이트로 본 파일이 바뀌어도 내 설정이 덮어써지지 않는 실무 방식입니다.

```bash
printf 'PasswordAuthentication no\nKbdInteractiveAuthentication no\nPermitRootLogin no\n' | sudo tee /etc/ssh/sshd_config.d/10-hardening.conf
```

설정 파일: [`day1-ssh-hardening/10-hardening.conf`](../day1-ssh-hardening/10-hardening.conf)

| 설정 | 의미 |
|---|---|
| `PasswordAuthentication no` | 비밀번호 로그인 차단 |
| `KbdInteractiveAuthentication no` | 키보드 입력식 인증(우회 경로) 차단 |
| `PermitRootLogin no` | root 계정 직접 로그인 차단 |

> 파일 이름을 `10-`으로 시작한 이유: sshd는 **먼저 읽은 값이 우선**이라, Ubuntu가 만드는 `50-cloud-init.conf`보다 앞 번호로 두어 내 설정이 먼저 적용되게 함.

### [실습 4] 문법 검사 후 재시작, 적용 확인
`sshd -t`로 문법을 먼저 검사하고, 통과했을 때만(`&&`) 재시작했습니다. 기존 접속 창은 닫지 않은 채로 진행했습니다.

```bash
sudo sshd -t && sudo systemctl restart ssh
sudo sshd -T | grep -E 'passwordauthentication|permitrootlogin|kbdinteractive'
```

<!-- 📸 After 캡처 (전부 no) -->

### [실습 5] 차단 검증
노트북의 **새 탭**에서 일부러 키를 빼고 비밀번호로 접속을 시도했고, 비밀번호를 묻지도 않고 거부되는 것을 확인했습니다.

```powershell
ssh -o PubkeyAuthentication=no www@127.0.0.1 -p 2222
# → www@127.0.0.1: Permission denied (publickey).

ssh www@127.0.0.1 -p 2222
# → 비밀번호 없이 접속 성공
```

<!-- 📸 Permission denied (publickey) 캡처 -->

### [실습 6] journalctl로 접속 기록 추적
`journalctl`로 SSH 서비스의 로그만 걸러서, 오늘 작업이 시간 순서대로 남아 있는 것을 확인했습니다.

```bash
journalctl -u ssh --since "15 min ago" --no-pager
```

| 시간 | 로그 | 의미 |
|---|---|---|
| 13:12:19 | `Accepted publickey for www` | 키로 첫 접속 성공 |
| 13:18:40 | `Received signal 15` → `Started ssh.service` | 재시작으로 새 설정 적용 |
| 13:21:30 | `Connection reset ... [preauth]` | 비밀번호 시도 거부 (인증 전 종료) |
| 13:22:05 | `Accepted publickey for www` | 키로 정상 접속 |

<!-- 📸 journalctl 캡처 -->

### [실습 7] 최신 명령어로 상태 점검
예전 명령어(`netstat`, `ifconfig`, `service`) 대신 현재 표준 명령어로 서버 상태를 확인했습니다.

```bash
ss -tlnp
ip -br a
systemctl status ssh --no-pager
```

<!-- 📸 ss / ip / systemctl 캡처 -->

---

## Troubleshooting (장애 대응 기록)

### 문제 1. 여러 줄 명령어(heredoc) 입력 오류
- **상황**: `<<'EOF'` 방식의 여러 줄 명령어를 손으로 입력하다가 `/dev/null/`, 짝이 안 맞는 따옴표 등 오타가 섞여 명령이 완료되지 않음
- **원인**: heredoc은 줄바꿈과 종료 문자(`EOF`)가 정확해야 동작하는데, 직접 타이핑하며 형식이 깨짐
- **해결**: `printf '...\n...\n'` 한 줄 명령으로 바꿔 복사·붙여넣기로 실행
- **배운 점**: 설정 파일 생성은 한 줄 명령이나 복사 가능한 블록으로 처리하는 것이 실수를 줄임

### 문제 2. 차단 테스트 시 `Connection refused`
- **상황**: `ssh -o PubkeyAuthentication=no www@127.0.0.1 -p 2222` 실행 시 `Connection refused`
- **원인**: 명령을 **서버 안**(`www@ubuntu-server`)에서 실행함. 서버 안에서 `127.0.0.1`은 서버 자기 자신을 가리키고, 서버에는 2222번 포트가 없음
- **해결**: 노트북 PowerShell(`PS C:\Users\user>`)에서 다시 실행 → `Permission denied (publickey)` 확인
- **배운 점**: `127.0.0.1`은 "명령을 실행한 그 기계 자신". 포트 포워딩은 **호스트(노트북)** 쪽에 걸려 있음

### 문제 3. PowerShell에서 `journalctl` 인식 불가
- **상황**: `journalctl` 실행 시 `CommandNotFoundException`
- **원인**: 리눅스 명령을 Windows PowerShell에서 실행함
- **해결**: SSH로 접속한 창(`www@ubuntu-server:~$`)에서 실행
- **배운 점**: 명령 입력 전 **프롬프트로 현재 위치(호스트/서버)를 먼저 확인**하는 습관

---

## 핵심 명령어 요약
- **`ssh-keygen -t ed25519`**: SSH 키 쌍 생성
- **`~/.ssh/authorized_keys`**: 접속을 허용할 공개키 목록
- **`sshd -T`**: sshd가 실제로 적용 중인 최종 설정 출력
- **`sshd -t`**: 설정 파일 문법 검사
- **`systemctl restart ssh`**: SSH 서비스 재시작
- **`journalctl -u ssh --since "15 min ago"`**: 특정 서비스의 최근 로그만 조회
- **`ss -tlnp`**: 대기 중인 TCP 포트와 프로세스 확인 (`netstat` 대체)
- **`ip -br a`**: 네트워크 인터페이스·IP 요약 (`ifconfig` 대체)

---

## 🇯🇵 오늘의 일본어 엔지니어링
- **단어 1:** **公開鍵認証 (こうかいかぎにんしょう, 코-카이카기닌쇼-)** - 공개키 인증 (Public key authentication)
- **단어 2:** **踏み台 (ふみだい, 후미다이)** - 발판 서버, 점프 서버 (Bastion host)
- **단어 3:** **ログイン拒否 (ログインきょひ, 로그인쿄히)** - 로그인 거부 (Login denied)
