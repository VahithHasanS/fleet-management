import 'package:socket_io_client/socket_io_client.dart' as io;

import 'config.dart';

/// Socket.io client wrapper for the live telemetry channel.
///
/// On connect it authenticates with the access token (via the handshake),
/// subscribes to the tenant room with `live:subscribe`, then fans out the
/// server-pushed events (`live:position`, `live:event`, `live:alert`,
/// `live:sos`, `live:leaderboard`, `simulator:status`) to registered handlers.
class LiveSocket {
  io.Socket? _socket;
  bool _connected = false;

  void Function(LiveMessage message)? onMessage;
  void Function(bool connected)? onConnectionChange;

  LiveSocket() {
    onMessage = (_) {};
    onConnectionChange = (_) {};
  }

  bool get connected => _connected;

  void connect({required String token, required String? tenantId}) {
    disconnect();
    _socket = io.io(
      AppConfig.backendUrl,
      io.OptionBuilder()
          .setPath('/ws')
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      _connected = true;
      onConnectionChange?.call(true);
      _socket!.emit('live:subscribe', {'tenantId': tenantId ?? ''});
      // Opt into the per-tenant driver camera frame stream.
      _socket!.emit('video:subscribe', {'tenantId': tenantId ?? ''});
      // Re-subscribe when reconnecting.
    });
    // socket_io_client does not reliably re-fire onConnect for reconnects, so
    // re-subscribe on 'reconnect' too.
    _socket!.on('reconnect', (_) {
      _socket!.emit('live:subscribe', {'tenantId': tenantId ?? ''});
      _socket!.emit('video:subscribe', {'tenantId': tenantId ?? ''});
    });

    _socket!.onConnectError((_) {});
    _socket!.onDisconnect((_) {
      _connected = false;
      onConnectionChange?.call(false);
    });

    _socket!.onAny((event, data) {
      switch (event) {
        case 'connect':
        case 'disconnect':
        case 'connect_error':
        case 'reconnect':
        case 'reconnect_attempt':
        case 'error':
          break;
        default:
          final payload = data is Map
              ? Map<String, dynamic>.from(data)
              : <String, dynamic>{};
          onMessage?.call(LiveMessage(event, payload));
      }
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _connected = false;
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }
}

class LiveMessage {
  final String event;
  final Map<String, dynamic> data;
  LiveMessage(this.event, this.data);
}
