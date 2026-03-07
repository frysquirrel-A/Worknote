from __future__ import annotations

import html
import json
import sys
from pathlib import Path


ENTRIES = [
    {
        "step": 1,
        "name": "step_01_home_root",
        "title": "앱 시작 스플래시",
        "section": "Unknown",
        "action": "앱 강제 종료 후 메인 액티비티 재실행",
        "summary": "브랜드 로고와 로딩 인디케이터가 보이는 초기 스플래시 상태다.",
        "features": [
            "앱 기동 직후 로딩 상태 표시",
            "브랜드 컬러 기반 다크 배경",
            "아직 상호작용 가능한 내부 UI는 없음",
        ],
        "concept": "딥 네이비 기반 프리미엄 다크 시작 화면으로 진입 무드를 통일한다.",
        "docs": [
            ("AGENTS.md", "../../AGENTS.md", "UI / UX Defaults: premium dark direction"),
            ("ARCHITECTURE.md", "../../ARCHITECTURE.md", "Product Identity / release readiness 문맥"),
        ],
        "code_paths": ["lib/main.dart", "lib/app/bootstrap.dart"],
        "ui_type": "내부 UI",
        "notes": "정상 로딩 장면이며, 잠시 후 홈으로 전환된다.",
    },
    {
        "step": 2,
        "name": "step_02_home_ready",
        "title": "홈 루트",
        "section": "Home",
        "action": "로딩 안정화 대기",
        "summary": "인사 영역, 현재 팀 카드, 팀원 목록, 프로젝트 현황, 오늘 할일 섹션이 한 화면에 모인 대시보드다.",
        "features": [
            "현재 날짜 표시",
            "현재 팀 전환 카드",
            "가로 팀원 목록",
            "프로젝트 진행률 카드",
            "오늘 할일 섹션",
            "하단 6탭 네비게이션",
        ],
        "concept": "정보 밀도를 유지하되 상단 셸은 다크, 본문 카드는 밝은 표면을 섞는 대시보드형 홈이다.",
        "docs": [
            ("PROJECT_MAP.md", "../../PROJECT_MAP.md", "Modules > Home"),
            ("ARCHITECTURE.md", "../../ARCHITECTURE.md", "1. Product Identity / 4.2 Team/Group"),
            ("AGENTS.md", "../../AGENTS.md", "premium dark additive direction"),
        ],
        "code_paths": ["lib/features/home/ui/home_tab.dart", "lib/app/main_shell.dart"],
        "ui_type": "내부 UI",
        "notes": "상단은 다크, 본문은 밝은 카드가 남아 있어 메신저 대비 톤 차이가 아직 느껴진다.",
    },
    {
        "step": 3,
        "name": "step_03_drawer_opened",
        "title": "드로어 열림",
        "section": "Home",
        "action": "좌상단 햄버거 버튼 탭",
        "summary": "프로필/팀 관리, 팀 목록, 의견 보내기, 위험 구역 액션을 포함한 사이드 드로어다.",
        "features": [
            "프로필 헤더",
            "팀 관리",
            "구글 드라이브 연동",
            "프로필 관리/전환",
            "테마 설정",
            "팀 목록",
            "의견 보내기",
            "앱 초기화",
            "로그아웃",
        ],
        "concept": "관리 액션과 위험 액션을 상하로 분리하는 운영 패널 구조다.",
        "docs": [
            ("PROJECT_MAP.md", "../../PROJECT_MAP.md", "Drawer entry point / reset tools"),
            ("AGENTS.md", "../../AGENTS.md", "Dangerous Actions"),
            ("AI_CHECKLIST.md", "../../AI_CHECKLIST.md", "UI Regression Safety / dangerous actions adjacency"),
        ],
        "code_paths": ["lib/app/widgets/master_drawer.dart"],
        "ui_type": "내부 UI",
        "notes": "위험 액션이 하단으로 분리돼 있지만, 현재 설치본은 아직 밝은 배경 드로어로 보인다.",
    },
    {
        "step": 5,
        "name": "step_05_tasks_root",
        "title": "할일 루트",
        "section": "Tasks",
        "action": "하단 탭에서 할일 선택",
        "summary": "상단 필터/정렬 제어부와 일정 기준으로 묶인 카드 목록, 하단 업무 추가 CTA가 보인다.",
        "features": [
            "프로젝트/묶음/정렬 필터",
            "날짜 그룹 헤더",
            "작업 카드 목록",
            "카드 내 달력 버튼",
            "하단 + 업무 추가 버튼",
        ],
        "concept": "카드 정보 밀도를 유지하는 생산성 목록 화면이며, 상단 제어부는 구조적으로 촘촘한 편이다.",
        "docs": [
            ("PROJECT_MAP.md", "../../PROJECT_MAP.md", "Modules > Tasks"),
            ("ARCHITECTURE.md", "../../ARCHITECTURE.md", "4.3 Tasks"),
            ("AI_CHECKLIST.md", "../../AI_CHECKLIST.md", "6. UI Regression Safety"),
        ],
        "code_paths": [
            "lib/features/tasks/ui/task_tab.dart",
            "lib/features/tasks/ui/widgets/task_filter_bar.dart",
        ],
        "ui_type": "내부 UI",
        "notes": "보호 카드 파일은 손대지 않았고, 카드 디자인은 기존 사용자 커스텀을 따른다.",
    },
    {
        "step": 6,
        "name": "step_06_tasks_add_form",
        "title": "업무 등록 폼",
        "section": "Tasks",
        "action": "하단 + 업무 추가 버튼 탭",
        "summary": "업무 제목, 담당자, 프로젝트, 기한, 중요도, 계획 토글, 저장 CTA로 구성된 등록 시트다.",
        "features": [
            "제목 입력",
            "담당자 선택",
            "프로젝트 선택",
            "기한 선택",
            "중요도 선택",
            "계획 표시 토글",
            "저장 버튼",
        ],
        "concept": "빠른 등록 중심의 하단 시트이며, 핵심 필드를 먼저 노출하는 입력 밀도형 폼이다.",
        "docs": [
            ("AGENTS.md", "../../AGENTS.md", "Prefer hintText over labelText"),
            ("ARCHITECTURE.md", "../../ARCHITECTURE.md", "4.3 Tasks"),
            ("AI_CHECKLIST.md", "../../AI_CHECKLIST.md", "11. Responsive UI Safety"),
        ],
        "code_paths": ["lib/features/tasks/ui/sheets/add_task_sheet.dart"],
        "ui_type": "내부 UI",
        "notes": "시트 기반이라 본문을 유지한 채 빠르게 추가하는 흐름이다.",
    },
    {
        "step": 8,
        "name": "step_08_schedule_root",
        "title": "일정 루트",
        "section": "Schedule",
        "action": "하단 탭에서 일정 선택",
        "summary": "검색, 전체 팀 일정 토글, 월간 캘린더, 우하단 계획 추가 CTA가 보이는 다크 캘린더 화면이다.",
        "features": [
            "계획 검색",
            "전체 팀 일정 보기",
            "월간 캘린더",
            "이전/다음 달 화살표",
            "오늘 버튼",
            "계획 추가 CTA",
        ],
        "concept": "메신저와 가장 가까운 프리미엄 다크 톤으로 일정 정보를 캘린더 보드에 압축한 화면이다.",
        "docs": [
            ("PROJECT_MAP.md", "../../PROJECT_MAP.md", "Modules > Schedule"),
            ("ARCHITECTURE.md", "../../ARCHITECTURE.md", "4.4 Schedule"),
            ("docs/ui_catalog_static_2026-03-07.md", "../../docs/ui_catalog_static_2026-03-07.md", "Schedule 정적 구조 메모"),
        ],
        "code_paths": ["lib/features/schedule/ui/schedule_tab.dart"],
        "ui_type": "내부 UI",
        "notes": "현재 설치본 기준으로 월 이동 hitbox는 실제로 누르기 편한 편이다.",
    },
    {
        "step": 9,
        "name": "step_09_schedule_next_month",
        "title": "일정 다음 달 이동",
        "section": "Schedule",
        "action": "다음 달 화살표 버튼 탭",
        "summary": "2026년 04월로 전환된 캘린더 상태다. 월 이동이 실제 전환으로 확인된다.",
        "features": [
            "월간 캘린더 전환",
            "이전/다음 달 이동",
            "월 제목 갱신",
        ],
        "concept": "캘린더 내비게이션의 터치 편의성과 반응성을 검증하는 장면이다.",
        "docs": [
            ("ARCHITECTURE.md", "../../ARCHITECTURE.md", "4.4 Schedule"),
            ("AI_CHECKLIST.md", "../../AI_CHECKLIST.md", "11. Responsive UI Safety"),
            ("PATCHLOG.md", "../../PATCHLOG.md", "v2 이후 일정/상태 유지 관련 문맥"),
        ],
        "code_paths": ["lib/features/schedule/ui/schedule_tab.dart"],
        "ui_type": "내부 UI",
        "notes": "이전 보고에서 지적된 월 이동 hitbox 문제는 현재 설치본에서는 재현되지 않았다.",
    },
    {
        "step": 10,
        "name": "step_10_journal_root",
        "title": "일지 루트",
        "section": "Journal",
        "action": "하단 탭에서 일지 선택",
        "summary": "검색창, 카테고리 칩, 리스트/전체 탭, 날짜 그룹, 카드형 일지, 하단 일지작성 CTA가 보인다.",
        "features": [
            "검색",
            "카테고리 칩",
            "일별/전체 리스트 전환",
            "날짜 그룹",
            "일지 카드",
            "+ 일지작성 버튼",
        ],
        "concept": "피드형 일지 아카이브에 필터와 작성 CTA를 결합한 작업 기록 허브다.",
        "docs": [
            ("PROJECT_MAP.md", "../../PROJECT_MAP.md", "Modules > Journal"),
            ("ARCHITECTURE.md", "../../ARCHITECTURE.md", "4.5 Journal"),
            ("AI_CHECKLIST.md", "../../AI_CHECKLIST.md", "6. UI Regression Safety"),
        ],
        "code_paths": ["lib/features/journal/ui/journal_tab.dart"],
        "ui_type": "내부 UI",
        "notes": "다크 셸과 카드 톤의 대비가 아직 강하다.",
    },
    {
        "step": 11,
        "name": "step_11_journal_write_form",
        "title": "일지 작성 폼",
        "section": "Journal",
        "action": "하단 + 일지작성 버튼 탭",
        "summary": "유형 선택, 제목, 관련 업무/프로젝트, 비공개 토글, 사진 추가, 본문 입력, 저장 버튼을 담은 작성 시트다.",
        "features": [
            "일반/진행/보고서 유형 탭",
            "제목 입력",
            "관련 업무/프로젝트 선택",
            "비공개 토글",
            "사진 추가",
            "본문 입력",
            "저장하기 버튼",
        ],
        "concept": "현장 기록과 보고 흐름을 하나의 시트에서 빠르게 처리하는 작성 전용 화면이다.",
        "docs": [
            ("AGENTS.md", "../../AGENTS.md", "Prefer hintText over labelText"),
            ("ARCHITECTURE.md", "../../ARCHITECTURE.md", "4.5 Journal"),
            ("AI_CHECKLIST.md", "../../AI_CHECKLIST.md", "11. Responsive UI Safety"),
        ],
        "code_paths": ["lib/features/journal/ui/sheets/journal_write_sheet.dart"],
        "ui_type": "내부 UI",
        "notes": "입력 밀도가 높지만, 작성/첨부/비공개 제어가 한 곳에 모여 있다.",
    },
    {
        "step": 12,
        "name": "step_12_gallery_root",
        "title": "갤러리 루트",
        "section": "Gallery",
        "action": "하단 탭에서 갤러리 선택",
        "summary": "날짜 그룹별로 사진 썸네일을 모아 보여 주는 전체 갤러리 화면이다.",
        "features": [
            "날짜 그룹",
            "사진 썸네일",
            "우하단 카메라/FAB",
        ],
        "concept": "저널과 채팅에서 파생된 이미지를 가볍게 훑는 미디어 인덱스 화면이다.",
        "docs": [
            ("PROJECT_MAP.md", "../../PROJECT_MAP.md", "Modules > Gallery"),
            ("ARCHITECTURE.md", "../../ARCHITECTURE.md", "4.6 Gallery"),
            ("AI_CHECKLIST.md", "../../AI_CHECKLIST.md", "6. UI Regression Safety"),
        ],
        "code_paths": ["lib/features/gallery/ui/gallery_tab.dart"],
        "ui_type": "내부 UI",
        "notes": "루트 화면만 보면 밝은 본문과 다크 셸의 대비가 남아 있다. 소스상 FAB는 일지 작성 플로우로 연결되도록 패치됐다.",
    },
    {
        "step": 13,
        "name": "step_13_messenger_root",
        "title": "메신저 루트",
        "section": "Messenger",
        "action": "하단 탭에서 채팅 선택",
        "summary": "스레드 선택 헤더, 빈 대화 empty state, 하단 메시지 입력창이 있는 메신저 기본 화면이다.",
        "features": [
            "대화 상대 선택 드롭다운",
            "빈 상태 안내",
            "메시지 입력창",
            "전송 버튼",
        ],
        "concept": "프리미엄 다크 방향이 가장 강하게 구현된 기준 화면이다.",
        "docs": [
            ("PROJECT_MAP.md", "../../PROJECT_MAP.md", "Modules > Messenger"),
            ("ARCHITECTURE.md", "../../ARCHITECTURE.md", "4.7 Messenger"),
            ("AI_CHECKLIST.md", "../../AI_CHECKLIST.md", "7. Messenger Safety"),
            ("PATCHLOG.md", "../../PATCHLOG.md", "v2 Patch Package"),
        ],
        "code_paths": ["lib/features/chat/ui/messenger_tab.dart"],
        "ui_type": "내부 UI",
        "notes": "다른 탭보다 완성도가 높아 전체 디자인 기준점 역할을 한다.",
    },
    {
        "step": 14,
        "name": "step_14_messenger_thread_selector",
        "title": "메신저 대화 상대 선택 시트",
        "section": "Messenger",
        "action": "상단 대화 선택 바 탭",
        "summary": "전체 방(팀 채팅)과 1:1 대화 상대 목록을 한 시트에서 고르는 바텀 시트다.",
        "features": [
            "팀 채팅 목록",
            "1:1 상대 목록",
            "바텀 시트 핸들",
        ],
        "concept": "팀 채팅과 DM을 같은 진입점에서 전환하는 대화 스코프 선택 시트다.",
        "docs": [
            ("PROJECT_MAP.md", "../../PROJECT_MAP.md", "ChatProvider / Threads group + DM"),
            ("ARCHITECTURE.md", "../../ARCHITECTURE.md", "4.7 Messenger"),
            ("AI_CHECKLIST.md", "../../AI_CHECKLIST.md", "7. Messenger Safety"),
        ],
        "code_paths": [
            "lib/features/chat/ui/messenger_tab.dart",
            "lib/features/chat/state/chat_provider.dart",
        ],
        "ui_type": "내부 UI",
        "notes": "외부 인증 없이 내부 스레드 범위를 안전하게 전환할 수 있다.",
    },
    {
        "step": 16,
        "name": "step_16_feedback_page",
        "title": "의견 보내기 화면",
        "section": "Unknown",
        "action": "드로어에서 의견 보내기 선택",
        "summary": "문의 유형 칩, 내용 입력 영역, 의견 보내기 CTA로 구성된 피드백 제출 화면이다.",
        "features": [
            "문의 유형 선택",
            "내용 입력 영역",
            "의견 보내기 버튼",
        ],
        "concept": "빠르게 피드백을 수집하는 단일 목적 폼이다.",
        "docs": [
            ("RELEASE_CHECKLIST.md", "../../RELEASE_CHECKLIST.md", "Feedback submit to Firestore smoke test"),
            ("AGENTS.md", "../../AGENTS.md", "SnackBar / premium dark direction"),
            ("AI_CHECKLIST.md", "../../AI_CHECKLIST.md", "6. UI Regression Safety"),
        ],
        "code_paths": ["lib/features/settings/ui/feedback_page.dart"],
        "ui_type": "내부 UI",
        "notes": "현재 설치본 기준으로는 아직 밝은 레거시 톤이 남아 있어, 소스 패치 결과와 시각 불일치 가능성이 있다.",
    },
]

WARNINGS = [
    "에뮬레이터 현재 설치본 기준 보고서다. 최신 debug APK 재설치는 저장공간 부족(INSTALL_FAILED_INSUFFICIENT_STORAGE)으로 수행하지 못했다.",
    "따라서 일부 화면은 현재 저장소 소스와 100% 일치하지 않을 수 있다.",
    "자동 좌표 검증 중 생성된 비의미 캡처(step_04, step_07, step_15)는 본문에서 제외했다.",
]

UNSAFE_AVOIDED = [
    "구글 로그인/계정 선택기/브라우저 인증 진입 회피",
    "앱 초기화/로그아웃/삭제/결제/외부 업로드 흐름 미진입",
    "업무/일지 생성 폼은 열기까지만 수행하고 저장하지 않음",
]

BLOCKERS = [
    "에뮬레이터 저장공간 부족으로 최신 APK를 재설치하지 못함",
    "따라서 런타임 화면과 저장소 최신 코드 간 시각 차이가 남을 수 있음",
]

EXCLUDED_STEPS = [
    "step_04_tasks_root",
    "step_07_schedule_root",
    "step_15_feedback_page",
]

SECTIONS_ORDER = [
    "Home",
    "Tasks",
    "Schedule",
    "Journal",
    "Gallery",
    "Messenger",
    "External/Auth",
    "Error/ANR",
    "Unknown",
]

SECTION_TITLES = {
    "Home": "Home",
    "Tasks": "Tasks",
    "Schedule": "Schedule",
    "Journal": "Journal",
    "Gallery": "Gallery",
    "Messenger": "Messenger",
    "External/Auth": "External/Auth",
    "Error/ANR": "Error/ANR",
    "Unknown": "Unknown / Settings",
}


def build_notes(session_name: str) -> str:
    lines = [
        f"세션: {session_name}",
        "기준: 현재 에뮬레이터 설치본 런타임 화면",
        "",
        "[중요 경고]",
    ]
    lines.extend(f"- {item}" for item in WARNINGS)
    lines.extend(
        [
            "",
            "[검수 범위]",
            "- Home 루트",
            "- Drawer",
            "- Tasks 루트 / 업무 등록 폼",
            "- Schedule 루트 / 다음 달 이동",
            "- Journal 루트 / 일지 작성 폼",
            "- Gallery 루트",
            "- Messenger 루트 / 대화 상대 선택 시트",
            "- 의견 보내기 화면",
            "",
            "[회피한 흐름]",
        ]
    )
    lines.extend(f"- {item}" for item in UNSAFE_AVOIDED)
    lines.extend(
        [
            "",
            "[핵심 관찰]",
            "- 메신저가 가장 완성된 프리미엄 다크 기준점이다.",
            "- 홈/할일/일지/갤러리는 다크 셸과 밝은 카드가 섞여 있어 톤 차이가 남는다.",
            "- 피드백 페이지는 현재 설치본 기준으로 밝은 레거시 톤이다.",
            "- 일정 탭의 월 이동은 실제로 다음 달 전환이 확인됐다.",
            "",
            "[제외한 캡처]",
        ]
    )
    lines.extend(f"- {item}" for item in EXCLUDED_STEPS)
    return "\n".join(lines)


def build_html(session_name: str) -> str:
    sections: dict[str, list[dict[str, object]]] = {key: [] for key in SECTIONS_ORDER}
    for entry in ENTRIES:
        sections[entry["section"]].append(entry)

    section_html: list[str] = []
    for section in SECTIONS_ORDER:
        cards: list[str] = []
        for entry in sections[section]:
            docs_html = "".join(
                f"<li><a href=\"{html.escape(href)}\">{html.escape(name)}</a> - {html.escape(desc)}</li>"
                for name, href, desc in entry["docs"]
            )
            code_html = "".join(
                f"<li>{html.escape(path)}</li>" for path in entry["code_paths"]
            )
            features_html = "".join(
                f"<li>{html.escape(item)}</li>" for item in entry["features"]
            )
            cards.append(
                f"""
        <article class="card">
          <div class="thumb-wrap">
            <a href="{entry['name']}.png"><img src="{entry['name']}.png" alt="{html.escape(entry['title'])}"></a>
          </div>
          <div class="meta">
            <h3>{entry['step']:02d}. {html.escape(entry['title'])}</h3>
            <p class="line"><strong>직전 액션:</strong> {html.escape(entry['action'])}</p>
            <p class="line"><strong>화면 요약:</strong> {html.escape(entry['summary'])}</p>
            <p class="line"><strong>UI 분류:</strong> {html.escape(entry['ui_type'])}</p>
            <p class="line"><strong>디자인 컨셉:</strong> {html.escape(entry['concept'])}</p>
            <div class="split">
              <div>
                <h4>보이는 기능</h4>
                <ul>{features_html}</ul>
              </div>
              <div>
                <h4>문서 근거</h4>
                <ul>{docs_html}</ul>
              </div>
            </div>
            <div class="split">
              <div>
                <h4>연결 코드</h4>
                <ul>{code_html}</ul>
              </div>
              <div>
                <h4>검수 메모</h4>
                <p>{html.escape(entry['notes'])}</p>
              </div>
            </div>
            <p class="links"><a href="{entry['name']}.png">원본 PNG</a> · <a href="{entry['name']}.xml">원본 XML</a></p>
          </div>
        </article>
        """
            )
        if cards:
            section_html.append(
                f"<section class='section'><h2>{SECTION_TITLES[section]}</h2>{''.join(cards)}</section>"
            )
        else:
            section_html.append(
                f"<section class='section empty'><h2>{SECTION_TITLES[section]}</h2><p>이번 세션에서 포함한 화면이 없습니다.</p></section>"
            )

    warnings_html = "".join(f"<li>{html.escape(item)}</li>" for item in WARNINGS)
    avoided_html = "".join(f"<li>{html.escape(item)}</li>" for item in UNSAFE_AVOIDED)
    blockers_html = "".join(f"<li>{html.escape(item)}</li>" for item in BLOCKERS)

    return f"""<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <title>WorkNote 런타임 UI 검수 보고서</title>
  <style>
    :root {{ color-scheme: dark; --bg:#061121; --panel:#0d1a32; --border:#22324d; --text:#eef4ff; --muted:#9fb2d1; --accent:#5b8cff; --warn:#ffb95b; }}
    * {{ box-sizing: border-box; }}
    body {{ margin: 0; font-family: "Segoe UI", sans-serif; background: linear-gradient(180deg, #061121, #09172b); color: var(--text); }}
    .wrap {{ max-width: 1280px; margin: 0 auto; padding: 32px 20px 64px; }}
    .hero {{ background: linear-gradient(180deg, #122347, #061121); border: 1px solid var(--border); border-radius: 24px; padding: 24px; box-shadow: 0 20px 40px rgba(0,0,0,.28); }}
    .hero h1 {{ margin: 0 0 8px; font-size: 30px; }}
    .hero p {{ margin: 4px 0; color: var(--muted); }}
    .pill {{ display: inline-block; margin-top: 10px; padding: 8px 12px; background: rgba(91,140,255,.16); border: 1px solid rgba(91,140,255,.35); border-radius: 999px; color: #dbe6ff; }}
    .grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 16px; margin-top: 20px; }}
    .panel {{ background: rgba(13,26,50,.92); border: 1px solid var(--border); border-radius: 20px; padding: 18px; }}
    h2 {{ margin: 28px 0 14px; font-size: 24px; }}
    h3 {{ margin: 0 0 10px; font-size: 20px; }}
    h4 {{ margin: 0 0 8px; font-size: 15px; color: #cfe0ff; }}
    ul {{ margin: 0; padding-left: 18px; }}
    li {{ margin: 4px 0; color: var(--muted); }}
    .section {{ margin-top: 30px; }}
    .card {{ display: grid; grid-template-columns: minmax(260px, 340px) 1fr; gap: 18px; padding: 18px; border-radius: 22px; border: 1px solid var(--border); background: rgba(13,26,50,.86); margin-bottom: 18px; }}
    .empty {{ opacity: .75; }}
    .thumb-wrap {{ background: #09172b; border-radius: 18px; overflow: hidden; border: 1px solid rgba(255,255,255,.05); align-self: start; }}
    .thumb-wrap img {{ display: block; width: 100%; height: auto; }}
    .meta .line {{ margin: 6px 0; color: var(--muted); }}
    .split {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 16px; margin-top: 14px; }}
    .links {{ margin-top: 16px; }}
    a {{ color: #9cc2ff; text-decoration: none; }}
    a:hover {{ text-decoration: underline; }}
    .warn li {{ color: #ffd6a3; }}
    @media (max-width: 900px) {{ .card {{ grid-template-columns: 1fr; }} }}
  </style>
</head>
<body>
  <div class="wrap">
    <section class="hero">
      <h1>WorkNote 런타임 UI 검수 보고서</h1>
      <p>세션: {html.escape(session_name)}</p>
      <p>기준: 현재 에뮬레이터 설치본 런타임 화면</p>
      <p>포함 화면: {len(ENTRIES)}개 / 포함 영역: Home, Tasks, Schedule, Journal, Gallery, Messenger, Unknown</p>
      <div class="pill">최신 debug APK 재설치 실패: INSTALL_FAILED_INSUFFICIENT_STORAGE</div>
      <div class="grid">
        <div class="panel warn">
          <h3>경고</h3>
          <ul>{warnings_html}</ul>
        </div>
        <div class="panel">
          <h3>권장 수동 확인</h3>
          <ul>
            <li>최신 APK를 다시 설치한 뒤 동일 화면을 한 번 더 재검수</li>
            <li>피드백 페이지가 실제로 다크 테마로 반영됐는지 재확인</li>
            <li>Tasks 상단 제어부와 Home 카드 톤 차이를 실제 최신 빌드에서 다시 비교</li>
          </ul>
        </div>
        <div class="panel">
          <h3>회피한 위험 액션</h3>
          <ul>{avoided_html}</ul>
        </div>
        <div class="panel">
          <h3>남은 블로커</h3>
          <ul>{blockers_html}</ul>
        </div>
      </div>
    </section>
    <section class="section">
      <h2>문서 연결</h2>
      <div class="panel">
        <ul>
          <li><a href="../../AGENTS.md">AGENTS.md</a> - 협업 규칙, 보호 파일, 위험 액션, UX 기본값</li>
          <li><a href="../../PROJECT_MAP.md">PROJECT_MAP.md</a> - 모듈 구조와 화면 책임</li>
          <li><a href="../../ARCHITECTURE.md">ARCHITECTURE.md</a> - 각 모듈 계약과 데이터/상태 아키텍처</li>
          <li><a href="../../PATCHLOG.md">PATCHLOG.md</a> - v1/v2 패치 문맥</li>
          <li><a href="../../AI_CHECKLIST.md">AI_CHECKLIST.md</a> - UI/데이터 안전 수칙</li>
          <li><a href="../../docs/ui_catalog_static_2026-03-07.md">docs/ui_catalog_static_2026-03-07.md</a> - 정적 UI 카탈로그</li>
        </ul>
      </div>
    </section>
    {''.join(section_html)}
  </div>
</body>
</html>
"""


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: rebuild_runtime_review.py <session_dir>")
        return 1

    session = Path(sys.argv[1]).resolve()
    if not session.exists():
        print(f"missing session dir: {session}")
        return 1

    manifest = {
        "session_folder": str(session),
        "title": "WorkNote 런타임 UI 검수 보고서",
        "timestamp": session.name,
        "runtime_basis": "현재 에뮬레이터 설치본",
        "latest_repo_install_status": "install blocked: insufficient storage",
        "included_steps": [entry["name"] for entry in ENTRIES],
        "excluded_steps": EXCLUDED_STEPS,
        "warnings": WARNINGS,
        "unsafe_actions_avoided": UNSAFE_AVOIDED,
        "unresolved_blockers": BLOCKERS,
    }

    review_data = {
        "title": manifest["title"],
        "timestamp": session.name,
        "runtime_basis": manifest["runtime_basis"],
        "warnings": WARNINGS,
        "unsafe_actions_avoided": UNSAFE_AVOIDED,
        "unresolved_blockers": BLOCKERS,
        "entries": ENTRIES,
    }

    (session / "session_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    (session / "review_data.json").write_text(
        json.dumps(review_data, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    (session / "notes.txt").write_text(
        build_notes(session.name),
        encoding="utf-8-sig",
    )
    (session / "review.html").write_text(
        build_html(session.name),
        encoding="utf-8-sig",
    )
    print(session)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
