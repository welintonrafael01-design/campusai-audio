import '../campus_intelligence/enterprise_result_repository.dart';

class ConversationPipeline {
  final List<String> stages;
  const ConversationPipeline({
    this.stages = const [
      'listen',
      'transcribe',
      'understand',
      'retrieve_context',
      'respond',
      'synthesize',
      'remember'
    ],
  });

  Map<String, dynamic> toJson() => {'stages': stages};
}

class VoiceSessionManager {
  final List<String> activeSessions = [];

  void start(String sessionId) {
    if (!activeSessions.contains(sessionId)) activeSessions.add(sessionId);
  }

  void end(String sessionId) => activeSessions.remove(sessionId);
}

class VoiceInterruptions {
  const VoiceInterruptions();
  bool shouldInterrupt(
          {required double userSpeechEnergy, bool wakeWord = false}) =>
      wakeWord || userSpeechEnergy > .7;
}

class VoiceQueue {
  final List<String> utterances = [];
  void enqueue(String text) => utterances.add(text);
  String? take() => utterances.isEmpty ? null : utterances.removeAt(0);
}

class VoiceConversationMemory {
  final List<String> turns = [];
  void remember(String turn) => turns.add(turn);
  List<String> latest({int limit = 8}) => turns.reversed.take(limit).toList();
}

class WakeWordController {
  final String wakeWord;
  const WakeWordController({this.wakeWord = 'studybook'});
  bool detected(String transcript) =>
      transcript.toLowerCase().contains(wakeWord.toLowerCase());
}

class StreamingController {
  const StreamingController();
  bool get enabled => false;
  String get status => 'stub';
}

class SpeechPipeline {
  final ConversationPipeline conversation;
  const SpeechPipeline({this.conversation = const ConversationPipeline()});

  Map<String, dynamic> describe() => {
        'conversation': conversation.toJson(),
        'streaming': const StreamingController().status,
      };
}

class VoiceV5FoundationService {
  final EnterpriseResultRepository repository;
  const VoiceV5FoundationService({
    this.repository = const EnterpriseResultRepository(),
  });

  Future<void> savePipeline(SpeechPipeline pipeline) => repository.save(
        documentId: 'voice_pipeline_latest',
        type: 'voice_pipeline',
        payload: pipeline.describe(),
      );
}
