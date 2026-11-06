# Day 06 - 새 서버 재구축 절차 (Runbook)

빈 Ubuntu Server를 `day4-ansible/playbook.yml` 한 번으로 기존 서버와 같은 상태로 만드는 절차.

## 구성
| 역할 | 호스트 | Host-only IP | 비고 |
|---|---|---|---|
| 제어 노드 | `ubuntu-server` | 192.168.56.101 | Ansible 실행 |
| 관리 대상 | `web02` | 192.168.56.102 | 새로 설치, 손으로 설정하지 않음 |

- VirtualBox 어댑터 1: NAT (인터넷) / 어댑터 2: Host-only (`192.168.56.0/24`, DHCP)

## 1. 새 서버 설치 (web02)
| 설치 화면 | 값 |
|---|---|
| 서버 이름 | `web02` |
| 사용자 | `www` (플레이북의 `web_owner`와 같아야 함) |
| 비밀번호 | 제어 노드와 동일 (`-K` 한 번으로 두 서버 통과) |
| SSH | Install OpenSSH server 체크 |

## 2. 제어 노드 → 대상 SSH 키 등록 (플레이북 실행 전 필수)
플레이북이 비밀번호 로그인을 막기 때문에 **키를 먼저** 등록해야 함.
```bash
ssh-keygen -t ed25519 -C "ansible@ubuntu-server"
ssh-copy-id www@192.168.56.102
ssh www@192.168.56.102 hostname      # 비밀번호 없이 web02
```

## 3. 인벤토리에 추가
```ini
[web]
localhost ansible_connection=local
web02 ansible_host=192.168.56.102 ansible_user=www
```
```bash
ansible web -m ping                  # 두 호스트 모두 pong
```

## 4. 적용과 검증
```bash
ansible-playbook playbook.yml -K --limit web02    # 새 서버에만 적용
curl http://192.168.56.102                         # host: web02
ssh -o PubkeyAuthentication=no www@192.168.56.102  # Permission denied (publickey)
ansible-playbook playbook.yml -K                   # 두 서버 모두 changed=0
```

> 빈 서버에는 `--check`를 쓰지 않음. 패키지 설치 결과에 의존하는 태스크(서비스 실행 등)는 드라이런으로 예측할 수 없어 실패로 표시됨.
