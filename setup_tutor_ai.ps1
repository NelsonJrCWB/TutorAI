# Instalação e Configuração Automática do Projeto Tutor AI
$projectPath = "C:\Projects\TutorAI"

if (!(Test-Path $projectPath)) {
    New-Item -ItemType Directory -Force -Path $projectPath
}

Set-Location $projectPath

Write-Host "1. Criando estrutura do projeto Flutter..." -ForegroundColor Green
flutter create . --org com.tutorai --project-name tutorai --platforms android --overwrite

Write-Host "2. Configurando dependencias (pubspec.yaml)..." -ForegroundColor Green
@'
name: tutor_ai
description: "Tutor de Espanhol por Voz integrado à API Gemini Live e ao Curso Kultiviti"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  web_socket_channel: ^3.0.0
  record: ^5.1.2
  audioplayers: ^6.0.0
  permission_handler: ^11.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
'@ | Out-File -FilePath "$projectPath\pubspec.yaml" -Encoding utf8

Write-Host "3. Criando diretórios e arquivos de código..." -ForegroundColor Green
New-Item -ItemType Directory -Force -Path "$projectPath\lib\models"
New-Item -ItemType Directory -Force -Path "$projectPath\lib\services"

# Models (kultiviti_modules.dart)
@'
class KultivitiModule {
  final String id;
  final String title;
  final String level;
  final String prompt;

  KultivitiModule({
    required this.id,
    required this.title,
    required this.level,
    required this.prompt,
  });
}

final List<KultivitiModule> kultivitiModules = [
  KultivitiModule(
    id: "1",
    level: "Iniciante",
    title: "Presentación y Saludos",
    prompt: "El usuario está aprendiendo saludos y presentaciones. Practica cómo saludar, presentarse, preguntar nombres, nacionalidades y origen.",
  ),
  KultivitiModule(
    id: "2",
    level: "Iniciante",
    title: "Alquilar un Piso y Por la Ciudad",
    prompt: "Simula situaciones de alquiler de apartamentos, pedir direcciones en la ciudad y describir ubicaciones.",
  ),
  KultivitiModule(
    id: "3",
    level: "Iniciante",
    title: "En el Restaurant e Ir de Compras",
    prompt: "Simula estar en un restaurante pidiendo comida o en una tienda comprando ropa. Practica vocabulario de comida y precios.",
  ),
  KultivitiModule(
    id: "4",
    level: "Iniciante",
    title: "Háblame de Ti e Invitaciones",
    prompt: "Habla sobre rutinas diarias, gustos y haz invitaciones para salir. Practica conectores sencillos.",
  ),
  KultivitiModule(
    id: "5",
    level: "Iniciante",
    title: "Pasado Cercano (¿Qué Has Hecho? / ¿Qué Hiciste?)",
    prompt: "Enfócate en hacer preguntas sobre experiencias recientes y eventos pasados específicos.",
  ),
  KultivitiModule(
    id: "6",
    level: "Intermediário",
    title: "Llevo Haciendo / ¿Qué Hacía?",
    prompt: "Practica estructuras de duración ('llevo + gerundio') y el Pretérito Imperfecto.",
  ),
  KultivitiModule(
    id: "7",
    level: "Intermediário",
    title: "Futuro y Condicional (Haremos / Haría)",
    prompt: "Conversa sobre proyectos futuros y situaciones hipotéticas o consejos.",
  ),
  KultivitiModule(
    id: "8",
    level: "Intermediário",
    title: "Instrucciones y Subjuntivo (Haga / Vaya)",
    prompt: "Simula situaciones donde das instrucciones y consejos amables usando Subjuntivo e Imperativo.",
  ),
  KultivitiModule(
    id: "9",
    level: "Intermediário",
    title: "Vida Social, Trabajo y Polémica",
    prompt: "Habla sobre el entorno laboral, estilo de vida y debates sencillos.",
  ),
  KultivitiModule(
    id: "10",
    level: "Avançado",
    title: "Tecnología, Medio Ambiente y Actualidad",
    prompt: "Entabla debates profundos sobre tecnología, impacto ambiental y sociedad moderna.",
  ),
  KultivitiModule(
    id: "11",
    level: "Avançado",
    title: "Cultura, Cine y Expresiones Idiomáticas",
    prompt: "Habla sobre cine, historias y modismos o expresiones idiomáticas en español.",
  ),
];
'@ | Out-File -FilePath "$projectPath\lib\models\kultiviti_modules.dart" -Encoding utf8

# Service (gemini_live_service.dart)
@'
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
Eres Mateo, un tutor nativo de español paciente y dinámico.
Tu objetivo es ayudar al usuario a practicar el módulo del curso Kultiviti:

OBJETIVO ESPECÍFICO: $modulePrompt

Reglas:
1. Responde SIEMPRE en español claro y natural (máximo 2-3 frases por turno).
2. Haz correcciones gentiles e inmediatas si el usuario comete errores gramaticales o de pronunciación.
3. Termina siempre tu turno con una pregunta sencilla para mantener el diálogo activo.
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
'@ | Out-File -FilePath "$projectPath\lib\services\gemini_live_service.dart" -Encoding utf8

# App UI (main.dart)
@'
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'models/kultiviti_modules.dart';
import 'services/gemini_live_service.dart';

void main() {
  runApp(const TutorApp());
}

class TutorApp extends StatelessWidget {
  const TutorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tutor AI - Kultiviti',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const TutorHomePage(),
    );
  }
}

class TutorHomePage extends StatefulWidget {
  const TutorHomePage({super.key});

  @override
  State<TutorHomePage> createState() => _TutorHomePageState();
}

class _TutorHomePageState extends State<TutorHomePage> {
  final GeminiLiveService _liveService = GeminiLiveService();
  final TextEditingController _apiKeyController = TextEditingController();
  
  KultivitiModule _selectedModule = kultivitiModules.first;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
  }

  void _toggleSession() async {
    if (_apiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe sua chave Gemini API')),
      );
      return;
    }

    if (_isActive) {
      await _liveService.stopSession((speaking) {
        setState(() => _isActive = speaking);
      });
    } else {
      await _liveService.startSession(
        apiKey: _apiKeyController.text.trim(),
        modulePrompt: _selectedModule.prompt,
        onStateChange: (speaking) {
          setState(() => _isActive = speaking);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutor Praktika - Espanhol'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Gemini API Key',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<KultivitiModule>(
              value: _selectedModule,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Módulo Kultiviti',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
              items: kultivitiModules.map((module) {
                return DropdownMenuItem(
                  value: module,
                  child: Text(
                    '[${module.level}] ${module.title}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _isActive
                  ? null
                  : (val) {
                      if (val != null) setState(() => _selectedModule = val);
                    },
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _isActive ? 160 : 120,
                      height: _isActive ? 160 : 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isActive
                            ? Colors.redAccent.withOpacity(0.2)
                            : Colors.deepPurple.withOpacity(0.2),
                        border: Border.all(
                          color: _isActive ? Colors.redAccent : Colors.deepPurple,
                          width: 4,
                        ),
                      ),
                      child: Icon(
                        _isActive ? Icons.mic : Icons.mic_none,
                        size: 64,
                        color: _isActive ? Colors.redAccent : Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isActive
                          ? 'Mateo está escutando...'
                          : 'Toque para iniciar a conversa',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isActive ? Colors.red : Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: _toggleSession,
                icon: Icon(_isActive ? Icons.call_end : Icons.call),
                label: Text(
                  _isActive ? 'Encerrar Conversa' : 'Iniciar Conversa',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
'@ | Out-File -FilePath "$projectPath\lib\main.dart" -Encoding utf8

Write-Host "4. Instalando os pacotes do Flutter (pub get)..." -ForegroundColor Green
flutter pub get

Write-Host "5. Atualizando o AndroidManifest.xml com permissoes de Audio e Internet..." -ForegroundColor Green
$manifestPath = "$projectPath\android\app\src\main\AndroidManifest.xml"
$manifestContent = Get-Content $manifestPath -Raw
if ($manifestContent -notmatch "RECORD_AUDIO") {
    $manifestContent = $manifestContent -replace '<manifest xmlns:android="http://schemas.android.com/apk/res/android">', '<manifest xmlns:android="http://schemas.android.com/apk/res/android"><uses-permission android:name="android.permission.INTERNET"/><uses-permission android:name="android.permission.RECORD_AUDIO"/><uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>'
    Set-Content -Path $manifestPath -Value $manifestContent -Encoding utf8
}

Write-Host "`n[SUCESSO] Projeto TutorAI totalmente configurado!" -ForegroundColor Yellow
Write-Host "Abrindo no VS Code..." -ForegroundColor Yellow
code .