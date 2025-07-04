- Android Controls: ./media_kit_video/lib/media_kit_video_controls/src/controls/material.dart

  - in that: `_MaterialVideoControls` stateful widget

- `VideoState` in `video_texture.dart`
  - it links the method `enterFullScreen`
- `enterFullscreen` in `methods/fullScreen.dart`
- `Video` - `video_texture` and `video_web`
- `AdaptiveVideoControls`
  - based on platform, it says which controls to use
- `MaterialVideoControls`
  - just a wrapper around below widget, its stateless widget
- `VideoControlsThemeDataInjector` (stateful widget)
  - it just injects both `normal` and `fullscreen` themes to below widget
- `MaterialVideoControlsTheme` (InheritedWidget)
  - it receives `normal` and `fullscreen` themes
- `_MaterialVideoControls` (stateful widget)
  - it uses the the theme properties and base on it renders the controls.

`isFullscreen(context)`
