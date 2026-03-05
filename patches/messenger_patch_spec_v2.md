# Messenger Patch Spec (v2)

This spec is based on the screenshot deck, `MainShell`, `ChatProvider`, and chat docs.
The real `lib/features/chat/ui/messenger_tab.dart` was not text-readable in the snapshot, so apply these changes against the actual source file in the real project ZIP.

## Visual references
Use these screenshot references from the PPT/contact sheet:
- `image12.png`: dark messenger screen with composer and send button
- `image13.png`: "대화 대상 선택" bottom sheet
- `image14.png`: "채팅 관리" bottom sheet

## Goals
1. Preserve current Messenger feature set
2. Keep the dark navy tone already visible in screenshots
3. Improve empty state / composer ergonomics / sheet polish
4. Reuse existing app architecture and provider flow

## Required imports
Add if missing:
```dart
import 'package:flutter/services.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/core/ui/widgets/empty_state_placeholder.dart';
import 'package:worknote/core/ui/widgets/press_scale.dart';
```

## 1. Conversation empty state
When the active thread has zero messages, do not leave a blank dark panel.
Use `EmptyStatePlaceholder` in compact mode.

### Search anchor
- the widget branch where current thread messages are rendered
- or where `chatProv.getMessages(activeThreadId)` is consumed

### Replacement target
If `messages.isEmpty`, render something equivalent to:

```dart
return const EmptyStatePlaceholder(
  icon: Icons.forum_outlined,
  title: '아직 대화가 없어요',
  description: '첫 메시지를 보내서 이 갈래의 대화를 시작해 보세요.',
  compact: true,
);
```

Notes:
- no new CTA is required if the composer is already visible at the bottom
- keep the existing dark background behind it

## 2. Composer / send button polish
The composer in `image12.png` is already close. Finish it with safer padding and touch feedback.

### Search anchor
- TextField with hint like `메시지를 입력하세요...`
- trailing send button

### Required changes
1. Put the composer inside bottom safe-area aware padding
2. Wrap send button with `PressScale`
3. Add `selection` or `light` haptic on send tap
4. Ensure blank/whitespace message send is blocked (provider patch already helps)

### Example structure
```dart
final bottomInset = MediaQuery.of(context).viewInsets.bottom;

SafeArea(
  top: false,
  child: Padding(
    padding: EdgeInsets.fromLTRB(
      16,
      12,
      16,
      bottomInset > 0 ? bottomInset + 8 : 12,
    ),
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        gradient: AppGradients.messengerPanel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              // keep existing controller / submit logic
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '메시지를 입력하세요...',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 10),
          PressScale(
            haptic: PressScaleHaptic.light,
            onTap: _handleSend,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppColors.premiumBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  ),
)
```

## 3. Thread selector sheet polish
The "대화 대상 선택" sheet in `image13.png` is structurally good.
Finish the spacing and make scroll behavior stable.

### Search anchor
- method opening "대화 대상 선택"
- `showModalBottomSheet(...)`

### Required changes
1. Use:
   - `isScrollControlled: true`
   - `backgroundColor: Colors.transparent`
2. Inside, use a dark rounded container:
   - background: `AppColors.darkSurface`
   - radius: `32`
   - border: `AppColors.darkBorder`
3. Add a top handle bar
4. Use `DraggableScrollableSheet` if the current list can overflow
5. Section labels should be small and muted:
   - `단체 (팀 채널)`
   - `1:1 대화`
   - `그룹 채팅`
6. Wrap tappable row items with `PressScale`
7. Use `cacheExtent` and `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag` if a search field exists

### Row style
- leading avatar/group icon in 52x52 circular container
- title weight `w800`
- vertical padding 12-14
- item radius 18
- selected/hover tint can use `AppColors.premiumBlue.withValues(alpha: 0.08)`

## 4. Chat management sheet polish
The "채팅 관리" panel in `image14.png` should keep its destructive actions visually clear but not noisy.

### Search anchor
- method opening "채팅 관리"
- sheet/dialog with group list + DM list + clear current chat action

### Required changes
1. Use same dark rounded sheet shell as selector sheet
2. Section divider between:
   - 단체 (팀 채널)
   - 1:1 대화
3. Delete icons:
   - color `AppColors.destructive`
   - use `PressScale(haptic: PressScaleHaptic.medium, ...)`
4. Bottom CTA "현재 대화 내용 지우기"
   - pinned to bottom area
   - medium haptic
   - confirm dialog before execution
5. Add `SafeArea(top: false)` at bottom so the pinned CTA does not collide with the home indicator

### Recommended bottom CTA style
```dart
Container(
  padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
  decoration: BoxDecoration(
    color: AppColors.darkSurface,
    border: Border(top: BorderSide(color: AppColors.darkBorder)),
  ),
  child: PressScale(
    haptic: PressScaleHaptic.medium,
    onTap: _confirmClearCurrentThread,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.cleaning_services_outlined, color: Color(0xFFF8D94B)),
        SizedBox(width: 10),
        Text(
          '현재 대화 내용 지우기',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  ),
)
```

## 5. Message list behavior
Do not change message ordering unless the real source clearly needs it.
Just ensure:
- list padding is stable
- keyboard dismisses on drag
- overscroll glow is not too distracting if custom physics are already used
- long conversations do not rebuild excessively

### Safe patch suggestions
```dart
ListView.builder(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
  cacheExtent: 320,
  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
  // keep existing reverse/itemBuilder/order if already correct
)
```

## 6. Thread card / header polish
At the top thread selector pill (`단체 · 마스터피스 건설 팀`) from `image12.png`:
- keep the navy pill
- vertical padding 14
- radius 20
- use `PressScale` on tap
- trailing chevron should have slightly lower opacity than the label

## 7. Do not break these
- active thread switching
- `ChatProvider.setActiveThread(...)`
- DM thread id generation
- group thread create / rename / delete
- any Gemini/AI conversation entry points if present in real source but not visible in snapshot

## Final verification after patch
1. open messenger
2. switch between bottom tabs and return
3. confirm current conversation is still selected
4. send a normal message
5. try sending blank spaces -> should do nothing
6. open thread selector sheet
7. open chat management sheet
8. delete or clear action still shows confirm and works
