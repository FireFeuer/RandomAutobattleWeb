import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket socket;

  factory SocketService() => _instance;

  SocketService._internal() {
    socket = IO.io('http://26.108.119.120:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 1000,
    });
    
    socket.connect();
    
    socket.onConnect((_) {
      print('✅ Connected to Server');
    });
    
    socket.onDisconnect((_) {
      print('❌ Disconnected from Server');
    });
    
    socket.onError((error) {
      print('⚠️ Socket Error: $error');
    });
    
    // Логируем все события для отладки
    socket.onAny((event, data) {
      print('📡 Socket event received: $event, data: $data');
    });
  }

  void createLobby(String playerName) {
    print('🚀 Creating lobby for $playerName');
    socket.emit('create_lobby', {'name': playerName});
  }

  void joinLobby(String matchId, String playerName) {
    print('🚀 Joining lobby $matchId as $playerName');
    socket.emit('join_lobby', {'match_id': matchId, 'name': playerName});
  }

  void choosePerk(String matchId, String perkId) {
    print('🎯 Choosing perk $perkId for match $matchId');
    socket.emit('choose_perk', {'match_id': matchId, 'perk_id': perkId});
  }
}