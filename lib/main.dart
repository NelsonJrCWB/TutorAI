import 'package:flutter/material.dart';
import 'package:tutorai/config/api_config.dart';
import 'package:tutorai/services/gemini_live_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TutorAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LiveTutorPage(title: 'TutorAI - Espanhol com Mateo'),
    );
  }
}

class LiveTutorPage extends StatefulWidget {
  const LiveTutorPage({super.key, required this.title});

  final String title;

  @override
  State<LiveTutorPage> createState() => _LiveTutorPageState();
}

class _LiveTutorPageState extends State<LiveTutorPage> {
  final GeminiLiveService _liveService = GeminiLiveService();
  bool _isConnected = false;
  bool _isLoading = false;

  Future<void> _toggleSession() async {
    if (_isConnected) {
      setState(() => _isLoading = true);
      await _liveService.stopSession((isSpeaking) {
        setState(() {
          _isConnected = isSpeaking;
          _isLoading = false;
        });
      });
    } else {
      setState(() => _isLoading = true);
      try {
        await _liveService.startSession(
          apiKey: ApiConfig.geminiApiKey, // <--- AQUI A CHAVE API É PASSADA
          modulePrompt: "Practicar saludos, presentaciones y conversación básica.",
          onStateChange: (isSpeaking) {
            setState(() {
              _isConnected = isSpeaking;
              _isLoading = false;
            });
          },
        );
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao conectar: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              _isConnected ? Icons.mic : Icons.mic_off,
              size: 100,
              color: _isConnected ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              _isConnected
                  ? 'Sessão Ativa com o Mateo!\nPode falar em espanhol...'
                  : 'Pressione o botão para iniciar a conversa',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 40),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _toggleSession,
                icon: Icon(_isConnected ? Icons.stop : Icons.play_arrow),
                label: Text(
                  _isConnected ? 'Encerrar Conversa' : 'Iniciar Tutor IA',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  backgroundColor: _isConnected ? Colors.redAccent : Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}