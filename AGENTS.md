# ASHENWILD project notes

- Target Godot 4 GDScript; project was checked with Godot 4.7.2.
- Keep gameplay source-only and Android-friendly; avoid plugins and desktop-only requirements.
- Preserve keyboard fallback and simultaneous multitouch controls when changing input.
- Keep gameplay working without the generated art by retaining script-drawn fallbacks.
- Before delivering changes, run a Godot headless editor import and a short headless main-scene run. State that touch/device behavior is untested unless actually tested on Android.
- Keep new work within the current compact first-level slice unless a later phase is explicitly requested.
