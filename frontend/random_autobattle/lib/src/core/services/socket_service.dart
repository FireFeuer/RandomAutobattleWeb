import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket socket;

  factory SocketService() => _instance;

  SocketService._internal() {
    // В реальном проекте IP лучше вынести в конфиг
    socket = IO.io('http://26.108.119.120:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 1000,
    });
    
    socket.connect();
    
    socket.onConnect((_) => print('✅ Connected to Server'));
    socket.onDisconnect((_) => print('❌ Disconnected from Server'));
    socket.onError((error) => print('⚠️ Socket Error: $error'));
    socket.onAny((event, data) => print('📡 Event: $event'));
  }

  // Методы-обертки для удобства
  void emit(String event, [dynamic data]) {
    socket.emit(event, data);
  }

  void off(String event) {
    socket.off(event);
  }
}