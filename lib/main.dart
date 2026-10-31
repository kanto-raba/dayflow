import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_service.dart';

const _supabaseUrl = 'https://sofioxoobxwnaeicaaow.supabase.co';
const _supabaseAnonKey = 'sb_publishable_cQS4U6DOuhNXe2OZTMMHMw_sDfITmGd';

// ───────────────────────── Design tokens ─────────────────────────
const kPrimary = Color(0xFF4F5FE8);
const kPrimarySoft = Color(0xFFECEEFF);
const kInk = Color(0xFF1E2438);
const kMuted = Color(0xFF7D849A);
const kFaint = Color(0xFFA3A9BA);
const kBg = Color(0xFFF5F6FB);
const kLine = Color(0xFFE8EAF2);
const kGreen = Color(0xFF3FA678);
const kGreenSoft = Color(0xFFE8F6EF);
const kOrange = Color(0xFFE98B4A);
const kOrangeSoft = Color(0xFFFFF1E4);
const kRed = Color(0xFFE5645A);
const kPurple = Color(0xFF8B63D6);
const kGold = Color(0xFFD9A441);
const kGoldSoft = Color(0xFFFFF4D9);

Future<String?> _initSupabase() async {
  try {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
    return null;
  } catch (error) {
    return 'Supabase connection failed: $error';
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(LifeAssistantApp(init: _initSupabase()));
}

class LifeAssistantApp extends StatelessWidget {
  const LifeAssistantApp({super.key, required this.init});

  final Future<String?> init;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dayflow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: kPrimary,
          onPrimary: Colors.white,
          secondary: kOrange,
          surface: kBg,
          onSurface: kInk,
        ),
        scaffoldBackgroundColor: kBg,
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: kInk,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 70,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: kPrimarySoft,
          labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color:
                  states.contains(WidgetState.selected) ? kPrimary : kMuted)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            side: const BorderSide(color: kLine),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        useMaterial3: true,
      ),
      home: _InitGate(init: init),
    );
  }
}

// ───────────────────────── Sign in ─────────────────────────
class _InitGate extends StatelessWidget {
  const _InitGate({required this.init});

  final Future<String?> init;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: init,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SplashView();
        }
        return _AuthGate(startupError: snapshot.data);
      },
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4F5FE8), Color(0xFF7A67EC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: Colors.white,
              child:
                  Icon(Icons.auto_awesome_rounded, size: 42, color: kPrimary),
            ),
            SizedBox(height: 20),
            Text('Dayflow',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8)),
            SizedBox(height: 22),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.4, color: Colors.white),
            ),
          ]),
        ),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate({this.startupError});

  final String? startupError;

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  StreamSubscription<AuthState>? _subscription;
  Session? _session;

  @override
  void initState() {
    super.initState();
    if (widget.startupError == null) {
      final auth = Supabase.instance.client.auth;
      _session = auth.currentSession;
      _subscription = auth.onAuthStateChange.listen((data) {
        if (mounted) setState(() => _session = data.session);
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.startupError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Text(widget.startupError!, textAlign: TextAlign.center),
          ),
        ),
      );
    }
    final session = _session;
    if (session == null) return const _AuthPage();
    return _StartupGate(key: ValueKey(session.user.id));
  }
}

class _AuthPage extends StatefulWidget {
  const _AuthPage();

  @override
  State<_AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<_AuthPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;
  bool _busy = false;
  bool _hidden = true;
  bool _isError = true;
  String? _message;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _fail(String text) => setState(() {
        _message = text;
        _isError = true;
      });

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    final name = _name.text.trim();
    if (!email.contains('@')) return _fail('Enter a valid email address.');
    if (password.length < 6) {
      return _fail('The password needs at least 6 characters.');
    }
    if (_signUp && name.isEmpty) return _fail('Enter your name.');
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      if (_signUp) {
        final result = await auth
            .signUp(email: email, password: password, data: {'name': name});
        if (result.session == null && mounted) {
          setState(() {
            _signUp = false;
            _isError = false;
            _message =
                'Account created. Open the email we sent you to confirm it, then sign in.';
          });
        }
      } else {
        await auth.signInWithPassword(email: email, password: password);
      }
    } on AuthException catch (error) {
      if (mounted) _fail(error.message);
    } catch (_) {
      if (mounted) _fail('Something went wrong. Check your connection.');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4F5FE8), Color(0xFF7A67EC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.auto_awesome_rounded,
                        size: 38, color: kPrimary),
                  ),
                  const SizedBox(height: 16),
                  const Text('Dayflow',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8)),
                  const SizedBox(height: 6),
                  const Text('Plan your days. Build better habits.',
                      style: TextStyle(color: Color(0xFFDCE1FF), fontSize: 14)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SegmentedButton<bool>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(
                                  value: false, label: Text('Sign in')),
                              ButtonSegment(
                                  value: true, label: Text('Create account')),
                            ],
                            selected: {_signUp},
                            onSelectionChanged: (value) => setState(() {
                              _signUp = value.first;
                              _message = null;
                            }),
                          ),
                          const SizedBox(height: 16),
                          if (_signUp) ...[
                            TextField(
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              decoration:
                                  const InputDecoration(labelText: 'Your name'),
                            ),
                            const SizedBox(height: 10),
                          ],
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration:
                                const InputDecoration(labelText: 'Email'),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _password,
                            obscureText: _hidden,
                            onSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _hidden = !_hidden),
                                icon: Icon(_hidden
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                              ),
                            ),
                          ),
                          if (_message != null) ...[
                            const SizedBox(height: 12),
                            Text(_message!,
                                style: TextStyle(
                                    color: _isError ? kRed : kGreen,
                                    fontSize: 12.5,
                                    height: 1.35)),
                          ],
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Text(_signUp ? 'Create account' : 'Sign in'),
                          ),
                        ]),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                      'Your data is saved to your account, so it is there on every device.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: Color(0xFFDCE1FF), fontSize: 12.5)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Startup ─────────────────────────
class _StartupGate extends StatefulWidget {
  const _StartupGate({super.key, this.startupError});

  final String? startupError;

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isCompleted) {
      return AppShell(startupError: widget.startupError);
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4F5FE8), Color(0xFF7A67EC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _controller, curve: Curves.easeIn),
            child: ScaleTransition(
              scale: Tween<double>(begin: .82, end: 1).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.auto_awesome_rounded,
                        size: 42, color: kPrimary),
                  ),
                  SizedBox(height: 20),
                  Text('Dayflow',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8)),
                  SizedBox(height: 7),
                  Text('Plan your days. Build better habits.',
                      style: TextStyle(color: Color(0xFFDCE1FF), fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Models ─────────────────────────
class TaskItem {
  TaskItem(this.title, this.area,
      {this.id,
      this.done = false,
      this.priority = 'Medium',
      this.createdAt,
      this.completedAt,
      this.dueDate});

  final String? id;
  final String title;
  final String area;
  bool done;
  final String priority;
  final DateTime? createdAt;
  DateTime? completedAt;
  final DateTime? dueDate;
}

class GroceryItem {
  GroceryItem(this.name, this.category,
      {this.bought = false,
      this.quantity = 1,
      this.minimumQuantity = 1,
      this.price = 0,
      this.fromPantry = false,
      DateTime? purchasedAt,
      DateTime? expiresAt})
      : purchasedAt = purchasedAt ?? DateTime.now(),
        expiresAt = expiresAt ?? DateTime.now().add(const Duration(days: 7));

  final String name;
  final String category;
  bool bought;
  double quantity;
  double minimumQuantity;
  double price;
  DateTime purchasedAt;
  DateTime expiresAt;
  bool fromPantry;

  bool get isLow => quantity <= minimumQuantity;
  bool get isExpired => expiresAt.isBefore(DateTime.now());

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'bought': bought,
        'quantity': quantity,
        'minimumQuantity': minimumQuantity,
        'price': price,
        'purchasedAt': purchasedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'fromPantry': fromPantry,
      };

  factory GroceryItem.fromJson(Map<String, dynamic> json) => GroceryItem(
        json['name'] as String? ?? 'Item',
        json['category'] as String? ?? 'Other',
        bought: json['bought'] as bool? ?? false,
        quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
        minimumQuantity: (json['minimumQuantity'] as num?)?.toDouble() ?? 1,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        purchasedAt: DateTime.tryParse(json['purchasedAt'] as String? ?? ''),
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
        fromPantry: json['fromPantry'] as bool? ?? false,
      );
}

/// A staple you keep in stock (shown in the Pantry section).
class MonthlyItem {
  MonthlyItem(this.name, this.category,
      {this.quantity = 1,
      this.minimum = 1,
      this.buyQuantity = 1,
      this.price = 0,
      this.lastBought,
      this.lowListed = false});

  String name;
  String category;
  double quantity; // in stock now
  double minimum; // alert when stock is at or below this
  double buyQuantity; // usual amount to buy
  double price; // price per unit
  DateTime? lastBought;
  bool lowListed; // already added to the shopping list for this low period

  bool get isLow => quantity <= minimum;

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'quantity': quantity,
        'minimum': minimum,
        'buyQuantity': buyQuantity,
        'price': price,
        'lastBought': lastBought?.toIso8601String(),
        'lowListed': lowListed,
      };

  factory MonthlyItem.fromJson(Map<String, dynamic> json) => MonthlyItem(
        json['name'] as String? ?? 'Item',
        json['category'] as String? ?? 'Other',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
        // Items saved by older versions had no alert level.
        minimum: (json['minimum'] as num?)?.toDouble() ?? 0,
        buyQuantity: (json['buyQuantity'] as num?)?.toDouble() ?? 1,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        lastBought: DateTime.tryParse(json['lastBought'] as String? ?? ''),
        lowListed: json['lowListed'] as bool? ?? false,
      );
}

class ChallengeItem {
  ChallengeItem(this.title, this.subtitle, this.color,
      {int totalDays = 30, DateTime? startDate})
      : startDate = _dateOnly(startDate ?? DateTime.now()),
        days = List<bool>.filled(totalDays, false);

  final String title;
  final String subtitle;
  final Color color;
  final DateTime startDate;
  final List<bool> days;
  final Set<int> restDays = <int>{};

  /// Day index -> base64 progress photo.
  final Map<int, String> photos = {};

  /// Day index -> short note.
  final Map<int, String> notes = {};

  /// Day index -> when the day was completed.
  final Map<int, DateTime> doneAt = {};
  bool expanded = false;

  int get totalDays => days.length;
  int get doneCount => days.where((d) => d).length;
  DateTime dateOf(int index) => startDate.add(Duration(days: index));

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'color': color.toARGB32(),
        'startDate': startDate.toIso8601String(),
        'days': days,
        'restDays': restDays.toList(),
        'photos': photos.map((k, v) => MapEntry('$k', v)),
        'notes': notes.map((k, v) => MapEntry('$k', v)),
        'doneAt': doneAt.map((k, v) => MapEntry('$k', v.toIso8601String())),
      };

  factory ChallengeItem.fromJson(Map<String, dynamic> json) {
    final savedDays = (json['days'] as List<dynamic>? ?? [])
        .map((day) => day as bool)
        .toList();
    final challenge = ChallengeItem(
      json['title'] as String? ?? 'Challenge',
      json['subtitle'] as String? ?? 'Complete it daily',
      Color((json['color'] as num?)?.toInt() ?? 0xFF4F5FE8),
      totalDays: savedDays.isEmpty ? 1 : savedDays.length,
      startDate: DateTime.tryParse(json['startDate'] as String? ?? ''),
    );
    challenge.days
      ..clear()
      ..addAll(savedDays.isEmpty ? [false] : savedDays);
    challenge.restDays.addAll((json['restDays'] as List<dynamic>? ?? [])
        .map((day) => (day as num).toInt()));
    (json['photos'] as Map<String, dynamic>? ?? {}).forEach((key, value) {
      final index = int.tryParse(key);
      if (index != null) challenge.photos[index] = value as String;
    });
    (json['notes'] as Map<String, dynamic>? ?? {}).forEach((key, value) {
      final index = int.tryParse(key);
      if (index != null) challenge.notes[index] = value as String;
    });
    (json['doneAt'] as Map<String, dynamic>? ?? {}).forEach((key, value) {
      final index = int.tryParse(key);
      final when = DateTime.tryParse(value as String? ?? '');
      if (index != null && when != null) challenge.doneAt[index] = when;
    });
    return challenge;
  }
}

class Exercise {
  Exercise(
      {required this.id,
      required this.name,
      this.detail = '',
      this.note = '',
      this.photo});

  final String id;
  final String name;
  final String detail;
  final String note;
  final String? photo;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'detail': detail,
        'note': note,
        'photo': photo,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String? ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: json['name'] as String? ?? 'Exercise',
        detail: json['detail'] as String? ?? '',
        note: json['note'] as String? ?? '',
        photo: json['photo'] as String?,
      );
}

class WorkoutPlan {
  WorkoutPlan(this.id, this.title, this.exercises);

  final String id;
  String title;
  final List<Exercise> exercises;

  static List<WorkoutPlan> defaultPlans() => [
        WorkoutPlan('push', 'Push day', [
          Exercise(
              id: 's1',
              name: 'Bench press',
              detail: '4 sets × 8 reps',
              note: 'Chest, front delts and triceps'),
          Exercise(
              id: 's2',
              name: 'Incline dumbbell press',
              detail: '3 sets × 12 reps',
              note: 'Upper chest emphasis'),
          Exercise(
              id: 's3',
              name: 'Dips',
              detail: '3 sets × 10 reps',
              note: 'Chest and triceps finisher'),
          Exercise(
              id: 's4',
              name: 'Plank',
              detail: '3 sets × 45 seconds',
              note: 'Core stability and control'),
        ]),
        WorkoutPlan('pull', 'Pull day', [
          Exercise(
              id: 'u1',
              name: 'Pull-ups',
              detail: '4 sets × 8 reps',
              note: 'Back and biceps'),
          Exercise(
              id: 'u2',
              name: 'Barbell row',
              detail: '4 sets × 10 reps',
              note: 'Mid back'),
          Exercise(
              id: 'u3',
              name: 'Lat pulldown',
              detail: '3 sets × 12 reps',
              note: 'Lats'),
          Exercise(
              id: 'u4',
              name: 'Biceps curl',
              detail: '3 sets × 12 reps',
              note: 'Arms'),
        ]),
        WorkoutPlan('legs', 'Leg day', [
          Exercise(
              id: 'l1',
              name: 'Squat',
              detail: '4 sets × 8 reps',
              note: 'Quads and glutes'),
          Exercise(
              id: 'l2',
              name: 'Romanian deadlift',
              detail: '3 sets × 10 reps',
              note: 'Hamstrings'),
          Exercise(
              id: 'l3',
              name: 'Leg press',
              detail: '3 sets × 12 reps',
              note: 'Quads'),
          Exercise(
              id: 'l4',
              name: 'Calf raises',
              detail: '3 sets × 15 reps',
              note: 'Calves'),
        ]),
      ];

  /// Weekday (1 = Monday ... 7 = Sunday) -> workout id.
  static Map<int, String> defaultSchedule() =>
      {1: 'push', 3: 'pull', 5: 'legs'};

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) => WorkoutPlan(
        json['id'] as String? ?? 'legacy',
        json['title'] as String? ?? 'Workout',
        (json['exercises'] as List<dynamic>? ?? [])
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// One thing the user did: a finished task, workout, purchase or challenge day.
class ActivityLog {
  ActivityLog(this.type, this.title, this.detail, this.date);

  final String type; // task | workout | grocery | challenge
  final String title;
  final String detail;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'detail': detail,
        'date': date.toIso8601String(),
      };

  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
        json['type'] as String? ?? 'task',
        json['title'] as String? ?? '',
        json['detail'] as String? ?? '',
        DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      );
}

class JournalEntry {
  JournalEntry(this.date, this.mood, this.text, this.photo);

  final DateTime date;
  final String mood;
  final String text;
  final String? photo;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'mood': mood,
        'text': text,
        'photo': photo,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        json['mood'] as String? ?? '🙂',
        json['text'] as String? ?? '',
        json['photo'] as String?,
      );
}

class ProfileData {
  ProfileData({
    this.name = 'User',
    this.email = '',
    this.goal = 'Build healthy habits',
    this.targetMass = 70,
    this.currency = 'MUR',
  });

  String name;
  String email;
  String goal;
  double targetMass;
  String currency;
  final List<MassEntry> massEntries = [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'goal': goal,
        'targetMass': targetMass,
        'currency': currency,
        'massEntries': massEntries.map((entry) => entry.toJson()).toList(),
      };

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    final profile = ProfileData(
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      goal: json['goal'] as String? ?? 'Build healthy habits',
      targetMass: (json['targetMass'] as num?)?.toDouble() ?? 70,
      currency: json['currency'] as String? ?? 'MUR',
    );
    final entries = json['massEntries'] as List<dynamic>? ?? [];
    profile.massEntries.addAll(entries
        .map((entry) => MassEntry.fromJson(entry as Map<String, dynamic>)));
    return profile;
  }
}

class MassEntry {
  MassEntry(this.date, this.mass);

  final DateTime date;
  final double mass;

  Map<String, dynamic> toJson() =>
      {'date': date.toIso8601String(), 'mass': mass};

  factory MassEntry.fromJson(Map<String, dynamic> json) => MassEntry(
        DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        (json['mass'] as num?)?.toDouble() ?? 0,
      );
}

class PlannerDeadline {
  PlannerDeadline(this.title, this.date);

  final String title;
  final DateTime date;

  Map<String, dynamic> toJson() =>
      {'title': title, 'date': date.toIso8601String()};

  factory PlannerDeadline.fromJson(Map<String, dynamic> json) =>
      PlannerDeadline(
        json['title'] as String? ?? 'Untitled deadline',
        DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      );
}

class TimetableEntry {
  TimetableEntry(this.title, this.day, this.start, this.end);

  final String title;
  final int day;
  final TimeOfDay start;
  final TimeOfDay end;

  Map<String, dynamic> toJson() => {
        'title': title,
        'day': day,
        'start': start.hour * 60 + start.minute,
        'end': end.hour * 60 + end.minute,
      };

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    final start = json['start'] as int? ?? 540;
    final end = json['end'] as int? ?? 600;
    return TimetableEntry(
      json['title'] as String? ?? 'Class',
      json['day'] as int? ?? 1,
      TimeOfDay(hour: start ~/ 60, minute: start % 60),
      TimeOfDay(hour: end ~/ 60, minute: end % 60),
    );
  }
}

// ───────────────────────── Helpers ─────────────────────────
DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

String _fmtTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String _dayLabel(DateTime date) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
}

String _relativeDay(DateTime date) {
  final today = _dateOnly(DateTime.now());
  final diff = today.difference(_dateOnly(date)).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return _dayLabel(date);
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

/// Local keys that are also copied to the user's account in Supabase.
/// Set when saving to the account fails, so the problem is visible.
final syncMessage = ValueNotifier<String?>(null);
final lastCloudSave = ValueNotifier<DateTime?>(null);

/// Local keys that are also copied to the user's account in Supabase.
const _syncKeys = [
  'groceries',
  'monthly_items',
  'profile',
  'deadlines',
  'timetable',
  'challenges',
  'workout_plan',
  'workout_plans',
  'workout_schedule',
  'workout_done',
  'workout_done_date',
  'activity',
  'journal',
  'tasks_done_today',
];

String _errorText(Object error) {
  if (error is PostgrestException) return error.message;
  final text = error.toString();
  return text.length > 140 ? '${text.substring(0, 140)}…' : text;
}

final Map<String, Object> _pendingValues = {};
final Map<String, DateTime> _pendingTimes = {};
Timer? _flushTimer;

Future<void> _saveJson(String key, Object value) async {
  final now = DateTime.now().toUtc();
  try {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, jsonEncode(value));
    await preferences.setString('ts_$key', now.toIso8601String());
  } catch (_) {
    syncMessage.value =
        'This browser could not store your latest changes (its storage may be full). They are still being sent to your account.';
  }
  _queueCloud(key, value, now);
}

/// Saves are grouped, so quick successive changes are sent once.
void _queueCloud(String key, Object value, DateTime time) {
  if (!_syncKeys.contains(key)) return;
  _pendingValues[key] = value;
  _pendingTimes[key] = time;
  _flushTimer?.cancel();
  _flushTimer = Timer(const Duration(milliseconds: 700), _flushCloud);
}

Future<void> _flushCloud() async {
  for (final key in _pendingValues.keys.toList()) {
    final value = _pendingValues.remove(key);
    final time = _pendingTimes.remove(key);
    if (value == null || time == null) continue;
    await _pushCloud(key, value, time);
  }
}

Future<bool> _pushCloud(String key, Object value, DateTime time) async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    await Supabase.instance.client.from('app_data').upsert({
      'user_id': user.id,
      'key': key,
      'value': value,
      'updated_at': time.toUtc().toIso8601String(),
    }, onConflict: 'user_id,key');
    syncMessage.value = null;
    lastCloudSave.value = DateTime.now();
    return true;
  } catch (error) {
    syncMessage.value = 'Could not save to your account: ${_errorText(error)}';
    return false;
  }
}

Future<dynamic> _readJson(String key) async {
  final preferences = await SharedPreferences.getInstance();
  final encoded = preferences.getString(key);
  if (encoded == null) return null;
  try {
    return jsonDecode(encoded);
  } catch (_) {
    await preferences.remove(key);
    return null;
  }
}

List<T> _decodeList<T>(dynamic raw, T Function(Map<String, dynamic>) build) {
  if (raw is! List) return <T>[];
  return raw.map((e) => build(e as Map<String, dynamic>)).toList();
}

BoxDecoration _cardDecoration({Color color = Colors.white}) {
  return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: kLine),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF27325D).withValues(alpha: 0.04),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ]);
}

// Photos are stored as small base64 JPEGs (resized when picked).
Future<String?> pickPhoto(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.photo_camera_outlined),
          title: const Text('Take a photo'),
          onTap: () => Navigator.pop(sheet, ImageSource.camera),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: const Text('Choose from gallery'),
          onTap: () => Navigator.pop(sheet, ImageSource.gallery),
        ),
        const SizedBox(height: 8),
      ]),
    ),
  );
  if (source == null) return null;
  try {
    final file = await ImagePicker()
        .pickImage(source: source, maxWidth: 720, imageQuality: 60);
    if (file == null) return null;
    return base64Encode(await file.readAsBytes());
  } catch (_) {
    return null;
  }
}

Widget _photo(String data, {double? width, double? height}) => Image.memory(
      base64Decode(data),
      width: width,
      height: height,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: kBg,
        child: const Icon(Icons.broken_image_outlined, color: kFaint),
      ),
    );

void _viewPhoto(BuildContext context, String data, {String? caption}) {
  showDialog<void>(
    context: context,
    builder: (dialog) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(14),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Flexible(
          child: InteractiveViewer(
            child: Image.memory(base64Decode(data), fit: BoxFit.contain),
          ),
        ),
        if (caption != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(caption,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(dialog),
          child: const Text('Close'),
        ),
      ]),
    ),
  );
}

// ───────────────────────── Shell ─────────────────────────
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.startupError});

  final String? startupError;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Page indexes
  static const _today = 1,
      _journalPage = 3,
      _shop = 4,
      _challengesPage = 5,
      _profilePage = 6,
      _planner = 7,
      _finance = 8,
      _bible = 9;

  final _taskService = TaskService(Supabase.instance.client);
  int _selectedIndex = 0;
  final List<TaskItem> _tasks = [];
  final List<GroceryItem> _groceries = [
    GroceryItem('Chicken breast', 'Protein'),
    GroceryItem('Eggs', 'Protein'),
    GroceryItem('Rice', 'Pantry'),
    GroceryItem('Broccoli', 'Vegetables', bought: true),
    GroceryItem('Tomatoes', 'Vegetables'),
    GroceryItem('Milk', 'Dairy', bought: true),
  ];
  final List<MonthlyItem> _monthlyItems = [
    MonthlyItem('Toothpaste', 'Household',
        quantity: 2, minimum: 1, buyQuantity: 2),
    MonthlyItem('Laundry detergent', 'Household',
        quantity: 2, minimum: 1, buyQuantity: 1),
    MonthlyItem('Swimming goggles', 'Personal',
        quantity: 1, minimum: 0, buyQuantity: 1),
    MonthlyItem('Supplements', 'Health',
        quantity: 3, minimum: 1, buyQuantity: 2),
  ];
  final List<ChallengeItem> _challenges = [
    ChallengeItem(
        '30-day push-up challenge', 'Target: 100 push-ups per day', kOrange),
    ChallengeItem('Read every day', 'Target: 20 pages per day', kPrimary),
  ];
  int _selectedChallengeIndex = 0;
  bool _loadingTasks = true;
  String? _taskError;
  String _grocerySort = 'Name';
  final Set<String> _doneTodayIds = {};
  final ProfileData _profile = ProfileData();
  final List<PlannerDeadline> _deadlines = [];
  final List<TimetableEntry> _timetable = [];
  List<WorkoutPlan> _plans = WorkoutPlan.defaultPlans();
  Map<int, String> _schedule = WorkoutPlan.defaultSchedule();
  int _workoutDay = DateTime.now().weekday;
  final Set<String> _doneExercises = {};
  final List<ActivityLog> _activity = [];
  final List<JournalEntry> _journal = [];

  @override
  void initState() {
    super.initState();
    _boot();
  }

  /// Quick, local only: drops data that belongs to another account.
  Future<void> _prepareLocal() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final preferences = await SharedPreferences.getInstance();
    final owner = preferences.getString('data_owner');
    if (owner != null && owner != user.id) {
      for (final key in _syncKeys) {
        await preferences.remove(key);
        await preferences.remove('ts_$key');
      }
    }
    await preferences.setString('data_owner', user.id);
  }

  /// Compares timestamps first (tiny request) and only downloads what is newer
  /// in the account. Returns true if data was pulled, false if nothing changed,
  /// and null if the account could not be reached.
  Future<bool?> _syncFromCloud() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    var pulled = false;
    try {
      final preferences = await SharedPreferences.getInstance();
      final rows = await Supabase.instance.client
          .from('app_data')
          .select('key, updated_at')
          .eq('user_id', user.id);
      final cloud = <String, DateTime?>{
        for (final row in rows)
          row['key'] as String:
              DateTime.tryParse(row['updated_at'] as String? ?? ''),
      };
      final toPull = <String>[];
      for (final key in _syncKeys) {
        final local = preferences.getString(key);
        final localTime =
            DateTime.tryParse(preferences.getString('ts_$key') ?? '');
        if (!cloud.containsKey(key)) {
          if (local != null) {
            await _pushCloud(key, jsonDecode(local) as Object,
                localTime ?? DateTime.now().toUtc());
          }
          continue;
        }
        final cloudTime = cloud[key];
        if (local == null || localTime == null || cloudTime == null) {
          toPull.add(key);
          continue;
        }
        final diff = cloudTime.difference(localTime).inMilliseconds;
        if (diff > 2000) {
          toPull.add(key);
        } else if (diff < -2000) {
          await _pushCloud(key, jsonDecode(local) as Object, localTime);
        }
      }
      if (toPull.isNotEmpty) {
        final results = await Future.wait(toPull.map((key) async {
          final row = await Supabase.instance.client
              .from('app_data')
              .select('value')
              .eq('user_id', user.id)
              .eq('key', key)
              .single();
          return row['value'];
        }));
        for (var i = 0; i < toPull.length; i++) {
          final key = toPull[i];
          await preferences.setString(key, jsonEncode(results[i]));
          final time = cloud[key];
          if (time != null) {
            await preferences.setString(
                'ts_$key', time.toUtc().toIso8601String());
          }
        }
        pulled = true;
      }
      syncMessage.value = null;
      return pulled;
    } catch (error) {
      syncMessage.value =
          'Cannot reach your account backup: ${_errorText(error)}';
      return null;
    }
  }

  Future<void> _backupNow() async {
    final preferences = await SharedPreferences.getInstance();
    var saved = 0;
    for (final key in _syncKeys) {
      final local = preferences.getString(key);
      if (local == null) continue;
      final now = DateTime.now().toUtc();
      await preferences.setString('ts_$key', now.toIso8601String());
      if (await _pushCloud(key, jsonDecode(local) as Object, now)) saved++;
    }
    if (!mounted) return;
    _showMessage(syncMessage.value ??
        (saved == 0
            ? 'Nothing to back up yet.'
            : 'Backed up $saved items to your account.'));
  }

  Future<void> _setupName() async {
    if (!mounted) return;
    final user = Supabase.instance.client.auth.currentUser;
    final metaName = (user?.userMetadata?['name'] as String?)?.trim() ?? '';
    if (_profile.name == 'User' && metaName.isNotEmpty) {
      setState(() => _profile.name = metaName);
      await _saveProfile();
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    if (_profile.name == 'User' &&
        !(preferences.getBool('name_prompted') ?? false)) {
      await preferences.setBool('name_prompted', true);
      await _askName();
    }
  }

  Future<void> _askName() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Welcome to Dayflow'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration:
              const InputDecoration(labelText: 'What should we call you?'),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('Skip')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Continue')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    setState(() => _profile.name = name);
    await _saveProfile();
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
            'Your data is saved to your account and will be here when you sign back in. Make sure you are online first.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed != true) return;
    _flushTimer?.cancel();
    _pendingValues.clear();
    _pendingTimes.clear();
    final preferences = await SharedPreferences.getInstance();
    for (final key in [
      ..._syncKeys,
      ..._syncKeys.map((k) => 'ts_$k'),
      'data_owner',
      'name_prompted'
    ]) {
      await preferences.remove(key);
    }
    financeStore.reset();
    measurementStore.reset();
    bibleStore.reset();
    await Supabase.instance.client.auth.signOut();
  }

  Future<void> _boot() async {
    // 1. Show what is stored on this device right away.
    await _prepareLocal();
    await _loadLocal();
    // 2. Everything else loads in parallel, without waiting for each other.
    _loadTasks();
    financeStore.load();
    bibleStore.load();
    measurementStore.load().then((_) => _importOldWeights());
    // 3. Check the account backup in the background.
    final pulled = await _syncFromCloud();
    if (!mounted) return;
    if (pulled == true) await _loadLocal();
    if (pulled != null && mounted) {
      await _seedDefaults();
      await _setupName();
    }
  }

  /// Defaults are only written after the account has been checked, so they can
  /// never replace saved data.
  Future<void> _seedDefaults() async {
    if (!mounted) return;
    if (!_challenges.any(_isBible)) {
      setState(() => _challenges.add(ChallengeItem(
          'Read the Bible', 'Target: 1 chapter a day', kGold,
          totalDays: 90)));
      _saveChallenges();
    }
    _checkPantryLow();
  }

  /// Moves weights saved on this device by an older version into Supabase.
  Future<void> _importOldWeights() async {
    if (!mounted ||
        measurementStore.error != null ||
        measurementStore.items.isNotEmpty ||
        _profile.massEntries.isEmpty) {
      return;
    }
    final old = List<MassEntry>.from(_profile.massEntries);
    try {
      for (final entry in old) {
        await _db.from('body_measurements').insert({
          'user_id': _uid,
          'kind': 'weight',
          'value': entry.mass,
          'unit': 'kg',
          'measured_at': entry.date.toUtc().toIso8601String(),
        });
      }
      if (!mounted) return;
      setState(() => _profile.massEntries.clear());
      await _saveProfile();
      await measurementStore.load();
    } catch (_) {}
  }

  int get _completedTasks => _tasks.where((task) => task.done).length;
  ChallengeItem get _selectedChallenge => _challenges[_selectedChallengeIndex];

  String get _currencySymbol {
    switch (_profile.currency) {
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      default:
        return 'Rs';
    }
  }

  // ── Loading ──
  Future<void> _loadLocal() async {
    final groceries = await _readJson('groceries');
    final monthly = await _readJson('monthly_items');
    final profile = await _readJson('profile');
    final deadlines = await _readJson('deadlines');
    final timetable = await _readJson('timetable');
    final challenges = await _readJson('challenges');
    final plan = await _readJson('workout_plan');
    final plans = await _readJson('workout_plans');
    final schedule = await _readJson('workout_schedule');
    final done = await _readJson('workout_done');
    final doneDate = await _readJson('workout_done_date');
    final activity = await _readJson('activity');
    final journal = await _readJson('journal');
    if (!mounted) return;
    setState(() {
      if (groceries is List) {
        _groceries
          ..clear()
          ..addAll(_decodeList(groceries, GroceryItem.fromJson));
      }
      if (monthly is List) {
        _monthlyItems
          ..clear()
          ..addAll(_decodeList(monthly, MonthlyItem.fromJson));
      }
      if (profile is Map<String, dynamic>) {
        final loaded = ProfileData.fromJson(profile);
        if (loaded.name == 'Harinjiva') loaded.name = 'User';
        _profile
          ..name = loaded.name
          ..email = loaded.email
          ..goal = loaded.goal
          ..targetMass = loaded.targetMass
          ..currency = loaded.currency;
        _profile.massEntries
          ..clear()
          ..addAll(loaded.massEntries);
      }
      _deadlines
        ..clear()
        ..addAll(_decodeList(deadlines, PlannerDeadline.fromJson));
      _timetable
        ..clear()
        ..addAll(_decodeList(timetable, TimetableEntry.fromJson));
      final loadedChallenges = _decodeList(challenges, ChallengeItem.fromJson);
      if (loadedChallenges.isNotEmpty) {
        _challenges
          ..clear()
          ..addAll(loadedChallenges);
        _selectedChallengeIndex = 0;
      }
      if (plans is List) {
        _plans = _decodeList(plans, WorkoutPlan.fromJson);
        _schedule = {
          if (schedule is Map<String, dynamic>)
            for (final entry in schedule.entries)
              if (int.tryParse(entry.key) != null)
                int.parse(entry.key): entry.value.toString(),
        };
      } else if (plan is Map<String, dynamic>) {
        // Saved by the single-workout version: keep it as the first workout.
        _plans = [WorkoutPlan.fromJson(plan)];
        _schedule = {};
      }
      if (done is List &&
          doneDate == _dateOnly(DateTime.now()).toIso8601String()) {
        _doneExercises
          ..clear()
          ..addAll(done.map((e) => e.toString()));
      }
      _activity
        ..clear()
        ..addAll(_decodeList(activity, ActivityLog.fromJson));
      _journal
        ..clear()
        ..addAll(_decodeList(journal, JournalEntry.fromJson));
    });
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _taskService.getTasks();
      final stored = await _readJson('tasks_done_today');
      final today = _dateOnly(DateTime.now());
      _doneTodayIds.clear();
      if (stored is Map<String, dynamic> &&
          stored['date'] == today.toIso8601String()) {
        _doneTodayIds.addAll(
            (stored['ids'] as List<dynamic>? ?? []).map((e) => e.toString()));
      }
      // A fresh list every day: open tasks carry over, finished tasks from
      // earlier days leave the list (they stay in the history).
      final visible = tasks
          .where((t) =>
              !t.done ||
              t.dueDate == null ||
              !t.dueDate!.isBefore(today) ||
              _doneTodayIds.contains(t.id))
          .toList();
      if (!mounted) return;
      setState(() {
        _tasks
          ..clear()
          ..addAll(visible);
        _loadingTasks = false;
        _taskError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingTasks = false;
        _taskError =
            'Could not load tasks. Check your Supabase table and policies.';
      });
    }
  }

  // ── Saving ──
  Future<void> _saveGroceries() =>
      _saveJson('groceries', _groceries.map((e) => e.toJson()).toList());
  Future<void> _saveMonthlyItems() =>
      _saveJson('monthly_items', _monthlyItems.map((e) => e.toJson()).toList());
  Future<void> _saveProfile() => _saveJson('profile', _profile.toJson());
  Future<void> _saveChallenges() =>
      _saveJson('challenges', _challenges.map((e) => e.toJson()).toList());
  Future<void> _savePlanner() async {
    await _saveJson('deadlines', _deadlines.map((e) => e.toJson()).toList());
    await _saveJson('timetable', _timetable.map((e) => e.toJson()).toList());
  }

  Future<void> _savePlan() async {
    await _saveJson('workout_plans', _plans.map((p) => p.toJson()).toList());
    await _saveJson(
        'workout_schedule', _schedule.map((day, id) => MapEntry('$day', id)));
    await _saveJson('workout_done', _doneExercises.toList());
    await _saveJson(
        'workout_done_date', _dateOnly(DateTime.now()).toIso8601String());
  }

  Future<void> _saveJournalList() =>
      _saveJson('journal', _journal.map((e) => e.toJson()).toList());

  // ── Activity history ──
  void _log(String type, String title, [String detail = '']) {
    setState(() {
      _activity.insert(0, ActivityLog(type, title, detail, DateTime.now()));
      if (_activity.length > 600) {
        _activity.removeRange(600, _activity.length);
      }
    });
    _saveJson('activity', _activity.map((e) => e.toJson()).toList());
  }

  void _unlog(String type, String title) {
    final index = _activity.indexWhere((log) =>
        log.type == type &&
        log.title == title &&
        _sameDay(log.date, DateTime.now()));
    if (index == -1) return;
    setState(() => _activity.removeAt(index));
    _saveJson('activity', _activity.map((e) => e.toJson()).toList());
  }

  void _openHistory(String type, String title, String empty) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => _HistoryPage(
        title: title,
        emptyText: empty,
        logs: _activity.where((log) => log.type == type).toList(),
      ),
    ));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Tasks ──
  Future<void> _toggleTask(TaskItem task) async {
    if (task.id == null) return;
    final previous = task.done;
    setState(() {
      task.done = !previous;
      task.completedAt = task.done ? DateTime.now() : null;
    });
    try {
      await _taskService.updateTask(id: task.id!, completed: task.done);
      if (task.done) {
        _doneTodayIds.add(task.id!);
      } else {
        _doneTodayIds.remove(task.id!);
      }
      _saveJson('tasks_done_today', {
        'date': _dateOnly(DateTime.now()).toIso8601String(),
        'ids': _doneTodayIds.toList(),
      });
      if (task.done) {
        _log('task', task.title, task.area);
      } else {
        _unlog('task', task.title);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => task.done = previous);
      _showMessage('Could not update that task.');
    }
  }

  Future<void> _deleteTask(TaskItem task) async {
    if (task.id == null) return;
    setState(() => _tasks.remove(task));
    try {
      await _taskService.deleteTask(task.id!);
    } catch (error) {
      if (!mounted) return;
      await _loadTasks();
      _showMessage('Could not delete that task.');
    }
  }

  Future<void> _addTask() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => _InputDialog(
        title: 'Add to today',
        hint: 'e.g. Call the dentist',
        controller: controller,
      ),
    );
    controller.dispose();
    if (title == null || title.trim().isEmpty || !mounted) return;
    try {
      final task = await _taskService.createTask(title: title.trim());
      if (!mounted) return;
      setState(() => _tasks.insert(0, task));
    } catch (error) {
      _showMessage('Could not save that task.');
    }
  }

  // ── Groceries ──
  void _toggleGrocery(GroceryItem item) {
    setState(() {
      item.bought = !item.bought;
      if (item.bought) item.purchasedAt = DateTime.now();
    });
    if (item.bought) {
      _log(
        'grocery',
        'Bought ${item.name}',
        item.price > 0
            ? '$_currencySymbol ${item.price.toStringAsFixed(2)} · ${item.category}'
            : item.category,
      );
    } else {
      _unlog('grocery', 'Bought ${item.name}');
    }
    _syncGroceryExpense(item);
    if (item.bought && item.fromPantry) _restockFromGrocery(item);
    _saveGroceries();
  }

  /// Bought groceries with a price are added to Money as a Groceries expense.
  Future<void> _syncGroceryExpense(GroceryItem item) async {
    final ref = 'grocery:${item.name}:${item.purchasedAt.toIso8601String()}';
    try {
      if (item.bought) {
        if (item.price <= 0) return;
        await financeStore.add({
          'kind': 'expense',
          'category': 'Groceries',
          'title': item.name,
          'amount': item.price,
          'occurred_at': item.purchasedAt.toUtc().toIso8601String(),
          'note': 'Added from Groceries',
          'source_ref': ref,
        });
      } else {
        await financeStore.removeWhere('source_ref', ref);
      }
    } catch (_) {}
  }

  Future<void> _addGrocery() async {
    final grocery = await showDialog<GroceryItem>(
      context: context,
      builder: (context) => const _GroceryEditorDialog(),
    );
    if (grocery == null || !mounted) return;
    setState(() => _groceries.add(grocery));
    await _saveGroceries();
  }

  Future<void> _editGrocery(GroceryItem item) async {
    final updated = await showDialog<GroceryItem>(
      context: context,
      builder: (context) => _GroceryEditorDialog(initial: item),
    );
    if (updated == null || !mounted) return;
    final index = _groceries.indexOf(item);
    if (index == -1) return;
    setState(() => _groceries[index] = updated);
    await _saveGroceries();
  }

  Future<void> _deleteGrocery(GroceryItem item) async {
    setState(() => _groceries.remove(item));
    await _saveGroceries();
  }

  void _sortGroceries() {
    setState(() {
      if (_grocerySort == 'Name') {
        _grocerySort = 'Status';
        _groceries.sort((a, b) => a.bought == b.bought
            ? a.name.compareTo(b.name)
            : (a.bought ? 1 : -1));
      } else {
        _grocerySort = 'Name';
        _groceries.sort((a, b) => a.name.compareTo(b.name));
      }
    });
  }

  // ── Pantry ──
  String _nameKey(String name) => name.trim().toLowerCase();

  void _usePantry(MonthlyItem item) {
    if (item.quantity <= 0) return;
    setState(
        () => item.quantity = (item.quantity - 1).clamp(0, 100000).toDouble());
    _afterPantryChange();
  }

  void _restockPantry(MonthlyItem item) {
    setState(() {
      item.quantity += 1;
      item.lastBought = DateTime.now();
    });
    _afterPantryChange();
  }

  void _afterPantryChange() {
    _saveMonthlyItems();
    _checkPantryLow();
  }

  /// Items that reach their alert level are added to the shopping list.
  void _checkPantryLow({bool announce = true}) {
    final added = <String>[];
    setState(() {
      for (final item in _monthlyItems) {
        if (!item.isLow) {
          item.lowListed = false;
          continue;
        }
        if (item.lowListed) continue;
        item.lowListed = true;
        final listed = _groceries
            .any((g) => !g.bought && _nameKey(g.name) == _nameKey(item.name));
        if (!listed) {
          _groceries.insert(
            0,
            GroceryItem(item.name, item.category,
                quantity: item.buyQuantity,
                price: item.price * item.buyQuantity,
                fromPantry: true),
          );
          added.add(item.name);
        }
      }
    });
    _saveMonthlyItems();
    if (added.isEmpty) return;
    _saveGroceries();
    if (announce) {
      final names = added.join(', ');
      _showMessage('Low in stock: $names. Added to your shopping list.');
      showNotification('Running low', '$names added to your shopping list.');
    }
  }

  /// Buying a list item that came from the pantry refills that pantry item.
  void _restockFromGrocery(GroceryItem grocery) {
    final index = _monthlyItems
        .indexWhere((m) => _nameKey(m.name) == _nameKey(grocery.name));
    if (index == -1) return;
    setState(() {
      final item = _monthlyItems[index];
      item.quantity += grocery.quantity <= 0 ? 1 : grocery.quantity;
      item.lastBought = DateTime.now();
      if (!item.isLow) item.lowListed = false;
      _groceries.remove(grocery);
    });
    _saveMonthlyItems();
    _saveGroceries();
    _showMessage('${grocery.name} refilled in your pantry.');
  }

  Future<void> _addMonthlyItem() async {
    final item = await showDialog<MonthlyItem>(
      context: context,
      builder: (context) => const _MonthlyItemDialog(),
    );
    if (item == null || !mounted) return;
    setState(() => _monthlyItems.add(item));
    _afterPantryChange();
  }

  Future<void> _editMonthlyItem(MonthlyItem item) async {
    final updated = await showDialog<MonthlyItem>(
      context: context,
      builder: (context) => _MonthlyItemDialog(initial: item),
    );
    if (updated == null || !mounted) return;
    final index = _monthlyItems.indexOf(item);
    if (index == -1) return;
    setState(() => _monthlyItems[index] = updated);
    _afterPantryChange();
  }

  Future<void> _deleteMonthlyItem(MonthlyItem item) async {
    setState(() => _monthlyItems.remove(item));
    await _saveMonthlyItems();
  }

  // ── Workout ──
  WorkoutPlan? _planForDay(int weekday) {
    final id = _schedule[weekday];
    for (final plan in _plans) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  WorkoutPlan? _planOf(Exercise exercise) {
    for (final plan in _plans) {
      if (plan.exercises.any((e) => e.id == exercise.id)) return plan;
    }
    return null;
  }

  void _selectWorkoutDay(int day) => setState(() => _workoutDay = day);

  void _toggleExercise(Exercise exercise) {
    setState(() {
      if (!_doneExercises.add(exercise.id)) _doneExercises.remove(exercise.id);
    });
    _savePlan();
  }

  Future<WorkoutPlan?> _createPlan() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => _InputDialog(
        title: 'New workout',
        hint: 'e.g. Upper body',
        controller: controller,
        confirmLabel: 'Create',
      ),
    );
    controller.dispose();
    if (title == null || title.trim().isEmpty || !mounted) return null;
    final plan = WorkoutPlan(
        DateTime.now().microsecondsSinceEpoch.toString(), title.trim(), []);
    setState(() => _plans.add(plan));
    return plan;
  }

  Future<void> _newWorkout() async {
    final plan = await _createPlan();
    if (plan == null || !mounted) return;
    setState(() => _schedule[_workoutDay] = plan.id);
    await _savePlan();
  }

  Future<void> _chooseWorkoutForDay() async {
    final day = _workoutDay;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                child: Text('${_weekdayNames[day - 1]} workout',
                    style: const TextStyle(
                        color: kInk,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ),
              ..._plans.map((plan) => ListTile(
                    leading: Icon(
                        _schedule[day] == plan.id
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: kPrimary),
                    title: Text(plan.title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${plan.exercises.length} exercises'),
                    onTap: () => Navigator.pop(sheet, plan.id),
                  )),
              ListTile(
                leading: Icon(
                    _schedule[day] == null
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: kPrimary),
                title: const Text('Rest day',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => Navigator.pop(sheet, '_rest'),
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline_rounded,
                    color: kPrimary),
                title: const Text('New workout',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => Navigator.pop(sheet, '_new'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == '_new') {
      await _newWorkout();
      return;
    }
    setState(() {
      if (choice == '_rest') {
        _schedule.remove(day);
      } else {
        _schedule[day] = choice;
      }
    });
    await _savePlan();
  }

  Future<void> _editExercise([Exercise? initial]) async {
    final plan = _planForDay(_workoutDay);
    if (plan == null) {
      _showMessage('Choose a workout for this day first.');
      return;
    }
    final result = await showDialog<Exercise>(
      context: context,
      builder: (context) => _ExerciseDialog(initial: initial),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (initial == null) {
        plan.exercises.add(result);
      } else {
        final index = plan.exercises.indexWhere((e) => e.id == initial.id);
        if (index != -1) plan.exercises[index] = result;
      }
    });
    await _savePlan();
  }

  void _deleteExercise(Exercise exercise) {
    final plan = _planOf(exercise);
    if (plan == null) return;
    final index = plan.exercises.indexOf(exercise);
    if (index == -1) return;
    final wasDone = _doneExercises.contains(exercise.id);
    setState(() {
      plan.exercises.removeAt(index);
      _doneExercises.remove(exercise.id);
    });
    _savePlan();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Removed ${exercise.name}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              plan.exercises
                  .insert(index.clamp(0, plan.exercises.length), exercise);
              if (wasDone) _doneExercises.add(exercise.id);
            });
            _savePlan();
          },
        ),
      ));
  }

  Future<void> _renamePlan() async {
    final plan = _planForDay(_workoutDay);
    if (plan == null) return;
    final controller = TextEditingController(text: plan.title);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => _InputDialog(
        title: 'Rename workout',
        hint: 'e.g. Leg day',
        controller: controller,
        confirmLabel: 'Save',
      ),
    );
    controller.dispose();
    if (title == null || title.trim().isEmpty || !mounted) return;
    setState(() => plan.title = title.trim());
    await _savePlan();
  }

  Future<void> _deletePlan() async {
    final plan = _planForDay(_workoutDay);
    if (plan == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${plan.title}?'),
        content: const Text(
            'It is removed from every day it was planned for. Your saved sessions in the history are kept.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _plans.remove(plan);
      _schedule.removeWhere((day, id) => id == plan.id);
      _doneExercises.removeAll(plan.exercises.map((e) => e.id));
    });
    await _savePlan();
  }

  Future<void> _restorePlans() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore suggested plans?'),
        content: const Text(
            'This replaces your workouts and weekly schedule with Push, Pull and Leg day (Mon, Wed, Fri). Your workout history is kept.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _plans = WorkoutPlan.defaultPlans();
      _schedule = WorkoutPlan.defaultSchedule();
      _doneExercises.clear();
    });
    await _savePlan();
  }

  Future<void> _resetWorkoutProgress() async {
    setState(_doneExercises.clear);
    await _savePlan();
  }

  Future<void> _finishWorkout() async {
    final plan = _planForDay(_workoutDay);
    if (plan == null) {
      _showMessage('Choose a workout for this day first.');
      return;
    }
    final done =
        plan.exercises.where((e) => _doneExercises.contains(e.id)).toList();
    if (done.isEmpty) {
      _showMessage('Tick at least one exercise first.');
      return;
    }
    _log(
      'workout',
      plan.title,
      '${done.length}/${plan.exercises.length} exercises · ${done.map((e) => e.name).join(', ')}',
    );
    setState(() => _doneExercises.removeAll(plan.exercises.map((e) => e.id)));
    await _savePlan();
    _showMessage('Session saved to your history.');
  }

  Future<void> _logManualWorkout() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => _InputDialog(
        title: 'Log a workout',
        hint: 'e.g. 30-minute run',
        controller: controller,
      ),
    );
    controller.dispose();
    if (title == null || title.trim().isEmpty || !mounted) return;
    _log('workout', title.trim(), 'Logged manually');
  }

  // ── Challenges ──
  void _toggleChallengeDay(int index) {
    final challenge = _selectedChallenge;
    setState(() {
      challenge.days[index] = !challenge.days[index];
      challenge.restDays.remove(index);
      if (challenge.days[index]) {
        challenge.doneAt[index] = DateTime.now();
      } else {
        challenge.doneAt.remove(index);
      }
    });
    if (challenge.days[index]) {
      _log('challenge', '${challenge.title} · day ${index + 1}');
    } else {
      _unlog('challenge', '${challenge.title} · day ${index + 1}');
    }
    _saveChallenges();
  }

  Future<void> _openChallengeDay(int index) async {
    final challenge = _selectedChallenge;
    final result = await showModalBottomSheet<_DayResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _ChallengeDaySheet(challenge: challenge, index: index),
    );
    if (result == null || !mounted) return;
    final wasDone = challenge.days[index];
    setState(() {
      challenge.days[index] = result.status == 'done';
      if (result.status == 'done') {
        challenge.doneAt.putIfAbsent(index, DateTime.now);
      } else {
        challenge.doneAt.remove(index);
      }
      if (result.status == 'rest') {
        challenge.restDays.add(index);
      } else {
        challenge.restDays.remove(index);
      }
      if (result.note.isEmpty) {
        challenge.notes.remove(index);
      } else {
        challenge.notes[index] = result.note;
      }
      if (result.photo == null) {
        challenge.photos.remove(index);
      } else {
        challenge.photos[index] = result.photo!;
      }
    });
    final logTitle = '${challenge.title} · day ${index + 1}';
    if (result.status == 'done' && !wasDone) {
      _log('challenge', logTitle, result.photo != null ? 'With a photo' : '');
    } else if (result.status != 'done' && wasDone) {
      _unlog('challenge', logTitle);
    }
    await _saveChallenges();
    if (_isBible(challenge) && result.status == 'done' && !wasDone && mounted) {
      await _addBibleReading(context);
    }
  }

  void _selectChallenge(int index) {
    setState(() {
      if (_selectedChallengeIndex == index) {
        _challenges[index].expanded = !_challenges[index].expanded;
      } else {
        _selectedChallengeIndex = index;
        _challenges[index].expanded = true;
      }
    });
  }

  Future<void> _deleteChallenge(int index) async {
    if (_challenges.length == 1) {
      _showMessage('Keep at least one challenge.');
      return;
    }
    setState(() {
      _challenges.removeAt(index);
      if (_selectedChallengeIndex >= _challenges.length) {
        _selectedChallengeIndex = _challenges.length - 1;
      } else if (_selectedChallengeIndex > index) {
        _selectedChallengeIndex--;
      }
    });
    await _saveChallenges();
  }

  Future<void> _addChallenge() async {
    final challenge = await showDialog<ChallengeItem>(
      context: context,
      builder: (context) => _ChallengeDialog(
        color: [
          kGreen,
          kOrange,
          kPurple,
          const Color(0xFF3D9BB5),
        ][_challenges.length % 4],
      ),
    );
    if (challenge == null || !mounted) return;
    setState(() {
      challenge.expanded = true;
      _challenges.add(challenge);
      _selectedChallengeIndex = _challenges.length - 1;
    });
    await _saveChallenges();
  }

  Future<void> _resetChallengeProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text(
            'This clears the done and rest days of this challenge. Your photos and notes are kept.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _selectedChallenge.days
          .fillRange(0, _selectedChallenge.days.length, false);
      _selectedChallenge.restDays.clear();
    });
    await _saveChallenges();
  }

  // ── Journal ──
  Future<void> _saveJournalEntry(JournalEntry entry) async {
    setState(() {
      _journal.removeWhere((e) => _sameDay(e.date, entry.date));
      _journal.insert(0, entry);
    });
    await _saveJournalList();
  }

  // ── Profile & planner ──
  Future<void> _editProfile() async {
    final updated = await showDialog<ProfileData>(
      context: context,
      builder: (context) => _ProfileEditorDialog(profile: _profile),
    );
    if (updated == null || !mounted) return;
    setState(() {
      _profile
        ..name = updated.name
        ..email = updated.email
        ..goal = updated.goal
        ..targetMass = updated.targetMass
        ..currency = updated.currency;
    });
    await _saveProfile();
  }

  Future<void> _addDeadline() async {
    final result = await showDialog<PlannerDeadline>(
      context: context,
      builder: (context) => const _DeadlineDialog(),
    );
    if (result == null || !mounted) return;
    setState(() => _deadlines.add(result));
    await _savePlanner();
  }

  Future<void> _addTimetableEntry() async {
    final result = await showDialog<TimetableEntry>(
      context: context,
      builder: (context) => const _TimetableDialog(),
    );
    if (result == null || !mounted) return;
    setState(() => _timetable.add(result));
    await _savePlanner();
  }

  Future<void> _deleteDeadline(PlannerDeadline deadline) async {
    setState(() => _deadlines.remove(deadline));
    await _savePlanner();
  }

  Future<void> _deleteTimetableEntry(TimetableEntry entry) async {
    setState(() => _timetable.remove(entry));
    await _savePlanner();
  }

  Future<void> _showNotifications() async {
    if (!notificationsSupported) {
      _showMessage('Browser notifications are not supported here.');
      return;
    }
    final enabled = await requestNotificationPermission();
    if (!mounted) return;
    if (!enabled) {
      _showMessage('Allow notifications in your browser to enable reminders.');
      return;
    }
    showNotification(
      'Dayflow reminders enabled',
      'You will receive reminders while Dayflow is open.',
    );
    _showMessage('Notifications enabled for this browser.');
  }

  // ── Navigation ──
  void _openMoreMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MoreMenuItem(
                  icon: Icons.shopping_basket_outlined,
                  label: 'Shop',
                  color: kOrange,
                  onTap: () => _selectMorePage(sheet, _shop)),
              _MoreMenuItem(
                  icon: Icons.emoji_events_outlined,
                  label: 'Challenges',
                  color: kPurple,
                  onTap: () => _selectMorePage(sheet, _challengesPage)),
              _MoreMenuItem(
                  icon: Icons.calendar_month_outlined,
                  label: 'Planner',
                  color: kGreen,
                  onTap: () => _selectMorePage(sheet, _planner)),
              _MoreMenuItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Money',
                  color: const Color(0xFF12A383),
                  onTap: () => _selectMorePage(sheet, _finance)),
              _MoreMenuItem(
                  icon: Icons.menu_book_outlined,
                  label: 'Bible',
                  color: kGold,
                  onTap: () => _selectMorePage(sheet, _bible)),
              _MoreMenuItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  color: kPrimary,
                  onTap: () => _selectMorePage(sheet, _profilePage)),
            ],
          ),
        ),
      ),
    );
  }

  void _selectMorePage(BuildContext sheetContext, int page) {
    Navigator.pop(sheetContext);
    setState(() => _selectedIndex = page);
  }

  // ── Meal ideas ──
  Future<void> _showMealPlan() async {
    final ingredients = _groceries
        .where((item) => item.bought && !item.isExpired)
        .map((item) => item.name.toLowerCase())
        .toSet();
    final meals = [
      (
        'Chicken rice bowl',
        'Chicken, rice, broccoli and tomatoes',
        Icons.rice_bowl
      ),
      ('Veggie omelette', 'Eggs, tomatoes and vegetables', Icons.egg_alt),
      (
        'Creamy tomato pasta',
        'Pasta, tomatoes and a simple sauce',
        Icons.dinner_dining
      ),
      (
        'Chicken stir-fry',
        'Chicken, rice and any vegetables available',
        Icons.outdoor_grill
      ),
    ];
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Today's meal plan"),
        content: SizedBox(
          width: 420,
          child: ListView(
            shrinkWrap: true,
            children: meals
                .map((meal) => ListTile(
                      leading: Icon(meal.$3, color: kOrange),
                      title: Text(meal.$1),
                      subtitle: Text(
                        '${meal.$2}\nAvailable: ${ingredients.isEmpty ? 'Add items to your pantry' : ingredients.take(3).join(', ')}',
                      ),
                      isThreeLine: true,
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _showPantryDetails() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pantry status'),
        content: SizedBox(
          width: 420,
          child: ListView(
            shrinkWrap: true,
            children: _groceries
                .where((item) => item.bought)
                .map((item) => ListTile(
                      leading: Icon(
                        item.isExpired
                            ? Icons.delete_outline
                            : item.isLow
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline,
                        color: item.isExpired
                            ? kRed
                            : item.isLow
                                ? kOrange
                                : kGreen,
                      ),
                      title: Text(item.name),
                      subtitle: Text(item.isExpired
                          ? 'Should be thrown out'
                          : item.isLow
                              ? 'Running low (${item.quantity} left)'
                              : 'Available until ${item.expiresAt.month}/${item.expiresAt.day}'),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final workoutsThisWeek = _activity
        .where((log) => log.type == 'workout' && log.date.isAfter(weekAgo))
        .length;
    final hasJournalToday =
        _journal.any((entry) => _sameDay(entry.date, DateTime.now()));
    final lowPantry = _monthlyItems
        .where((item) => item.isLow)
        .map((item) => item.name)
        .toList();
    final selectedPlan = _planForDay(_workoutDay);
    ActivityLog? lastSession;
    if (selectedPlan != null) {
      for (final log in _activity) {
        if (log.type == 'workout' && log.title == selectedPlan.title) {
          lastSession = log;
          break;
        }
      }
    }
    final recentWorkouts =
        _activity.where((log) => log.type == 'workout').take(5).toList();
    final todayPlan = _planForDay(DateTime.now().weekday);
    final todayWorkout = todayPlan == null
        ? null
        : '${todayPlan.title} · ${todayPlan.exercises.length} exercises planned.';

    final pages = <Widget>[
      _DashboardPage(
        name: _profile.name,
        tasks: _tasks,
        completedTasks: _completedTasks,
        workoutsThisWeek: workoutsThisWeek,
        challenge: _selectedChallenge,
        hasJournalToday: hasJournalToday,
        currencySymbol: _currencySymbol,
        onTaskToggle: _toggleTask,
        onTaskDelete: _deleteTask,
        onChallengeOpen: _openChallengeDay,
        onChallengeQuick: _toggleChallengeDay,
        onSeeAllTasks: () => setState(() => _selectedIndex = _today),
        onOpenChallenges: () =>
            setState(() => _selectedIndex = _challengesPage),
        onOpenProfile: () => setState(() => _selectedIndex = _profilePage),
        onOpenJournal: () => setState(() => _selectedIndex = _journalPage),
        onOpenFinance: () => setState(() => _selectedIndex = _finance),
        onOpenBible: () => setState(() => _selectedIndex = _bible),
        lowStock: lowPantry,
        onOpenShop: () => setState(() => _selectedIndex = _shop),
        todayWorkout: todayWorkout,
        onOpenWorkout: () => setState(() => _selectedIndex = 2),
        onMealPlan: _showMealPlan,
        onNotifications: _showNotifications,
      ),
      _TasksPage(
        tasks: _tasks,
        onToggle: _toggleTask,
        onDelete: _deleteTask,
        onAdd: _addTask,
        onHistory: () => _openHistory(
            'task', 'Completed tasks', 'Tasks you finish will show up here.'),
        loading: _loadingTasks,
        error: _taskError,
        onRetry: _loadTasks,
      ),
      _WorkoutPage(
        plans: _plans,
        schedule: _schedule,
        selectedDay: _workoutDay,
        done: _doneExercises,
        lastSession: lastSession,
        recent: recentWorkouts,
        onSelectDay: _selectWorkoutDay,
        onChoosePlan: _chooseWorkoutForDay,
        onToggle: _toggleExercise,
        onAdd: () => _editExercise(),
        onEdit: _editExercise,
        onDelete: _deleteExercise,
        onFinish: _finishWorkout,
        onManual: _logManualWorkout,
        onRename: _renamePlan,
        onDeletePlan: _deletePlan,
        onNewPlan: _newWorkout,
        onRestore: _restorePlans,
        onReset: _resetWorkoutProgress,
        onHistory: () => _openHistory('workout', 'Workout history',
            'Finish a session and it will be saved here.'),
      ),
      _JournalPage(
        journal: _journal,
        activity: _activity,
        onSave: _saveJournalEntry,
      ),
      _GroceriesPage(
        groceries: _groceries,
        monthlyItems: _monthlyItems,
        onToggle: _toggleGrocery,
        onAdd: _addGrocery,
        onSort: _sortGroceries,
        sortLabel: _grocerySort,
        onMealPlan: _showMealPlan,
        onManagePantry: _showPantryDetails,
        onEdit: _editGrocery,
        onDelete: _deleteGrocery,
        onAddMonthly: _addMonthlyItem,
        onEditMonthly: _editMonthlyItem,
        onDeleteMonthly: _deleteMonthlyItem,
        onUsePantry: _usePantry,
        onRestockPantry: _restockPantry,
        onHistory: () => _openHistory('grocery', 'Shopping history',
            'Tick an item as bought and it will be saved here.'),
        currencySymbol: _currencySymbol,
      ),
      _ChallengesPage(
        challenges: _challenges,
        selectedIndex: _selectedChallengeIndex,
        onSelect: _selectChallenge,
        onOpenDay: _openChallengeDay,
        onQuickDay: _toggleChallengeDay,
        onAdd: _addChallenge,
        onDelete: _deleteChallenge,
        onResetProgress: _resetChallengeProgress,
      ),
      _ProfilePage(
        profile: _profile,
        groceries: _groceries,
        challenges: _challenges,
        onEdit: _editProfile,
        onSignOut: _signOut,
        onBackup: _backupNow,
      ),
      _PlannerPage(
        deadlines: _deadlines,
        timetable: _timetable,
        onAddDeadline: _addDeadline,
        onAddClass: _addTimetableEntry,
        onDeleteDeadline: _deleteDeadline,
        onDeleteClass: _deleteTimetableEntry,
      ),
      _FinancePage(currencySymbol: _currencySymbol),
      const _BiblePage(),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (widget.startupError != null)
              _ConnectionBanner(message: widget.startupError!),
            ValueListenableBuilder<String?>(
              valueListenable: syncMessage,
              builder: (context, message, _) => message == null
                  ? const SizedBox.shrink()
                  : _ConnectionBanner(message: message),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: KeyedSubtree(
                      key: ValueKey(_selectedIndex),
                      child: pages[_selectedIndex],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex <= _journalPage ? _selectedIndex : 4,
        onDestinationSelected: (index) {
          if (index == 4) {
            _openMoreMenu();
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: kPrimary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist_rounded, color: kPrimary),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center_rounded, color: kPrimary),
            label: 'Workout',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories_rounded, color: kPrimary),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_rounded, color: kPrimary),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Home ─────────────────────────
class _DashboardPage extends StatelessWidget {
  const _DashboardPage({
    required this.name,
    required this.tasks,
    required this.completedTasks,
    required this.workoutsThisWeek,
    required this.challenge,
    required this.hasJournalToday,
    required this.currencySymbol,
    required this.onTaskToggle,
    required this.onTaskDelete,
    required this.onChallengeOpen,
    required this.onChallengeQuick,
    required this.onSeeAllTasks,
    required this.onOpenChallenges,
    required this.onOpenProfile,
    required this.onOpenJournal,
    required this.onOpenFinance,
    required this.onOpenBible,
    required this.lowStock,
    required this.onOpenShop,
    required this.todayWorkout,
    required this.onOpenWorkout,
    required this.onMealPlan,
    required this.onNotifications,
  });

  final String name;
  final List<TaskItem> tasks;
  final int completedTasks;
  final int workoutsThisWeek;
  final ChallengeItem challenge;
  final bool hasJournalToday;
  final String currencySymbol;
  final ValueChanged<TaskItem> onTaskToggle;
  final ValueChanged<TaskItem> onTaskDelete;
  final ValueChanged<int> onChallengeOpen;
  final ValueChanged<int> onChallengeQuick;
  final VoidCallback onSeeAllTasks;
  final VoidCallback onOpenChallenges;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenJournal;
  final VoidCallback onOpenFinance;
  final VoidCallback onOpenBible;
  final List<String> lowStock;
  final VoidCallback onOpenShop;
  final String? todayWorkout;
  final VoidCallback onOpenWorkout;
  final VoidCallback onMealPlan;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final progress = tasks.isEmpty ? 0.0 : completedTasks / tasks.length;
    final pending = tasks.where((task) => !task.done).take(3).toList();
    return _PageScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
        children: [
          _Reveal(
            index: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_dayLabel(DateTime.now()),
                          style: const TextStyle(
                              color: kMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text('${_greeting()}, $name',
                          style: const TextStyle(
                              color: kInk,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8)),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: onOpenProfile,
                  tooltip: 'Profile',
                  icon: const Icon(Icons.person_outline_rounded),
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  onPressed: onNotifications,
                  tooltip: 'Enable notifications',
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _Reveal(index: 1, child: _VerseBanner(onOpen: onOpenBible)),
          const SizedBox(height: 16),
          _Reveal(
            index: 2,
            child: _FocusCard(
                progress: progress,
                completed: completedTasks,
                total: tasks.length),
          ),
          const SizedBox(height: 14),
          _Reveal(
            index: 3,
            child: Row(children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.checklist_rounded,
                  color: kPrimary,
                  count: completedTasks.toDouble(),
                  suffix: '/${tasks.length}',
                  label: 'Tasks done',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.fitness_center_rounded,
                  color: kGreen,
                  count: workoutsThisWeek.toDouble(),
                  suffix: '',
                  label: 'Workouts this week',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.emoji_events_rounded,
                  color: challenge.color,
                  count: challenge.doneCount.toDouble(),
                  suffix: '/${challenge.totalDays}',
                  label: 'Challenge days',
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          const _Reveal(index: 4, child: _MotivationCard()),
          const SizedBox(height: 14),
          _Reveal(
            index: 5,
            child: _MoneyMiniCard(symbol: currencySymbol, onTap: onOpenFinance),
          ),
          const SizedBox(height: 24),
          _Reveal(
            index: 6,
            child: _SectionTitle(
                title: 'Up next', action: 'See all', onAction: onSeeAllTasks),
          ),
          const SizedBox(height: 10),
          if (pending.isEmpty)
            const _Reveal(
              index: 7,
              child: _EmptyCard(
                icon: Icons.celebration_outlined,
                text: 'Nothing left on your list. Enjoy the calm.',
              ),
            )
          else
            ...pending.asMap().entries.map(
                  (entry) => _Reveal(
                    index: 7 + entry.key,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _TaskRow(
                        task: entry.value,
                        onToggle: () => onTaskToggle(entry.value),
                        onDelete: () => onTaskDelete(entry.value),
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 15),
          _Reveal(
            index: 8,
            child: _AssistantCard(
              title: 'Today’s workout',
              message: todayWorkout ??
                  'Rest day today. Recover well, or plan a session in Workout.',
              icon: Icons.fitness_center_rounded,
              action: 'Open workout',
              onAction: onOpenWorkout,
            ),
          ),
          if (lowStock.isNotEmpty) ...[
            const SizedBox(height: 15),
            _Reveal(
              index: 9,
              child: _AssistantCard(
                title: 'Running low',
                message:
                    '${lowStock.take(4).join(', ')} ${lowStock.length == 1 ? 'is' : 'are'} low in stock and on your shopping list.',
                icon: Icons.shopping_cart_checkout_rounded,
                action: 'Open shopping list',
                onAction: onOpenShop,
              ),
            ),
          ],
          const SizedBox(height: 15),
          _Reveal(
            index: 10,
            child: _AssistantCard(
              title: 'Daily log',
              message: hasJournalToday
                  ? 'Today’s entry is saved. Open your journal to review everything you completed.'
                  : 'How was today? Write a quick entry and keep a record of what you got done.',
              icon: Icons.auto_stories_rounded,
              action:
                  hasJournalToday ? 'Review journal' : 'Write today’s entry',
              onAction: onOpenJournal,
            ),
          ),
          const SizedBox(height: 12),
          _Reveal(
            index: 11,
            child: _AssistantCard(
              title: 'Your assistant noticed',
              message:
                  'You have chicken, eggs, rice and broccoli available. A high-protein lunch is ready to make.',
              icon: Icons.lightbulb_rounded,
              action: 'View meal ideas',
              onAction: onMealPlan,
            ),
          ),
          const SizedBox(height: 24),
          _Reveal(
            index: 12,
            child: _SectionTitle(
                title: challenge.title,
                action: 'Open',
                onAction: onOpenChallenges),
          ),
          const SizedBox(height: 10),
          _Reveal(
            index: 13,
            child: _ChallengeCard(
              challenge: challenge,
              onOpen: onChallengeOpen,
              onQuick: onChallengeQuick,
            ),
          ),
        ],
      ),
    );
  }
}

class _MotivationCard extends StatelessWidget {
  const _MotivationCard();

  static const _lines = [
    'Small steps, taken every day, build the life you want.',
    'Progress, not perfection. Show up again today.',
    'Future you is cheering for what you do in the next hour.',
    'Discipline is just a promise you keep to yourself.',
    'One more rep, one more page, one more good choice.',
    'Consistency beats intensity. Keep the streak alive.',
    'You are closer than you were yesterday.',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final day = now.difference(DateTime(now.year)).inDays;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFF9A5A), Color(0xFFFF6B8B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFFF6B8B).withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(children: [
        const Icon(Icons.local_fire_department_rounded,
            color: Colors.white, size: 32),
        const SizedBox(width: 14),
        Expanded(
          child: Text(_lines[day % _lines.length],
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  height: 1.4)),
        ),
      ]),
    );
  }
}

// ───────────────────────── Today ─────────────────────────
class _TasksPage extends StatelessWidget {
  const _TasksPage({
    required this.tasks,
    required this.onToggle,
    required this.onDelete,
    required this.onAdd,
    required this.onHistory,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final List<TaskItem> tasks;
  final ValueChanged<TaskItem> onToggle;
  final ValueChanged<TaskItem> onDelete;
  final VoidCallback onAdd;
  final VoidCallback onHistory;
  final bool loading;
  final String? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final pending = tasks.where((task) => !task.done).toList();
    final done = tasks.where((task) => task.done).toList();
    return _PageScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
        children: [
          _PageHeader(
            eyebrow: _dayLabel(DateTime.now()),
            title: 'Today',
            subtitle: '${pending.length} things to focus on',
            action: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton.filledTonal(
                onPressed: onHistory,
                icon: const Icon(Icons.history_rounded),
                tooltip: 'Completed tasks',
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Add task',
              ),
            ]),
          ),
          const SizedBox(height: 22),
          _AssistantCard(
            title: 'Suggested by Dayflow',
            message:
                'Protect 7–9 PM for Flutter practice. You usually focus best during this window.',
            icon: Icons.lightbulb_rounded,
            action: 'Add focus block',
            onAction: onAdd,
          ),
          const SizedBox(height: 24),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (error != null)
            _ErrorState(message: error!, onRetry: onRetry)
          else if (tasks.isEmpty)
            const _EmptyCard(
              icon: Icons.edit_note_rounded,
              text: 'Your day is empty. Tap + to add the first task.',
            )
          else ...[
            ...pending.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TaskRow(
                  task: task,
                  onToggle: () => onToggle(task),
                  onDelete: () => onDelete(task),
                ),
              ),
            ),
            if (done.isNotEmpty) ...[
              const SizedBox(height: 14),
              _SectionTitle(
                  title: 'Done today (${done.length})',
                  action: 'History',
                  onAction: onHistory),
              const SizedBox(height: 10),
              ...done.map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TaskRow(
                    task: task,
                    onToggle: () => onToggle(task),
                    onDelete: () => onDelete(task),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ───────────────────────── Groceries ─────────────────────────
class _GroceriesPage extends StatelessWidget {
  const _GroceriesPage({
    required this.groceries,
    required this.monthlyItems,
    required this.onToggle,
    required this.onAdd,
    required this.onSort,
    required this.sortLabel,
    required this.onMealPlan,
    required this.onManagePantry,
    required this.onEdit,
    required this.onDelete,
    required this.onAddMonthly,
    required this.onEditMonthly,
    required this.onDeleteMonthly,
    required this.onUsePantry,
    required this.onRestockPantry,
    required this.onHistory,
    required this.currencySymbol,
  });

  final List<GroceryItem> groceries;
  final List<MonthlyItem> monthlyItems;
  final ValueChanged<GroceryItem> onToggle;
  final VoidCallback onAdd;
  final VoidCallback onSort;
  final String sortLabel;
  final VoidCallback onMealPlan;
  final VoidCallback onManagePantry;
  final ValueChanged<GroceryItem> onEdit;
  final ValueChanged<GroceryItem> onDelete;
  final VoidCallback onAddMonthly;
  final ValueChanged<MonthlyItem> onEditMonthly;
  final ValueChanged<MonthlyItem> onDeleteMonthly;
  final ValueChanged<MonthlyItem> onUsePantry;
  final ValueChanged<MonthlyItem> onRestockPantry;
  final VoidCallback onHistory;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final available =
        groceries.where((item) => item.bought).map((item) => item.name);
    final totalCost = groceries
        .where((item) => !item.bought)
        .fold<double>(0, (sum, item) => sum + item.price);
    final lowStock =
        groceries.where((item) => item.isLow && item.bought).toList();
    final expired =
        groceries.where((item) => item.isExpired && item.bought).toList();
    return _PageScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
        children: [
          _PageHeader(
            eyebrow: 'Smart shopping',
            title: 'Groceries',
            subtitle:
                '${groceries.where((item) => !item.bought).length} items to buy',
            action: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton.filledTonal(
                onPressed: onHistory,
                icon: const Icon(Icons.history_rounded),
                tooltip: 'Shopping history',
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Add grocery',
              ),
            ]),
          ),
          const SizedBox(height: 20),
          _MealSuggestion(
              ingredients: available.toList(), onOpenPlan: onMealPlan),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PantrySummary(
                    title: 'Shopping total',
                    value: '$currencySymbol ${totalCost.toStringAsFixed(2)}',
                    icon: Icons.receipt_long_rounded,
                    color: kPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onManagePantry,
                  child: _PantrySummary(
                      title: 'Low stock',
                      value: '${lowStock.length}',
                      icon: Icons.warning_amber_rounded,
                      color: kOrange),
                ),
              ),
            ],
          ),
          if (lowStock.isNotEmpty || expired.isNotEmpty) ...[
            const SizedBox(height: 12),
            _PantryAlert(lowStock: lowStock, expired: expired),
          ],
          const SizedBox(height: 24),
          _SectionTitle(
              title: 'Weekly groceries',
              action: 'Sort: $sortLabel',
              onAction: onSort),
          const SizedBox(height: 10),
          if (groceries.isEmpty)
            const _EmptyCard(
                icon: Icons.shopping_basket_outlined,
                text: 'No groceries yet. Tap + to add one.'),
          ...groceries.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _GroceryRow(
                  item: item,
                  onToggle: () => onToggle(item),
                  onEdit: () => onEdit(item),
                  onDelete: () => onDelete(item),
                  currencySymbol: currencySymbol),
            ),
          ),
          const SizedBox(height: 24),
          _PantrySection(
            items: monthlyItems,
            onAdd: onAddMonthly,
            onEdit: onEditMonthly,
            onDelete: onDeleteMonthly,
            onUse: onUsePantry,
            onRestock: onRestockPantry,
            currencySymbol: currencySymbol,
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Workout ─────────────────────────
const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

class _WorkoutPage extends StatelessWidget {
  const _WorkoutPage({
    required this.plans,
    required this.schedule,
    required this.selectedDay,
    required this.done,
    required this.lastSession,
    required this.recent,
    required this.onSelectDay,
    required this.onChoosePlan,
    required this.onToggle,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onFinish,
    required this.onManual,
    required this.onRename,
    required this.onDeletePlan,
    required this.onNewPlan,
    required this.onRestore,
    required this.onReset,
    required this.onHistory,
  });

  final List<WorkoutPlan> plans;
  final Map<int, String> schedule;
  final int selectedDay;
  final Set<String> done;
  final ActivityLog? lastSession;
  final List<ActivityLog> recent;
  final ValueChanged<int> onSelectDay;
  final VoidCallback onChoosePlan;
  final ValueChanged<Exercise> onToggle;
  final VoidCallback onAdd;
  final ValueChanged<Exercise> onEdit;
  final ValueChanged<Exercise> onDelete;
  final VoidCallback onFinish;
  final VoidCallback onManual;
  final VoidCallback onRename;
  final VoidCallback onDeletePlan;
  final VoidCallback onNewPlan;
  final VoidCallback onRestore;
  final VoidCallback onReset;
  final VoidCallback onHistory;

  WorkoutPlan? get _plan {
    final id = schedule[selectedDay];
    for (final plan in plans) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final current = _plan;
    final today = DateTime.now().weekday;
    final dayName = _weekdayNames[selectedDay - 1];
    final exercises = current?.exercises ?? const <Exercise>[];
    final total = exercises.length;
    final completed = exercises.where((e) => done.contains(e.id)).length;
    final progress = total == 0 ? 0.0 : completed / total;
    final last = lastSession;
    return _PageScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
        children: [
          _PageHeader(
            eyebrow: 'Workout planner',
            title: current?.title ?? 'Rest day',
            subtitle:
                '$dayName${selectedDay == today ? ' · today' : ''}${current == null ? '' : ' · $total exercises'}',
            action: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton.filledTonal(
                onPressed: onHistory,
                icon: const Icon(Icons.history_rounded),
                tooltip: 'Workout history',
              ),
              if (current != null) ...[
                const SizedBox(width: 6),
                IconButton.filled(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'Add exercise',
                ),
              ],
              PopupMenuButton<String>(
                tooltip: 'More',
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  switch (value) {
                    case 'choose':
                      onChoosePlan();
                    case 'new':
                      onNewPlan();
                    case 'rename':
                      onRename();
                    case 'delete':
                      onDeletePlan();
                    case 'reset':
                      onReset();
                    case 'restore':
                      onRestore();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                      value: 'choose',
                      child: Text('Change workout for $dayName')),
                  const PopupMenuItem(value: 'new', child: Text('New workout')),
                  if (current != null) ...const [
                    PopupMenuItem(
                        value: 'rename', child: Text('Rename this workout')),
                    PopupMenuItem(
                        value: 'delete', child: Text('Delete this workout')),
                  ],
                  const PopupMenuItem(
                      value: 'reset', child: Text('Clear today’s ticks')),
                  const PopupMenuItem(
                      value: 'restore', child: Text('Restore suggested plans')),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 18),
          _WeekStrip(
            plans: plans,
            schedule: schedule,
            selected: selectedDay,
            onSelect: onSelectDay,
          ),
          const SizedBox(height: 18),
          if (current == null)
            _EmptyCard(
              icon: Icons.hotel_rounded,
              text:
                  'Rest day. Recovery is part of the plan. Want to train on $dayName instead?',
              actionLabel: 'Plan a workout',
              onAction: onChoosePlan,
            )
          else ...[
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              decoration: _cardDecoration(),
              child: Row(children: [
                const Icon(Icons.event_available_rounded,
                    color: kPrimary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('$dayName: ${current.title}',
                      style: const TextStyle(
                          color: kInk,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800)),
                ),
                TextButton(
                    onPressed: onChoosePlan, child: const Text('Change')),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kGreenSoft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD1EEDB)),
              ),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.history_rounded, color: kGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            last == null
                                ? 'No session saved yet for ${current.title}'
                                : 'Last session · ${_relativeDay(last.date)} at ${_fmtTime(last.date)}',
                            style: const TextStyle(
                                color: Color(0xFF2D714A),
                                fontSize: 13,
                                fontWeight: FontWeight.w800)),
                        if (last != null && last.detail.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(last.detail,
                              style: const TextStyle(
                                  color: Color(0xFF548269),
                                  fontSize: 12,
                                  height: 1.35)),
                        ],
                      ]),
                ),
              ]),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionTitle(title: 'Exercises'),
                Text('$completed/$total',
                    style: const TextStyle(
                        color: kPrimary, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              color: kPrimary,
              backgroundColor: const Color(0xFFE4E7F5),
            ),
            const SizedBox(height: 14),
            if (exercises.isEmpty)
              _EmptyCard(
                icon: Icons.fitness_center_rounded,
                text: 'No exercises yet. Add your first one.',
                actionLabel: 'Add exercise',
                onAction: onAdd,
              )
            else
              ...exercises.asMap().entries.map(
                    (entry) => _ExerciseRow(
                      number: entry.key + 1,
                      exercise: entry.value,
                      done: done.contains(entry.value.id),
                      onToggle: () => onToggle(entry.value),
                      onEdit: () => onEdit(entry.value),
                      onDelete: () => onDelete(entry.value),
                    ),
                  ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onFinish,
              icon: const Icon(Icons.flag_rounded),
              label: const Text('Finish and save session'),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add exercise'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onManual,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Log other'),
                ),
              ),
            ]),
          ],
          const SizedBox(height: 26),
          _SectionTitle(
              title: 'Recent sessions', action: 'All', onAction: onHistory),
          const SizedBox(height: 10),
          if (recent.isEmpty)
            const _EmptyCard(
              icon: Icons.history_rounded,
              text: 'Finish a session and it will be saved here.',
            )
          else
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: _cardDecoration(),
              child: Column(
                children: recent
                    .map((log) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(_relativeDay(log.date),
                                    style: const TextStyle(
                                        color: kMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                              ),
                              _ActivityTile(log: log),
                            ]))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.plans,
    required this.schedule,
    required this.selected,
    required this.onSelect,
  });

  final List<WorkoutPlan> plans;
  final Map<int, String> schedule;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;
    return Row(
      children: List.generate(7, (i) {
        final day = i + 1;
        String? label;
        for (final plan in plans) {
          if (plan.id == schedule[day]) label = plan.title;
        }
        final isSelected = day == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
              decoration: BoxDecoration(
                color: isSelected ? kPrimary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? kPrimary : kLine),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: kPrimary.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 5))
                      ]
                    : null,
              ),
              child: Column(children: [
                Text(_weekdayNames[i].substring(0, 3),
                    style: TextStyle(
                        color: isSelected ? Colors.white : kMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Icon(
                    label == null
                        ? Icons.hotel_rounded
                        : Icons.fitness_center_rounded,
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : (label == null ? kFaint : kPrimary)),
                const SizedBox(height: 6),
                Text(label ?? 'Rest',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (label == null ? kFaint : kInk),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: day == today
                          ? (isSelected ? Colors.white : kPrimary)
                          : Colors.transparent),
                ),
              ]),
            ),
          ),
        );
      }),
    );
  }
}

class _ExerciseDialog extends StatefulWidget {
  const _ExerciseDialog({this.initial});

  final Exercise? initial;

  @override
  State<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<_ExerciseDialog> {
  late final TextEditingController _name;
  late final TextEditingController _detail;
  late final TextEditingController _note;
  String? _photoData;

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    _name = TextEditingController(text: item?.name ?? '');
    _detail = TextEditingController(text: item?.detail ?? '');
    _note = TextEditingController(text: item?.note ?? '');
    _photoData = item?.photo;
  }

  @override
  void dispose() {
    _name.dispose();
    _detail.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add exercise' : 'Edit exercise'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: _name,
                autofocus: widget.initial == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    labelText: 'Exercise or machine name',
                    hintText: 'Leave a guess if you are not sure')),
            const SizedBox(height: 10),
            TextField(
                controller: _detail,
                decoration: const InputDecoration(
                    labelText: 'Sets and reps',
                    hintText: 'e.g. 4 sets × 8 reps')),
            const SizedBox(height: 10),
            TextField(
                controller: _note,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Notes', hintText: 'Muscles, weight, settings')),
            const SizedBox(height: 12),
            _PhotoPicker(
              photo: _photoData,
              label: 'Add a photo of the machine',
              onChanged: (value) => setState(() => _photoData = value),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(
              context,
              Exercise(
                id: widget.initial?.id ??
                    DateTime.now().microsecondsSinceEpoch.toString(),
                name: name,
                detail: _detail.text.trim(),
                note: _note.text.trim(),
                photo: _photoData,
              ),
            );
          },
          child: Text(widget.initial == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.number,
    required this.exercise,
    required this.done,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final int number;
  final Exercise exercise;
  final bool done;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final photo = exercise.photo;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(color: done ? kGreenSoft : Colors.white),
      child: Row(children: [
        photo != null
            ? GestureDetector(
                onTap: () => _viewPhoto(context, photo, caption: exercise.name),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _photo(photo, width: 56, height: 56),
                ),
              )
            : CircleAvatar(
                radius: 20,
                backgroundColor: kPrimarySoft,
                child: Text('$number',
                    style: const TextStyle(
                        color: kPrimary, fontWeight: FontWeight.w800))),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(exercise.name,
                style: TextStyle(
                    color: kInk,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    decoration: done ? TextDecoration.lineThrough : null)),
            if (exercise.detail.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(exercise.detail,
                  style: const TextStyle(
                      color: kPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
            if (exercise.note.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(exercise.note,
                  style: const TextStyle(color: kMuted, fontSize: 11.5)),
            ],
          ]),
        ),
        PopupMenuButton<String>(
          tooltip: 'Edit or delete',
          icon: const Icon(Icons.more_horiz_rounded, color: kMuted),
          onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        IconButton(
            onPressed: onToggle,
            icon: Icon(
                done ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: done ? kGreen : const Color(0xFFB5BAC8))),
      ]),
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
          color: kGreenSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD1EEDB))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.auto_awesome_rounded, color: kGreen),
        const SizedBox(width: 11),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: Color(0xFF2D714A),
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(message,
              style: const TextStyle(
                  color: Color(0xFF548269), fontSize: 12, height: 1.4)),
        ])),
      ]),
    );
  }
}

// ───────────────────────── Challenges ─────────────────────────
class _DayResult {
  _DayResult(this.status, this.note, this.photo);

  final String status; // done | rest | none
  final String note;
  final String? photo;
}

class _ChallengeDaySheet extends StatefulWidget {
  const _ChallengeDaySheet({required this.challenge, required this.index});

  final ChallengeItem challenge;
  final int index;

  @override
  State<_ChallengeDaySheet> createState() => _ChallengeDaySheetState();
}

class _ChallengeDaySheetState extends State<_ChallengeDaySheet> {
  late String _status;
  late final TextEditingController _note;
  String? _photoData;

  @override
  void initState() {
    super.initState();
    final c = widget.challenge;
    final i = widget.index;
    _status = c.days[i]
        ? 'done'
        : c.restDays.contains(i)
            ? 'rest'
            : 'none';
    _note = TextEditingController(text: c.notes[i] ?? '');
    _photoData = c.photos[i];
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.challenge;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          22, 14, 22, MediaQuery.of(context).viewInsets.bottom + 22),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Day ${widget.index + 1} · ${_fmtDate(c.dateOf(widget.index))}',
                style: const TextStyle(
                    color: kInk, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(c.title, style: const TextStyle(color: kMuted)),
            if (c.doneAt[widget.index] != null) ...[
              const SizedBox(height: 4),
              Text(
                  'Completed ${_fmtDate(c.doneAt[widget.index]!)} at ${_fmtTime(c.doneAt[widget.index]!)}',
                  style: const TextStyle(
                      color: kGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                      value: 'done',
                      icon: Icon(Icons.check_rounded),
                      label: Text('Done')),
                  ButtonSegment(
                      value: 'rest',
                      icon: Icon(Icons.bedtime_outlined),
                      label: Text('Rest')),
                  ButtonSegment(
                      value: 'none',
                      icon: Icon(Icons.close_rounded),
                      label: Text('Not done')),
                ],
                selected: {_status},
                onSelectionChanged: (value) =>
                    setState(() => _status = value.first),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Note',
                  hintText: 'How did it feel? Weight, reps, pages…'),
            ),
            const SizedBox(height: 14),
            _PhotoPicker(
              photo: _photoData,
              height: 200,
              label: 'Add a progress photo',
              onChanged: (value) => setState(() => _photoData = value),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: c.color),
                onPressed: () => Navigator.pop(
                  context,
                  _DayResult(_status, _note.text.trim(), _photoData),
                ),
                child: const Text('Save day'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengesPage extends StatelessWidget {
  const _ChallengesPage({
    required this.challenges,
    required this.selectedIndex,
    required this.onSelect,
    required this.onOpenDay,
    required this.onQuickDay,
    required this.onAdd,
    required this.onDelete,
    required this.onResetProgress,
  });

  final List<ChallengeItem> challenges;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onOpenDay;
  final ValueChanged<int> onQuickDay;
  final VoidCallback onAdd;
  final ValueChanged<int> onDelete;
  final VoidCallback onResetProgress;

  @override
  Widget build(BuildContext context) {
    final selected = challenges[selectedIndex];
    final endDate = selected.dateOf(selected.totalDays - 1);
    return _PageScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
        children: [
          const _PageHeader(
            eyebrow: 'Consistency builder',
            title: 'Challenges',
            subtitle: 'Small actions, repeated daily',
          ),
          const SizedBox(height: 18),
          Text(
            'Tap a day to mark it done or rest, add a note, or attach a photo. Long-press a day to tick it quickly.',
            style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 6),
          Text(
            'Calendar: ${_fmtDate(selected.startDate)} – ${_fmtDate(endDate)}',
            style: const TextStyle(
                color: kPrimary, fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _ChallengeCard(
            challenge: selected,
            onOpen: onOpenDay,
            onQuick: onQuickDay,
            showDays: false,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onResetProgress,
              icon: const Icon(Icons.restart_alt_rounded, size: 17),
              label: const Text('Reset progress'),
            ),
          ),
          const SizedBox(height: 8),
          _SectionTitle(title: 'Calendar · ${selected.title}'),
          const SizedBox(height: 10),
          _CalendarGrid(
            challenge: selected,
            onOpen: onOpenDay,
            onQuick: onQuickDay,
          ),
          const SizedBox(height: 24),
          _SectionTitle(
              title: 'Your challenges', action: 'New', onAction: onAdd),
          const SizedBox(height: 10),
          ...challenges.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SimpleChallenge(
                    challenge: entry.value,
                    selected: entry.key == selectedIndex,
                    onTap: () => onSelect(entry.key),
                    onDelete: () => onDelete(entry.key),
                  ),
                ),
              ),
          const SizedBox(height: 22),
          const _SectionTitle(title: 'Evolution'),
          const SizedBox(height: 10),
          _EvolutionCard(challenge: selected),
        ],
      ),
    );
  }
}

class _EvolutionCard extends StatelessWidget {
  const _EvolutionCard({required this.challenge});

  final ChallengeItem challenge;

  @override
  Widget build(BuildContext context) {
    final days = challenge.photos.keys.toList()..sort();
    if (days.isEmpty) {
      return const _EmptyCard(
        icon: Icons.photo_camera_back_outlined,
        text:
            'No photos yet. Open a day and add a photo to see your body evolution here.',
      );
    }
    final first = days.first;
    final last = days.last;
    Widget tile(int day, String label) => Expanded(
          child: GestureDetector(
            onTap: () => _viewPhoto(context, challenge.photos[day]!,
                caption: 'Day ${day + 1} · ${_fmtDate(challenge.dateOf(day))}'),
            child: Column(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: _photo(challenge.photos[day]!),
                ),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                      color: kInk, fontWeight: FontWeight.w800, fontSize: 12)),
              Text('Day ${day + 1} · ${_fmtDate(challenge.dateOf(day))}',
                  style: const TextStyle(color: kMuted, fontSize: 11)),
            ]),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (days.length > 1) ...[
          Text('${last - first} days between your first and latest photo',
              style: const TextStyle(color: kMuted, fontSize: 12)),
          const SizedBox(height: 12),
          Row(children: [
            tile(first, 'Before'),
            const SizedBox(width: 12),
            tile(last, 'Latest'),
          ]),
          const SizedBox(height: 16),
        ],
        Text('${days.length} photo${days.length == 1 ? '' : 's'}',
            style: const TextStyle(
                color: kInk, fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(height: 10),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final day = days[i];
              return GestureDetector(
                onTap: () => _viewPhoto(context, challenge.photos[day]!,
                    caption:
                        'Day ${day + 1} · ${_fmtDate(challenge.dateOf(day))}'),
                child: Column(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        _photo(challenge.photos[day]!, width: 72, height: 86),
                  ),
                  const SizedBox(height: 4),
                  Text('Day ${day + 1}',
                      style: const TextStyle(color: kMuted, fontSize: 10.5)),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard(
      {required this.challenge,
      required this.onOpen,
      required this.onQuick,
      this.showDays = true});

  final ChallengeItem challenge;
  final ValueChanged<int> onOpen;
  final ValueChanged<int> onQuick;
  final bool showDays;

  @override
  Widget build(BuildContext context) {
    final completed = challenge.doneCount;
    final total = challenge.totalDays;
    final progress = total == 0 ? 0.0 : completed / total;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(challenge.title,
                  style: const TextStyle(
                      color: kInk, fontSize: 15, fontWeight: FontWeight.w800))),
          Text('$completed/$total days',
              style: TextStyle(
                  color: challenge.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 5),
        Text(challenge.subtitle,
            style: const TextStyle(color: kFaint, fontSize: 12)),
        const SizedBox(height: 13),
        LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            color: challenge.color,
            backgroundColor: challenge.color.withValues(alpha: 0.14)),
        if (showDays) ...[
          const SizedBox(height: 15),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: List.generate(
              total,
              (index) => _ChallengeDayCell(
                index: index,
                date: challenge.dateOf(index),
                completed: challenge.days[index],
                rest: challenge.restDays.contains(index),
                hasPhoto: challenge.photos.containsKey(index),
                color: challenge.color,
                onTap: () => onOpen(index),
                onLongPress: () => onQuick(index),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

class _SimpleChallenge extends StatelessWidget {
  const _SimpleChallenge(
      {required this.challenge,
      required this.selected,
      required this.onTap,
      required this.onDelete});

  final ChallengeItem challenge;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final completed = challenge.doneCount;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: _cardDecoration(),
        foregroundDecoration: selected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: challenge.color, width: 1.6))
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(challenge.title,
                      style: const TextStyle(
                          color: kInk,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                ),
                Text('$completed/${challenge.totalDays}',
                    style: TextStyle(
                        color: challenge.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
                IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 19),
                    color: kFaint,
                    tooltip: 'Remove challenge'),
              ],
            ),
            const SizedBox(height: 4),
            Text(challenge.subtitle,
                style: const TextStyle(color: kFaint, fontSize: 11)),
            const SizedBox(height: 11),
            LinearProgressIndicator(
                value: challenge.totalDays == 0
                    ? 0
                    : completed / challenge.totalDays,
                color: challenge.color,
                backgroundColor: challenge.color.withValues(alpha: 0.14),
                minHeight: 6,
                borderRadius: BorderRadius.circular(8)),
          ],
        ),
      ),
    );
  }
}

class _ChallengeDayCell extends StatelessWidget {
  const _ChallengeDayCell({
    required this.index,
    required this.date,
    required this.completed,
    required this.rest,
    required this.hasPhoto,
    required this.color,
    required this.onTap,
    required this.onLongPress,
  });

  final int index;
  final DateTime date;
  final bool completed;
  final bool rest;
  final bool hasPhoto;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final status = completed
        ? 'Done'
        : rest
            ? 'Rest'
            : 'Not done';
    final icon = completed
        ? Icons.check_rounded
        : rest
            ? Icons.bedtime_outlined
            : Icons.close_rounded;
    final iconColor = completed
        ? color
        : rest
            ? kPrimary
            : kFaint;
    return Tooltip(
      message: 'Day ${index + 1} · ${_fmtDate(date)} · $status',
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 42,
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            decoration: BoxDecoration(
              color: completed
                  ? kGreenSoft
                  : rest
                      ? kPrimarySoft
                      : const Color(0xFFF4F5F8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: completed
                      ? const Color(0xFFBDE7CE)
                      : rest
                          ? const Color(0xFFDCE0FF)
                          : kLine),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${date.day}/${date.month}',
                    maxLines: 1,
                    style: const TextStyle(
                        fontSize: 8, fontWeight: FontWeight.w800, color: kInk)),
                Icon(icon, size: 16, color: iconColor),
              ],
            ),
          ),
          if (hasPhoto)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(
                    color: kPrimary, shape: BoxShape.circle),
                child: const Icon(Icons.photo_camera_rounded,
                    size: 9, color: Colors.white),
              ),
            ),
        ]),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid(
      {required this.challenge, required this.onOpen, required this.onQuick});

  final ChallengeItem challenge;
  final ValueChanged<int> onOpen;
  final ValueChanged<int> onQuick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(children: [
        const Row(
          children: [
            Icon(Icons.check_rounded, size: 16, color: kGreen),
            SizedBox(width: 4),
            Text('Done'),
            SizedBox(width: 14),
            Icon(Icons.bedtime_outlined, size: 16, color: kPrimary),
            SizedBox(width: 4),
            Text('Rest'),
            SizedBox(width: 14),
            Icon(Icons.close_rounded, size: 16, color: kFaint),
            SizedBox(width: 4),
            Text('Not done'),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: challenge.totalDays,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8),
          itemBuilder: (context, index) => _ChallengeDayCell(
            index: index,
            date: challenge.dateOf(index),
            completed: challenge.days[index],
            rest: challenge.restDays.contains(index),
            hasPhoto: challenge.photos.containsKey(index),
            color: challenge.color,
            onTap: () => onOpen(index),
            onLongPress: () => onQuick(index),
          ),
        ),
      ]),
    );
  }
}

class _ChallengeDialog extends StatefulWidget {
  const _ChallengeDialog({required this.color});

  final Color color;

  @override
  State<_ChallengeDialog> createState() => _ChallengeDialogState();
}

class _ChallengeDialogState extends State<_ChallengeDialog> {
  final _title = TextEditingController();
  final _target = TextEditingController(text: 'Complete it daily');
  final _days = TextEditingController(text: '30');
  DateTime _startDate = _dateOnly(DateTime.now());

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    _days.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('New challenge'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: _title,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Challenge name')),
            const SizedBox(height: 10),
            TextField(
                controller: _target,
                decoration: const InputDecoration(labelText: 'Daily target')),
            const SizedBox(height: 10),
            TextField(
              controller: _days,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'How many days?',
                hintText: 'Enter any number from 1 to 365',
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _startDate = _dateOnly(picked));
                  }
                },
                icon: const Icon(Icons.calendar_today_rounded, size: 17),
                label: Text('Starts ${_fmtDate(_startDate)}'),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: widget.color),
            onPressed: () {
              final totalDays = int.tryParse(_days.text.trim());
              if (_title.text.trim().isEmpty ||
                  totalDays == null ||
                  totalDays < 1 ||
                  totalDays > 365) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Enter a name and 1 to 365 days.')));
                return;
              }
              Navigator.pop(
                context,
                ChallengeItem(
                  _title.text.trim(),
                  _target.text.trim().isEmpty
                      ? 'Complete it daily'
                      : _target.text.trim(),
                  widget.color,
                  totalDays: totalDays,
                  startDate: _startDate,
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      );
}

// ───────────────────────── Journal & history ─────────────────────────
class _ActivityStyle {
  const _ActivityStyle(this.icon, this.color, this.label);

  final IconData icon;
  final Color color;
  final String label;
}

_ActivityStyle _styleFor(String type) {
  switch (type) {
    case 'workout':
      return const _ActivityStyle(
          Icons.fitness_center_rounded, kPrimary, 'Workout');
    case 'grocery':
      return const _ActivityStyle(
          Icons.shopping_basket_rounded, kOrange, 'Groceries');
    case 'challenge':
      return const _ActivityStyle(
          Icons.emoji_events_rounded, kPurple, 'Challenge');
    default:
      return const _ActivityStyle(Icons.check_circle_rounded, kGreen, 'Task');
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.log});

  final ActivityLog log;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(log.type);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(style.icon, size: 17, color: style.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(log.title,
                style: const TextStyle(
                    color: kInk, fontSize: 13.5, fontWeight: FontWeight.w700)),
            if (log.detail.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(log.detail,
                  style: const TextStyle(
                      color: kMuted, fontSize: 11.5, height: 1.3)),
            ],
          ]),
        ),
        const SizedBox(width: 8),
        Text(_fmtTime(log.date),
            style: const TextStyle(color: kFaint, fontSize: 11)),
      ]),
    );
  }
}

List<Widget> _groupedLogs(List<ActivityLog> logs) {
  final groups = <DateTime, List<ActivityLog>>{};
  for (final log in logs) {
    groups.putIfAbsent(_dateOnly(log.date), () => []).add(log);
  }
  final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final day in days)
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          decoration: _cardDecoration(),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(_relativeDay(day),
                    style: const TextStyle(
                        color: kInk,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
              ),
              Text('${groups[day]!.length}',
                  style: const TextStyle(
                      color: kPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 4),
            ...groups[day]!.map((log) => _ActivityTile(log: log)),
          ]),
        ),
      ),
  ];
}

class _HistoryPage extends StatelessWidget {
  const _HistoryPage(
      {required this.title, required this.logs, required this.emptyText});

  final String title;
  final List<ActivityLog> logs;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800, color: kInk)),
        backgroundColor: kBg,
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
            children: logs.isEmpty
                ? [_EmptyCard(icon: Icons.history_rounded, text: emptyText)]
                : [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text('${logs.length} in total',
                          style: const TextStyle(
                              color: kMuted, fontWeight: FontWeight.w600)),
                    ),
                    ..._groupedLogs(logs),
                  ],
          ),
        ),
      ),
    );
  }
}

class _JournalPage extends StatefulWidget {
  const _JournalPage(
      {required this.journal, required this.activity, required this.onSave});

  final List<JournalEntry> journal;
  final List<ActivityLog> activity;
  final Future<void> Function(JournalEntry) onSave;

  @override
  State<_JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<_JournalPage> {
  static const _moods = ['😄', '🙂', '😐', '😕', '😞'];
  late final TextEditingController _text;
  String _mood = '🙂';
  String? _photoData;
  String _filter = 'all';

  JournalEntry? _entryFor(DateTime day) {
    for (final entry in widget.journal) {
      if (_sameDay(entry.date, day)) return entry;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final entry = _entryFor(DateTime.now());
    _text = TextEditingController(text: entry?.text ?? '');
    _mood = entry?.mood ?? '🙂';
    _photoData = entry?.photo;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.onSave(
        JournalEntry(DateTime.now(), _mood, _text.text.trim(), _photoData));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Today’s entry saved.')));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.activity
        .where((log) => _filter == 'all' || log.type == _filter)
        .toList();
    final days = <DateTime>{
      if (_filter == 'all') ...widget.journal.map((e) => _dateOnly(e.date)),
      ...filtered.map((e) => _dateOnly(e.date)),
    }.toList()
      ..sort((a, b) => b.compareTo(a));
    const filters = [
      ('all', 'All'),
      ('task', 'Tasks'),
      ('workout', 'Workouts'),
      ('grocery', 'Groceries'),
      ('challenge', 'Challenges'),
    ];
    final todayLogs = widget.activity
        .where((log) => _sameDay(log.date, DateTime.now()))
        .length;
    return _PageScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
        children: [
          _PageHeader(
            eyebrow: _dayLabel(DateTime.now()),
            title: 'Journal',
            subtitle:
                '$todayLogs done today · ${widget.journal.length} entries kept',
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('How was today?',
                  style: TextStyle(
                      color: kInk, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _moods
                    .map((mood) => GestureDetector(
                          onTap: () => setState(() => _mood = mood),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _mood == mood ? kPrimarySoft : kBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: _mood == mood
                                      ? kPrimary
                                      : Colors.transparent,
                                  width: 1.5),
                            ),
                            child: Text(mood,
                                style: const TextStyle(fontSize: 24)),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _text,
                minLines: 3,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    hintText: 'What went well? What did you learn?'),
              ),
              const SizedBox(height: 12),
              _PhotoPicker(
                photo: _photoData,
                height: 170,
                label: 'Add a photo of your day',
                onChanged: (value) => setState(() => _photoData = value),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.bookmark_added_rounded),
                  label: const Text('Save today’s entry'),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Your days'),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => ChoiceChip(
                label: Text(filters[i].$2),
                selected: _filter == filters[i].$1,
                onSelected: (_) => setState(() => _filter = filters[i].$1),
                selectedColor: kPrimarySoft,
                showCheckmark: false,
                side: BorderSide(
                    color: _filter == filters[i].$1 ? kPrimary : kLine),
                labelStyle: TextStyle(
                    color: _filter == filters[i].$1 ? kPrimary : kMuted,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (days.isEmpty)
            const _EmptyCard(
              icon: Icons.auto_stories_outlined,
              text:
                  'Nothing here yet. Finish a task, workout or challenge day and it appears in your journal.',
            )
          else
            ...days.take(60).map((day) => _DayCard(
                  day: day,
                  entry: _filter == 'all' ? _entryFor(day) : null,
                  logs:
                      filtered.where((log) => _sameDay(log.date, day)).toList(),
                )),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day, required this.entry, required this.logs});

  final DateTime day;
  final JournalEntry? entry;
  final List<ActivityLog> logs;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final entryPhoto = e?.photo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        decoration: _cardDecoration(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(_relativeDay(day),
                  style: const TextStyle(
                      color: kInk, fontSize: 14, fontWeight: FontWeight.w800)),
            ),
            if (e != null) ...[
              Text(_fmtTime(e.date),
                  style: const TextStyle(color: kFaint, fontSize: 11)),
              const SizedBox(width: 8),
              Text(e.mood, style: const TextStyle(fontSize: 20)),
            ],
          ]),
          if (e != null && e.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(e.text,
                style: const TextStyle(
                    color: Color(0xFF454C63), fontSize: 13, height: 1.45)),
          ],
          if (entryPhoto != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () =>
                  _viewPhoto(context, entryPhoto, caption: _dayLabel(day)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _photo(entryPhoto, width: double.infinity, height: 150),
              ),
            ),
          ],
          if (logs.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: kLine),
            const SizedBox(height: 4),
            ...logs.map((log) => _ActivityTile(log: log)),
          ],
        ]),
      ),
    );
  }
}

// ───────────────────────── Profile ─────────────────────────
class _ProfilePage extends StatelessWidget {
  const _ProfilePage({
    required this.profile,
    required this.groceries,
    required this.challenges,
    required this.onEdit,
    required this.onSignOut,
    required this.onBackup,
  });

  final ProfileData profile;
  final List<GroceryItem> groceries;
  final List<ChallengeItem> challenges;
  final VoidCallback onEdit;
  final VoidCallback onSignOut;
  final VoidCallback onBackup;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
        children: [
          _PageHeader(
            eyebrow: 'Personal space',
            title: profile.name,
            subtitle: 'Your information, goals and progress',
            action: IconButton.filled(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit profile',
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            width: double.infinity,
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    profile.email.isNotEmpty
                        ? profile.email
                        : (Supabase.instance.client.auth.currentUser?.email ??
                            'No email added'),
                    style: const TextStyle(color: kMuted)),
                const SizedBox(height: 8),
                Text('Goal: ${profile.goal}',
                    style: const TextStyle(
                        color: kInk, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Target mass: ${profile.targetMass.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                        color: kPrimary, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _RecapCard(
            groceries: groceries,
            challenges: challenges,
            currencySymbol: profile.currency == 'MUR'
                ? 'Rs'
                : profile.currency == 'EUR'
                    ? '€'
                    : '\$',
          ),
          const SizedBox(height: 24),
          _MeasurementsCard(targetMass: profile.targetMass),
          const SizedBox(height: 28),
          Center(
            child: ValueListenableBuilder<DateTime?>(
              valueListenable: lastCloudSave,
              builder: (context, time, _) => Text(
                  time == null
                      ? 'Account backup: ready'
                      : 'Account backup: saved at ${_fmtTime(time)}',
                  style: const TextStyle(color: kMuted, fontSize: 12)),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onBackup,
            icon: const Icon(Icons.cloud_upload_outlined, size: 18),
            label: const Text('Back up now'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _RecapCard extends StatelessWidget {
  const _RecapCard(
      {required this.groceries,
      required this.challenges,
      required this.currencySymbol});

  final List<GroceryItem> groceries;
  final List<ChallengeItem> challenges;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    double spentSince(Duration duration) => groceries
        .where((item) =>
            item.bought && now.difference(item.purchasedAt) <= duration)
        .fold(0, (total, item) => total + item.price);
    final weekly = spentSince(const Duration(days: 7));
    final monthly = spentSince(const Duration(days: 30));
    final completed = challenges.fold<int>(
        0, (total, challenge) => total + challenge.doneCount);
    final rest = challenges.fold<int>(
        0, (total, challenge) => total + challenge.restDays.length);
    return Container(
      padding: const EdgeInsets.all(17),
      width: double.infinity,
      decoration: _cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Weekly & monthly recap',
            style: TextStyle(
                color: kInk, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _RecapMetric(
                  label: 'Groceries · 7 days',
                  value: '$currencySymbol ${weekly.toStringAsFixed(2)}')),
          Expanded(
              child: _RecapMetric(
                  label: 'Groceries · 30 days',
                  value: '$currencySymbol ${monthly.toStringAsFixed(2)}')),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _RecapMetric(
                  label: 'Challenge days', value: '$completed done')),
          Expanded(
              child: _RecapMetric(label: 'Rest days', value: '$rest logged')),
        ]),
      ]),
    );
  }
}

class _RecapMetric extends StatelessWidget {
  const _RecapMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: kMuted, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: kInk, fontSize: 15, fontWeight: FontWeight.w800)),
        ],
      );
}

class _ProgressPainter extends CustomPainter {
  _ProgressPainter(
      {required this.entries, required this.color, this.unit = 'kg'});

  final List<MassEntry> entries;
  final Color color;
  final String unit;

  @override
  void paint(Canvas canvas, Size size) {
    final values = entries.map((entry) => entry.mass).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).abs() < 0.1 ? 1.0 : maxValue - minValue;
    final chart = Rect.fromLTWH(8, 8, size.width - 16, size.height - 28);
    final line = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final dot = Paint()..color = color;
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? chart.center.dx
          : chart.left + chart.width * index / (values.length - 1);
      final y =
          chart.bottom - (values[index] - minValue) / range * chart.height;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 5, dot);
    }
    canvas.drawPath(path, line);
    final label = TextPainter(
      text: TextSpan(
          text:
              '${minValue.toStringAsFixed(1)} - ${maxValue.toStringAsFixed(1)} $unit',
          style: const TextStyle(color: kMuted, fontSize: 11)),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(8, size.height - 16));
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter oldDelegate) =>
      oldDelegate.entries != entries || oldDelegate.color != color;
}

class _ProfileEditorDialog extends StatefulWidget {
  const _ProfileEditorDialog({required this.profile});

  final ProfileData profile;

  @override
  State<_ProfileEditorDialog> createState() => _ProfileEditorDialogState();
}

class _ProfileEditorDialogState extends State<_ProfileEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _goal;
  late final TextEditingController _target;
  String _currency = 'MUR';

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.name);
    _email = TextEditingController(text: widget.profile.email);
    _goal = TextEditingController(text: widget.profile.goal);
    _target = TextEditingController(text: widget.profile.targetMass.toString());
    _currency = widget.profile.currency;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _goal.dispose();
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit profile'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 10),
          TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 10),
          TextField(
              controller: _goal,
              decoration: const InputDecoration(labelText: 'Main goal')),
          const SizedBox(height: 10),
          TextField(
              controller: _target,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Target mass (kg)')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _currency,
            decoration: const InputDecoration(labelText: 'Currency'),
            items: const [
              DropdownMenuItem(
                  value: 'MUR', child: Text('MUR · Mauritian rupee')),
              DropdownMenuItem(value: 'EUR', child: Text('EUR · Euro')),
              DropdownMenuItem(value: 'USD', child: Text('USD · US dollar')),
            ],
            onChanged: (value) => setState(() => _currency = value ?? 'MUR'),
          ),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            ProfileData(
              name: _name.text.trim().isEmpty ? 'User' : _name.text.trim(),
              email: _email.text.trim(),
              goal: _goal.text.trim().isEmpty
                  ? 'Build healthy habits'
                  : _goal.text.trim(),
              targetMass: double.tryParse(_target.text) ?? 70,
              currency: _currency,
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ───────────────────────── Planner ─────────────────────────
class _PlannerPage extends StatelessWidget {
  const _PlannerPage({
    required this.deadlines,
    required this.timetable,
    required this.onAddDeadline,
    required this.onAddClass,
    required this.onDeleteDeadline,
    required this.onDeleteClass,
  });

  final List<PlannerDeadline> deadlines;
  final List<TimetableEntry> timetable;
  final VoidCallback onAddDeadline;
  final VoidCallback onAddClass;
  final ValueChanged<PlannerDeadline> onDeleteDeadline;
  final ValueChanged<TimetableEntry> onDeleteClass;

  @override
  Widget build(BuildContext context) {
    final sortedDeadlines = [...deadlines]
      ..sort((a, b) => a.date.compareTo(b.date));
    final today = DateTime.now();
    return _PageScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
        children: [
          _PageHeader(
            eyebrow: 'Student planner',
            title: 'Planner',
            subtitle: 'Deadlines, timetable and study planning',
            action: IconButton.filled(
              onPressed: onAddDeadline,
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add deadline',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle(title: 'Upcoming deadlines'),
              TextButton.icon(
                onPressed: onAddDeadline,
                icon: const Icon(Icons.event_rounded, size: 17),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (sortedDeadlines.isEmpty)
            const _EmptyCard(
                icon: Icons.event_available_outlined,
                text: 'No deadlines added yet.')
          else
            ...sortedDeadlines.map((deadline) {
              final days = deadline.date
                  .difference(DateTime(today.year, today.month, today.day))
                  .inDays;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PlannerDeadlineRow(
                  deadline: deadline,
                  daysUntil: days,
                  onDelete: () => onDeleteDeadline(deadline),
                ),
              );
            }),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle(title: 'Weekly timetable'),
              TextButton.icon(
                onPressed: onAddClass,
                icon: const Icon(Icons.add, size: 17),
                label: const Text('Add class'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (timetable.isEmpty)
            const _EmptyCard(
                icon: Icons.schedule_rounded,
                text: 'Add your classes and study blocks.')
          else
            ...List.generate(7, (day) {
              final entries = timetable
                  .where((entry) => entry.day == day)
                  .toList()
                ..sort((a, b) =>
                    a.start.hour * 60 +
                    a.start.minute -
                    (b.start.hour * 60 + b.start.minute));
              if (entries.isEmpty) return const SizedBox.shrink();
              return _PlannerDay(
                day: day,
                entries: entries,
                onDelete: onDeleteClass,
              );
            }),
        ],
      ),
    );
  }
}

class _PlannerDeadlineRow extends StatelessWidget {
  const _PlannerDeadlineRow(
      {required this.deadline,
      required this.daysUntil,
      required this.onDelete});

  final PlannerDeadline deadline;
  final int daysUntil;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final urgent = daysUntil <= 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: _cardDecoration(),
      child: Row(children: [
        Icon(Icons.assignment_late_outlined, color: urgent ? kRed : kPrimary),
        const SizedBox(width: 11),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(deadline.title,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(
                '${_fmtDate(deadline.date)} · ${daysUntil < 0 ? 'Overdue' : daysUntil == 0 ? 'Today' : '$daysUntil days left'}',
                style: TextStyle(
                    color: urgent ? kRed : kMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
        IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Remove deadline'),
      ]),
    );
  }
}

class _PlannerDay extends StatelessWidget {
  const _PlannerDay(
      {required this.day, required this.entries, required this.onDelete});

  final int day;
  final List<TimetableEntry> entries;
  final ValueChanged<TimetableEntry> onDelete;
  static const names = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(names[day],
                style: const TextStyle(
                    color: kPrimary, fontWeight: FontWeight.w800)),
            ...entries.map((entry) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_rounded, size: 19),
                  title: Text(entry.title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      '${entry.start.format(context)} - ${entry.end.format(context)}'),
                  trailing: IconButton(
                      onPressed: () => onDelete(entry),
                      icon: const Icon(Icons.close_rounded, size: 18)),
                )),
          ]),
        ),
      );
}

class _DeadlineDialog extends StatefulWidget {
  const _DeadlineDialog();

  @override
  State<_DeadlineDialog> createState() => _DeadlineDialogState();
}

class _DeadlineDialogState extends State<_DeadlineDialog> {
  final title = TextEditingController();
  DateTime date = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Add deadline'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: title,
              autofocus: true,
              decoration:
                  const InputDecoration(labelText: 'Assignment or exam')),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (selected != null) setState(() => date = selected);
            },
            icon: const Icon(Icons.calendar_today_rounded),
            label: Text(_fmtDate(date)),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                if (title.text.trim().isNotEmpty) {
                  Navigator.pop(
                      context, PlannerDeadline(title.text.trim(), date));
                }
              },
              child: const Text('Add')),
        ],
      );
}

class _TimetableDialog extends StatefulWidget {
  const _TimetableDialog();

  @override
  State<_TimetableDialog> createState() => _TimetableDialogState();
}

class _TimetableDialogState extends State<_TimetableDialog> {
  final title = TextEditingController();
  int day = 0;
  TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay end = const TimeOfDay(hour: 10, minute: 0);

  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  Future<void> pickTime(bool isStart) async {
    final selected = await showTimePicker(
        context: context, initialTime: isStart ? start : end);
    if (selected == null) return;
    setState(() {
      if (isStart) {
        start = selected;
      } else {
        end = selected;
      }
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Add timetable entry'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: title,
              autofocus: true,
              decoration:
                  const InputDecoration(labelText: 'Class or study block')),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: day,
            decoration: const InputDecoration(labelText: 'Day'),
            items: List.generate(
                7,
                (index) => DropdownMenuItem(
                    value: index, child: Text(_PlannerDay.names[index]))),
            onChanged: (value) => setState(() => day = value ?? 0),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: OutlinedButton(
                    onPressed: () => pickTime(true),
                    child: Text(start.format(context)))),
            const SizedBox(width: 8),
            Expanded(
                child: OutlinedButton(
                    onPressed: () => pickTime(false),
                    child: Text(end.format(context)))),
          ]),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                if (title.text.trim().isNotEmpty) {
                  Navigator.pop(context,
                      TimetableEntry(title.text.trim(), day, start, end));
                }
              },
              child: const Text('Add')),
        ],
      );
}

// ───────────────────────── Shared widgets ─────────────────────────
class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kOrangeSoft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: kOrange, size: 18),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF754B2F),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageScaffold extends StatelessWidget {
  const _PageScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Material(color: kBg, child: child);
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow,
                  style: const TextStyle(
                      color: kMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              Text(title,
                  style: const TextStyle(
                      color: kInk,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.9)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(color: kMuted, fontSize: 14)),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    if (action == null) {
      return Text(title,
          style: const TextStyle(
              color: kInk,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: kInk,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3)),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text(action!,
                style: const TextStyle(
                    color: kPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800)),
          ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(
      {required this.icon,
      required this.text,
      this.actionLabel,
      this.onAction});

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: _cardDecoration(),
      child: Column(children: [
        Icon(icon, size: 30, color: kFaint),
        const SizedBox(height: 10),
        Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: kMuted, fontWeight: FontWeight.w600, height: 1.4)),
        if (actionLabel != null) ...[
          const SizedBox(height: 12),
          FilledButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ]),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photo,
    required this.onChanged,
    required this.label,
    this.height = 150,
  });

  final String? photo;
  final ValueChanged<String?> onChanged;
  final String label;
  final double height;

  Future<void> _pick(BuildContext context) async {
    final picked = await pickPhoto(context);
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final data = photo;
    if (data == null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _pick(context),
          icon: const Icon(Icons.add_a_photo_outlined, size: 19),
          label: Text(label),
        ),
      );
    }
    return Stack(children: [
      GestureDetector(
        onTap: () => _viewPhoto(context, data),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _photo(data, width: double.infinity, height: height),
        ),
      ),
      Positioned(
        top: 8,
        right: 8,
        child: Row(children: [
          _PhotoAction(
              icon: Icons.refresh_rounded, onTap: () => _pick(context)),
          const SizedBox(width: 6),
          _PhotoAction(
              icon: Icons.delete_outline_rounded, onTap: () => onChanged(null)),
        ]),
      ),
    ]);
  }
}

class _PhotoAction extends StatelessWidget {
  const _PhotoAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle),
          child: Icon(icon, size: 17, color: Colors.white),
        ),
      );
}

class _MoreMenuItem extends StatelessWidget {
  const _MoreMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: ((MediaQuery.sizeOf(context).width - 56) / 2)
            .clamp(120.0, 340.0)
            .toDouble(),
        child: ListTile(
          onTap: onTap,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tileColor: kBg,
          leading: Icon(icon, color: color),
          title:
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
}

class _FocusCard extends StatelessWidget {
  const _FocusCard(
      {required this.progress, required this.completed, required this.total});

  final double progress;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = _heroColors();
    final message = total == 0
        ? 'Add your first task to start the day.'
        : progress >= 1
            ? 'All done. What a day!'
            : progress > 0.5
                ? 'More than halfway there. Keep going!'
                : 'You are building a strong day.';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: colors.first.withValues(alpha: 0.30),
              blurRadius: 26,
              offset: const Offset(0, 14))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(children: [
          Positioned(
            right: -34,
            top: -34,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10)),
            ),
          ),
          Positioned(
            left: -26,
            bottom: -46,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Today’s focus',
                          style: TextStyle(
                              color: Color(0xFFFFEEF2),
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      _CountUp(
                        value: completed.toDouble(),
                        format: (v) => '${v.round()} of $total tasks done',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4),
                      ),
                      const SizedBox(height: 6),
                      Text(message,
                          style: const TextStyle(
                              color: Color(0xFFFFEEF2), fontSize: 13)),
                    ]),
              ),
              const SizedBox(width: 14),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 1100),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(alignment: Alignment.center, children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: v,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        color: Colors.white,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                    Text('${(v * 100).round()}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(
      {required this.icon,
      required this.color,
      required this.count,
      required this.suffix,
      required this.label});

  final IconData icon;
  final Color color;
  final double count;
  final String suffix;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(height: 10),
        _CountUp(
          value: count,
          format: (v) => '${v.round()}$suffix',
          style: const TextStyle(
              color: kInk, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: kMuted, fontSize: 11, height: 1.2)),
      ]),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.onToggle,
    this.onDelete,
  });

  final TaskItem task;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final priorityColor = task.priority == 'High'
        ? kRed
        : task.priority == 'Low'
            ? kGreen
            : const Color(0xFFE1A448);
    final content = Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(children: [
        GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.done ? kPrimary : Colors.transparent,
                border: Border.all(
                    color: task.done ? kPrimary : const Color(0xFFB5BAC8),
                    width: 2)),
            child: task.done
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(task.title,
                style: TextStyle(
                    color: task.done ? kFaint : kInk,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    decoration: task.done ? TextDecoration.lineThrough : null)),
            const SizedBox(height: 4),
            Row(children: [
              Text(task.area,
                  style: const TextStyle(
                      color: kFaint,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 7),
              Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                      color: priorityColor, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(task.priority,
                  style: TextStyle(
                      color: priorityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
              if (task.done && task.completedAt != null) ...[
                const SizedBox(width: 7),
                Text('· done at ${_fmtTime(task.completedAt!)}',
                    style: const TextStyle(
                        color: kGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ],
            ]),
          ]),
        ),
      ]),
    );
    if (onDelete == null) return content;
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete!(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: kRed,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: content,
    );
  }
}

class _AssistantCard extends StatelessWidget {
  const _AssistantCard(
      {required this.title,
      required this.message,
      required this.icon,
      required this.action,
      this.onAction});

  final String title;
  final String message;
  final IconData icon;
  final String action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFEEF0FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDCE0FF))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: kPrimary, size: 20)),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    color: Color(0xFF3945A0),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(message,
                style: const TextStyle(
                    color: Color(0xFF5C6594), fontSize: 12.5, height: 1.4)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: Text(action,
                  style: const TextStyle(
                      color: kPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _MealSuggestion extends StatelessWidget {
  const _MealSuggestion({required this.ingredients, required this.onOpenPlan});

  final List<String> ingredients;
  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFFF3E9), Color(0xFFFFF9F3)]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFE1C6))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.restaurant_menu_rounded, color: kOrange, size: 20),
          const SizedBox(width: 8),
          const Expanded(
              child: Text('Meal ideas from what you have',
                  style: TextStyle(
                      color: Color(0xFF8A5529),
                      fontSize: 14,
                      fontWeight: FontWeight.w800))),
          Text('${ingredients.length} ingredients',
              style: const TextStyle(
                  color: Color(0xFFB87B4A),
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 13),
        const Text('Chicken rice bowl',
            style: TextStyle(
                color: Color(0xFF49392E),
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text(
            'Chicken · rice · broccoli · tomatoes  •  620 kcal  •  42g protein',
            style: TextStyle(color: Color(0xFF987A61), fontSize: 11)),
        const SizedBox(height: 13),
        OutlinedButton(
            onPressed: onOpenPlan,
            style: OutlinedButton.styleFrom(
                foregroundColor: kOrange,
                side: const BorderSide(color: Color(0xFFF3C99F)),
                visualDensity: VisualDensity.compact),
            child: const Text('See today’s meal plan')),
      ]),
    );
  }
}

class _PantrySummary extends StatelessWidget {
  const _PantrySummary(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 9),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    color: kMuted, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(value,
                style: const TextStyle(
                    color: kInk, fontSize: 15, fontWeight: FontWeight.w800)),
          ]),
        ),
      ]),
    );
  }
}

class _PantryAlert extends StatelessWidget {
  const _PantryAlert({required this.lowStock, required this.expired});

  final List<GroceryItem> lowStock;
  final List<GroceryItem> expired;

  @override
  Widget build(BuildContext context) {
    final messages = <String>[
      if (lowStock.isNotEmpty)
        'Running low: ${lowStock.map((item) => item.name).join(', ')}',
      if (expired.isNotEmpty)
        'Check expiry: ${expired.map((item) => item.name).join(', ')}',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: kOrangeSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFDDB8)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.notifications_active_outlined,
            color: kOrange, size: 19),
        const SizedBox(width: 9),
        Expanded(
          child: Text(messages.join('\n'),
              style: const TextStyle(
                  color: Color(0xFF754B2F),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  height: 1.4)),
        ),
      ]),
    );
  }
}

class _GroceryRow extends StatelessWidget {
  const _GroceryRow(
      {required this.item,
      required this.onToggle,
      required this.onEdit,
      required this.onDelete,
      required this.currencySymbol});

  final GroceryItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
      decoration: _cardDecoration(),
      child: Row(children: [
        GestureDetector(
          onTap: onToggle,
          child: Icon(
              item.bought
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: item.bought ? kGreen : const Color(0xFFB5BAC8),
              size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name,
                style: TextStyle(
                    color: item.bought ? kFaint : kInk,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    decoration:
                        item.bought ? TextDecoration.lineThrough : null)),
            const SizedBox(height: 4),
            Text(
                item.bought
                    ? '${_qty(item.quantity)} in stock · ${item.category}'
                    : 'Buy ${_qty(item.quantity)} · ${item.category}${item.fromPantry ? ' · from pantry' : ''}',
                style: TextStyle(
                    color: item.isExpired
                        ? kRed
                        : item.isLow
                            ? kOrange
                            : kFaint,
                    fontSize: 11)),
          ],
        )),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$currencySymbol ${item.price.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: kPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    onPressed: onEdit,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    tooltip: 'Edit grocery'),
                IconButton(
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline_rounded, size: 17),
                    tooltip: 'Delete grocery'),
              ],
            ),
          ],
        ),
      ]),
    );
  }
}

class _GroceryEditorDialog extends StatefulWidget {
  const _GroceryEditorDialog({this.initial});

  final GroceryItem? initial;

  @override
  State<_GroceryEditorDialog> createState() => _GroceryEditorDialogState();
}

class _GroceryEditorDialogState extends State<_GroceryEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _quantity;
  late final TextEditingController _minimum;
  late final TextEditingController _price;
  late final TextEditingController _expiryDays;

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    _name = TextEditingController(text: item?.name ?? '');
    _category = TextEditingController(text: item?.category ?? 'Other');
    _quantity = TextEditingController(text: '${item?.quantity ?? 1}');
    _minimum = TextEditingController(text: '${item?.minimumQuantity ?? 1}');
    _price = TextEditingController(text: '${item?.price ?? 0}');
    _expiryDays = TextEditingController(
        text: '${item?.expiresAt.difference(DateTime.now()).inDays ?? 7}');
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _category,
      _quantity,
      _minimum,
      _price,
      _expiryDays,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final now = DateTime.now();
    Navigator.pop(
      context,
      GroceryItem(
        name,
        _category.text.trim().isEmpty ? 'Other' : _category.text.trim(),
        bought: widget.initial?.bought ?? false,
        fromPantry: widget.initial?.fromPantry ?? false,
        quantity: double.tryParse(_quantity.text) ?? 1,
        minimumQuantity: double.tryParse(_minimum.text) ?? 1,
        price: double.tryParse(_price.text) ?? 0,
        purchasedAt: widget.initial?.purchasedAt ?? now,
        expiresAt: now.add(Duration(days: int.tryParse(_expiryDays.text) ?? 7)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.initial == null ? 'Add grocery item' : 'Edit grocery item'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Item name')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: const ['Protein', 'Pantry', 'Vegetables', 'Dairy', 'Other']
                    .contains(_category.text)
                ? _category.text
                : 'Other',
            decoration: const InputDecoration(labelText: 'Category suggestion'),
            items: const ['Protein', 'Pantry', 'Vegetables', 'Dairy', 'Other']
                .map((category) =>
                    DropdownMenuItem(value: category, child: Text(category)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _category.text = value);
            },
          ),
          const SizedBox(height: 10),
          TextField(
              controller: _category,
              decoration: const InputDecoration(
                  labelText: 'Category (or type your own)')),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'))),
            const SizedBox(width: 10),
            Expanded(
                child: TextField(
                    controller: _minimum,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Alert below'))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Price'))),
            const SizedBox(width: 10),
            Expanded(
                child: TextField(
                    controller: _expiryDays,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Expires in days'))),
          ]),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: _save,
            child: Text(widget.initial == null ? 'Add' : 'Save')),
      ],
    );
  }
}

String _qty(double value) =>
    value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);

class _PantrySection extends StatelessWidget {
  const _PantrySection({
    required this.items,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onUse,
    required this.onRestock,
    required this.currencySymbol,
  });

  final List<MonthlyItem> items;
  final VoidCallback onAdd;
  final ValueChanged<MonthlyItem> onEdit;
  final ValueChanged<MonthlyItem> onDelete;
  final ValueChanged<MonthlyItem> onUse;
  final ValueChanged<MonthlyItem> onRestock;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final low = items.where((item) => item.isLow).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionTitle(title: 'Pantry', action: 'Add', onAction: onAdd),
      const SizedBox(height: 4),
      const Text(
          'What you keep at home. Tap − when you use one. When stock gets low, it goes to your shopping list.',
          style: TextStyle(color: kMuted, fontSize: 12, height: 1.4)),
      const SizedBox(height: 12),
      if (low.isNotEmpty) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: kOrangeSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFDDB8)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.shopping_cart_checkout_rounded,
                color: kOrange, size: 19),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                  'Low in stock: ${low.map((item) => item.name).join(', ')}. They are on your shopping list above.',
                  style: const TextStyle(
                      color: Color(0xFF754B2F),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.4)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
      ],
      if (items.isEmpty)
        _EmptyCard(
          icon: Icons.inventory_2_outlined,
          text:
              'Your pantry is empty. Add the things you buy regularly, like toothpaste or detergent.',
          actionLabel: 'Add an item',
          onAction: onAdd,
        )
      else
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
          decoration: _cardDecoration(),
          child: Column(
            children: items.map((item) {
              final color = item.isLow ? kOrange : kGreen;
              final bought = item.lastBought == null
                  ? ''
                  : ' · bought ${_fmtDate(item.lastBought!)}';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(
                        item.isLow
                            ? Icons.warning_amber_rounded
                            : Icons.inventory_2_rounded,
                        size: 18,
                        color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Flexible(
                              child: Text(item.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: kInk,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800)),
                            ),
                            if (item.isLow) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                    color: kOrange,
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Text('LOW',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ]),
                          const SizedBox(height: 3),
                          Text(
                              '${item.category} · alert at ${_qty(item.minimum)}$bought',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(color: kMuted, fontSize: 11)),
                        ]),
                  ),
                  IconButton(
                    onPressed: item.quantity <= 0 ? null : () => onUse(item),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: kMuted,
                    tooltip: 'I used one',
                  ),
                  SizedBox(
                    width: 30,
                    child: Text(_qty(item.quantity),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: color,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    onPressed: () => onRestock(item),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: kPrimary,
                    tooltip: 'I bought one',
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Edit or delete',
                    icon: const Icon(Icons.more_vert_rounded,
                        size: 19, color: kMuted),
                    onSelected: (value) =>
                        value == 'edit' ? onEdit(item) : onDelete(item),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ]),
              );
            }).toList(),
          ),
        ),
    ]);
  }
}

class _MonthlyItemDialog extends StatefulWidget {
  const _MonthlyItemDialog({this.initial});

  final MonthlyItem? initial;

  @override
  State<_MonthlyItemDialog> createState() => _MonthlyItemDialogState();
}

class _MonthlyItemDialogState extends State<_MonthlyItemDialog> {
  late final TextEditingController _name;
  late final TextEditingController _quantity;
  late final TextEditingController _minimum;
  late final TextEditingController _buy;
  late final TextEditingController _price;
  late String _category;
  String? _error;

  static const _categories = [
    'Household',
    'Personal',
    'Health',
    'Food',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    _name = TextEditingController(text: item?.name ?? '');
    _quantity = TextEditingController(text: _qty(item?.quantity ?? 1));
    _minimum = TextEditingController(text: _qty(item?.minimum ?? 1));
    _buy = TextEditingController(text: _qty(item?.buyQuantity ?? 1));
    _price = TextEditingController(
        text: (item?.price ?? 0) == 0 ? '' : '${item!.price}');
    _category = _categories.contains(item?.category) ? item!.category : 'Other';
  }

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _minimum.dispose();
    _buy.dispose();
    _price.dispose();
    super.dispose();
  }

  double _num(TextEditingController c, double fallback) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? fallback;

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give the item a name.');
      return;
    }
    final old = widget.initial;
    Navigator.pop(
      context,
      MonthlyItem(
        name,
        _category,
        quantity: _num(_quantity, 1),
        minimum: _num(_minimum, 1),
        buyQuantity: _num(_buy, 1) <= 0 ? 1 : _num(_buy, 1),
        price: _num(_price, 0),
        lastBought: old?.lastBought,
        lowListed: old?.lowListed ?? false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title:
            Text(widget.initial == null ? 'Add to pantry' : 'Edit pantry item'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 420,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                      controller: _name,
                      autofocus: widget.initial == null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                          labelText: 'Item name', hintText: 'e.g. Toothpaste')),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _categories
                        .map((c) => ChoiceChip(
                              label: Text(c),
                              selected: _category == c,
                              onSelected: (_) => setState(() => _category = c),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextField(
                          controller: _quantity,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration:
                              const InputDecoration(labelText: 'In stock now')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                          controller: _minimum,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                              labelText: 'Alert at or below')),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: TextField(
                          controller: _buy,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration:
                              const InputDecoration(labelText: 'Usually buy')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                          controller: _price,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration:
                              const InputDecoration(labelText: 'Price each')),
                    ),
                  ]),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!,
                        style: const TextStyle(color: kRed, fontSize: 12)),
                  ],
                ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      );
}

class _InputDialog extends StatelessWidget {
  const _InputDialog(
      {required this.title,
      required this.hint,
      required this.controller,
      this.confirmLabel = 'Add'});

  final String title;
  final String hint;
  final TextEditingController controller;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(confirmLabel)),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Cloud data (Supabase) ─────────────────────────
SupabaseClient get _db => Supabase.instance.client;

String get _uid {
  final user = _db.auth.currentUser;
  if (user == null) throw StateError('Not signed in to Supabase.');
  return user.id;
}

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

DateTime _startOfWeek(DateTime d) {
  final day = _dateOnly(d);
  return _addDays(day, 1 - day.weekday);
}

String _monthLabel(DateTime d) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[d.month - 1]} ${d.year}';
}

String _money(String symbol, double value) => value < 0
    ? '-$symbol ${(-value).toStringAsFixed(2)}'
    : '$symbol ${value.toStringAsFixed(2)}';

bool _isBible(ChallengeItem c) => c.title.toLowerCase().contains('bible');

List<Color> _heroColors() {
  final hour = DateTime.now().hour;
  if (hour < 12) return const [Color(0xFFFF8A5B), Color(0xFFF2557C)];
  if (hour < 18) return const [Color(0xFF4F5FE8), Color(0xFF7A67EC)];
  return const [Color(0xFF3B3F9E), Color(0xFF7B4FC9)];
}

/// A list of rows stored in a Supabase table, shared by every screen.
class CloudStore<T> extends ChangeNotifier {
  CloudStore(this.table, this.fromRow, this.idOf,
      {this.orderBy = 'created_at'});

  final String table;
  final T Function(Map<String, dynamic>) fromRow;
  final String Function(T) idOf;
  final String orderBy;
  List<T> items = [];
  bool loading = true;
  String? error;

  void reset() {
    items = [];
    loading = true;
    error = null;
    notifyListeners();
  }

  Future<void> load() async {
    try {
      final rows = await _db
          .from(table)
          .select()
          .eq('user_id', _uid)
          .order(orderBy, ascending: false)
          .limit(1000);
      items = rows.map<T>((row) => fromRow(row)).toList();
      error = null;
    } catch (_) {
      error =
          'Could not load this data. Run the new SQL script in Supabase, then try again.';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> add(Map<String, dynamic> values) async {
    await _db.from(table).insert({...values, 'user_id': _uid});
    await load();
  }

  Future<void> remove(T item) async {
    await _db.from(table).delete().eq('id', idOf(item)).eq('user_id', _uid);
    items.remove(item);
    notifyListeners();
  }

  Future<void> removeWhere(String column, String value) async {
    await _db.from(table).delete().eq('user_id', _uid).eq(column, value);
    await load();
  }
}

class FinanceEntry {
  FinanceEntry({
    required this.id,
    required this.kind,
    required this.category,
    required this.title,
    required this.amount,
    required this.occurredAt,
    this.note = '',
  });

  final String id;
  final String kind; // income | expense
  final String category;
  final String title;
  final double amount;
  final DateTime occurredAt;
  final String note;

  bool get isIncome => kind == 'income';

  factory FinanceEntry.fromRow(Map<String, dynamic> row) => FinanceEntry(
        id: row['id'] as String,
        kind: row['kind'] as String? ?? 'expense',
        category: row['category'] as String? ?? 'Other',
        title: row['title'] as String? ?? '',
        amount: (row['amount'] as num?)?.toDouble() ?? 0,
        occurredAt: DateTime.parse(row['occurred_at'] as String).toLocal(),
        note: row['note'] as String? ?? '',
      );
}

class BodyMeasurement {
  BodyMeasurement({
    required this.id,
    required this.kind,
    required this.value,
    required this.unit,
    required this.measuredAt,
    this.note = '',
  });

  final String id;
  final String kind;
  final double value;
  final String unit;
  final DateTime measuredAt;
  final String note;

  factory BodyMeasurement.fromRow(Map<String, dynamic> row) => BodyMeasurement(
        id: row['id'] as String,
        kind: row['kind'] as String? ?? 'weight',
        value: (row['value'] as num?)?.toDouble() ?? 0,
        unit: row['unit'] as String? ?? 'cm',
        measuredAt: DateTime.parse(row['measured_at'] as String).toLocal(),
        note: row['note'] as String? ?? '',
      );
}

class BibleReading {
  BibleReading({
    required this.id,
    required this.book,
    required this.chapter,
    required this.verseRef,
    required this.verseText,
    required this.note,
    required this.readAt,
  });

  final String id;
  final String book;
  final int? chapter;
  final String verseRef;
  final String verseText;
  final String note;
  final DateTime readAt;

  String get chapterTitle => chapter == null ? book : '$book $chapter';

  String get reference {
    if (verseRef.isEmpty) return chapterTitle;
    return chapter == null ? '$book $verseRef' : '$book $chapter:$verseRef';
  }

  factory BibleReading.fromRow(Map<String, dynamic> row) => BibleReading(
        id: row['id'] as String,
        book: row['book'] as String? ?? '',
        chapter: (row['chapter'] as num?)?.toInt(),
        verseRef: row['verse_ref'] as String? ?? '',
        verseText: row['verse_text'] as String? ?? '',
        note: row['note'] as String? ?? '',
        readAt: DateTime.parse(row['read_at'] as String).toLocal(),
      );
}

final financeStore = CloudStore<FinanceEntry>(
    'finance_entries', FinanceEntry.fromRow, (e) => e.id,
    orderBy: 'occurred_at');
final measurementStore = CloudStore<BodyMeasurement>(
    'body_measurements', BodyMeasurement.fromRow, (e) => e.id,
    orderBy: 'measured_at');
final bibleStore = CloudStore<BibleReading>(
    'bible_readings', BibleReading.fromRow, (e) => e.id,
    orderBy: 'read_at');

// ───────────────────────── Shared animated widgets ─────────────────────────
class _Reveal extends StatefulWidget {
  const _Reveal({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: 70 * widget.index), () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _shown ? 1 : 0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _shown ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _CountUp extends StatelessWidget {
  const _CountUp({required this.value, required this.format, this.style});

  final double value;
  final String Function(double) format;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(format(v), style: style),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({required this.value, required this.onChanged});

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      onChanged(DateTime(
          picked.year, picked.month, picked.day, value.hour, value.minute));
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(value));
    if (picked != null) {
      onChanged(DateTime(
          value.year, value.month, value.day, picked.hour, picked.minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => _pickDate(context),
          icon: const Icon(Icons.calendar_today_rounded, size: 17),
          label: Text(_fmtDate(value)),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => _pickTime(context),
          icon: const Icon(Icons.schedule_rounded, size: 17),
          label: Text(_fmtTime(value)),
        ),
      ),
    ]);
  }
}

// ───────────────────────── Finance ─────────────────────────
const kIncomeCategories = ['Salary', 'Freelance', 'Business', 'Gift', 'Other'];
const kExpenseCategories = [
  'Rent',
  'Utilities',
  'Groceries',
  'Takeout',
  'Transport',
  'Health',
  'Fun',
  'Other',
];
const kTakeoutWeeklyLimit = 1;

IconData _categoryIcon(String category) {
  switch (category) {
    case 'Salary':
      return Icons.work_rounded;
    case 'Freelance':
      return Icons.laptop_mac_rounded;
    case 'Business':
      return Icons.storefront_rounded;
    case 'Gift':
      return Icons.card_giftcard_rounded;
    case 'Rent':
      return Icons.home_rounded;
    case 'Utilities':
      return Icons.bolt_rounded;
    case 'Groceries':
      return Icons.shopping_basket_rounded;
    case 'Takeout':
      return Icons.delivery_dining_rounded;
    case 'Transport':
      return Icons.directions_bus_rounded;
    case 'Health':
      return Icons.favorite_rounded;
    case 'Fun':
      return Icons.celebration_rounded;
    default:
      return Icons.payments_rounded;
  }
}

Color _categoryColor(String category) {
  switch (category) {
    case 'Salary':
    case 'Freelance':
    case 'Business':
    case 'Gift':
      return kGreen;
    case 'Rent':
      return kPurple;
    case 'Utilities':
      return kGold;
    case 'Groceries':
      return kOrange;
    case 'Takeout':
      return kRed;
    case 'Transport':
      return const Color(0xFF3D9BB5);
    case 'Health':
      return const Color(0xFFE05C8A);
    case 'Fun':
      return kPrimary;
    default:
      return kMuted;
  }
}

int _takeoutCountInWeek(DateTime when) {
  final week = _startOfWeek(when);
  return financeStore.items
      .where((e) =>
          !e.isIncome &&
          e.category == 'Takeout' &&
          _startOfWeek(e.occurredAt) == week)
      .length;
}

Future<void> _addFinance(BuildContext context, String symbol) async {
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => _FinanceDialog(symbol: symbol),
  );
  if (result == null || !context.mounted) return;
  if (result['kind'] == 'expense' && result['category'] == 'Takeout') {
    final when = DateTime.parse(result['occurred_at'] as String).toLocal();
    final count = _takeoutCountInWeek(when);
    if (count >= kTakeoutWeeklyLimit) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          icon:
              const Icon(Icons.warning_amber_rounded, color: kOrange, size: 34),
          title: const Text('Takeout limit reached'),
          content: Text(
              'You planned $kTakeoutWeeklyLimit takeout per week and already have $count this week. Add it anyway?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialog, false),
                child: const Text('Skip it')),
            FilledButton(
                onPressed: () => Navigator.pop(dialog, true),
                child: const Text('Add anyway')),
          ],
        ),
      );
      if (proceed != true || !context.mounted) return;
    }
  }
  try {
    await financeStore.add(result);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not save. Did you run the new SQL script?')));
    }
  }
}

class _FinancePage extends StatefulWidget {
  const _FinancePage({required this.currencySymbol});

  final String currencySymbol;

  @override
  State<_FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<_FinancePage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shift(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  Future<void> _delete(FinanceEntry entry) async {
    try {
      await financeStore.remove(entry);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete that entry.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final symbol = widget.currencySymbol;
    return _PageScaffold(
      child: ListenableBuilder(
        listenable: financeStore,
        builder: (context, _) {
          final entries = financeStore.items
              .where((e) =>
                  e.occurredAt.year == _month.year &&
                  e.occurredAt.month == _month.month)
              .toList()
            ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
          var income = 0.0;
          var spent = 0.0;
          final spendBy = <String, double>{};
          final incomeBy = <String, double>{};
          for (final e in entries) {
            if (e.isIncome) {
              income += e.amount;
              incomeBy[e.category] = (incomeBy[e.category] ?? 0) + e.amount;
            } else {
              spent += e.amount;
              spendBy[e.category] = (spendBy[e.category] ?? 0) + e.amount;
            }
          }
          final takeouts = _takeoutCountInWeek(DateTime.now());
          final groups = <DateTime, List<FinanceEntry>>{};
          for (final e in entries) {
            groups.putIfAbsent(_dateOnly(e.occurredAt), () => []).add(e);
          }
          final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
            children: [
              _PageHeader(
                eyebrow: 'Income and spending',
                title: 'Money',
                subtitle: _monthLabel(_month),
                action: IconButton.filled(
                  onPressed: () => _addFinance(context, symbol),
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'Add income or expense',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      onPressed: () => _shift(-1),
                      icon: const Icon(Icons.chevron_left_rounded),
                      tooltip: 'Previous month'),
                  Text(_monthLabel(_month),
                      style: const TextStyle(
                          color: kInk, fontWeight: FontWeight.w800)),
                  IconButton(
                      onPressed: () => _shift(1),
                      icon: const Icon(Icons.chevron_right_rounded),
                      tooltip: 'Next month'),
                ],
              ),
              const SizedBox(height: 8),
              if (financeStore.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (financeStore.error != null)
                _EmptyCard(
                  icon: Icons.cloud_off_rounded,
                  text: financeStore.error!,
                  actionLabel: 'Try again',
                  onAction: financeStore.load,
                )
              else ...[
                _Reveal(
                  index: 0,
                  child: _BalanceCard(
                      balance: income - spent,
                      income: income,
                      spent: spent,
                      symbol: symbol),
                ),
                const SizedBox(height: 14),
                _Reveal(
                  index: 1,
                  child: _TakeoutBanner(
                      count: takeouts, limit: kTakeoutWeeklyLimit),
                ),
                if (spendBy.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const _SectionTitle(title: 'Where it went'),
                  const SizedBox(height: 10),
                  _CategoryBars(totals: spendBy, symbol: symbol),
                ],
                if (incomeBy.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const _SectionTitle(title: 'Where it came from'),
                  const SizedBox(height: 10),
                  _CategoryBars(totals: incomeBy, symbol: symbol),
                ],
                const SizedBox(height: 24),
                const _SectionTitle(title: 'Every entry'),
                const SizedBox(height: 10),
                if (entries.isEmpty)
                  _EmptyCard(
                    icon: Icons.account_balance_wallet_outlined,
                    text:
                        'Nothing recorded this month. Add your pay, rent, bills and spending with the + button.',
                    actionLabel: 'Add an entry',
                    onAction: () => _addFinance(context, symbol),
                  )
                else
                  ...days.map((day) {
                    final list = groups[day]!;
                    final net = list.fold<double>(
                        0, (s, e) => s + (e.isIncome ? e.amount : -e.amount));
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
                        decoration: _cardDecoration(),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Row(children: [
                                  Expanded(
                                    child: Text(_relativeDay(day),
                                        style: const TextStyle(
                                            color: kInk,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800)),
                                  ),
                                  Text(
                                      '${net >= 0 ? '+' : '-'}${_money(symbol, net.abs())}',
                                      style: TextStyle(
                                          color: net >= 0 ? kGreen : kMuted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800)),
                                ]),
                              ),
                              ...list.map((e) => _FinanceTile(
                                  entry: e,
                                  symbol: symbol,
                                  onDelete: () => _delete(e))),
                            ]),
                      ),
                    );
                  }),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard(
      {required this.balance,
      required this.income,
      required this.spent,
      required this.symbol});

  final double balance;
  final double income;
  final double spent;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final ratio = income <= 0
        ? (spent > 0 ? 1.0 : 0.0)
        : (spent / income).clamp(0.0, 1.0).toDouble();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF12A383), Color(0xFF3CC6A0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF12A383).withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 12))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Left this month',
            style: TextStyle(
                color: Color(0xFFD9FFF3),
                fontSize: 13,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        _CountUp(
          value: balance,
          format: (v) => _money(symbol, v),
          style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
              child: _MoneyChip(
                  icon: Icons.south_west_rounded,
                  label: 'Received',
                  value: _money(symbol, income))),
          const SizedBox(width: 10),
          Expanded(
              child: _MoneyChip(
                  icon: Icons.north_east_rounded,
                  label: 'Spent',
                  value: _money(symbol, spent))),
        ]),
        const SizedBox(height: 16),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: ratio),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
                value: v,
                minHeight: 8,
                color: Colors.white,
                backgroundColor: Colors.white24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
            income > 0
                ? 'You have spent ${(spent / income * 100).round()}% of what came in.'
                : 'Add your income to see how much is left.',
            style: const TextStyle(color: Color(0xFFD9FFF3), fontSize: 12)),
      ]),
    );
  }
}

class _MoneyChip extends StatelessWidget {
  const _MoneyChip(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(color: Color(0xFFD9FFF3), fontSize: 11)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _TakeoutBanner extends StatelessWidget {
  const _TakeoutBanner({required this.count, required this.limit});

  final int count;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final over = count >= limit;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: over ? const Color(0xFFFFEBE8) : kGreenSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: over ? const Color(0xFFFFCFC8) : const Color(0xFFD1EEDB)),
      ),
      child: Row(children: [
        Icon(over ? Icons.warning_amber_rounded : Icons.delivery_dining_rounded,
            color: over ? kRed : kGreen),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            over
                ? 'Takeout limit reached: $count of $limit this week. Cook at home until Monday.'
                : 'Takeout this week: $count of $limit. You are on track.',
            style: TextStyle(
                color: over ? const Color(0xFF9C3B31) : const Color(0xFF2D714A),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.35),
          ),
        ),
      ]),
    );
  }
}

class _CategoryBars extends StatelessWidget {
  const _CategoryBars({required this.totals, required this.symbol});

  final Map<String, double> totals;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = sorted.isEmpty ? 1.0 : sorted.first.value;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: _cardDecoration(),
      child: Column(
        children: sorted.map((e) {
          final color = _categoryColor(e.key);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(_categoryIcon(e.key), size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(e.key,
                      style: const TextStyle(
                          color: kInk,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700)),
                ),
                Text(_money(symbol, e.value),
                    style: const TextStyle(
                        color: kInk,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 6),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: e.value / maxValue),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                      value: v,
                      minHeight: 7,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.12)),
                ),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

class _FinanceTile extends StatelessWidget {
  const _FinanceTile(
      {required this.entry, required this.symbol, required this.onDelete});

  final FinanceEntry entry;
  final String symbol;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(entry.category);
    final detail = entry.note.isEmpty
        ? '${entry.category} · ${_fmtTime(entry.occurredAt)}'
        : '${entry.category} · ${_fmtTime(entry.occurredAt)} · ${entry.note}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(_categoryIcon(entry.category), size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(entry.title.isEmpty ? entry.category : entry.title,
                style: const TextStyle(
                    color: kInk, fontSize: 13.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: kMuted, fontSize: 11.5)),
          ]),
        ),
        Text('${entry.isIncome ? '+' : '-'}${_money(symbol, entry.amount)}',
            style: TextStyle(
                color: entry.isIncome ? kGreen : kInk,
                fontSize: 13,
                fontWeight: FontWeight.w800)),
        IconButton(
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: kFaint,
            tooltip: 'Delete'),
      ]),
    );
  }
}

class _FinanceDialog extends StatefulWidget {
  const _FinanceDialog({required this.symbol});

  final String symbol;

  @override
  State<_FinanceDialog> createState() => _FinanceDialogState();
}

class _FinanceDialogState extends State<_FinanceDialog> {
  String _kind = 'expense';
  String _category = 'Rent';
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _when = DateTime.now();
  String? _error;

  List<String> get _categories =>
      _kind == 'income' ? kIncomeCategories : kExpenseCategories;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter an amount greater than 0.');
      return;
    }
    Navigator.pop(context, {
      'kind': _kind,
      'category': _category,
      'title': _title.text.trim().isEmpty ? _category : _title.text.trim(),
      'amount': amount,
      'occurred_at': _when.toUtc().toIso8601String(),
      'note': _note.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add to your money'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                          value: 'expense',
                          icon: Icon(Icons.north_east_rounded),
                          label: Text('Spent')),
                      ButtonSegment(
                          value: 'income',
                          icon: Icon(Icons.south_west_rounded),
                          label: Text('Received')),
                    ],
                    selected: {_kind},
                    onSelectionChanged: (value) => setState(() {
                      _kind = value.first;
                      _category = _categories.first;
                    }),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _amount,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: 'Amount', prefixText: '${widget.symbol} '),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                      labelText: 'What is it for?',
                      hintText: _kind == 'income'
                          ? 'e.g. October salary'
                          : 'e.g. Electricity bill'),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _categories
                      .map((c) => ChoiceChip(
                            avatar: Icon(_categoryIcon(c),
                                size: 16, color: _categoryColor(c)),
                            label: Text(c),
                            selected: _category == c,
                            onSelected: (_) => setState(() => _category = c),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 14),
                _DateTimeField(
                    value: _when,
                    onChanged: (value) => setState(() => _when = value)),
                const SizedBox(height: 10),
                TextField(
                  controller: _note,
                  decoration:
                      const InputDecoration(labelText: 'Note (optional)'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!,
                      style: const TextStyle(color: kRed, fontSize: 12)),
                ],
              ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _MoneyMiniCard extends StatelessWidget {
  const _MoneyMiniCard({required this.symbol, required this.onTap});

  final String symbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: financeStore,
      builder: (context, _) {
        final now = DateTime.now();
        var income = 0.0;
        var spent = 0.0;
        for (final e in financeStore.items) {
          if (e.occurredAt.year == now.year &&
              e.occurredAt.month == now.month) {
            if (e.isIncome) {
              income += e.amount;
            } else {
              spent += e.amount;
            }
          }
        }
        final ratio = income <= 0
            ? (spent > 0 ? 1.0 : 0.0)
            : (spent / income).clamp(0.0, 1.0).toDouble();
        final takeouts = _takeoutCountInWeek(now);
        final over = takeouts >= kTakeoutWeeklyLimit;
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: kGreenSoft,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: kGreen, size: 19),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Money this month',
                      style: TextStyle(
                          color: kInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                ),
                const Icon(Icons.chevron_right_rounded, color: kFaint),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                    child: _MiniFigure(
                        label: 'Received',
                        value: income,
                        symbol: symbol,
                        color: kGreen)),
                Expanded(
                    child: _MiniFigure(
                        label: 'Spent',
                        value: spent,
                        symbol: symbol,
                        color: kInk)),
                Expanded(
                    child: _MiniFigure(
                        label: 'Left',
                        value: income - spent,
                        symbol: symbol,
                        color: kPrimary)),
              ]),
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: ratio),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                      value: v,
                      minHeight: 8,
                      color: v > 0.85 ? kOrange : kGreen,
                      backgroundColor: kGreenSoft),
                ),
              ),
              if (over) ...[
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: kRed, size: 17),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                        'Takeout limit reached this week ($takeouts of $kTakeoutWeeklyLimit).',
                        style: const TextStyle(
                            color: Color(0xFF9C3B31),
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
              ],
            ]),
          ),
        );
      },
    );
  }
}

class _MiniFigure extends StatelessWidget {
  const _MiniFigure(
      {required this.label,
      required this.value,
      required this.symbol,
      required this.color});

  final String label;
  final double value;
  final String symbol;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              color: kMuted, fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(height: 3),
      _CountUp(
        value: value,
        format: (v) => _money(symbol, v),
        style: TextStyle(
            color: color, fontSize: 13.5, fontWeight: FontWeight.w800),
      ),
    ]);
  }
}

// ───────────────────────── Body measurements ─────────────────────────
const kMeasureKinds = <String, String>{
  'weight': 'Weight',
  'waist': 'Waist',
  'hips': 'Hips',
  'shoulders': 'Shoulders',
  'chest': 'Chest',
  'arms': 'Arms',
  'thighs': 'Thighs',
  'neck': 'Neck',
};

String _kindLabel(String kind) =>
    kMeasureKinds[kind] ??
    (kind.isEmpty ? kind : kind[0].toUpperCase() + kind.substring(1));

class _MeasurementsCard extends StatefulWidget {
  const _MeasurementsCard({required this.targetMass});

  final double targetMass;

  @override
  State<_MeasurementsCard> createState() => _MeasurementsCardState();
}

class _MeasurementsCardState extends State<_MeasurementsCard> {
  String _kind = 'weight';

  Future<void> _add() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _MeasurementDialog(initialKind: _kind),
    );
    if (result == null || !mounted) return;
    try {
      await measurementStore.add(result);
      if (mounted) setState(() => _kind = result['kind'] as String);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not save. Did you run the new SQL script?')));
    }
  }

  Future<void> _delete(BodyMeasurement m) async {
    try {
      await measurementStore.remove(m);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete that entry.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: measurementStore,
      builder: (context, _) {
        final all = measurementStore.items;
        final custom = all
            .map((m) => m.kind)
            .where((k) => !kMeasureKinds.containsKey(k))
            .toSet();
        final kinds = [...kMeasureKinds.keys, ...custom];
        final list = all.where((m) => m.kind == _kind).toList()
          ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
        final unit = _kind == 'weight' ? 'kg' : 'cm';
        final latest = list.isEmpty ? null : list.last;
        final first = list.isEmpty ? null : list.first;
        final change = (latest != null && first != null)
            ? latest.value - first.value
            : 0.0;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle(title: 'Body measurements'),
              TextButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add, size: 17),
                label: const Text('Log'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kinds.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => ChoiceChip(
                label: Text(_kindLabel(kinds[i])),
                selected: _kind == kinds[i],
                onSelected: (_) => setState(() => _kind = kinds[i]),
                selectedColor: kPrimarySoft,
                showCheckmark: false,
                side: BorderSide(color: _kind == kinds[i] ? kPrimary : kLine),
                labelStyle: TextStyle(
                    color: _kind == kinds[i] ? kPrimary : kMuted,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (measurementStore.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (measurementStore.error != null)
            _EmptyCard(
              icon: Icons.cloud_off_rounded,
              text: measurementStore.error!,
              actionLabel: 'Try again',
              onAction: measurementStore.load,
            )
          else if (list.isEmpty)
            _EmptyCard(
              icon: Icons.straighten_rounded,
              text:
                  'No ${_kindLabel(_kind).toLowerCase()} logged yet. You can add earlier dates too, to see your whole evolution.',
              actionLabel: 'Log ${_kindLabel(_kind).toLowerCase()}',
              onAction: _add,
            )
          else ...[
            Container(
              height: 210,
              padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
              decoration: _cardDecoration(),
              child: CustomPaint(
                painter: _ProgressPainter(
                  entries: list
                      .map((m) => MassEntry(m.measuredAt, m.value))
                      .toList(),
                  color: kPrimary,
                  unit: unit,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Row(children: [
                Expanded(
                    child: _RecapMetric(
                        label: 'Latest',
                        value: '${latest!.value.toStringAsFixed(1)} $unit')),
                Expanded(
                    child: _RecapMetric(
                        label: 'Change',
                        value: list.length < 2
                            ? '-'
                            : '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} $unit')),
                Expanded(
                    child: _RecapMetric(
                        label: _kind == 'weight' ? 'Target' : 'Entries',
                        value: _kind == 'weight'
                            ? '${widget.targetMass.toStringAsFixed(1)} kg'
                            : '${list.length}')),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              decoration: _cardDecoration(),
              child: Column(
                children: list.reversed.take(6).map((m) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${m.value.toStringAsFixed(1)} ${m.unit}',
                                  style: const TextStyle(
                                      color: kInk,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text(
                                  '${_fmtDate(m.measuredAt)} · ${_fmtTime(m.measuredAt)}${m.note.isEmpty ? '' : ' · ${m.note}'}',
                                  style: const TextStyle(
                                      color: kMuted, fontSize: 11.5)),
                            ]),
                      ),
                      IconButton(
                          onPressed: () => _delete(m),
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18),
                          color: kFaint,
                          tooltip: 'Delete'),
                    ]),
                  );
                }).toList(),
              ),
            ),
          ],
        ]);
      },
    );
  }
}

class _MeasurementDialog extends StatefulWidget {
  const _MeasurementDialog({required this.initialKind});

  final String initialKind;

  @override
  State<_MeasurementDialog> createState() => _MeasurementDialogState();
}

class _MeasurementDialogState extends State<_MeasurementDialog> {
  late String _kind;
  final _custom = TextEditingController();
  final _value = TextEditingController();
  final _note = TextEditingController();
  DateTime _when = DateTime.now();
  String? _error;

  @override
  void initState() {
    super.initState();
    if (kMeasureKinds.containsKey(widget.initialKind)) {
      _kind = widget.initialKind;
    } else {
      _kind = '_other';
      _custom.text = widget.initialKind;
    }
  }

  @override
  void dispose() {
    _custom.dispose();
    _value.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final kind = _kind == '_other' ? _custom.text.trim().toLowerCase() : _kind;
    final value = double.tryParse(_value.text.trim().replaceAll(',', '.'));
    if (kind.isEmpty) {
      setState(() => _error = 'Give this measurement a name.');
      return;
    }
    if (value == null || value <= 0) {
      setState(() => _error = 'Enter a value greater than 0.');
      return;
    }
    Navigator.pop(context, {
      'kind': kind,
      'value': value,
      'unit': kind == 'weight' ? 'kg' : 'cm',
      'measured_at': _when.toUtc().toIso8601String(),
      'note': _note.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final unit = _kind == 'weight' ? 'kg' : 'cm';
    return AlertDialog(
      title: const Text('Log a measurement'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    ...kMeasureKinds.entries.map((e) => ChoiceChip(
                          label: Text(e.value),
                          selected: _kind == e.key,
                          onSelected: (_) => setState(() => _kind = e.key),
                        )),
                    ChoiceChip(
                      label: const Text('Other'),
                      selected: _kind == '_other',
                      onSelected: (_) => setState(() => _kind = '_other'),
                    ),
                  ],
                ),
                if (_kind == '_other') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _custom,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                        labelText: 'Name', hintText: 'e.g. Calves'),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _value,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      InputDecoration(labelText: 'Value', suffixText: unit),
                ),
                const SizedBox(height: 12),
                _DateTimeField(
                    value: _when,
                    onChanged: (value) => setState(() => _when = value)),
                const SizedBox(height: 10),
                TextField(
                  controller: _note,
                  decoration:
                      const InputDecoration(labelText: 'Note (optional)'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!,
                      style: const TextStyle(color: kRed, fontSize: 12)),
                ],
              ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

// ───────────────────────── Bible reading ─────────────────────────
int _readingStreak(Set<DateTime> days) {
  var cursor = _dateOnly(DateTime.now());
  if (!days.contains(cursor)) cursor = _addDays(cursor, -1);
  var count = 0;
  while (days.contains(cursor)) {
    count++;
    cursor = _addDays(cursor, -1);
  }
  return count;
}

Future<void> _addBibleReading(BuildContext context) async {
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => const _BibleDialog(),
  );
  if (result == null || !context.mounted) return;
  try {
    await bibleStore.add(result);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not save. Did you run the new SQL script?')));
    }
  }
}

class _BibleDialog extends StatefulWidget {
  const _BibleDialog();

  @override
  State<_BibleDialog> createState() => _BibleDialogState();
}

class _BibleDialogState extends State<_BibleDialog> {
  final _book = TextEditingController();
  final _chapter = TextEditingController();
  final _verseRef = TextEditingController();
  final _verse = TextEditingController();
  final _note = TextEditingController();
  DateTime _when = DateTime.now();
  String? _error;

  @override
  void dispose() {
    _book.dispose();
    _chapter.dispose();
    _verseRef.dispose();
    _verse.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final book = _book.text.trim();
    if (book.isEmpty) {
      setState(() => _error = 'Which book did you read?');
      return;
    }
    final chapter = int.tryParse(_chapter.text.trim());
    Navigator.pop(context, {
      'book': book,
      'chapter': chapter,
      'verse_ref': _verseRef.text.trim(),
      'verse_text': _verse.text.trim(),
      'note': _note.text.trim(),
      'read_at': _when.toUtc().toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('I read a chapter'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _book,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                          labelText: 'Book', hintText: 'e.g. John'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _chapter,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Chapter'),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                TextField(
                  controller: _verse,
                  minLines: 3,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                      labelText: 'The verse that spoke to you',
                      hintText:
                          'Type it here. It will appear on your home screen as a reminder.'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _verseRef,
                  decoration: const InputDecoration(
                      labelText: 'Verse number (optional)',
                      hintText: 'e.g. 16 or 16-17'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _note,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                      labelText: 'What it means for me (optional)'),
                ),
                const SizedBox(height: 12),
                _DateTimeField(
                    value: _when,
                    onChanged: (value) => setState(() => _when = value)),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!,
                      style: const TextStyle(color: kRed, fontSize: 12)),
                ],
              ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _VerseCard extends StatelessWidget {
  const _VerseCard(
      {required this.reading, this.label = 'Verse reminder', this.trailing});

  final BibleReading reading;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [kGoldSoft, Color(0xFFFFE6AE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3D58C)),
        boxShadow: [
          BoxShadow(
              color: kGold.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.format_quote_rounded, color: kGold, size: 26),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF8A6512),
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
          ),
          if (trailing != null) trailing!,
        ]),
        const SizedBox(height: 8),
        Text(reading.verseText,
            style: const TextStyle(
                color: Color(0xFF4A3A12),
                fontSize: 16,
                height: 1.45,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(reading.reference,
            style: const TextStyle(
                color: Color(0xFF8A6512),
                fontSize: 12.5,
                fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _VerseBanner extends StatefulWidget {
  const _VerseBanner({required this.onOpen});

  final VoidCallback onOpen;

  @override
  State<_VerseBanner> createState() => _VerseBannerState();
}

class _VerseBannerState extends State<_VerseBanner> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 9), (_) {
      if (mounted) setState(() => _index++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: bibleStore,
      builder: (context, _) {
        final verses = bibleStore.items
            .where((r) => r.verseText.trim().isNotEmpty)
            .toList();
        if (verses.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: kGoldSoft,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF3D58C)),
            ),
            child: Row(children: [
              const Icon(Icons.menu_book_rounded, color: kGold, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Daily verse',
                          style: TextStyle(
                              color: Color(0xFF8A6512),
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      const Text(
                          'Read a chapter, save the verse that spoke to you, and it will wait for you here every day.',
                          style: TextStyle(
                              color: Color(0xFF6B5420),
                              fontSize: 12.5,
                              height: 1.4)),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () => _addBibleReading(context),
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: const Text('Add a verse',
                            style: TextStyle(
                                color: Color(0xFFB07A0F),
                                fontWeight: FontWeight.w800)),
                      ),
                    ]),
              ),
            ]),
          );
        }
        final streak = _readingStreak(
            bibleStore.items.map((r) => _dateOnly(r.readAt)).toSet());
        final verse = verses[_index % verses.length];
        return GestureDetector(
          onTap: widget.onOpen,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: KeyedSubtree(
              key: ValueKey(verse.id),
              child: _VerseCard(
                reading: verse,
                trailing: streak > 0
                    ? Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.local_fire_department_rounded,
                            color: kOrange, size: 18),
                        const SizedBox(width: 3),
                        Text('$streak day${streak == 1 ? '' : 's'}',
                            style: const TextStyle(
                                color: Color(0xFF8A6512),
                                fontSize: 12,
                                fontWeight: FontWeight.w800)),
                      ])
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BiblePage extends StatelessWidget {
  const _BiblePage();

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      child: ListenableBuilder(
        listenable: bibleStore,
        builder: (context, _) {
          final items = bibleStore.items;
          final days = items.map((r) => _dateOnly(r.readAt)).toSet();
          final streak = _readingStreak(days);
          final weekStart = _startOfWeek(DateTime.now());
          final thisWeek =
              items.where((r) => !r.readAt.isBefore(weekStart)).length;
          final withVerse =
              items.where((r) => r.verseText.trim().isNotEmpty).toList();
          final groups = <DateTime, List<BibleReading>>{};
          for (final r in items) {
            groups.putIfAbsent(_dateOnly(r.readAt), () => []).add(r);
          }
          final dayList = groups.keys.toList()..sort((a, b) => b.compareTo(a));
          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
            children: [
              _PageHeader(
                eyebrow: 'Daily reading',
                title: 'Bible',
                subtitle:
                    '$thisWeek chapter${thisWeek == 1 ? '' : 's'} this week · ${items.length} in total',
                action: IconButton.filled(
                  onPressed: () => _addBibleReading(context),
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'I read a chapter',
                ),
              ),
              const SizedBox(height: 20),
              _Reveal(
                index: 0,
                child: _ReadingHero(
                  streak: streak,
                  days: days,
                  onRead: () => _addBibleReading(context),
                ),
              ),
              if (withVerse.isNotEmpty) ...[
                const SizedBox(height: 16),
                _Reveal(
                  index: 1,
                  child: _VerseCard(
                      reading: withVerse.first, label: 'Latest verse'),
                ),
              ],
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Reading history'),
              const SizedBox(height: 10),
              if (bibleStore.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (bibleStore.error != null)
                _EmptyCard(
                  icon: Icons.cloud_off_rounded,
                  text: bibleStore.error!,
                  actionLabel: 'Try again',
                  onAction: bibleStore.load,
                )
              else if (items.isEmpty)
                _EmptyCard(
                  icon: Icons.menu_book_outlined,
                  text:
                      'No chapters yet. Read one today and save the verse that stays with you.',
                  actionLabel: 'I read a chapter',
                  onAction: () => _addBibleReading(context),
                )
              else
                ...dayList.map((day) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                        decoration: _cardDecoration(),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_relativeDay(day),
                                  style: const TextStyle(
                                      color: kInk,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              ...groups[day]!
                                  .map((r) => _ReadingTile(reading: r)),
                            ]),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class _ReadingHero extends StatelessWidget {
  const _ReadingHero(
      {required this.streak, required this.days, required this.onRead});

  final int streak;
  final Set<DateTime> days;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFE9A83B), Color(0xFFE8743B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFE8743B).withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 12))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.local_fire_department_rounded,
              color: Colors.white, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _CountUp(
                value: streak.toDouble(),
                format: (v) => '${v.round()} day streak',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5),
              ),
              Text(
                  streak == 0
                      ? 'Read a chapter today to start your streak.'
                      : 'Keep going. One chapter a day.',
                  style: const TextStyle(
                      color: Color(0xFFFFF0D9), fontSize: 12.5)),
            ]),
          ),
        ]),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(14, (i) {
            final day = _addDays(today, i - 13);
            final read = days.contains(day);
            return Column(children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: read ? Colors.white : Colors.white24),
                child: read
                    ? const Icon(Icons.check_rounded,
                        size: 12, color: Color(0xFFE8743B))
                    : null,
              ),
              const SizedBox(height: 4),
              Text('MTWTFSS'[day.weekday - 1],
                  style: const TextStyle(
                      color: Color(0xFFFFF0D9),
                      fontSize: 9,
                      fontWeight: FontWeight.w700)),
            ]);
          }),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFE8743B)),
            onPressed: onRead,
            icon: const Icon(Icons.menu_book_rounded),
            label: const Text('I read a chapter'),
          ),
        ),
      ]),
    );
  }
}

class _ReadingTile extends StatelessWidget {
  const _ReadingTile({required this.reading});

  final BibleReading reading;

  Future<void> _delete(BuildContext context) async {
    try {
      await bibleStore.remove(reading);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete that entry.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: kGoldSoft, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.menu_book_rounded, size: 17, color: kGold),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(reading.chapterTitle,
                    style: const TextStyle(
                        color: kInk,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800)),
              ),
              Text(_fmtTime(reading.readAt),
                  style: const TextStyle(color: kFaint, fontSize: 11)),
            ]),
            if (reading.verseText.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('“${reading.verseText}”',
                  style: const TextStyle(
                      color: Color(0xFF5A4A1E),
                      fontSize: 12.5,
                      height: 1.4,
                      fontStyle: FontStyle.italic)),
              if (reading.verseRef.isNotEmpty)
                Text(reading.reference,
                    style: const TextStyle(
                        color: Color(0xFF8A6512),
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
            ],
            if (reading.note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(reading.note,
                  style: const TextStyle(color: kMuted, fontSize: 12)),
            ],
          ]),
        ),
        IconButton(
            onPressed: () => _delete(context),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: kFaint,
            tooltip: 'Delete'),
      ]),
    );
  }
}

// ───────────────────────── Supabase ─────────────────────────
class TaskService {
  TaskService(this._client);

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated Supabase user.');
    }
    return user.id;
  }

  Future<List<TaskItem>> getTasks() async {
    final rows = await _client
        .from('tasks')
        .select(
            'id, title, area, priority, completed, due_date, created_at, completed_at')
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return rows
        .map(
          (row) => TaskItem(
            row['title'] as String,
            row['area'] as String,
            id: row['id'] as String,
            done: row['completed'] as bool,
            priority: row['priority'] as String,
            createdAt: DateTime.tryParse(row['created_at'] as String? ?? '')
                ?.toLocal(),
            completedAt: DateTime.tryParse(row['completed_at'] as String? ?? '')
                ?.toLocal(),
            dueDate: DateTime.tryParse(row['due_date'] as String? ?? ''),
          ),
        )
        .toList();
  }

  Future<TaskItem> createTask({
    required String title,
    String area = 'Personal',
    String priority = 'Medium',
  }) async {
    final row = await _client
        .from('tasks')
        .insert({
          'user_id': _userId,
          'title': title,
          'area': area,
          'priority': priority,
          'due_date': _isoDate(DateTime.now()),
        })
        .select(
            'id, title, area, priority, completed, due_date, created_at, completed_at')
        .single();

    return TaskItem(
      row['title'] as String,
      row['area'] as String,
      id: row['id'] as String,
      done: row['completed'] as bool,
      priority: row['priority'] as String,
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal(),
      completedAt:
          DateTime.tryParse(row['completed_at'] as String? ?? '')?.toLocal(),
      dueDate: DateTime.tryParse(row['due_date'] as String? ?? ''),
    );
  }

  Future<void> updateTask({
    required String id,
    bool? completed,
    String? title,
    String? area,
    String? priority,
  }) async {
    final changes = <String, dynamic>{};
    if (completed != null) {
      changes['completed'] = completed;
      changes['completed_at'] =
          completed ? DateTime.now().toUtc().toIso8601String() : null;
    }
    if (title != null) changes['title'] = title;
    if (area != null) changes['area'] = area;
    if (priority != null) changes['priority'] = priority;
    if (changes.isEmpty) return;

    await _client
        .from('tasks')
        .update(changes)
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> deleteTask(String id) async {
    await _client.from('tasks').delete().eq('id', id).eq('user_id', _userId);
  }
}
