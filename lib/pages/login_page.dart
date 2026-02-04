import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLoginMode = true;
  
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _roleCtrl = TextEditingController(text: "팀원");

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
              const Text("오프라인 모드로 시작", style: TextStyle(color: Colors.grey, fontSize: 14)),
              
              const SizedBox(height: 48),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Text(isLoginMode ? "로컬 로그인" : "로컬 회원가입", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),

                    _buildTextField(_idCtrl, "아이디", Icons.person, false),
                    const SizedBox(height: 12),
                    _buildTextField(_pwCtrl, "비밀번호", Icons.lock, true),

                    if (!isLoginMode) ...[
                      const SizedBox(height: 12),
                      _buildTextField(_nameCtrl, "이름 (예: 김반장)", Icons.badge, false),
                      const SizedBox(height: 12),
                      _buildTextField(_roleCtrl, "직책 (예: 소장)", Icons.work, false),
                    ],

                    const SizedBox(height: 24),

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
                            // [수정] 로컬 로그인 호출
                            final success = await authProv.loginLocal(_idCtrl.text, _pwCtrl.text);
                            if (!success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("로그인 실패 (임시 모드)")));
                            }
                          } else {
                            // [수정] 로컬 회원가입 호출
                            if (_nameCtrl.text.isEmpty) return;
                            await authProv.signUpLocal(_idCtrl.text, _pwCtrl.text, _nameCtrl.text, _roleCtrl.text);
                          }
                        },
                        child: authProv.isLoading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isLoginMode ? "시작하기" : "가입하고 시작", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
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
                    if (isLoginMode) _nameCtrl.clear();
                  });
                },
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.grey),
                    children: [
                      TextSpan(text: isLoginMode ? "처음이신가요? " : "이미 계정이 있나요? "),
                      TextSpan(
                        text: isLoginMode ? "회원가입" : "로그인",
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