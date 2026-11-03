# Day 07. 쉘 스크립트 기초 및 자동화 (2026-02-13)

## 오늘의 목표
- 여러 명령어를 하나의 파일로 만들어 실행하는 '자동화 스크립트' 작성하기

---

## 실습 기록 상세

### [실습 1] 첫 번째 쉘 스크립트 작성
`vi` 에디터를 사용하여 `backup.sh` 파일을 생성했습니다. 텍스트 출력(`echo`), 날짜 확인(`date`), 폴더 생성(`mkdir`), 복사(`cp`) 명령어를 순서대로 배치했습니다.
<img width="1279" height="802" alt="vi " src="https://github.com/user-attachments/assets/c99b1bc0-ab0e-41bc-83e3-88c086c1cbc4" />

### [실습 2] 실행 권한 부여 및 테스트
처음 생성된 파일은 실행 권한이 없으므로 `chmod +x`를 통해 실행 권한을 부여했습니다. 이후 `./backup.sh`를 실행하여 단 한 번의 명령으로 폴더 생성부터 파일 복사까지 완료되는 것을 확인했습니다.
<img width="1277" height="797" alt="chmod" src="https://github.com/user-attachments/assets/040eb6e9-a487-400d-974b-3c3c17618933" />
<img width="1278" height="796" alt="실행" src="https://github.com/user-attachments/assets/538522d0-1035-4f44-be49-2e7dc5c6930d" />

---

## 핵심 개념 요약
- **`#!/bin/bash`**: "이 파일은 bash 쉘로 실행해라"라는 선언 (Shebang)
- **`chmod +x [파일명]`**: 일반 파일을 '실행 가능한 프로그램'으로 변환
- **`./[파일명]`**: 현재 폴더에 있는 스크립트를 실행
- **변수 및 환경**: 리눅스 명령어를 조합하여 업무 효율을 높이는 방법

---

## 🇯🇵 오늘의 일본어 엔지니어링
- **단어 1:** **自動化 (じどうか, 지도-카)** - 자동화
