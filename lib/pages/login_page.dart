import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("WORKNOTE", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
            const SizedBox(height: 48),
            TextField(controller: _idController, decoration: const InputDecoration(labelText: "아이디")),
            TextField(controller: _pwController, decoration: const InputDecoration(labelText: "비밀번호"), obscureText: true),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () {
                  // 임시 로그인 로직
                  context.read<AuthProvider>().login(AppUser(
                    id: 'me', password: '123', name: '관리자', role: '현장총괄'
                  ));
                },
                child: const Text("로그인", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
