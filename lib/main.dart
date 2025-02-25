import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:projectaig/views/splashscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'service/photo_monitoring_service.dart';
import 'service/sound_monitoring_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CameraService()..initialize(),
        ),
        ChangeNotifierProxyProvider<CameraService, SoundMonitoringService>(
          create: (context) => SoundMonitoringService(
            context.read<CameraService>(),
          )..initialize(),
          update: (context, cameraService, previous) =>
          previous ?? SoundMonitoringService(cameraService)..initialize(),
        ),
      ],
      child: const SecretCalculatorApp(),
    ),
  );
}

class SecretCalculatorApp extends StatelessWidget {
  const SecretCalculatorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        fontFamily: 'Roboto',
      ),
      home: const CalculatorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({Key? key}) : super(key: key);

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = "0";
  String _currentInput = "";
  String _secretCode = "";
  bool _hasCodeBeenSet = false;
  bool _isSettingCodeMode = false;
  bool _hasPermission = false;


  @override
  void initState() {
    super.initState();
    _loadSecretCode();
    _requestPermissions();
  }
  Future<void> _requestPermissions() async {
    final status = await Permission.microphone.request();
    setState(() {
      _hasPermission = status.isGranted;
    });

    if (_hasPermission) {
      await context.read<SoundMonitoringService>().initialize();
    }
    context.read<SoundMonitoringService>().startMonitoring();
  }

  // Load the secret code from shared preferences
  Future<void> _loadSecretCode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _secretCode = prefs.getString('secretCode') ?? "";
      _hasCodeBeenSet = _secretCode.isNotEmpty;
      if (!_hasCodeBeenSet) {
        // If code hasn't been set, show dialog on first app open
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSetCodeDialog();
        });
      }
    });
  }

  // Save the secret code to shared preferences
  Future<void> _saveSecretCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('secretCode', code);
    setState(() {
      _secretCode = code;
      _hasCodeBeenSet = true;
    });
  }

  void _showSetCodeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String tempCode = "";
        String confirmCode = "";
        bool confirmingCode = false;

        return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(confirmingCode ? 'Confirm Secret Code' : 'Set Your Secret Code'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      confirmingCode
                          ? 'Please enter your code again to confirm'
                          : 'Enter a numeric code that will be used to access your secret area',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      autofocus: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter code',
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          if (confirmingCode) {
                            confirmCode = value;
                          } else {
                            tempCode = value;
                          }
                        });
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      if (confirmingCode) {
                        // Going back to first entry
                        setDialogState(() {
                          confirmingCode = false;
                          tempCode = "";
                          confirmCode = "";
                        });
                      } else {
                        // User cancelled during initial setup - use a default code
                        _saveSecretCode("123456");
                        Navigator.pop(context);
                      }
                    },
                    child: Text(confirmingCode ? 'Back' : 'Use Default (123456)'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (!confirmingCode) {
                        if (tempCode.isNotEmpty) {
                          // Move to confirmation step
                          setDialogState(() {
                            confirmingCode = true;
                          });
                        }
                      } else {
                        // Validate codes match
                        if (tempCode == confirmCode) {
                          _saveSecretCode(tempCode);
                          Navigator.pop(context);
                        } else {
                          // Codes don't match, go back to first entry
                          setDialogState(() {
                            confirmingCode = false;
                            tempCode = "";
                            confirmCode = "";
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Codes do not match. Try again.')),
                            );
                          });
                        }
                      }
                    },
                    child: Text(confirmingCode ? 'Confirm' : 'Next'),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  void _onButtonPressed(String buttonText) {
    setState(() {
      // Handle equals button differently to check for secret code
      if (buttonText == "=") {
        if (_currentInput == _secretCode) {
          // Navigate to secret screen if input matches secret code
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>  SplashScreen()),
          );
          _currentInput = "";
          _display = "0";
          return;
        } else {
          // Calculate result normally
          try {
            _calculateResult();
            _currentInput = _display; // Store result as current input
          } catch (e) {
            _display = "Error";
            _currentInput = "";
          }
          return;
        }
      }

      // Handle different button presses
      if (buttonText == "C") {
        context.read<SoundMonitoringService>().startMonitoring();
        _display = "0";
        _currentInput = "";
      } else if (buttonText == "⌫") {
        if (_display.length > 1) {
          _display = _display.substring(0, _display.length - 1);
          _currentInput = _currentInput.substring(0, _currentInput.length - 1);
        } else {
          _display = "0";
          _currentInput = "";
        }
      } else {
        // Add to display and current input
        if (_display == "0" && !isOperator(buttonText) && buttonText != ".") {
          _display = buttonText;
          _currentInput += buttonText;
        } else {
          _display += buttonText;

          // Only add digits to _currentInput for secret code checking
          if (!isOperator(buttonText) && buttonText != ".") {
            _currentInput += buttonText;
          } else {
            // If an operator is pressed, reset the secret code sequence
            _currentInput = "";
          }
        }
      }
    });
  }

  bool isOperator(String text) {
    return text == "+" || text == "-" || text == "×" || text == "÷" || text == "%";
  }

  void _calculateResult() {
    // Replace operators for parsing
    String expression = _display.replaceAll('×', '*').replaceAll('÷', '/');

    try {
      // Simple expression parser
      // In a production app, use a proper parser library
      final result = _parseExpression(expression);
      if (result == result.toInt()) {
        _display = result.toInt().toString();
      } else {
        _display = result.toString();
      }
    } catch (e) {
      _display = "Error";
    }
  }

  // Expression parser with proper calculation support
  double _parseExpression(String expression) {
    try {
      // First, handle percentage calculations
      if (expression.contains("%")) {
        expression = expression.replaceAll("%", "/100");
      }

      // Parse and evaluate the expression
      // For a production app, use a proper math expression library
      // This is a simplified evaluator for demonstration purposes

      // Split by operators while keeping them in the array
      List<String> tokens = [];
      String currentNumber = "";

      for (int i = 0; i < expression.length; i++) {
        String char = expression[i];
        if (char == "+" || char == "-" || char == "*" || char == "/") {
          if (currentNumber.isNotEmpty) {
            tokens.add(currentNumber);
            currentNumber = "";
          }
          tokens.add(char);
        } else {
          currentNumber += char;
        }
      }

      if (currentNumber.isNotEmpty) {
        tokens.add(currentNumber);
      }

      // First pass: handle multiplication and division
      List<String> secondPass = [];
      for (int i = 0; i < tokens.length; i++) {
        if (i + 1 < tokens.length && (tokens[i + 1] == "*" || tokens[i + 1] == "/")) {
          double leftVal = double.parse(tokens[i]);
          double rightVal = double.parse(tokens[i + 2]);
          double result;

          if (tokens[i + 1] == "*") {
            result = leftVal * rightVal;
          } else {
            if (rightVal == 0) throw Exception("Division by zero");
            result = leftVal / rightVal;
          }

          secondPass.add(result.toString());
          i += 2; // Skip the next two tokens
        } else if (i - 1 >= 0 && (tokens[i - 1] == "*" || tokens[i - 1] == "/")) {
          // Skip as we've already processed this
          continue;
        } else {
          secondPass.add(tokens[i]);
        }
      }

      // Second pass: handle addition and subtraction
      double result = double.parse(secondPass[0]);
      for (int i = 1; i < secondPass.length; i += 2) {
        if (i + 1 >= secondPass.length) break;

        double rightVal = double.parse(secondPass[i + 1]);
        if (secondPass[i] == "+") {
          result += rightVal;
        } else if (secondPass[i] == "-") {
          result -= rightVal;
        }
      }

      return result;
    } catch (e) {
      print("Error in expression parsing: $e");
      throw Exception("Invalid expression");
    }
  }

  void _changeSecretCode() {
    _showSetCodeDialog();
  }

  Widget _buildButton(String text, {Color? color, Color? textColor}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          onPressed: () => _onButtonPressed(text),
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.white,
            foregroundColor: textColor ?? Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20.0),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 24.0),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _changeSecretCode,
            tooltip: 'Change Secret Code',
          ),
        ],
      ),
      body: Column(
        children: [
          // Display
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              alignment: Alignment.bottomRight,
              child: Text(
                _display,
                style: const TextStyle(
                  fontSize: 48.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Keypad
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  // Row 1
                  Row(
                    children: [
                      _buildButton("C", color: const Color(0xFFB40085), textColor: Colors.white),
                      _buildButton("%"),
                      _buildButton("⌫"),
                      _buildButton("÷", color: const Color(0xFFCFC2F9)),
                    ],
                  ),
                  // Row 2
                  Row(
                    children: [
                      _buildButton("7"),
                      _buildButton("8"),
                      _buildButton("9"),
                      _buildButton("×", color: const Color(0xFFCFC2F9)),
                    ],
                  ),
                  // Row 3
                  Row(
                    children: [
                      _buildButton("4"),
                      _buildButton("5"),
                      _buildButton("6"),
                      _buildButton("-", color: const Color(0xFFCFC2F9)),
                    ],
                  ),
                  // Row 4
                  Row(
                    children: [
                      _buildButton("1"),
                      _buildButton("2"),
                      _buildButton("3"),
                      _buildButton("+", color: const Color(0xFFCFC2F9)),
                    ],
                  ),
                  // Row 5
                  Row(
                    children: [
                      _buildButton("0"),
                      _buildButton("."),
                      _buildButton("=", color: const Color(0xFFF8F5F7), textColor: const Color(
                          0xFF949394)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SecretScreen extends StatefulWidget {
  const SecretScreen({Key? key}) : super(key: key);

  @override
  State<SecretScreen> createState() => _SecretScreenState();
}

class _SecretScreenState extends State<SecretScreen> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedNotes();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // Load saved notes from shared preferences
  Future<void> _loadSavedNotes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notesController.text = prefs.getString('privateNotes') ?? '';
    });
  }

  // Save notes to shared preferences
  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('privateNotes', _notesController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notes saved successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secret Area'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNotes,
            tooltip: 'Save Notes',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Icon(
                Icons.lock_open,
                size: 60,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              const Text(
                'Welcome to your Secret Area',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'This area is protected by your secret code. You can store sensitive information here.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Secret content with expanded card to fill available space
              Expanded(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Private Notes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: TextField(
                            controller: _notesController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: const InputDecoration(
                              hintText: 'Store your private notes here...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 45),
                ),
                child: const Text('Return to Calculator'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}