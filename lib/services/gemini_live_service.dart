import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class GeminiLiveService {
  WebSocketChannel? _channel;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _recorderSubscription;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<void> startSession({
    required String apiKey,
    required String modulePrompt,
    required Function(bool isSpeaking) onStateChange,
  }) async {
    final uri = Uri.parse(
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=$apiKey',
    );

    _channel = IOWebSocketChannel.connect(uri);
    _isConnected = true;
    onStateChange(true);

    final systemInstruction = '''
Eres Mateo, un tutor nativo de espaÃ±ol paciente y dinÃ¡mico.
Tu objetivo es ayudar al usuario a practicar el mÃ³dulo del curso Kultiviti:

OBJETIVO ESPECÃFICO: $modulePrompt

Reglas:
1. Responde SIEMPRE en espaÃ±ol claro y natural (mÃ¡ximo 2-3 frases por turno).
2. Haz correcciones gentiles e inmediatas si el usuario comete errores gramaticales o de pronunciaciÃ³n.
3. Termina siempre tu turno con una pregunta sencilla para mantener el diÃ¡logo activo.
''';

    final setupMessage = {
      "setup": {
        "model": "models/gemini-2.0-flash-exp",
        "generationConfig": {
          "responseModalities": ["AUDIO"],
          "speechConfig": {
            "voiceConfig": {
              "prebuiltVoiceConfig": {"voiceName": "Kore"}
            }
          }
        },
        "systemInstruction": {
          "parts": [
            {"text": systemInstruction}
          ]
        }
      }
    };

    _channel?.sink.add(jsonEncode(setupMessage));

    _channel?.stream.listen(
      (data) async {
        if (data is String) {
          final response = jsonDecode(data);
          final serverContent = response['serverContent'];
          if (serverContent != null && serverContent['modelTurn'] != null) {
            final parts = serverContent['modelTurn']['parts'] as List?;
            if (parts != null) {
              for (var part in parts) {
                if (part['inlineData'] != null) {
                  String base64Audio = part['inlineData']['data'];
                  Uint8List audioBytes = base64Decode(base64Audio);
                  await _audioPlayer.play(BytesSource(audioBytes));
                }
              }
            }
          }
        }
      },
      onError: (error) => stopSession(onStateChange),
      onDone: () => stopSession(onStateChange),
    );

    final stream = await _audioRecorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    _recorderSubscription = stream.listen((Uint8List data) {
      if (_isConnected && _channel != null) {
        final base64Audio = base64Encode(data);
        final audioMessage = {
          "realtimeInput": {
            "mediaChunks": [
              {
                "mimeType": "audio/pcm",
                "data": base64Audio,
              }
            ]
          }
        };
        _channel?.sink.add(jsonEncode(audioMessage));
      }
    });
  }

  Future<void> stopSession(Function(bool isSpeaking) onStateChange) async {
    _isConnected = false;
    await _recorderSubscription?.cancel();
    await _audioRecorder.stop();
    await _audioPlayer.stop();
    await _channel?.sink.close();
    onStateChange(false);
  }
}
