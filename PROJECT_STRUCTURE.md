# 🛠️ WorkNote 마스터 기술 명세서 (Detailed Architecture PRD)

본 문서는 WorkNote 프로젝트의 프론트엔드 UI, 비즈니스 로직, 데이터 스키마 및 시스템 통합 구조를 상세히 기술합니다.

---

## 1. 시스템 계층 구조 (System Layer Decomposition)

### **A. Presentation Layer (UI 컴포넌트)**
*   **Root (MainScreen)**: `Scaffold`와 `NavigationBar`를 포함하며 `IndexedStack`을 통해 탭 간 상태 유실 없는 화면 전환을 관리합니다.
*   **HomeTab**: 대시보드 인터페이스. `LinearProgressIndicator`를 활용한 실시간 진행률 시각화 및 팀원 프로필 서랍(`showModalBottomSheet`) 호출 로직을 포함합니다.
*   **TeamTaskTab**: 복합 필터링 위젯. `SegmentedButton`(상태) + `ListView`(멤버) + `ChoiceChip`(정렬)의 3중 필터 구조입니다.
*   **JournalTab**: 데이터 생성기. `TextField`의 포커스 제어 및 전역 업무 데이터(`tasks`)를 바텀시트로 불러와 텍스트로 치환하는 매핑 로직이 핵심입니다.
*   **GalleryTab**: 미디어 관리자. `GridView.builder`를 사용하여 날짜별 섹션을 동적으로 생성하며, 팀원 ID 기반의 다차원 필터링을 수행합니다.

### **B. Logic & State Layer (데이터 흐름)**
*   **Single Source of Truth**: 모든 상태(`_tasks`, `_journals`, `_profileImage`, `_tabTones`)는 `_MainScreenState`에서 집중 관리됩니다.
*   **Bi-directional Bridge**: 
    *   `Journal` -> `Task`: 일지 제목을 `Task` 생성자로 전달하여 즉시 업무 등록.
    *   `Task` -> `Journal`: 완료된 업무 리스트를 일지 본문에 문자열로 주입.
*   **Theme Engine**: `AppTone` Enum 값에 따라 `_getBgColor()` 함수가 배경색을 리턴하며, 각 위젯 내부에서 `isDark` 여부를 판별해 텍스트와 카드 색상을 실시간 계산합니다.

---

## 2. 데이터 모델 상세 (Granular Data Schema)

### **Class: Task (업무)**
| 필드명 | 타입 | 설명 |
| :--- | :--- | :--- |
| `id` | `String` | 고유 식별자 (DateTime 기반) |
| `title` | `String` | 업무 명칭 |
| `assigneeId` | `String` | 담당자 고유 ID ('me', 'kim' 등) |
| `taskNotes` | `List<String>` | **[타임라인]** "yyyy.MM.dd 나: 내용" 형식의 히스토리 기록 |
| `isDone` | `bool` | 완료 여부 (Checkbox 연동) |
| `priority` | `Enum` | High(Red), Medium(Amber), Low(Blue), None(Grey) |
| `completedAt` | `DateTime?` | 완료 버튼 클릭 시점 자동 기록 |

### **Class: JournalEntry (일지)**
| 필드명 | 타입 | 설명 |
| :--- | :--- | :--- |
| `userId` | `String` | 작성자 ID (갤러리 필터링의 핵심 키) |
| `photos` | `List<String>` | `image_picker`에서 전달받은 로컬 파일 경로 리스트 |
| `content` | `String` | 업무 내용 및 '업무 불러오기'로 추가된 텍스트 |

---

## 3. 핵심 비즈니스 로직 분석 (Logic Deep-Dive)

### **1) 업무 진행사항(Timeline) 시스템**
*   **로직**: `_showTaskNoteDialog` 내에서 `StatefulBuilder`를 호출하여 다이얼로그가 닫히지 않은 상태로 리스트를 실시간 업데이트합니다.
*   **데이터**: 신규 입력 시 `DateFormat('yy.MM.dd HH:mm')`을 접두어로 붙여 문자열 리스트로 저장합니다.

### **2) 탭별 독립 테마 시스템**
*   **로직**: `List<AppTone> _tabTones` 배열을 인덱스별로 관리합니다. (예: `_tabTones[0]`은 홈 탭 테마)
*   **전환**: 상단 팔레트 클릭 시 `_selectedIndex`에 해당하는 배열 요소만 변경 후 `setState`를 호출하여 해당 탭의 색상만 리렌더링합니다.

### **3) 갤러리 다차원 정렬 및 필터**
*   **그룹화**: `Map<String, List<String>> grouped = {}` 형식을 사용하여 날짜를 Key로, 해당 날짜의 모든 사진을 Value로 묶어 리스트 뷰를 구성합니다.
*   **필터**: `j.userId == _selectedMemberId` 조건문을 통해 런타임에 리스트를 필터링하여 불필요한 메모리 낭비를 방지합니다.

---

## 4. 기술적 제약 및 인프라 (Tech Constraints)
*   **UI Framework**: Flutter Material 3 (입체적 카드 디자인 적용)
*   **Storage**: 현재 메모리 내 리스트 보관 (앱 종료 시 초기화되나, 구조상 SQLite/Firebase 마이그레이션이 용이하게 설계됨)
*   **Image**: `FileImage` 위젯을 통한 로컬 파일 스트리밍
*   **Layout**: `Row`와 `Column`의 정밀한 중첩 구조를 통해 체크박스-제목 / 깃발-날짜 간의 1px 단위 수직 정렬 달성

---

이 문서는 WorkNote의 내부 작동 원리를 정의하며, 향후 Gemini를 통한 코드 리팩토링이나 새로운 기능(예: 알림 시스템, DB 연동) 요청 시 기술적 가이드라인이 됩니다.
