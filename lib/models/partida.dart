class Partida { // Una fila de la tabla partidas
  final int? id; // null hasta que se inserta
  final int usuarioId; // Clave foránea -> usuarios.id
  final String? usuario; // Nombre del jugador (viene del JOIN, no es columna)
  final int puntuacion; // Puntos
  final int fichaMaxima; // Ficha más alta (solo 2048; en Tetris queda a 0)
  final int movimientos; // Movimientos hechos (en Tetris: piezas colocadas)
  final int duracionSegundos; // Duración
  final String fecha; // Fecha en texto ISO 8601
  final int tamanoTablero; // Columna añadida en la versión 2
  final String juego; // '2048' o 'tetris' (versión 3)
  final int lineas; // Líneas completadas, solo Tetris (versión 3)

  Partida({
    this.id,
    required this.usuarioId,
    this.usuario,
    required this.puntuacion,
    this.fichaMaxima = 0, // Ya no es required: el Tetris no la usa
    required this.movimientos,
    required this.duracionSegundos,
    required this.fecha,
    this.tamanoTablero = 4, // Por defecto 4
    this.juego = '2048', // Por defecto 2048, así lo que ya tenías no cambia
    this.lineas = 0,
  });

  Map<String, Object?> toMap() => { // Objeto -> BD (sin "usuario", no es columna)
    'id': id,
    'usuario_id': usuarioId,
    'puntuacion': puntuacion,
    'ficha_maxima': fichaMaxima,
    'movimientos': movimientos,
    'duracion_segundos': duracionSegundos,
    'fecha': fecha,
    'tamano_tablero': tamanoTablero,
    'juego': juego,
    'lineas': lineas,
  };

  factory Partida.fromMap(Map<String, Object?> m) => Partida( // BD -> objeto
    id: m['id'] as int,
    usuarioId: m['usuario_id'] as int,
    usuario: m['usuario'] as String?,
    puntuacion: m['puntuacion'] as int,
    fichaMaxima: m['ficha_maxima'] as int,
    movimientos: m['movimientos'] as int,
    duracionSegundos: m['duracion_segundos'] as int,
    fecha: m['fecha'] as String,
    tamanoTablero: m['tamano_tablero'] as int,
    juego: m['juego'] as String,
    lineas: m['lineas'] as int,
  );
}