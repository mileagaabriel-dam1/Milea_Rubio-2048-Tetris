import 'package:path/path.dart'; // join()
import 'package:sqflite/sqflite.dart'; // SQLite

class DatabaseHelper { // Abre la BD y crea las tablas
  DatabaseHelper._(); // Constructor privado (singleton)
  static final instance = DatabaseHelper._(); // La única instancia

  Database? _db; // La BD abierta

  Future<Database> get database async { // Devuelve la BD (la abre la 1ª vez)
    _db ??= await openDatabase(
      join(await getDatabasesPath(), 'game2048.db'), // Ruta del archivo
      version: 3, // Versión del esquema
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'), // Activa las claves foráneas
      onCreate: (db, version) async { // Solo la 1ª vez
        await _crearTablas(db); // Tablas de la versión 1
        await _migrarAV2(db); // + cambios de la versión 2
        await _migrarAV3(db); // + cambios de la versión 3

      },
      onUpgrade: (db, vieja, nueva) async { // Si el móvil tenía una versión antigua
        if (vieja < 2) await _migrarAV2(db); // De la 1 a la 2
        if (vieja < 3) await _migrarAV3(db); // De la 2 a la 3

      },
    );
    return _db!;
  }

  Future<void> _crearTablas(Database db) async { // VERSIÓN 1
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        contrasena TEXT NOT NULL,
        fecha_registro TEXT NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE partidas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        puntuacion INTEGER NOT NULL,
        ficha_maxima INTEGER NOT NULL,
        movimientos INTEGER NOT NULL,
        duracion_segundos INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
      )''');
    await db.execute('''
      CREATE TABLE partida_guardada (
        id INTEGER PRIMARY KEY,
        usuario_id INTEGER NOT NULL,
        tablero TEXT NOT NULL,
        puntuacion INTEGER NOT NULL,
        movimientos INTEGER NOT NULL,
        segundos_transcurridos INTEGER NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
      )''');
  }

  Future<void> _migrarAV2(Database db) async { // MIGRACIÓN 1 -> 2: columna nueva sin perder datos
    await db.execute('ALTER TABLE partidas ADD COLUMN tamano_tablero INTEGER NOT NULL DEFAULT 4');
  }
  Future<void> _migrarAV3(Database db) async { // MIGRACIÓN 2 -> 3: soporte para Tetris
    // A qué juego pertenece cada partida; las que ya existían quedan como '2048'
    await db.execute("ALTER TABLE partidas ADD COLUMN juego TEXT NOT NULL DEFAULT '2048'");
    // Líneas completadas en Tetris (en 2048 se queda a 0)
    await db.execute('ALTER TABLE partidas ADD COLUMN lineas INTEGER NOT NULL DEFAULT 0');
    await db.execute("ALTER TABLE partida_guardada ADD COLUMN juego TEXT NOT NULL DEFAULT '2048'");
    // Una partida guardada por usuario y por juego (ALTER TABLE no deja añadir UNIQUE, por eso va con un índice)
    await db.execute('CREATE UNIQUE INDEX idx_guardada_usuario_juego ON partida_guardada(usuario_id, juego)');
  }
}