import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:http/http.dart' as http;

class QuizModel {
  final String question;
  final List<String> options;
  final String answer;

  QuizModel({required this.question, required this.options, required this.answer});

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      question: json['question'],
      options: List<String>.from(json['options']),
      answer: json['answer'],
    );
  }
}

class StoryData {
  final String storyText;
  final QuizModel quiz;

  StoryData({required this.storyText, required this.quiz});
}

class AiStoryService {
  static const String _apiKey = 'groq_api_key'; // Replace with your actual API key
  static const String _apiUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static Future<StoryData> generateNewStoryAndQuiz() async {
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        "model": "openai/gpt-oss-20b",
        "messages": [
          {
            "role": "system",
            "content": "You are a children's story creator. Generate a 7-sentence story for kids and a multiple-choice question about it. Return strictly in JSON format: {\"story\": \"...\", \"quiz\": {\"question\": \"...\", \"options\": [\"...\", \"...\", \"...\", \"...\"], \"answer\": \"...\"}}"
          }
        ],
        "response_format": {"type": "json_object"}
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final content = responseBody['choices'][0]['message']['content'];
      final Map<String, dynamic> data = jsonDecode(content);
      
      return StoryData(
        storyText: data['story'],
        quiz: QuizModel.fromJson(data['quiz']),
      );
    } else {
      throw Exception('Failed to load AI content');
    }
  }
}

class StoryProvider with ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isPlaying = false;
  bool _showQuiz = false;
  bool _isLoading = false;
  bool _isSuccess = false;
  String _errorMessage = "";
  
  String _currentStoryText = "";
  QuizModel? _quizData;

  bool get isPlaying => _isPlaying;
  bool get showQuiz => _showQuiz;
  bool get isLoading => _isLoading;
  bool get isSuccess => _isSuccess;
  String get errorMessage => _errorMessage;
  String get currentStoryText => _currentStoryText;
  QuizModel? get quizData => _quizData;

  StoryProvider() {
    _initTts();
    generateAiContent();
  }

  void _initTts() {
    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
      _showQuiz = true;
      notifyListeners();
    });
    
    _flutterTts.setErrorHandler((msg) {
      _isPlaying = false;
      _isLoading = false;
      _errorMessage = "Oops! Buddy lost his voice. Try again!";
      notifyListeners();
    });
  }

  Future<void> generateAiContent() async {
    _isLoading = true;
    _showQuiz = false;
    _isSuccess = false;
    _errorMessage = "";
    notifyListeners();

    try {
      final aiResult = await AiStoryService.generateNewStoryAndQuiz();
      _currentStoryText = aiResult.storyText;
      _quizData = aiResult.quiz;
    } catch (e) {
      _errorMessage = "Failed to generate AI story. Please check your API key and connection.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> readStory() async {
    if (_currentStoryText.isEmpty) return;
    
    _isLoading = true;
    _errorMessage = "";
    notifyListeners();

    try {
      await _flutterTts.setLanguage("en-IN");
      await _flutterTts.setSpeechRate(0.4);
      _isLoading = false;
      _isPlaying = true;
      notifyListeners();
      await _flutterTts.speak(_currentStoryText);
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Audio error. Let's try again!";
      notifyListeners();
    }
  }

  void checkAnswer(String selectedOption) {
    if (selectedOption == _quizData!.answer) {
      _isSuccess = true;
    } else {
      _isSuccess = false;
    }
    notifyListeners();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => StoryProvider(),
      child: const PebloApp(),
    ),
  );
}

class PebloApp extends StatelessWidget {
  const PebloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Peblo AI Buddy',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'ComicSans',
      ),
      home: const StoryScreen(),
    );
  }
}

class StoryScreen extends StatelessWidget {
  const StoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StoryProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.orangeAccent,
                child: Icon(Icons.smart_toy, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),
              if (provider.isLoading && provider.currentStoryText.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: Text(
                    provider.currentStoryText,
                    style: const TextStyle(fontSize: 20, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 30),
              if (provider.errorMessage.isNotEmpty)
                Text(provider.errorMessage, style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
              if (!provider.showQuiz)
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: provider.isLoading || provider.isPlaying 
                          ? null 
                          : () => provider.readStory(),
                      icon: provider.isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Icon(Icons.volume_up),
                      label: Text(provider.isPlaying ? "Reading..." : "Read Me a Story"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextButton.icon(
                      onPressed: provider.isLoading || provider.isPlaying ? null : () => provider.generateAiContent(),
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text("Generate New AI Story"),
                    )
                  ],
                )
              else
                Expanded(child: QuizWidget(quizData: provider.quizData!)),
            ],
          ),
        ),
      ),
    );
  }
}

class QuizWidget extends StatefulWidget {
  final QuizModel quizData;
  const QuizWidget({super.key, required this.quizData});

  @override
  State<QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 24)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _shakeController.reset();
        }
      });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _handleAnswer(String option, StoryProvider provider) {
    provider.checkAnswer(option);
    if (provider.isSuccess) {
      _confettiController.play();
    } else {
      _shakeController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StoryProvider>(context, listen: false);

    return SingleChildScrollView(
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(sin(_shakeAnimation.value * pi) * 10, 0),
            child: child,
          );
        },
        child: Column(
          children: [
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
            if (provider.isSuccess)
               const Padding(
                 padding: EdgeInsets.only(bottom: 15.0),
                 child: Text("Great Job!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
               ),
            Text(
              widget.quizData.question,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ...widget.quizData.options.map((option) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ElevatedButton(
                    onPressed: provider.isSuccess ? null : () => _handleAnswer(option, provider),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.deepPurple.shade100, width: 2)
                      ),
                      elevation: 2,
                    ),
                    child: Text(option, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                )),
            const SizedBox(height: 20),
            if (provider.isSuccess)
              ElevatedButton.icon(
                onPressed: () => provider.generateAiContent(),
                icon: const Icon(Icons.refresh),
                label: const Text("Play Again!"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.white,
                ),
              )
          ],
        ),
      ),
    );
  }
}
