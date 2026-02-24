import 'package:worknote/app/bootstrap.dart';

Future<void> main() async {
  // 모든 초기화 로직은 bootstrap 내부의 runZonedGuarded 안으로 이동되었습니다.
  await bootstrap();
}
