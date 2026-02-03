import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLoginMode = true; // true: 로그인, false: 회원가입
  
  // 입력 컨트롤러
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _roleCtrl = TextEditingController(text: "팀원");

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    super.dispose();
  }

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
              // 1. 로고
              const Icon(Icons.architecture, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 16),
              const Text("WORKNOTE", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const Text("현장 협업의 시작", style: TextStyle(color: Colors.grey, fontSize: 14)),
              
              const SizedBox(height: 48),

              // 2. 입력 폼
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Text(
                      isLoginMode ? "로그인" : "회원가입", 
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 24),

                    // ID, PW 입력창
                    _buildTextField(_idCtrl, "아이디", Icons.person, false),
                    const SizedBox(height: 12),
                    _buildTextField(_pwCtrl, "비밀번호", Icons.lock, true),

                    // 회원가입 추가 입력창
                    if (!isLoginMode) ...[
                      const SizedBox(height: 12),
                      _buildTextField(_nameCtrl, "이름 (예: 김반장)", Icons.badge, false),
                      const SizedBox(height: 12),
                      _buildTextField(_roleCtrl, "직책 (예: 소장)", Icons.work, false),
                    ],

                    const SizedBox(height: 24),

                    // 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: authProv.isLoading ? null : () async {
                          if (isLoginMode) {
                            // [수정됨] 로그인: 인자 2개 (아이디, 비번) 전달
                            final success = await authProv.login(_idCtrl.text, _pwCtrl.text);
                            
                            if (!success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("아이디 또는 비밀번호를 확인해주세요.")));
                            }
                          } else {
                            // 회원가입
                            if (_idCtrl.text.isEmpty || _pwCtrl.text.isEmpty || _nameCtrl.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("모든 필드를 입력해주세요.")));
                              return;
                            }
                            final success = await authProv.signUp(_idCtrl.text, _pwCtrl.text, _nameCtrl.text, _roleCtrl.text);
                            
                            if (!success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("이미 존재하는 아이디입니다.")));
                            }
                          }
                        },
                        child: authProv.isLoading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isLoginMode ? "로그인하기" : "가입 완료", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. 모드 전환
              TextButton(
                onPressed: () {
                  setState(() {
                    isLoginMode = !isLoginMode;
                    if (isLoginMode) _nameCtrl.clear();
                  });
                },
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.grey),
                    children: [
                      TextSpan(text: isLoginMode ? "계정이 없으신가요? " : "이미 계정이 있으신가요? "),
                      TextSpan(
                        text: isLoginMode ? "회원가입하기" : "로그인하기",
                        style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
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
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
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
