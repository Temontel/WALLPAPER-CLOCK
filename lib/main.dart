
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clock App',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Timer _timer;
  String _formattedDate = '';
  String _formattedTime = '';
  double _progress = 0.0;
  bool _isInverted = false;
  String _greetingMessage = '';
  List<GreetingSetting> _greetingSettings = [];
  Timer? _longPressTimer;
  String _userName = 'Nama Anda';



  @override
  void initState() {
    super.initState();
    _loadGreetings();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  Future<void> _loadGreetings() async {
    final loadedGreetings = await GreetingStorage.loadGreetings();
    final name = await UserStorage.loadName();
    setState(() {
      _greetingSettings = loadedGreetings;
      _userName = name;
    });
    _updateTime();
  }


  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(now);
      _formattedTime = DateFormat('HH:mm:ss').format(now);
      _progress = calculateProgress(now);
      _greetingMessage = getGreetingMessageFromList(_greetingSettings,now);
    });
  }
  

  void _toggleInversion() {
    setState(() => _isInverted = !_isInverted);
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: _isInverted ? Colors.black : Colors.white,
      body: GestureDetector(
        onLongPress: _toggleInversion,
        onLongPressStart: (details) {
         _longPressTimer = Timer(const Duration(seconds: 2), () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GreetingSettingsPage()),
            ).then((_) => _loadGreetings());
          });
        },
        onLongPressEnd: (_) => _longPressTimer?.cancel(),
        child: Center(
          child: LayoutBuilder(
            builder: (_, __) => isLandscape
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildGreetingText(isLandscape),
                      const SizedBox(width: 40),
                      ClockWidget(
                        isInverted: _isInverted,
                        formattedDate: _formattedDate,
                        formattedTime: _formattedTime,
                        progress: _progress,
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildGreetingText(isLandscape),
                      const SizedBox(height: 32),
                      ClockWidget(
                        isInverted: _isInverted,
                        formattedDate: _formattedDate,
                        formattedTime: _formattedTime,
                        progress: _progress,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingText(bool isLandscape) {
    final color = _isInverted ? Colors.white : const Color(0xFF494EC6);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isLandscape ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(_greetingMessage, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(_userName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}


class GreetingSettingsPage extends StatefulWidget {
  const GreetingSettingsPage({super.key});

  @override
  State<GreetingSettingsPage> createState() => _GreetingSettingsPageState();
}

class _GreetingSettingsPageState extends State<GreetingSettingsPage> {
  List<GreetingSetting> _greetings = [];
  String userName = '';
  final ScrollController _scrollController = ScrollController();
  final Map<int, TextEditingController> _messageControllers = {};

  @override
  void initState() {
    super.initState();
    _loadGreetings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadGreetings();
  }




  TextEditingController _messageController(GreetingSetting setting) {
    final key = _greetings.indexOf(setting);
    if (!_messageControllers.containsKey(key)) {
      _messageControllers[key] = TextEditingController(text: setting.message);
    }
    return _messageControllers[key]!;
  }

  Future<void> _loadGreetings() async {
    final loaded = await GreetingStorage.loadGreetings();
    final name = await UserStorage.loadName();
    setState(() {
      _greetings = loaded;
      userName = name;
    });
  }

  Future<void> _saveUserName(String name) async {
    setState(() => userName = name);
    await UserStorage.saveName(name);
  }






  void _saveGreetings() async {
    for (int i = 0; i < _greetings.length; i++) {
      final controller = _messageControllers[i];
      if (controller != null) {
        _greetings[i] = _greetings[i].copyWith(message: controller.text);
      }
    }

    await GreetingStorage.saveGreetings(_greetings);
  
}



  void _addGreeting() {
    setState(() {
      _greetings.add(
        GreetingSetting(startMinute: 0, endMinute: 60, message: 'Pesan Baru'),
      );
    });
  }

  void _removeGreeting(int index) {
    setState(() {
      _greetings.removeAt(index);
    });
  }

  void _updateGreeting(int index, GreetingSetting updated) {
    setState(() {
      _greetings[index] = updated;
    });
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Edit Greetings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed:
            _saveGreetings,            
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addGreeting();
          Future.delayed(const Duration(milliseconds: 100), () {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
          _saveGreetings();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextFormField(
              initialValue: userName,
              decoration: const InputDecoration(
                labelText: 'Nama Pengguna',
                border: OutlineInputBorder(),
              ),
              onChanged: _saveUserName,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _greetings.length,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewPadding.bottom + 80,
              ),
              itemBuilder: (context, index) {
                final setting = _greetings[index];
                return Card(
                  key: ValueKey('${setting.startMinute}-${setting.endMinute}-${setting.message}'),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: TextFormField(
                      controller: _messageController(setting),
                      decoration: const InputDecoration(labelText: 'Pesan'),
                    ),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _minuteToTime(setting.startMinute),
                            decoration: const InputDecoration(labelText: 'Mulai'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [TimeInputFormatter()],
                            onChanged: (val) {
                              final newStart = _timeToMinute(val);
                              if (newStart != null) {
                                _updateGreeting(index, setting.copyWith(startMinute: newStart));
                                _saveGreetings();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: _minuteToTime(setting.endMinute),
                            decoration: const InputDecoration(labelText: 'Selesai'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [TimeInputFormatter()],
                            onChanged: (val) {
                              final newEnd = _timeToMinute(val);
                              if (newEnd != null) {
                                _updateGreeting(index, setting.copyWith(endMinute: newEnd));
                                _saveGreetings();
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeGreeting(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _minuteToTime(int minute) {
    final h = (minute ~/ 60).toString().padLeft(2, '0');
    final m = (minute % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  int? _timeToMinute(String input) {
    try {
      final parts = input.split(':');
      if (parts.length != 2) return null;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return hour * 60 + minute;
    } catch (_) {
      return null;
    }
  }
}

extension GreetingSettingCopy on GreetingSetting {
  GreetingSetting copyWith({
    int? startMinute,
    int? endMinute,
    String? message,
  }) {
    return GreetingSetting(
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      message: message ?? this.message,
    );
  }
}


class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    String formatted = '';
    
    
    if (digitsOnly.length >= 4) {
      formatted = '${digitsOnly.substring(0, 2)}:${digitsOnly.substring(2, digitsOnly.length.clamp(2, 4))}';
    } else {
      formatted = digitsOnly;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}


class ClockWidget extends StatelessWidget {
  final bool isInverted;
  final String formattedDate;
  final String formattedTime;
  final double progress;

  const ClockWidget({
    super.key,
    required this.isInverted,
    required this.formattedDate,
    required this.formattedTime,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final outerColor = isInverted ? Colors.grey[900]! : const Color(0xFFECEEF5);
    final innerColor = isInverted ? Colors.grey[800]! : const Color(0xFFDDE0ED);
    final textColor = isInverted ? Colors.white : const Color(0xFF494EC6);

    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildCircle(outerColor, 280),
          _buildCircle(innerColor, 258, child: _buildContent(textColor)),
        ],
      ),
    );
  }

  Widget _buildCircle(Color color, double size, {Widget? child}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: child,
    );
  }

  Widget _buildContent(Color textColor) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 224,
          height: 224,
          child: CustomPaint(
            painter: CircularProgressPainter(
              progress: progress,
              backgroundColor: isInverted ? Colors.white24 : Colors.grey[300]!,
              progressColor: isInverted ? Colors.white : const Color(0xFF494EC6),
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(formattedDate, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor)),
            const SizedBox(height: 8),
            Text(formattedTime, style: TextStyle(fontSize: 46, fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
      ],
    );
  }
}


class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Offset.zero & size;
    const startAngle = pi / 2;
    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(rect, startAngle, 2 * pi, false, backgroundPaint);
    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}



double calculateProgress(DateTime now) {
  final start = DateTime(now.year, now.month, now.day, 7);
  final end = DateTime(now.year, now.month, now.day, 17);

  if (now.isBefore(start)) return 0.0;
  if (now.isAfter(end)) return 1.0;

  return now.difference(start).inSeconds / end.difference(start).inSeconds;
}


String getGreetingMessageFromList(List<GreetingSetting> greetings, DateTime now) {
  final totalMinutes = now.hour * 60 + now.minute;
  for (var setting in greetings) {
    if (totalMinutes >= setting.startMinute && totalMinutes < setting.endMinute) {
      return setting.message;
    }
  }
  return '';
}

class GreetingSetting {
  final int startMinute;
  final int endMinute;
  final String message;

  GreetingSetting({
    required this.startMinute,
    required this.endMinute,
    required this.message,
  });

  factory GreetingSetting.fromJson(Map<String, dynamic> json) {
    return GreetingSetting(
      startMinute: json['startMinute'],
      endMinute: json['endMinute'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() => {
        'startMinute': startMinute,
        'endMinute': endMinute,
        'message': message,
      };

  static List<GreetingSetting> defaultGreetings() {
    return [
      // GreetingSetting(startMinute: 300, endMinute: 480, message: 'Bersiap & Berangkat'),
      // GreetingSetting(startMinute: 480, endMinute: 720, message: 'Semangat Bekerja'),
      // GreetingSetting(startMinute: 720, endMinute: 780, message: 'Selamat Istirahat'),
      // GreetingSetting(startMinute: 780, endMinute: 1035, message: 'Semangat Bekerja'),
      // GreetingSetting(startMinute: 1035, endMinute: 1050, message: 'Siap-Siap Kejar Kereta'),
    ];
  }
}


class GreetingStorage {
  static const _key = 'greeting_settings';

  static Future<List<GreetingSetting>> loadGreetings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return GreetingSetting.defaultGreetings();
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => GreetingSetting.fromJson(e)).toList();
  }

  static Future<void> saveGreetings(List<GreetingSetting> greetings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(greetings.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }
}

class UserStorage {
  static const _nameKey = 'user_name';

  static Future<String> loadName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey) ?? 'Nama Anda';
  }

  static Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
  }
}

