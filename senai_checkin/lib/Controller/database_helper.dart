import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/registro.dart';

// vai gerenciar a conexão e operações com o banco de dados SQLite local.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // vai retornar o banco existente ou inicializa um novo caso ainda não exista
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // localiza e abre o arquivo do banco de dados no dispositivo
  Future<Database> _initDatabase() async {
   String dbPath = await getDatabasesPath();
    
    //vai juntar o caminho do diretório com o nome do arquivo do db
    String path = join(dbPath, 'senai_checkin.db');

    //vai abrir o banco de dados; se o arquivo não existir, dispara a função _onCreate
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // executa automaticamente na primeira vez que o banco é criado
  Future<void> _onCreate(Database db, int version) async {
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

  // para inserir um novo registro no banco de dados
  Future<int> insertRegistro(Registro registro) async {
    Database db = await database;
    return await db.insert('registros', registro.toMap());
  }

  //lista todos os registros gravados no bd
  Future<List<Registro>> getRegistros() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('registros', orderBy: 'id DESC');

    return List.generate(maps.length, (i) {
      return Registro.fromMap(maps[i]);
    });
  }

//exclui os registros
  Future<int> deleteRegistro(int id) async {
  Database db = await database;
  return await db.delete('registros', where: 'id = ?', whereArgs: [id]);
  }
}