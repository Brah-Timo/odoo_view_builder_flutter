// lib/presentation/notifiers/view_notifier.dart
//
// Re-exports the primary CurrentViewNotifier so it can be imported
// from a single path when other screens need it.

export '../providers/editor_state_provider.dart'
    show CurrentViewNotifier, currentViewProvider;
