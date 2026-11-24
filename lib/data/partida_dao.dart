import 'package:sqflite/sqflite.dart'; // Para usar la BD

import '../models/estadisticas.dart'; // Modelos de estadísticas
import '../models/partida.dart'; // Modelo Partida
import 'database_helper.dart'; // Para abrir la BD

class PartidaDao { // Todo el SQL de la tabla partidas
  Future<Database> get _db => DatabaseHelper.instance.database; // Atajo para la BD

  // SQL que se repite: partidas + nombre del jugador (JOIN)
  static const _select = 'SELECT p.*, u.usuario FROM partidas p JOIN usuarios u ON p.usuario_id = u.id';

  Future<int> insertar(Partida p) async { // INSERT (el juego va dentro de p.toMap())
    final db = await _db; // BD
    return db.insert('partidas', p.toMap()); // Devuelve el id nuevo
  }

  Future<List<Partida>> historial({String jugador = '', int fichaMinima = 0, String juego = '2048'}) async {
    final db = await _db; // BD
    final filas = await db.rawQuery(
      '$_select WHERE p.juego = ? AND u.usuario LIKE ? AND p.ficha_maxima >= ? ORDER BY p.fecha DESC',
      [juego, '%$jugador%', fichaMinima], // En Tetris deja fichaMinima a 0
    );
    return filas.map(Partida.fromMap).toList(); // Filas -> objetos
  }

  Future<Partida?> porId(int id) async { // Detalle de una partida (el id ya es único, no hace falta juego)
    final db = await _db; // BD
    final filas = await db.rawQuery('$_select WHERE p.id = ?', [id]); // Busca por id
    return filas.isEmpty ? null : Partida.fromMap(filas.first); // null si no existe
  }

  Future<void> eliminar(int id) async { // DELETE de una
    final db = await _db; // BD
    await db.delete('partidas', where: 'id = ?', whereArgs: [id]); // Solo la de ese id
  }

  Future<void> eliminarTodo({String juego = '2048'}) async { // DELETE del historial de un juego
    final db = await _db; // BD
    await db.delete('partidas', where: 'juego = ?', whereArgs: [juego]); // No toca las del otro juego
  }

  Future<List<Partida>> ranking({String juego = '2048'}) async { // Top 10 del juego
    final db = await _db; // BD
    final filas = await db.rawQuery('$_select WHERE p.juego = ? ORDER BY p.puntuacion DESC LIMIT 10', [juego]);
    return filas.map(Partida.fromMap).toList(); // Filas -> objetos
  }

  Future<EstadisticasGlobales> estadisticas({String juego = '2048'}) async { // COUNT, MAX, AVG, SUM
    final db = await _db; // BD
    final filas = await db.rawQuery(
      'SELECT COUNT(*) AS total, MAX(puntuacion) AS max_puntos, AVG(puntuacion) AS media_puntos, '
          'MAX(ficha_maxima) AS max_ficha, MAX(lineas) AS max_lineas, SUM(duracion_segundos) AS tiempo_total '
          'FROM partidas WHERE juego = ?',
      [juego],
    ); // max_ficha sirve para 2048, max_lineas para Tetris
    return EstadisticasGlobales.fromMap(filas.first); // Una sola fila
  }

  Future<List<EstadisticaJugador>> porJugador({String juego = '2048'}) async { // GROUP BY
    final db = await _db; // BD
    final filas = await db.rawQuery(
      'SELECT u.usuario, MAX(p.puntuacion) AS mejor, COUNT(*) AS num_partidas '
          'FROM partidas p JOIN usuarios u ON p.usuario_id = u.id '
          'WHERE p.juego = ? '
          'GROUP BY u.id ORDER BY mejor DESC',
      [juego],
    ); // Una fila por jugador, solo de ese juego
    return filas.map(EstadisticaJugador.fromMap).toList(); // Filas -> objetos
  }

  Future<int> mejorPuntuacion(int usuarioId, {String juego = '2048'}) async { // Récord de un jugador en un juego
    final db = await _db; // BD
    final filas = await db.rawQuery(
      'SELECT MAX(puntuacion) FROM partidas WHERE usuario_id = ? AND juego = ?',
      [usuarioId, juego],
    );
    return Sqflite.firstIntValue(filas) ?? 0; // Primer número de la consulta, o 0
  }

  Future<void> terminarPartida(Partida p) async { // TRANSACCIÓN: o se hace todo o nada
    final db = await _db; // BD
    await db.transaction((txn) async { // Dentro se usa txn, no db
      await txn.insert('partidas', p.toMap()); // 1) Guarda en el historial
      await txn.delete( // 2) Borra SOLO la partida en curso de este usuario y este juego
        'partida_guardada',
        where: 'usuario_id = ? AND juego = ?',
        whereArgs: [p.usuarioId, p.juego],
      );
    });
  }
}