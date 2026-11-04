# Day 02. Nginx 웹 서버와 UFW 방화벽 수동 구성 (2026-11-04)

## 오늘의 목표
- 예전에 손으로 만들었던 **Nginx 웹 서버 + UFW 방화벽** 환경을 다시 수동으로 구성하기
- 실행한 명령과 결과 상태를 하나하나 기록해서, Day 04 Ansible 코드화의 **원본 절차** 만들기
- 노트북 브라우저에서 VM 웹 서버까지 접속 경로 완성하기

---

## 실습 환경
| 항목 | 내용 |
|---|---|
| 서버 | Ubuntu Server 26.04 LTS (VirtualBox, NAT) |
| 접속 | SSH `127.0.0.1:2222` → VM `22` / HTTP `127.0.0.1:8080` → VM `80` |
| 결과물 | [`day2-manual-setup/`](../day2-manual-setup) — `lab`(Nginx 설정), `index.html`, `manual-steps.md` |

---

## 실습 기록 상세

### [실습 1] Nginx·UFW 설치
```bash
sudo apt update
sudo apt install -y nginx ufw
systemctl status nginx --no-pager
```

<!-- 📸 systemctl status nginx (active running) -->

### [실습 2] 사이트 폴더와 페이지 생성
`install -d`로 폴더 생성·소유자·권한 지정을 한 번에 처리했습니다. 폴더 주인을 로그인 계정(`www`)으로 두어 `sudo` 없이 페이지를 수정할 수 있게 하고, Nginx(`www-data`)는 읽기 권한만 갖도록 했습니다.

```bash
sudo install -d -o www -g www -m 755 /var/www/lab
printf '<h1>Iac - manual setup</h1>\n<p>built by hand on Day 02</p>\n' > /var/www/lab/index.html
ls -ld /var/www/lab && cat /var/www/lab/index.html
```

| 대상 | 주인 | 권한 | 의미 |
|---|---|---|---|
| `/var/www/lab` | `www` | `755` (`drwxr-xr-x`) | 나는 수정 가능, Nginx는 읽기만 가능 |

### [실습 3] 사이트 설정 작성 및 활성화
설정은 `sites-available/`에 보관하고, 실제로 켤 사이트만 `sites-enabled/`에 심볼릭 링크로 연결했습니다. 기본 사이트(`default`)는 링크를 지워 비활성화했습니다.

```bash
sudo tee /etc/nginx/sites-available/lab > /dev/null <<'EOF'
server { ... }   # 전체 내용: day2-manual-setup/lab
EOF
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/lab /etc/nginx/sites-enabled/lab
ls -l /etc/nginx/sites-enabled/
```

| 설정 | 의미 |
|---|---|
| `listen 80 default_server` | 80번 포트, 다른 사이트에 안 걸리는 요청은 전부 이 사이트로 |
| `root /var/www/lab` | 웹 문서 위치 |
| `server_tokens off` | 응답 헤더에서 Nginx 버전 숨김 |
| `access_log` / `error_log` | 사이트 전용 로그 파일 분리 |
| `try_files $uri $uri/ =404` | 파일 → 폴더 순서로 찾고 없으면 404 |

<!-- 📸 ls -l /etc/nginx/sites-enabled/ (lab -> sites-available/lab) -->

### [실습 4] 문법 검사 후 반영
Day 01의 `sshd -t`와 같은 패턴으로, 검사를 통과했을 때만 반영했습니다. 웹 서버는 접속을 끊지 않는 `reload`를 사용했습니다.

```bash
sudo nginx -t && sudo systemctl reload nginx
```

<!-- 📸 nginx -t (syntax is ok / test is successful) -->

### [실습 5] 서버 내부 응답 확인
```bash
curl -i localhost
```
- `HTTP/1.1 200 OK` 정상 응답
- `Server: nginx` — 버전 번호가 없어 `server_tokens off` 적용 확인
- `Content-Length: 59` — 작성한 `index.html` 크기와 일치

<!-- 📸 curl -i localhost -->

### [실습 6] UFW 방화벽 구성
SSH 접속이 끊기지 않도록 **SSH 허용 규칙을 먼저** 넣고 방화벽을 켰습니다.

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw limit OpenSSH
sudo ufw allow 'Nginx HTTP'
sudo ufw enable
sudo ufw status verbose
```

| 규칙 | 의미 |
|---|---|
| `default deny incoming` | 들어오는 연결 기본 차단 |
| `default allow outgoing` | 나가는 연결 허용 (apt, git) |
| `limit OpenSSH` | 22번 허용, 30초 안에 6회 이상 접속 시도 시 차단 |
| `allow 'Nginx HTTP'` | 80번만 허용 |

<!-- 📸 ufw status verbose -->

### [실습 7] 노트북 브라우저 접속
VirtualBox NAT 포트 포워딩에 `127.0.0.1:8080 → VM 80` 규칙을 추가하고 노트북 브라우저에서 접속했습니다.

| 이름 | 호스트 IP | 호스트 포트 | 게스트 포트 |
|---|---|---|---|
| http | 127.0.0.1 | 8080 | 80 |

<!-- 📸 브라우저 http://127.0.0.1:8080 -->

### [실습 8] 접속 로그 확인
```bash
sudo tail -n 5 /var/log/nginx/lab.access.log
```
브라우저 접속이 `10.0.2.2`(VirtualBox NAT 게이트웨이 = 노트북)에서 온 `GET / 200`으로 기록됨.

<!-- 📸 lab.access.log -->

### [실습 9] 최종 상태 점검
```bash
systemctl is-enabled nginx ufw
sudo ss -tlnp | grep -E ':22|:80'
sudo ufw status verbose
ls -l /etc/nginx/sites-enabled/
```

<!-- 📸 최종 상태 -->

---

## Troubleshooting (장애 대응 기록)

### 문제 1. 심볼릭 링크 경로 오타로 `nginx -t` 실패
- **상황**: `nginx -t` 실행 시 `open() "/etc/nginx/sites-enabled/lab" failed (2: No such file or directory)`
- **원인**: `ln -s` 원본 경로를 `sites-availalbe`로 잘못 입력 → 존재하지 않는 곳을 가리키는 **깨진 링크** 생성 (`ls -l`에서 빨간색 표시). 다시 만들 때는 원본 자리에 `sites-enabled`를 넣어 **링크가 자기 자신을 가리키는** 문제도 발생
- **해결**: 깨진 링크 삭제 후 `ln -s /etc/nginx/sites-available/lab /etc/nginx/sites-enabled/lab`로 재생성, `ls -l`로 링크 대상 확인
- **배운 점**: `ln -s <원본> <링크>` 순서. 그리고 `nginx -t`를 먼저 돌렸기 때문에 **깨진 설정이 서비스에 반영되기 전에 막을 수 있었음**

<!-- 📸 nginx -t 에러 / 깨진 링크 -->

### 문제 2. `ufw` 명령 문법 오류
- **상황**: `sudo ufw 'nginx HTTP'` → `ERROR: Invalid syntax`
- **원인**: 동작(`allow`)이 빠졌고, 앱 프로필 이름은 대소문자를 구분함 (`Nginx HTTP`)
- **해결**: `sudo ufw allow 'Nginx HTTP'`, 프로필 이름은 `sudo ufw app list`로 확인

### 문제 3. 브라우저 `ERR_CONNECTION_REFUSED`
- **상황**: 노트북 브라우저에서 `127.0.0.1:8080` 접속 거부
- **원인**: VirtualBox에 8080 포트 포워딩 규칙이 없어서 노트북에서 해당 포트를 받는 곳이 없었음 (서버·방화벽 문제 아님)
- **해결**: NAT 포트 포워딩에 `8080 → 80` 추가 후 접속 성공
- **배운 점**: 장애는 **경로 순서대로** 확인 — 서버 내부(`curl localhost`) 정상 → 방화벽 → 호스트 포워딩

### 문제 4. 붙여넣기 관련
- VirtualBox 콘솔 창은 Server 환경에 클립보드 공유가 없어 붙여넣기 불가 → SSH 접속 창에서 작업
- 여러 줄 명령을 붙여넣을 때 `sudo` 비밀번호 프롬프트가 섞임 → 결과 파일을 `cat`으로 확인, 미리 `sudo -v`로 인증해두면 안전

---

## 핵심 명령어 요약
- **`install -d -o 주인 -g 그룹 -m 권한 경로`**: 폴더 생성 + 소유자 + 권한을 한 번에
- **`ln -s 원본 링크`**: 심볼릭 링크 생성 (`sites-available` → `sites-enabled`)
- **`nginx -t`**: Nginx 설정 문법 검사
- **`systemctl reload nginx`**: 접속을 끊지 않고 설정만 다시 읽기
- **`curl -i localhost`**: 응답 헤더까지 포함해 웹 응답 확인
- **`ufw default` / `limit` / `allow` / `enable`**: 방화벽 기본 정책과 규칙
- **`ufw app list`**: 사용할 수 있는 앱 프로필 이름 확인
- **`ss -tlnp`**: 대기 중인 포트와 프로세스 확인

---

## 🇯🇵 오늘의 일본어 엔지니어링
- **단어 1:** **手順書 (てじゅんしょ, 테쥰쇼)** - 작업 절차서 (Runbook)
- **단어 2:** **疎通確認 (そつうかくにん, 소츠-카쿠닌)** - 통신 확인 (Connectivity check)
- **단어 3:** **シンボリックリンク (신보릿쿠링쿠)** - 심볼릭 링크 (Symbolic link)
