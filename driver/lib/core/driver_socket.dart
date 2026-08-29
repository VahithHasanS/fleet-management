import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import 'config.dart';

/// Socket.io client for the driver app.
///
/// Two jobs:
/// 1. Subscribe to the tenant room (`live:subscribe`) so the driver receives
///    `live:event`, `live:alert`, `live:sos` pushes (coaching feedback loop).
/// 2. Stream telemetry batches from the device to the backend via the
///    `telemetry` message — the same ingestion path the Phantom Fleet
///    simulator uses (`schemaVersion 1.2`).
class DriverSocket {
  io.Socket? _socket;
  bool _connected = false;
  int _seq = 0;

  void Function(LiveMessage message)? onMessage;
  void Function(bool connected)? onConnectionChange;

  DriverSocket() {
    onMessage = (_) {};
    onConnectionChange = (_) {};
  }

  bool get connected => _connected;

  void connect({required String token}) {
    disconnect();
    _socket = io.io(
      AppConfig.apiUrl,
      io.OptionBuilder()
          .setPath(AppConfig.wsPath)
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      _connected = true;
      onConnectionChange?.call(true);
    });
    _socket!.onDisconnect((_) {
      _connected = false;
      onConnectionChange?.call(false);
    });
    _socket!.onConnectError((_) {});

    _socket!.onAny((event, data) {
      switch (event) {
        case 'connect':
        case 'disconnect':
        case 'connect_error':
        case 'reconnect':
        case 'reconnect_attempt':
        case 'error':
          return;
        default:
          final payload =
              data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
          onMessage?.call(LiveMessage(event, payload));
      }
    });

    _socket!.connect();
  }

  void subscribe({required String tenantId}) {
    _socket?.emit('live:subscribe', {'tenantId': tenantId});
  }

  /// Streams one telemetry batch. Returns the server ack
  /// (`{status, reason?}`) or `null` on timeout/disconnect.
  Future<Map<String, dynamic>?> sendBatch(Map<String, dynamic> batch) {
    final completer = Completer<Map<String, dynamic>?>();
    final socket = _socket;
    if (socket == null || !_connected) {
      completer.complete(null);
      return completer.future;
    }
    // Ack comes back on the same 'telemetry' event (Nest returns the value).
    void ack(dynamic data) {
      if (!completer.isCompleted) {
        completer.complete(
          data is Map ? Map<String, dynamic>.from(data) : null,
        );
      }
    }

    socket.emitWithAck('telemetry', batch, ack: ack);
    Timer(const Duration(seconds: 8), () {
      if (!completer.isCompleted) completer.complete(null);
    });
    return completer.future;
  }

  int nextSeq() => ++_seq;

  /// Streams one cabin-camera frame to the backend for the admin live feed.
  /// Returns the server ack or null when offline.
  Future<Map<String, dynamic>?> sendVideoFrame(Map<String, dynamic> frame) {
    final completer = Completer<Map<String, dynamic>?>();
    final socket = _socket;
    if (socket == null || !_connected) {
      completer.complete(null);
      return completer.future;
    }
    socket.emitWithAck('video:frame', frame, ack: (dynamic data) {
      if (!completer.isCompleted) {
        completer.complete(data is Map ? Map<String, dynamic>.from(data) : null);
      }
    });
    Timer(const Duration(seconds: 4), () {
      if (!completer.isCompleted) completer.complete(null);
    });
    return completer.future;
  }

  /// Reports a camera AI breach (drowsiness / eye closure / distraction).
  Future<Map<String, dynamic>?> sendVideoBreach(Map<String, dynamic> breach) {
    final completer = Completer<Map<String, dynamic>?>();
    final socket = _socket;
    if (socket == null || !_connected) {
      completer.complete(null);
      return completer.future;
    }
    socket.emitWithAck('video:breach', breach, ack: (dynamic data) {
      if (!completer.isCompleted) {
        completer.complete(data is Map ? Map<String, dynamic>.from(data) : null);
      }
    });
    Timer(const Duration(seconds: 6), () {
      if (!completer.isCompleted) completer.complete(null);
    });
    return completer.future;
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _connected = false;
  }
}

class LiveMessage {
  final String event;
  final Map<String, dynamic> data;
  LiveMessage(this.event, this.data);
}
