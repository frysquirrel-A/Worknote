import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:worknote/core/crash/crash_reporter.dart';
import 'package:worknote/data/sync/sync_outbox.dart';
import 'package:worknote/data/sync/sync_processor.dart';
import 'package:worknote/core/ui/app_palette.dart';

class SystemMonitorPage extends StatelessWidget {
  const SystemMonitorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('시스템 모니터링', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        actions: [
          // ✨ 동기화 엔진 상태를 감지하여 스피너 혹은 버튼 표시
          ListenableBuilder(
            listenable: SyncProcessor.instance,
            builder: (context, _) {
              if (SyncProcessor.instance.isSyncing) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.only(right: 20),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary)),
                  ),
                );
              }
              return TextButton.icon(
                onPressed: () => SyncProcessor.instance.processOutbox(),
                icon: const Icon(Icons.cloud_sync_rounded, color: AppColors.primary),
                label: const Text('지금 동기화', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
              );
            }
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCrashLogsCard(),
          const SizedBox(height: 16),
          _buildOutboxCard(),
        ],
      ),
    );
  }

  Widget _buildCrashLogsCard() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Map>(CrashReporter.boxName).listenable(),
      builder: (context, Box<Map> box, _) {
        final logs = CrashReporter.instance.latest(limit: 5);
        return _MonitorCard(
          title: '크래시 리포트',
          count: box.length,
          countColor: AppColors.danger,
          icon: Icons.bug_report_rounded,
          isEmpty: logs.isEmpty,
          emptyMsg: '발견된 크래시 로그가 없습니다.',
          onClear: () => CrashReporter.instance.clear(),
          children: logs.map((e) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(e['error'] ?? 'Unknown Error', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: Text(e['ts'] ?? '', style: const TextStyle(fontSize: 11)),
            trailing: Icon(Icons.warning_amber_rounded, color: e['severity'] == 'ui' ? AppColors.warning : AppColors.danger),
          )).toList(),
        );
      },
    );
  }

  Widget _buildOutboxCard() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Map>(SyncOutbox.boxName).listenable(),
      builder: (context, Box<Map> box, _) {
        final items = box.values.toList().reversed.take(5);
        return _MonitorCard(
          title: '동기화 대기열 (Outbox)',
          count: box.length,
          countColor: AppColors.primary,
          icon: Icons.cloud_sync_rounded,
          isEmpty: box.isEmpty,
          emptyMsg: '대기 중인 동기화 항목이 없습니다.',
          onClear: () => SyncOutbox.instance.clear(),
          children: items.map((e) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${e['entity']} - ${e['action']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: Text(e['ts'] ?? '', style: const TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.queue_rounded, color: AppColors.primary),
          )).toList(),
        );
      },
    );
  }
}

class _MonitorCard extends StatelessWidget {
  final String title; final int count; final Color countColor; final IconData icon;
  final bool isEmpty; final String emptyMsg; final VoidCallback onClear; final List<Widget> children;

  const _MonitorCard({required this.title, required this.count, required this.countColor, required this.icon, required this.isEmpty, required this.emptyMsg, required this.onClear, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: countColor, size: 20), const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const Spacer(),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: countColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(99)), child: Text('$count건', style: TextStyle(color: countColor, fontWeight: FontWeight.w900, fontSize: 13))),
            ],
          ),
          const Divider(height: 24),
          if (isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Center(child: Text(emptyMsg, style: const TextStyle(color: AppColors.hint, fontWeight: FontWeight.w600)))),
          ...children,
          if (!isEmpty)
            Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: onClear, icon: const Icon(Icons.delete_sweep_rounded, size: 16), label: const Text('큐 비우기', style: TextStyle(fontWeight: FontWeight.w800)))),
        ],
      ),
    );
  }
}
