import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const FlowCodeApp());
}

class FlowCodeApp extends StatelessWidget {
  const FlowCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowCode',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF007ACC),
          surface: Color(0xFF252526),
        ),
      ),
      home: const FlowCodeEditorScreen(),
    );
  }
}

class FlowCodeEditorScreen extends StatefulWidget {
  const FlowCodeEditorScreen({super.key});

  @override
  State<FlowCodeEditorScreen> createState() => _FlowCodeEditorScreenState();
}

class _FlowCodeEditorScreenState extends State<FlowCodeEditorScreen> {
  // Pre-loaded code templates for each supported language
  final Map<String, String> _codeTemplates = {
    'python': '# Python Example\nname = input("Enter your name: ")\nprint(f"Hello, {name} from FlowCode!")\n',
    'javascript': '// JavaScript (Node.js) Example\nconst readline = require("readline");\nconst rl = readline.createInterface({ input: process.stdin, output: process.stdout });\n\nrl.question("Enter something: ", (answer) => {\n  console.log(`You entered: ${answer}`);\n  rl.close();\n});\n',
    'cpp': '// C++ Example\n#include <iostream>\n#include <string>\nusing namespace std;\n\nint main() {\n    string name;\n    cin >> name;\n    cout << "Hello " << name << " from C++!" << endl;\n    return 0;\n}\n',
    'c': '// C Example\n#include <stdio.stdio.h>\n#include <stdio.h>\n\nint main() {\n    char str[50];\n    scanf("%s", str);\n    printf("Input received: %s\\n", str);\n    return 0;\n}\n',
    'java': '// Java Example\nimport java.util.Scanner;\n\npublic class Main {\n    public static void main(String[] args) {\n        Scanner scanner = new Scanner(System.in);\n        String input = scanner.nextLine();\n        System.out.println("Java Output: " + input);\n    }\n}\n',
    'go': '// Go Example\npackage main\nimport "fmt"\n\nfunc main() {\n    var input string\n    fmt.Scanln(&input)\n    fmt.Println("Go received:", input)\n}\n',
  };

  late TextEditingController _codeController;
  final TextEditingController _stdinController = TextEditingController();
  
  String _selectedLanguage = 'python';
  String _output = 'Press "Run" to execute code.';
  bool _isExecuting = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: _codeTemplates[_selectedLanguage]);
  }

  void _onLanguageChanged(String? newLang) {
    if (newLang == null) return;
    setState(() {
      _selectedLanguage = newLang;
      _codeController.text = _codeTemplates[newLang] ?? '';
      _output = 'Language switched to $newLang. Ready to execute.';
    });
  }

  // Calls the Piston API Sandbox to safely compile/execute code
  Future<void> _runCode() async {
    setState(() {
      _isExecuting = true;
      _output = 'Compiling and executing code...';
    });

    final payload = {
      'language': _selectedLanguage,
      'version': '*',
      'files': [
        {'content': _codeController.text}
      ],
      'stdin': _stdinController.text,
    };

    try {
      final response = await http.post(
        Uri.parse('https://emkc.org/api/v2/piston/execute'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final run = data['run'] ?? {};
        final stdout = run['stdout'] ?? '';
        final stderr = run['stderr'] ?? '';
        final exitCode = run['code'] ?? 0;

        setState(() {
          if (stderr.toString().isNotEmpty) {
            _output = '--- COMPILATION / RUNTIME ERROR (Code $exitCode) ---\n$stderr';
          } else if (stdout.toString().isNotEmpty) {
            _output = stdout;
          } else {
            _output = 'Program executed successfully with no output (Exit Code $exitCode).';
          }
        });
      } else {
        setState(() {
          _output = 'Server error: Status ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _output = 'Failed to execute code: $e\nPlease check internet connection.';
      });
    } finally {
      setState(() {
        _isExecuting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate line numbers column
    final lineCount = '\n'.allMatches(_codeController.text).length + 1;
    final lineNumbers = Iterable<int>.generate(lineCount, (i) => i + 1).join('\n');

    return Scaffold(
      appBar: AppBar(
        title: const Text('FlowCode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF323233),
        elevation: 0,
        actions: [
          // Language Selector Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLanguage,
                dropdownColor: const Color(0xFF252526),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: const [
                  DropdownMenuItem(value: 'python', child: Text('Python')),
                  DropdownMenuItem(value: 'javascript', child: Text('JavaScript')),
                  DropdownMenuItem(value: 'cpp', child: Text('C++')),
                  DropdownMenuItem(value: 'c', child: Text('C')),
                  DropdownMenuItem(value: 'java', child: Text('Java')),
                  DropdownMenuItem(value: 'go', child: Text('Go')),
                ],
                onChanged: _onLanguageChanged,
              ),
            ),
          ),
          // Run Code Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              onPressed: _isExecuting ? null : _runCode,
              icon: _isExecuting 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.play_arrow, size: 18),
              label: Text(_isExecuting ? 'Running' : 'Run'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // CODE EDITOR AREA WITH LINE NUMBERS
          Expanded(
            flex: 3,
            child: Container(
              color: const Color(0xFF1E1E1E),
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Line numbers bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      color: const Color(0xFF252526),
                      child: Text(
                        lineNumbers,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: Colors.grey,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Code input textfield
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: TextField(
                          controller: _codeController,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: Color(0xFFD4D4D4),
                            height: 1.4,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFF333333)),
          // INPUT & OUTPUT TERMINAL AREA
          Expanded(
            flex: 2,
            child: Container(
              color: const Color(0xFF181818),
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Program STDIN Input
                  const Text('PROGRAM INPUT (STDIN):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 35,
                    child: TextField(
                      controller: _stdinController,
                      style: const TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        hintText: 'Enter input arguments for your program here...',
                        hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        filled: true,
                        fillColor: Color(0xFF252526),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Terminal STDOUT Output
                  const Text('TERMINAL OUTPUT (STDOUT):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF333333)),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _output,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: _output.startsWith('--- COMPILATION') ? Colors.redAccent : Colors.lightGreenAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
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
