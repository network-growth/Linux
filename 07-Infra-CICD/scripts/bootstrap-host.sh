#!/bin/bash
# 새 서버를 Ansible 관리 대상으로 준비하는 스크립트
# 실행 위치: ubuntu-server (runner가 도는 www 계정)
# 사용법: ./bootstrap-host.sh <새 서버 IP> [접속 계정, 기본 www]
#
# 하는 일
#   1. 같은 IP의 예전 호스트 키 정리 (서버를 다시 설치한 경우 대비)
#   2. 새 서버의 호스트 키 등록
#   3. runner 계정의 SSH 공개키를 새 서버에 등록 (비밀번호 1회 입력)
#   4. 비밀번호 없이 접속되는지, Ansible에 필요한 것이 있는지 확인
#   5. inventory.ini에 넣을 줄을 출력 → GitHub에서 PR로 추가하면 자동 배포

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "사용법: $0 <새 서버 IP> [접속 계정]"
    exit 1
fi

HOST_IP="$1"
USER_NAME="${2:-www}"
KEY="$HOME/.ssh/id_ed25519.pub"

if [ ! -f "$KEY" ]; then
    echo "SSH 키가 없습니다: $KEY"
    echo "먼저 실행: ssh-keygen -t ed25519"
    exit 1
fi

echo "[1/4] 예전 호스트 키 정리"
ssh-keygen -R "$HOST_IP" >/dev/null 2>&1 || true

echo "[2/4] 새 서버 호스트 키 등록"
ssh-keyscan -H "$HOST_IP" 2>/dev/null >> "$HOME/.ssh/known_hosts"
ssh-keygen -lf <(ssh-keyscan "$HOST_IP" 2>/dev/null) | head -1

echo "[3/4] 공개키 등록 (새 서버 비밀번호를 한 번 입력)"
ssh-copy-id -i "$KEY" "$USER_NAME@$HOST_IP"

echo "[4/4] 비밀번호 없이 접속 + 필요한 것 확인"
NEW_HOST=$(ssh -o BatchMode=yes "$USER_NAME@$HOST_IP" hostname)
ssh -o BatchMode=yes "$USER_NAME@$HOST_IP" \
    'python3 --version && test -x /usr/bin/sudo.ws && echo "sudo.ws: ok"'

echo
echo "준비 완료: $NEW_HOST ($HOST_IP)"
echo "GitHub에서 07-Infra-CICD/ansible/inventory.ini 의 [web] 아래에 이 줄을 PR로 추가하세요:"
echo
echo "$NEW_HOST ansible_host=$HOST_IP ansible_user=$USER_NAME"
