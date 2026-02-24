import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// 현재 로그인된 유저 확인
  User? get currentUser => _firebaseAuth.currentUser;

  /// 🚀 구글 계정으로 파이어베이스 로그인 (안전장치 추가됨)
  Future<User?> signInWithGoogle() async {
    try {
      print('🔄 [AuthService] 구글 로그인 프로세스 시작...');

      // 1. 기존에 진행 중인 로그인이 꼬여있을 수 있으니 일단 로그아웃 시도 (안전장치)
      try {
        await _googleSignIn.signOut(); 
      } catch (e) {
        // 로그아웃 에러는 무시하고 진행
      }

      // 2. 구글 로그인 창 띄우기
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('🚫 [AuthService] 사용자가 로그인 창을 취소/닫았습니다.');
        return null;
      }

      print('✅ [AuthService] 구글 계정 선택 완료: ${googleUser.email}');

      // 3. 인증 토큰 요청
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 4. 파이어베이스용 자격 증명 생성
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. 파이어베이스 로그인 실행
      final UserCredential userCredential = 
          await _firebaseAuth.signInWithCredential(credential);

      // 🎉 성공 로그 출력 (이게 보여야 진짜 성공입니다!)
      print('🎉🎉🎉 [AuthService] 파이어베이스 로그인 대성공! UID: ${userCredential.user?.uid} 🎉🎉🎉');
      
      return userCredential.user;

    } catch (e) {
      print('💥 [AuthService] 로그인 중 치명적 에러 발생: $e');
      return null;
    }
  }

  /// 📝 [전통적 방식] 이메일/비밀번호로 회원가입
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      print('📝 [AuthService] 이메일 회원가입 시도: $email');
      
      UserCredential credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('🎉 [AuthService] 회원가입 성공! UID: ${credential.user?.uid}');
      return credential.user;
      
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('⚠️ 비밀번호가 너무 약합니다.');
      } else if (e.code == 'email-already-in-use') {
        print('⚠️ 이미 가입된 이메일입니다.');
      }
      return null;
    } catch (e) {
      print('💥 회원가입 에러: $e');
      return null;
    }
  }

  /// 🔑 [전통적 방식] 이메일/비밀번호로 로그인
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ [AuthService] 이메일 로그인 성공!');
      return credential.user;
    } catch (e) {
      print('🚫 로그인 실패 (아이디/비번 확인 필요): $e');
      return null;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    print('👋 [AuthService] 로그아웃 완료');
  }

  /// 🧨 회원 탈퇴 (계정 영구 삭제)
  Future<bool> withdrawAccount() async {
    try {
      print('🧨 [AuthService] 회원 탈퇴 프로세스 시작...');
      
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        print('🚫 로그인된 사용자가 없습니다.');
        return false;
      }

      try {
        await _googleSignIn.disconnect(); 
      } catch (e) {
        print('⚠️ 구글 연결 해제 중 오류 (무시 가능): $e');
      }

      await user.delete();
      
      print('👋 [AuthService] 계정이 영구적으로 삭제되었습니다.');
      return true;

    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        print('🔒 [AuthService] 보안상 다시 로그인해야 탈퇴할 수 있습니다.');
      }
      print('🔥 [AuthService] 회원 탈퇴 실패: $e');
      return false;
    } catch (e) {
      print('💥 [AuthService] 알 수 없는 오류: $e');
      return false;
    }
  }
}
