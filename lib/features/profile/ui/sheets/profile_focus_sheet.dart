import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:worknote/core/theme/premium_theme.dart';
import 'package:worknote/features/profile/models/profile_focus_prefs.dart';
import 'package:worknote/features/profile/state/focus_provider.dart';

class ProfileFocusSheet extends StatefulWidget {
  const ProfileFocusSheet({
    super.key,
    required this.profileId,
    required this.profileName,
  });

  final String profileId;
  final String profileName;

  @override
  State<ProfileFocusSheet> createState() => _ProfileFocusSheetState();
}

class _ProfileFocusSheetState extends State<ProfileFocusSheet> {
  late ProfileFocusPrefs _currentPrefs;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final focusProv = context.read<FocusProvider>();
      _currentPrefs = focusProv.getPrefs(widget.profileId);
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: WorkNotePremium.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: WorkNotePremium.textMuted.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '${widget.profileName}의 Focus 설정',
            style: WorkNoteType.subHeading,
          ),
          const SizedBox(height: 8),
          const Text(
            '이 프로필로 전환했을 때의 기본 동작 방식을 설정합니다.',
            style: WorkNoteType.caption,
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('기본 시작 화면'),
          const SizedBox(height: 12),
          _buildTabSelector(),
          const SizedBox(height: 24),
          _buildSectionTitle('업무 리스트 레이아웃'),
          const SizedBox(height: 12),
          _buildLayoutSelector(),
          const SizedBox(height: 24),
          _buildToggleOption(
            title: '오늘의 브리핑 먼저 보기',
            value: _currentPrefs.showTodayBriefingFirst,
            onChanged: (value) => setState(
              () => _currentPrefs = _currentPrefs.copyWith(
                showTodayBriefingFirst: value,
              ),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                await context.read<FocusProvider>().updatePrefs(_currentPrefs);
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: WorkNotePremium.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                '설정 저장',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: WorkNotePremium.textMuted,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildTabSelector() {
    const tabs = {
      'home': '홈',
      'tasks': '업무',
      'schedule': '일정',
      'journal': '일지',
    };

    return Wrap(
      spacing: 8,
      children: tabs.entries.map((entry) {
        final selected = _currentPrefs.landingTab == entry.key;
        return ChoiceChip(
          label: Text(entry.value),
          selected: selected,
          onSelected: (_) => setState(
            () => _currentPrefs = _currentPrefs.copyWith(landingTab: entry.key),
          ),
          selectedColor: WorkNotePremium.primary.withValues(alpha: 0.2),
          checkmarkColor: WorkNotePremium.primary,
          labelStyle: TextStyle(
            color: selected
                ? WorkNotePremium.primary
                : WorkNotePremium.textMain,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
          backgroundColor: WorkNotePremium.surface,
          side: BorderSide(
            color: selected ? WorkNotePremium.primary : Colors.transparent,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLayoutSelector() {
    const layouts = {
      'classic': '클래식 리스트',
      'gallery': '갤러리 카드',
    };

    return Wrap(
      spacing: 8,
      children: layouts.entries.map((entry) {
        final selected = _currentPrefs.taskLayout == entry.key;
        return ChoiceChip(
          label: Text(entry.value),
          selected: selected,
          onSelected: (_) => setState(
            () => _currentPrefs = _currentPrefs.copyWith(taskLayout: entry.key),
          ),
          selectedColor: WorkNotePremium.secondary.withValues(alpha: 0.2),
          checkmarkColor: WorkNotePremium.secondary,
          labelStyle: TextStyle(
            color: selected
                ? WorkNotePremium.secondary
                : WorkNotePremium.textMain,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
          backgroundColor: WorkNotePremium.surface,
          side: BorderSide(
            color: selected ? WorkNotePremium.secondary : Colors.transparent,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToggleOption({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: WorkNoteType.body),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: WorkNotePremium.primary,
        ),
      ],
    );
  }
}
