import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/registro.dart';

// vai gerenciar a conexão e operações com o banco de dados SQLite local.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  // Construtor factory que sempre retorna a mesma instância existente
  factory DatabaseHelper() => _instance;

  // Construtor privado para impedir novas instanciações externas
  DatabaseHelper._internal();

  // Atributo estático para manter a referência da conexão do banco
  static Database? _database;

  // Getter assíncrono: Retorna o banco existente ou inicializa um novo caso ainda não exista
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Método responsável por localizar e abrir o arquivo do banco de dados no dispositivo
  Future<Database> _initDatabase() async {
    // Obtém o diretório padrão onde os bancos de dados são salvos no sistema operacional
    String dbPath = await getDatabasesPath();
    
    // Une o caminho do diretório com o nome do arquivo do banco (.db)
    String path = join(dbPath, 'senai_checkin.db');

    // Abre o banco de dados; se o arquivo não existir, dispara a função _onCreate
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Método executado automaticamente apenas na PRIMEIRA vez que o banco é criado
  Future<void> _onCreate(Database db, int version) async {
    // Cria a tabela 'registros' e define os tipos de dados de cada coluna
    await db.execute('''
      CREATE TABLE registros(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data_hora TEXT,
        latitude REAL,
        longitude REAL,
        observacao TEXT,
        caminho_foto TEXT
      )
    ''');
  }

  // Método para INSERIR um novo registro no banco de dados (C do CRUD)
  Future<int> insertRegistro(Registro registro) async {
    Database db = await database;
    // Transforma o objeto Registro em Map para que o SQLite consiga salvar
    return await db.insert('registros', registro.toMap());
  }

  // Método para LISTAR todos os registros gravados no banco (R do CRUD)
  Future<List<Registro>> getRegistros() async {
    Database db = await database;
    
    // Consulta a tabela ordenando do registro mais recente para o mais antigo (id DESC)
    List<Map<String, dynamic>> maps = await db.query('registros', orderBy: 'id DESC');

    // Converte a lista de Maps retornada pelo banco de volta em uma lista de objetos Registro
    return List.generate(maps.length, (i) {
      return Registro.fromMap(maps[i]);
    });
  }

  Future<int> deleteRegistro(int id) async {
  Database db = await database;
  return await db.delete('registros', where: 'id = ?', whereArgs: [id]);
  }
}