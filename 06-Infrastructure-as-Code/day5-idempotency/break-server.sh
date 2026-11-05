#!/bin/bash
# Day 05 - 일부러 서버 설정을 망가뜨려 드리프트(코드와 실제 서버의 차이)를 만드는 스크립트
# 실습용 VM에서만 실행할 것. 복구는 day4-ansible의 플레이북으로 한다.
# 실행: sudo bash break-server.sh

set -uo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "sudo로 실행해 주세요: sudo bash $0"
    exit 1
fi

echo "[1] 웹 페이지 변조"
echo '<h1>hacked</h1>' > /var/www/lab/index.html

echo "[2] 웹 폴더 권한을 777로"
chmod 777 /var/www/lab

echo "[3] 기본(default) 사이트 다시 켜기"
ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

echo "[4] 방화벽에서 HTTP 규칙 삭제"
ufw delete allow 'Nginx HTTP' || true

echo "[5] SSH 비밀번호 로그인 다시 허용"
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/10-hardening.conf
systemctl restart ssh

echo "[6] 백업 타이머 끄기"
systemctl disable --now lab-backup.timer

echo
echo "드리프트 6개 생성 완료. 이제 플레이북으로 탐지(--check --diff)하고 복구해 보세요."
