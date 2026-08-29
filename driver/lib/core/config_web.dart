import 'dart:js_interop';

@JS('window.ghostApiUrl')
external JSString? get _ghostApiUrl;

String? get ghostApiUrl => _ghostApiUrl?.toDart;
