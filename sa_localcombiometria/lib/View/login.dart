import 'package:flutter/material.dart';
import '../Services/auth_service.dart';
import '../Services/biometria_service.dart';
import 'home.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  final AuthService _authService = AuthService();
  final BiometriaService _biometriaService = BiometriaService();

  bool _isLogin = true; 
  bool _isLoading = false;
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // exibe alertas na parte inferior da tela
  void _mostrarMensagem(String mensagem, {bool ehErro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: ehErro ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // processa a autenticação tradicional por E-mail e Senha
  Future<void> _submeterFormulario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text;
    final senha = _senhaController.text;

    Map<String, dynamic> resultado;

    if (_isLogin) {
      resultado = await _authService.entrarComEmailESenha(email, senha);
    } else {
      resultado = await _authService.cadastrarComEmailESenha(email, senha);
    }

    setState(() => _isLoading = false);

    if (resultado['sucesso'] == true) {
      _mostrarMensagem(resultado['mensagem']);
      _navegarParaHome();
    } else {
      _mostrarMensagem(resultado['mensagem'], ehErro: true);
    }
  }

  // autenticação rápida por reconhecimento facial
  Future<void> _loginComBiometria() async {
    // verifica se já existe um usuário ativo na sessão do Firebase
    if (_authService.usuarioAtual == null) {
      _mostrarMensagem(
        'Faça o primeiro login com e-mail e senha para ativar o reconhecimento facial.',
        ehErro: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    final resultadoBiometria = await _biometriaService.autenticarFacial();
    setState(() => _isLoading = false);

    if (resultadoBiometria['sucesso'] == true) {
      _mostrarMensagem('Login facial reconhecido com sucesso!');
      _navegarParaHome();
    } else {
      _mostrarMensagem(resultadoBiometria['mensagem'], ehErro: true);
    }
  }

  void _navegarParaHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TelaHome()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ícone de Cabeçalho
                  Icon(
                    Icons.fingerprint,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isLogin ? 'Registro de Ponto' : 'Criar Conta',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin
                        ? 'Acesse com seu e-mail e senha ou biometria'
                        : 'Preencha os dados abaixo para se cadastrar',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),

                  // Campo E-mail
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail / NIF',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.isEmpty) {
                        return 'Informe o seu e-mail';
                      }
                      if (!valor.contains('@')) {
                        return 'Informe um e-mail válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo Senha
                  TextFormField(
                    controller: _senhaController,
                    obscureText: !_senhaVisivel,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _senhaVisivel
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _senhaVisivel = !_senhaVisivel);
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.isEmpty) {
                        return 'Informe a sua senha';
                      }
                      if (valor.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Botão Entrar / Cadastrar
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submeterFormulario,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isLogin ? 'ENTRAR' : 'CADASTRAR',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // botão de login por biometria facial 
                  if (_isLogin) ...[
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _loginComBiometria,
                      icon: const Icon(Icons.face_unlock_rounded),
                      label: const Text('Entrar com Reconhecimento Facial'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  //botão para alternar entre Login e Cadastro
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                      });
                    },
                    child: Text(
                      _isLogin
                          ? 'Não tem uma conta? Cadastre-se'
                          : 'Já tem uma conta? Faça Login',
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