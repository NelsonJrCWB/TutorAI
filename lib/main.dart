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
                labelText: 'MÃ³dulo Kultiviti',
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
                          ? 'Mateo estÃ¡ escutando...'
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
