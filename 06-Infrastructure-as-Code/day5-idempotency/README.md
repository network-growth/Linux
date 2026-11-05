# Day 05 - 멱등성·드리프트 테스트

| 파일 | 역할 |
|---|---|
| `break-server.sh` | 실습용으로 설정 6곳을 일부러 망가뜨림 (드리프트 생성) |

## 망가뜨리는 항목과 복구하는 태스크

| # | 드리프트 | 증상 | 복구 태스크 (`day4-ansible/playbook.yml`) |
|---|---|---|---|
| 1 | 웹 페이지 변조 | `curl localhost` → `hacked` | 페이지 (`template`) |
| 2 | 웹 폴더 권한 777 | `ls -ld /var/www/lab` → `drwxrwxrwx` | 사이트 폴더 (`file`) |
| 3 | default 사이트 다시 켜짐 | `nginx -t` → duplicate default server | 기본 사이트 끄기 (`file: absent`) |
| 4 | 방화벽 HTTP 규칙 삭제 | 노트북 브라우저 접속 불가 | HTTP 허용 (`ufw`) |
| 5 | SSH 비밀번호 로그인 허용 | `sshd -T` → `passwordauthentication yes` | SSH 보안 설정 배치 (`copy`) + 핸들러 |
| 6 | 백업 타이머 꺼짐 | `is-enabled` → `disabled` | 백업 타이머 켜기 (`systemd_service`) |

## 흐름
```bash
sudo bash break-server.sh                          # 드리프트 생성
cd ../day4-ansible
ansible-playbook playbook.yml -K --check --diff    # 탐지
ansible-playbook playbook.yml -K                   # 복구
ansible-playbook playbook.yml -K                   # changed=0 확인
```
