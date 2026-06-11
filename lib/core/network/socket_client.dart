import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/app_constants.dart';
import '../storage/secure_storage.dart';

class SocketClient {
  static final SocketClient _instance = SocketClient._internal();
  IO.Socket? _socket;

  factory SocketClient() {
    return _instance;
  }

  SocketClient._internal();

  IO.Socket? get socket => _socket;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await SecureStorage.getToken(AppConstants.tokenKey);
    
    _socket = IO.io(AppConstants.socketUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .setPath('/realtime/')
        .setAuth({'token': token})
        .enableAutoConnect()
        .build());

    _socket?.onConnect((_) {
      print('Socket connected: ${_socket?.id}');
    });

    _socket?.onDisconnect((_) {
      print('Socket disconnected');
    });

    _socket?.onError((data) {
      print('Socket Error: $data');
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
