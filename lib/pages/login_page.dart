import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 처음엔 회원가입 모드(프로필 설정)로 시작하도록 변경
  bool isLoginMode = false; 
  
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.architecture, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 16),
              const Text("WORKNOTE", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const Text("현장 협업의 시작", style: TextStyle(color: Colors.grey, fontSize: 14)),
              
              const SizedBox(height: 48),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Text(isLoginMode ? "로그인" : "프로필 설정", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),

                    // 아이디/비번은 공통
                    _buildTextField(_idCtrl, "아이디", Icons.person, false),
                    const SizedBox(height: 12),
                    _buildTextField(_pwCtrl, "비밀번호", Icons.lock, true),
                    
                    // 회원가입(프로필 설정) 모드일 때만 이름/직책 입력
                    if (!isLoginMode) ...[
                      const SizedBox(height: 12),
                      _buildTextField(_nameCtrl, "이름 (예: 홍길동)", Icons.badge, false),
                      const SizedBox(height: 12),
                      _buildTextField(_roleCtrl, "직책 (예: 전기 팀장)", Icons.work, false),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 10,
                          shadowColor: Colors.blueAccent.withValues(alpha: 0.3),
                        ),
                        onPressed: authProv.isLoading ? null : () async {
                          if (isLoginMode) {
                            // 로그인: 입력된 ID/PW로 로그인 시도
                            await authProv.loginLocal(_idCtrl.text, _pwCtrl.text);
                          } else {
                            // 가입: 입력한 이름/직책으로 유저 생성
                            if (_nameCtrl.text.isEmpty || _roleCtrl.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("이름과 직책을 모두 입력해주세요.")));
                              return;
                            }
                            await authProv.signUpLocal(
                              _idCtrl.text, 
                              _pwCtrl.text, 
                              _nameCtrl.text, // [중요] 사용자가 입력한 이름 전달
                              _roleCtrl.text  // [중요] 사용자가 입력한 직책 전달
                            );
                          }
                        },
                        child: authProv.isLoading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isLoginMode ? "입장하기" : "시작하기", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              TextButton(
                onPressed: () {
                  setState(() {
                    isLoginMode = !isLoginMode;
                  });
                },
                child: Text(
                  isLoginMode ? "처음이신가요? 프로필 설정하기" : "이미 계정이 있으신가요? 로그인", 
                  style: const TextStyle(color: Colors.white54, fontSize: 12)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, bool isObscure) {
    return TextField(
      controller: ctrl,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blueAccent.withValues(alpha: 0.5), size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}