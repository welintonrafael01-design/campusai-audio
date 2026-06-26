import 'dart:collection';

/// Non-streaming contracts for Voice Intelligence 4.0. Transport stays optional.
enum VoicePipelineState {
  idle,
  listening,
  processing,
  speaking,
  interrupted,
  error
}

class VoicePipelineEvent {
  final String id;
  final String type;
  final String content;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const VoicePipelineEvent({
    this.id = '',
    this.type = 'message',
    this.content = '',
    required this.createdAt,
    this.metadata = const {},
  });
}

abstract class VoicePipeline {
  Future<void> start();
  Future<void> stop();
  Future<void> submit(VoicePipelineEvent event);
  VoicePipelineState get state;
}

/// FIFO queue that keeps conversational work deterministic until streaming lands.
class VoiceConversationQueue {
  final Queue<VoicePipelineEvent> _items = Queue<VoicePipelineEvent>();

  bool get isEmpty => _items.isEmpty;
  int get length => _items.length;

  void enqueue(VoicePipelineEvent event) {
    if (event.content.trim().isNotEmpty) _items.addLast(event);
  }

  VoicePipelineEvent? takeNext() =>
      _items.isEmpty ? null : _items.removeFirst();

  void clear() => _items.clear();
}

class VoiceInterruptManager {
  bool _interrupted = false;
  String _reason = '';

  bool get isInterrupted => _interrupted;
  String get reason => _reason;

  void interrupt(String reason) {
    _interrupted = true;
    _reason = reason.trim();
  }

  void resume() {
    _interrupted = false;
    _reason = '';
  }
}

/// Owns an in-memory queue and state only; it does not replace existing sessions.
class VoiceSessionManager implements VoicePipeline {
  final VoiceConversationQueue queue;
  final VoiceInterruptManager interruptManager;
  VoicePipelineState _state = VoicePipelineState.idle;

  VoiceSessionManager({
    VoiceConversationQueue? queue,
    VoiceInterruptManager? interruptManager,
  })  : queue = queue ?? VoiceConversationQueue(),
        interruptManager = interruptManager ?? VoiceInterruptManager();

  @override
  VoicePipelineState get state => _state;

  @override
  Future<void> start() async {
    interruptManager.resume();
    _state = VoicePipelineState.listening;
  }

  @override
  Future<void> stop() async {
    queue.clear();
    _state = VoicePipelineState.idle;
  }

  @override
  Future<void> submit(VoicePipelineEvent event) async {
    if (interruptManager.isInterrupted) {
      _state = VoicePipelineState.interrupted;
      return;
    }
    queue.enqueue(event);
    _state = VoicePipelineState.processing;
  }

  VoicePipelineEvent? nextEvent() {
    if (interruptManager.isInterrupted) {
      _state = VoicePipelineState.interrupted;
      return null;
    }
    final event = queue.takeNext();
    _state = event == null
        ? VoicePipelineState.listening
        : VoicePipelineState.processing;
    return event;
  }

  void interrupt(String reason) {
    interruptManager.interrupt(reason);
    _state = VoicePipelineState.interrupted;
  }
}

/// Small controller intended for future UI adapters; no stream transport yet.
class VoiceConversationController {
  final VoiceSessionManager sessionManager;

  VoiceConversationController({VoiceSessionManager? sessionManager})
      : sessionManager = sessionManager ?? VoiceSessionManager();

  Future<void> begin() => sessionManager.start();
  Future<void> end() => sessionManager.stop();
  Future<void> enqueueUserMessage(String content) => sessionManager.submit(
        VoicePipelineEvent(
          id: 'voice_${DateTime.now().microsecondsSinceEpoch}',
          type: 'user_message',
          content: content,
          createdAt: DateTime.now(),
        ),
      );
  void interrupt(String reason) => sessionManager.interrupt(reason);
}
