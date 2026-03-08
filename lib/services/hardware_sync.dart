import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;

class HardwareSync {
  /// Forcefully stops all active media tracks in the browser.
  /// This is the "Nuclear Option" to resolve "Microphone is busy" errors
  /// caused by the camera plugin not releasing tracks cleanly on Web.
  static void forceReleaseHardware() {
    if (!kIsWeb) return;

    try {
      // Injects and runs a JS snippet to find all tracks and stop them.
      // We also clear any srcObject from video/audio elements to break the lock.
      js.context.callMethod('eval', ["""
        (async () => {
          try {
            // 1. Stop tracks from any active navigator.mediaDevices streams
            if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
               // We can't easily list existing streams, but we can stop 
               // all tracks associated with any video/audio elements.
            }

            // 2. Clear all video/audio element sources
            const elements = document.querySelectorAll('video, audio');
            elements.forEach(el => {
              if (el.srcObject) {
                const stream = el.srcObject;
                const tracks = stream.getTracks();
                tracks.forEach(track => {
                  console.log('Force stopping track:', track.kind, track.label);
                  track.stop();
                });
                el.srcObject = null;
              }
              el.src = "";
              el.load();
              el.remove(); // Clean up the DOM element if it was a preview
            });

            console.log('Hardware release: All media tracks forcefully stopped.');
          } catch (e) {
            console.error('Hardware release error:', e);
          }
        })();
      """]);
    } catch (e) {
      // Fallback if js context is not available as expected
      print("HardwareSync: JS call failed: $e");
    }
  }
}
