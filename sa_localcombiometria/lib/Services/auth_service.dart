import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Model/registro.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // retorna o usuário logado atualmente (ou null se estiver deslogado)
  User? get usuarioAtual => _auth.currentUser;

  // monitora em tempo real as mudanças no estado de autenticação
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // realiza o login utilizando E-mail e Senha
  Future<Map<String, dynamic>> entrarComEmailESenha(String email, String senha) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );
      return {
        'sucesso': true,
        'mensagem': 'Login efetuado com sucesso!',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      //condições para o email e a senha
      String mensagem = 'Erro ao realizar login.';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        mensagem = 'E-mail ou senha incorretos.';
      } else if (e.code == 'wrong-password') {
        mensagem = 'Senha incorreta.';
      } else if (e.code == 'invalid-email') {
        mensagem = 'E-mail em formato inválido.';
      } else if (e.code == 'user-disabled') {
        mensagem = 'Esta conta foi desativada.';
      }
      return {'sucesso': false, 'mensagem': mensagem};
    } catch (e) {
      return {'sucesso': false, 'mensagem': 'Erro inesperado: $e'};
    }
  }

  // realiza o cadastro de um novo usuário com E-mail e Senha
  Future<Map<String, dynamic>> cadastrarComEmailESenha(String email, String senha) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );
      return {
        'sucesso': true,
        'mensagem': 'Usuário cadastrado com sucesso!',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      //condições para permitir o cadastro sem erros ou repetições
      String mensagem = 'Erro ao cadastrar usuário.';
      if (e.code == 'email-already-in-use') {
        mensagem = 'Este e-mail já está em uso por outra conta.';
      } else if (e.code == 'weak-password') {
        mensagem = 'A senha deve ter no mínimo 6 caracteres.';
      } else if (e.code == 'invalid-email') {
        mensagem = 'E-mail em formato inválido.';
      }
      return {'sucesso': false, 'mensagem': mensagem};
    } catch (e) {
      return {'sucesso': false, 'mensagem': 'Erro inesperado: $e'};
    }
  }

  // encerra a sessão do usuário logado
  Future<void> deslogar() async {
    await _auth.signOut();
  }

  // grava o registro do ponto na coleção 'registros' no Cloud Firestore
  Future<Map<String, dynamic>> registrarPonto(Registro registro) async {
    try {
      await _firestore.collection('registros').add(registro.toMap());
      return {
        'sucesso': true,
        'mensagem': 'Ponto registrado no banco de dados com sucesso!',
      };
    } catch (e) {
      print('Erro ao salvar no Firestore: $e');
      return {
        'sucesso': false,
        'mensagem': 'Erro ao conectar ao banco de dados para salvar o ponto.',
      };
    }
  }

  //retorna em tempo real a lista de registros(pontos) batidos pelo usuário atual
  Stream<List<Registro>> buscarHistoricoPontos() {
    final userId = usuarioAtual?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('registros')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final lista = snapshot.docs
          .map((doc) => Registro.fromMap(doc.data(), doc.id))
          .toList();
      
      // Ordena os pontos mais recentes primeiro
      lista.sort((a, b) => b.dataHora.compareTo(a.dataHora));
      return lista;
    });
  }
}