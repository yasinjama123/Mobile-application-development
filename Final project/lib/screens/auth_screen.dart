import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../utils/theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
// LOGIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill all fields'); return;
    }
    setState(() { _loading = true; _error = null; });
    final err = await context.read<AppProvider>()
        .signIn(_emailCtrl.text.trim(), _passCtrl.text);
    if (mounted) setState(() { _loading = false; _error = err; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 32),
            _Logo(),
            const SizedBox(height: 40),
            const Text('Welcome back', style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            const Text('Sign in to track prices near you',
                style: TextStyle(fontSize: 14, color: AppColors.gray400)),
            const SizedBox(height: 32),
            if (_error != null) ...[_ErrorBanner(_error!), const SizedBox(height: 14)],
            _FieldLabel('Email address'),
            TextField(controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.gray400, size: 20))),
            const SizedBox(height: 14),
            _FieldLabel('Password'),
            TextField(controller: _passCtrl, obscureText: _obscure,
                textInputAction: TextInputAction.done, onSubmitted: (_) => _submit(),
                decoration: InputDecoration(hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.gray400, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.gray400, size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure)))),
            Align(alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen())),
                    child: const Text('Forgot password?',
                        style: TextStyle(color: AppColors.primary, fontSize: 13)))),
            const SizedBox(height: 8),
            ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _loading ? const _Spinner()
                    : const Text('Sign In', style: TextStyle(fontSize: 16))),
            const SizedBox(height: 28),
            const Row(children: [Expanded(child: Divider()),
              Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text("New to FairPrice?",
                      style: TextStyle(fontSize: 12, color: AppColors.gray400))),
              Expanded(child: Divider())]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _AccountTypeCard(
                  icon: Icons.person_rounded, title: 'User',
                  subtitle: 'Track & report prices', color: AppColors.primary,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen())))),
              const SizedBox(width: 12),
              Expanded(child: _AccountTypeCard(
                  icon: Icons.admin_panel_settings_rounded, title: 'Admin',
                  subtitle: 'Requires approval', color: AppColors.amber,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AdminRequestScreen())))),
            ]),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// USER SIGN-UP
// ═══════════════════════════════════════════════════════════════════════════

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _agreed  = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill all required fields'); return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match'); return;
    }
    if (_passCtrl.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters'); return;
    }
    if (!_agreed) {
      setState(() => _error = 'Please agree to the terms'); return;
    }
    setState(() { _loading = true; _error = null; });
    final err = await context.read<AppProvider>().signUpUser(
        _emailCtrl.text.trim(), _passCtrl.text, _nameCtrl.text.trim());
    if (mounted) setState(() { _loading = false; _error = err; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create User Account'),
          backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
        Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14)),
            child: const Row(children: [
              Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('User Account', style: TextStyle(fontSize: 15,
                    fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                Text('Track prices, report deals, earn community points',
                    style: TextStyle(fontSize: 12, color: AppColors.primary)),
              ])),
            ])),
        const SizedBox(height: 24),
        if (_error != null) ...[_ErrorBanner(_error!), const SizedBox(height: 14)],
        _FieldLabel('Full Name *'),
        TextField(controller: _nameCtrl, textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'Your full name',
                prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.gray400, size: 20))),
        const SizedBox(height: 14),
        _FieldLabel('Email Address *'),
        TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'you@example.com',
                prefixIcon: Icon(Icons.email_outlined, color: AppColors.gray400, size: 20))),
        const SizedBox(height: 14),
        _FieldLabel('Password *'),
        TextField(controller: _passCtrl, obscureText: _obscure,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(hintText: 'Min 6 characters',
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.gray400, size: 20),
                suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.gray400, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure)))),
        const SizedBox(height: 14),
        _FieldLabel('Confirm Password *'),
        TextField(controller: _confirmCtrl, obscureText: true,
            textInputAction: TextInputAction.done, onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(hintText: 'Re-enter password',
                prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.gray400, size: 20))),
        const SizedBox(height: 16),
        GestureDetector(onTap: () => setState(() => _agreed = !_agreed),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Checkbox(value: _agreed, activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _agreed = v ?? false)),
              const Expanded(child: Padding(padding: EdgeInsets.only(top: 12),
                  child: Text('I agree to the Terms of Service. My price reports will be visible to the community.',
                      style: TextStyle(fontSize: 12, color: AppColors.gray400, height: 1.4)))),
            ])),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: _loading ? const _Spinner()
                : const Text('Create Account', style: TextStyle(fontSize: 16))),
        const SizedBox(height: 16),
        Center(child: TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Already have an account? Sign in',
                style: TextStyle(color: AppColors.primary)))),
        const SizedBox(height: 32),
      ])),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ADMIN REQUEST SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class AdminRequestScreen extends StatefulWidget {
  const AdminRequestScreen({super.key});
  @override
  State<AdminRequestScreen> createState() => _AdminRequestScreenState();
}

class _AdminRequestScreenState extends State<AdminRequestScreen> {
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _orgCtrl     = TextEditingController();
  final _reasonCtrl  = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading  = false;
  bool _obscure  = true;
  bool _agreed   = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _orgCtrl.dispose();
    _reasonCtrl.dispose(); _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty ||
        _orgCtrl.text.trim().isEmpty || _reasonCtrl.text.trim().isEmpty ||
        _passCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill all required fields'); return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match'); return;
    }
    if (_passCtrl.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters'); return;
    }
    if (_reasonCtrl.text.trim().length < 30) {
      setState(() => _error = 'Please provide a more detailed reason (min 30 chars)'); return;
    }
    if (!_agreed) {
      setState(() => _error = 'Please agree to the terms'); return;
    }
    setState(() { _loading = true; _error = null; });
    final err = await context.read<AppProvider>().requestAdminAccount(
      email: _emailCtrl.text.trim(), password: _passCtrl.text,
      name: _nameCtrl.text.trim(), reason: _reasonCtrl.text.trim(),
      organization: _orgCtrl.text.trim(),
    );
    if (mounted) {
      if (err != null) setState(() { _loading = false; _error = err; });
      else setState(() { _loading = false; _submitted = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _PendingScreen(name: _nameCtrl.text.trim());
    return Scaffold(
      appBar: AppBar(title: const Text('Request Admin Account'),
          backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
        // Warning header
        Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.amberLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.amber.withOpacity(0.3))),
            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.admin_panel_settings_rounded, color: AppColors.amber, size: 28),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Admin Account Request', style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.amber)),
                SizedBox(height: 4),
                Text('Requires approval from an existing administrator. '
                    'You will receive limited access until approved.',
                    style: TextStyle(fontSize: 12, color: AppColors.amber, height: 1.4)),
              ])),
            ])),
        const SizedBox(height: 16),
        // Privileges list
        Container(padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.gray50,
                borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Admin privileges include:', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray800)),
              const SizedBox(height: 8),
              ...['✅ Manage all products and shops',
                '✅ Approve or reject admin requests',
                '✅ Ban / unban users',
                '✅ Delete inappropriate reports',
                '✅ View platform analytics']
                  .map((s) => Padding(padding: const EdgeInsets.only(bottom: 4),
                  child: Text(s, style: const TextStyle(fontSize: 12, color: AppColors.gray400)))),
            ])),
        const SizedBox(height: 24),
        if (_error != null) ...[_ErrorBanner(_error!), const SizedBox(height: 14)],
        _FieldLabel('Full Name *'),
        TextField(controller: _nameCtrl, textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'Your full name',
                prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.gray400, size: 20))),
        const SizedBox(height: 14),
        _FieldLabel('Email Address *'),
        TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'your@email.com',
                prefixIcon: Icon(Icons.email_outlined, color: AppColors.gray400, size: 20))),
        const SizedBox(height: 14),
        _FieldLabel('Organization / Institution *'),
        TextField(controller: _orgCtrl, textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
                hintText: 'e.g. Addis Ababa University, Ministry of Trade',
                prefixIcon: Icon(Icons.business_outlined, color: AppColors.gray400, size: 20))),
        const SizedBox(height: 14),
        _FieldLabel('Why do you need admin access? * (min 30 characters)'),
        TextField(controller: _reasonCtrl, maxLines: 4, maxLength: 500,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
                hintText: 'Describe your role and why you need admin access to FairPrice.',
                alignLabelWithHint: true)),
        const SizedBox(height: 14),
        _FieldLabel('Password *'),
        TextField(controller: _passCtrl, obscureText: _obscure,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(hintText: 'Min 6 characters',
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.gray400, size: 20),
                suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.gray400, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure)))),
        const SizedBox(height: 14),
        _FieldLabel('Confirm Password *'),
        TextField(controller: _confirmCtrl, obscureText: true,
            textInputAction: TextInputAction.done, onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(hintText: 'Re-enter password',
                prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.gray400, size: 20))),
        const SizedBox(height: 16),
        GestureDetector(onTap: () => setState(() => _agreed = !_agreed),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Checkbox(value: _agreed, activeColor: AppColors.amber,
                  onChanged: (v) => setState(() => _agreed = v ?? false)),
              const Expanded(child: Padding(padding: EdgeInsets.only(top: 12),
                  child: Text('I confirm the information above is accurate. '
                      'Submitting false information may result in a permanent ban.',
                      style: TextStyle(fontSize: 12, color: AppColors.gray400, height: 1.4)))),
            ])),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.amber,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: _loading ? const _Spinner()
                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.send_rounded, size: 18), SizedBox(width: 8),
                  Text('Submit Admin Request', style: TextStyle(fontSize: 16))])),
        const SizedBox(height: 16),
        Center(child: TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Already have an account? Sign in',
                style: TextStyle(color: AppColors.primary)))),
        const SizedBox(height: 32),
      ])),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PENDING APPROVAL SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class _PendingScreen extends StatelessWidget {
  final String name;
  const _PendingScreen({required this.name});
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 100, height: 100,
              decoration: BoxDecoration(color: AppColors.amberLight,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.amber.withOpacity(0.3), blurRadius: 20)]),
              child: const Icon(Icons.hourglass_top_rounded, color: AppColors.amber, size: 50)),
          const SizedBox(height: 24),
          Text('Hi, ${name.split(' ').first}! 👋', style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          const Text('Your admin request is pending review',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.amberLight,
                  borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                _StepRow(icon: Icons.check_circle_rounded,
                    label: 'Account created', done: true),
                const SizedBox(height: 8),
                _StepRow(icon: Icons.hourglass_top_rounded,
                    label: 'Awaiting admin review', done: false, active: true),
                const SizedBox(height: 8),
                _StepRow(icon: Icons.admin_panel_settings_rounded,
                    label: 'Admin access granted', done: false),
              ])),
          const SizedBox(height: 20),
          const Text(
            'An administrator will review your request shortly.\n'
            'You will receive a notification when approved.\n\n'
            'In the meantime you can use FairPrice as a regular user.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.gray400, height: 1.5)),
          const SizedBox(height: 28),
          ElevatedButton(onPressed: () {},
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('Continue as User', style: TextStyle(fontSize: 16))),
          const SizedBox(height: 12),
          TextButton(onPressed: () => context.read<AppProvider>().signOut(),
              child: const Text('Sign out',
                  style: TextStyle(color: AppColors.gray400))),
        ]),
      ))),
    );
  }
}

class _StepRow extends StatelessWidget {
  final IconData icon; final String label; final bool done; final bool active;
  const _StepRow({required this.icon, required this.label,
      required this.done, this.active = false});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 20, color: done ? AppColors.primary
        : active ? AppColors.amber : AppColors.gray400),
    const SizedBox(width: 10),
    Text(label, style: TextStyle(fontSize: 13,
        fontWeight: active || done ? FontWeight.w600 : FontWeight.normal,
        color: done ? AppColors.primaryDark
            : active ? AppColors.amber : AppColors.gray400)),
  ]);
}

// ═══════════════════════════════════════════════════════════════════════════
// PENDING ADMIN BANNER (shown inside app when role == pending_admin)
// ═══════════════════════════════════════════════════════════════════════════

class PendingAdminBanner extends StatelessWidget {
  const PendingAdminBanner({super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.amberLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amber.withOpacity(0.4))),
    child: Row(children: [
      const Icon(Icons.hourglass_top_rounded, color: AppColors.amber, size: 20),
      const SizedBox(width: 10),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Admin Request Pending', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.amber)),
        Text('Awaiting approval from an existing admin.',
            style: TextStyle(fontSize: 11, color: AppColors.amber)),
      ])),
      TextButton(onPressed: () => context.read<AppProvider>().signOut(),
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: const Text('Sign out',
              style: TextStyle(fontSize: 11, color: AppColors.amber))),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// FORGOT PASSWORD
// ═══════════════════════════════════════════════════════════════════════════

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false; bool _sent = false; String? _error;
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  Future<void> _submit() async {
    if (_ctrl.text.trim().isEmpty) { setState(() => _error = 'Enter your email'); return; }
    setState(() { _loading = true; _error = null; });
    final err = await context.read<AppProvider>().resetPassword(_ctrl.text.trim());
    if (mounted) setState(() { _loading = false; _error = err; _sent = err == null; });
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reset Password'),
        backgroundColor: Colors.transparent, elevation: 0),
    body: SafeArea(child: Padding(padding: const EdgeInsets.all(24),
      child: _sent
          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.mark_email_read_outlined, color: AppColors.primary, size: 64),
              const SizedBox(height: 20),
              const Text('Email Sent!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text('Reset link sent to ${_ctrl.text}', textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.gray400)),
              const SizedBox(height: 28),
              ElevatedButton(onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  child: const Text('Back to Sign In')),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 12),
              const Text('Enter your email and we\'ll send a reset link.',
                  style: TextStyle(fontSize: 14, color: AppColors.gray400, height: 1.5)),
              const SizedBox(height: 24),
              if (_error != null) ...[_ErrorBanner(_error!), const SizedBox(height: 14)],
              _FieldLabel('Email address'),
              TextField(controller: _ctrl, keyboardType: TextInputType.emailAddress,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(hintText: 'you@example.com',
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.gray400, size: 20))),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  child: _loading ? const _Spinner() : const Text('Send Reset Link')),
            ]),
    )),
  );
}

// ─── Shared helpers ────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 48, height: 48,
        decoration: BoxDecoration(color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35),
                blurRadius: 16, offset: const Offset(0, 6))]),
        child: const Icon(Icons.currency_exchange_rounded, color: Colors.white, size: 26)),
    const SizedBox(width: 12),
    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('FairPrice', style: TextStyle(fontSize: 22,
          fontWeight: FontWeight.w800, letterSpacing: -0.4)),
      Text('BirrWise · Price Tracker',
          style: TextStyle(fontSize: 12, color: AppColors.gray400)),
    ]),
  ]);
}

class _AccountTypeCard extends StatelessWidget {
  final IconData icon; final String title, subtitle; final Color color; final VoidCallback onTap;
  const _AccountTypeCard({required this.icon, required this.title, required this.subtitle,
      required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25), width: 1)),
        child: Column(children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22)),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.gray400),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
              child: const Text('Sign Up', style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white))),
        ])),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)));
}

class _ErrorBanner extends StatelessWidget {
  final String msg;
  const _ErrorBanner(this.msg);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: AppColors.accent, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(color: AppColors.accent, fontSize: 13))),
    ]),
  );
}

class _Spinner extends StatelessWidget {
  const _Spinner();
  @override
  Widget build(BuildContext context) => const SizedBox(width: 22, height: 22,
      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white));
}
