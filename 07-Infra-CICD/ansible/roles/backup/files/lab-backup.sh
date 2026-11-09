#!/bin/bash
# Day 03 - 웹 사이트 + 설정 백업 스크립트
# 위치: /usr/local/sbin/lab-backup.sh
# 실행: lab-backup.service (lab-backup.timer가 매일 실행)

set -euo pipefail

BACKUP_DIR=/var/backups/lab
KEEP=7                                   # 최근 7개만 보관
STAMP=$(date +%Y%m%d-%H%M%S)
FILE="$BACKUP_DIR/lab-$STAMP.tar.gz"

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

# 웹 문서 + Nginx 사이트 설정 + SSH 보안 설정
tar -czf "$FILE" -C / \
    var/www/lab \
    etc/nginx/sites-available/lab \
    etc/ssh/sshd_config.d/10-hardening.conf

# 오래된 백업 정리 (수정 시각 기준 최신순 정렬 후 KEEP개 넘는 것 삭제)
# ls 출력은 파일 이름을 안전하게 다루지 못해서(SC2012) find로 시각과 경로를 함께 뽑아 정렬
find "$BACKUP_DIR" -maxdepth 1 -name 'lab-*.tar.gz' -printf '%T@ %p\n' \
    | sort -rn \
    | tail -n +$((KEEP + 1)) \
    | cut -d' ' -f2- \
    | xargs -r rm --

echo "backup ok: $FILE ($(du -h "$FILE" | cut -f1))"
