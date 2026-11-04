<img width="847" height="149" alt="image" src="https://github.com/user-attachments/assets/0c0c730a-56c0-4192-9e83-6311636c034b" /># Day 03. systemd timer 자동 백업과 복구 훈련 (2026-11-04)

## 오늘의 목표
- 웹 문서·Nginx 설정·SSH 설정을 **매일 자동으로 백업**하기
- 예전 Crontab 방식 대신 요즘 표준인 **systemd service + timer** 사용하기
- 일부러 파일을 지우고 백업에서 되살려 **복구 가능한 백업인지 검증**하기

---

## 실습 환경
| 항목 | 내용 |
|---|---|
| 서버 | Ubuntu Server 26.04 LTS (VirtualBox, NAT) |
| 결과물 | [`day3-systemd-backup/`](../day3-systemd-backup) — `lab-backup.sh`, `lab-backup.service`, `lab-backup.timer` |
| 백업 위치 | `/var/backups/lab/lab-YYYYMMDD-HHMMSS.tar.gz` (최근 7개 보관) |

### cron과 비교
| | cron | systemd timer |
|---|---|---|
| 실행 기록 | 로그를 직접 만들어야 함 | `journalctl -u`로 자동 기록 |
| 성공/실패 | 확인 어려움 | `systemctl status`로 종료 코드 확인 |
| 서버가 꺼져 있던 시간 | 건너뜀 | `Persistent=true`면 부팅 후 실행 |
| 수동 실행 | 명령을 따로 실행 | `systemctl start`로 예약 실행과 동일하게 실행 |

---

## 실습 기록 상세

### [실습 1] 저장소에서 파일을 받아 서버에 설치
설정을 손으로 붙여넣지 않고, **Git 저장소의 파일을 원본으로** 서버에 설치했습니다.

```bash
git clone https://github.com/network-growth/Linux.git ~/linux
cd ~/linux/06-Infrastructure-as-Code/day3-systemd-backup
sudo install -o root -g root -m 755 lab-backup.sh /usr/local/sbin/lab-backup.sh
sudo install -o root -g root -m 644 lab-backup.service lab-backup.timer /etc/systemd/system/
sudo systemctl daemon-reload
```

| 파일 | 역할 | 설치 위치 |
|---|---|---|
| `lab-backup.sh` | 실제 백업 작업 (`tar.gz` 생성 + 7개 초과분 삭제) | `/usr/local/sbin/` |
| `lab-backup.service` | 스크립트를 한 번 실행 (`Type=oneshot`) | `/etc/systemd/system/` |
| `lab-backup.timer` | 매일 03:00 실행 (`RandomizedDelaySec=10min`, `Persistent=true`) | `/etc/systemd/system/` |

### [실습 2] 수동 실행으로 동작 확인
```bash
sudo systemctl start lab-backup.service
systemctl status lab-backup.service --no-pager
journalctl -u lab-backup --no-pager
sudo ls -lh /var/backups/lab
```
- `status=0/SUCCESS` — oneshot 서비스는 끝나면 `inactive (dead)`가 정상
- `journalctl`에 `backup ok: ... (4.0K)` 기록

<img width="986" height="275" alt="image" src="https://github.com/user-attachments/assets/fda71366-bf84-49fa-8982-90c3cd8122d1" />

<img width="1291" height="808" alt="image" src="https://github.com/user-attachments/assets/bf6ebb67-110d-4b71-83a1-57876ce09034" />

<img width="957" height="80" alt="image" src="https://github.com/user-attachments/assets/7d23b01b-a906-4eb5-8f9d-6f6e7c8258ee" />

```bash
sudo tar -tzf /var/backups/lab/lab-20261104-131539.tar.gz
```
백업 안에 `var/www/lab/index.html`, `etc/nginx/sites-available/lab`, `etc/ssh/sshd_config.d/10-hardening.conf` 포함 확인.

<img width="1161" height="125" alt="image" src="https://github.com/user-attachments/assets/b89171ce-0ce8-47ab-be94-073b58dac966" />

### [실습 3] 타이머 활성화
```bash
sudo systemctl enable --now lab-backup.timer
systemctl list-timers lab-backup.timer --no-pager
systemd-analyze calendar "*-*-* 03:00:00"
```

<img width="994" height="121" alt="image" src="https://github.com/user-attachments/assets/3b1691f0-54f3-446d-a190-d42c9328eea1" />

<img width="972" height="133" alt="image" src="https://github.com/user-attachments/assets/51954840-4b15-4259-bc99-2291c9c23b33" />

### [실습 4] 복구 훈련
웹 페이지를 일부러 삭제하고, 최신 백업에서 **그 파일만** 원래 위치로 복구했습니다.

```bash
rm /var/www/lab/index.html
curl -I localhost                 # 403 Forbidden

sudo sh -c 'tar -xzf $(ls -1t /var/backups/lab/*.tar.gz | head -1) -C / var/www/lab/index.html'
ls -l /var/www/lab/index.html     # www www 59, 수정 시각 11:09 그대로
curl -i localhost                 # 200 OK
```
tar가 소유자·권한·수정 시각까지 저장하기 때문에 파일이 **원래 상태 그대로** 돌아온 것을 확인했습니다.

<img width="771" height="115" alt="image" src="https://github.com/user-attachments/assets/6bbbf31d-a91b-437f-9777-277969c4f6ff" />

<img width="824" height="38" alt="image" src="https://github.com/user-attachments/assets/89211060-24a1-4f51-9a88-d5766cb854e8" />

<img width="741" height="211" alt="image" src="https://github.com/user-attachments/assets/6c89bf31-0eab-48b3-a4c3-1eaaad2159c0" />

### [실습 5] 보관 개수(7개) 확인
```bash
sudo systemctl reset-failed lab-backup.service
for i in $(seq 8); do sudo systemctl start lab-backup.service; sleep 3; done
sudo ls -1t /var/backups/lab
sudo ls /var/backups/lab | wc -l   # 7
```
기존 1개 + 8개 생성 = 9개 중 오래된 2개가 자동 삭제되어 **최근 7개만 유지**됨 (가장 오래된 `131539` 삭제 확인).

<img width="825" height="149" alt="image" src="https://github.com/user-attachments/assets/388252f2-3aa5-416d-a536-a3cf18c83ffe" />

<img width="897" height="37" alt="image" src="https://github.com/user-attachments/assets/49c60c2b-2516-4145-aed8-6c680a7868a9" />

---

## Troubleshooting (장애 대응 기록)

### 문제 1. 백업 반복 실행 시 `start of the service was attempted too often`
- **상황**: 반복문으로 백업 서비스를 연속 실행하자 빨간 오류와 함께 실행이 거부됨
- **원인**: systemd는 기본적으로 **10초 안에 5번 넘게 시작되는 서비스를 차단**함 (`StartLimitIntervalSec=10s`, `StartLimitBurst=5`). 장애 난 서비스가 무한 재시작하며 서버를 망가뜨리는 것을 막는 안전장치. 처음엔 `sleep1`(띄어쓰기 누락)로 대기 없이 실행됐고, `sleep 1`도 이 제한을 넘음
- **해결**: `systemctl reset-failed lab-backup.service`로 차단 해제 후 `sleep 3` 간격으로 실행
- **배운 점**: systemd의 시작 횟수 제한 동작과 `reset-failed`의 의미

### 문제 2. 복구 확인 시 `No such file or directory`
- **상황**: `ls -l var/www/lab/index.html` 실행 시 파일이 없다고 나옴
- **원인**: 맨 앞 `/`가 빠져 **현재 폴더 기준(상대 경로)** 으로 찾음. tar 명령 안에서는 `/` 없이 쓰지만(아카이브 내부 경로), 일반 경로는 `/`부터 시작해야 함
- **해결**: `/var/www/lab/index.html`로 확인 → 실제로 아직 복구 전이었음을 확인하고 복구 진행

### 문제 3. 진행 상황 파악
- **상황**: 단계가 많아 어디까지 했는지 헷갈림
- **해결**: 점검 항목을 한 번에 출력하는 확인 블록(✅/❌)으로 상태 점검 → 복구 단계만 남은 것을 확인
- **배운 점**: 현재 상태를 명령으로 확인하는 습관. 이 점검 항목이 Day 05 멱등성·드리프트 확인의 기초가 됨

---

## 핵심 명령어 요약
- **`install -o -g -m 원본 대상`**: 파일 복사 + 소유자·권한 지정
- **`systemctl daemon-reload`**: 새 유닛 파일 인식
- **`systemctl start <service>`**: 수동 실행 (예약 실행과 동일)
- **`systemctl enable --now <timer>`**: 타이머 활성화 + 즉시 시작
- **`systemctl list-timers`**: 다음 실행 예정 시각 확인
- **`systemd-analyze calendar "<표현식>"`**: 시간 표현식 검증
- **`systemctl reset-failed <service>`**: 시작 횟수 제한 해제
- **`tar -czf` / `tar -tzf` / `tar -xzf ... -C / <경로>`**: 백업 생성 / 내용 확인 / 특정 파일만 복구

