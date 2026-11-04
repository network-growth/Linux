# Day 02 수동 구성 절차 (Ansible 코드화 원본)

Day 04에서 이 순서를 그대로 Ansible 작업(task)으로 옮긴다.

| # | 수동 명령 | 결과 상태 | Ansible 모듈 (Day 04) |
|---|---|---|---|
| 1 | `apt install -y nginx ufw` | 패키지 설치됨 | `ansible.builtin.apt` |
| 2 | `install -d -o www -g www -m 755 /var/www/lab` | 폴더 존재, 주인 `www`, 권한 755 | `ansible.builtin.file` |
| 3 | `printf ... > /var/www/lab/index.html` | 페이지 파일 존재 | `ansible.builtin.template` |
| 4 | `tee /etc/nginx/sites-available/lab` | 사이트 설정 존재 | `ansible.builtin.copy` |
| 5 | `rm /etc/nginx/sites-enabled/default` | 기본 사이트 꺼짐 | `ansible.builtin.file` (`state: absent`) |
| 6 | `ln -s .../sites-available/lab .../sites-enabled/lab` | 내 사이트 켜짐 | `ansible.builtin.file` (`state: link`) |
| 7 | `nginx -t && systemctl reload nginx` | 설정 반영 | `handlers` |
| 8 | `ufw default deny incoming` / `allow outgoing` | 기본 정책 | `community.general.ufw` |
| 9 | `ufw limit OpenSSH` | SSH 허용 + 접속 횟수 제한 | `community.general.ufw` |
| 10 | `ufw allow 'Nginx HTTP'` | 80번 허용 | `community.general.ufw` |
| 11 | `ufw enable` | 방화벽 켜짐 | `community.general.ufw` |

## 명령어 원본

```bash
# 1. 패키지
sudo apt update
sudo apt install -y nginx ufw

# 2~3. 사이트 폴더와 페이지
sudo install -d -o www -g www -m 755 /var/www/lab
printf '<h1>Iac - manual setup</h1>\n<p>built by hand on Day 02</p>\n' > /var/www/lab/index.html

# 4. 사이트 설정 (내용은 이 폴더의 lab 파일)
sudo tee /etc/nginx/sites-available/lab > /dev/null < lab

# 5~6. 기본 사이트 끄고 내 사이트 켜기
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/lab /etc/nginx/sites-enabled/lab

# 7. 검사 후 반영
sudo nginx -t && sudo systemctl reload nginx

# 8~11. 방화벽 (SSH 허용을 enable보다 먼저)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw limit OpenSSH
sudo ufw allow 'Nginx HTTP'
sudo ufw enable
```

## 호스트(VirtualBox) 쪽 설정

코드로 관리하지 않는 부분. VM 설정 → 네트워크 → 어댑터 1(NAT) → 포트 포워딩

| 이름 | 호스트 IP | 호스트 포트 | 게스트 포트 |
|---|---|---|---|
| ssh | 127.0.0.1 | 2222 | 22 |
| http | 127.0.0.1 | 8080 | 80 |
