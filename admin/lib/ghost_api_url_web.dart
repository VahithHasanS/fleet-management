// Web-only implementation: reads `window.ghostApiUrl` set in web/index.html
// so the demo can target a remote backend without a rebuild.
import 'dart:js_interop';

@JS('window.ghostApiUrl')
external JSString? _windowGhostApiUrl;

void updateFromWindowGhostApiUrl(void Function(String?) onUpdate) {
  final v = _windowGhostApiUrl;
  if (v != null) onUpdate(v.toDart);
}
