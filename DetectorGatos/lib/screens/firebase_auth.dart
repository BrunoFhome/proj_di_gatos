import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  
  String _email = '';
  String _password = '';
  bool _isLogin = true;
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      UserCredential userCredential;
      
      if (_isLogin) {
        // Login existing user
        userCredential = await _auth.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );
      } else {
        // Create new user
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: _email,
          password: _password,
        );
        
        // Store basic user info in Firestore (just email)
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'email': _email,
          'createdAt': Timestamp.now(),
        });
      }
      
      // Navigate to home screen after successful authentication
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false; // Stop loading when there's an error
        _errorMessage = 'Erro de autenticação: ${e.code} - ${e.message}';
        print("Firebase Auth Error: ${e.code} - ${e.message}");
      });
    } catch (e) {
      setState(() {
        _isLoading = false; // Stop loading when there's an error
        _errorMessage = 'Erro: ${e.toString()}';
        print("General Error: ${e.toString()}");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Cadastro'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 150,
                    errorBuilder: (ctx, error, _) => Icon(
                      Icons.pets,
                      size: 100,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isLogin ? 'Bem-vindo de volta!' : 'Crie sua conta',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, digite seu email';
                      }
                      if (!value.contains('@')) {
                        return 'Por favor, digite um email válido';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _email = value?.trim() ?? '';
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, digite sua senha';
                      }
                      if (value.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _password = value?.trim() ?? '';
                    },
                  ),
                  const SizedBox(height: 20),
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: Text(
                            _isLogin ? 'Entrar' : 'Cadastrar',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _errorMessage = '';
                      });
                    },
                    child: Text(
                      _isLogin
                          ? 'Não tem uma conta? Cadastre-se'
                          : 'Já tem uma conta? Faça login',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}