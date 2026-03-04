import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:worknote/core/utils/dev_log.dart';

class DevLogPage extends StatelessWidget {
  const DevLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('개발자 로그'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              final text = DevLog.instance.logs.value.join('\n');
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('모든 로그가 클립보드에 복사되었습니다.')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => DevLog.instance.clear(),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<String>>(
        valueListenable: DevLog.instance.logs,
        builder: (context, logs, _) {
          if (logs.isEmpty) {
            return const Center(child: Text('수집된 로그가 없습니다.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[logs.length - 1 - index]; // 최신 로그가 위로
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  log,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
