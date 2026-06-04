import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../utils/theme.dart';

/// Shown to the default super-admin on first login so they immediately
/// replace the hardcoded password.
class ChangeDefaultPasswordScreen extends StatefulWidget {
  const ChangeDefaultPasswordScreen({super.key});

  @override
  State<ChangeDefaultPasswordScreen> createState() =>
      _ChangeDefaultPasswordScreenState();
}

class _ChangeDefaultPasswordScreenState
    extends State<ChangeDefaultPasswordScreen> {
  final _newCtrl  = TextEditingController();
  final _confCtrl = TextEditingController();
  bool   _loading  = false;
  bool   _obscure1 = true;
  bool   _obscure2 = true;
  String? _error;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final newPass  = _newCtrl.text.trim();
    final confPass = _confCtrl.text.trim();

    if (newPass.isEmpty) {
      setState(() => _error = 'Enter a new password'); return;
    }
    if (newPass.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters'); return;
    }
    if (newPass == 'Admin@FairPrice2025') {
      setState(() => _error = 'Please choose a different password from the default'); return;
    }
    if (newPass != confPass) {
      setState(() => _error = 'Passwords do not match'); return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final p = context.read<AppProvider>();
      // Reauthenticate with the default password first
      await p.reauthenticate('Admin@FairPrice2025');
      await p.changePassword(newPass);

      // Mark password changed in Firestore so we don't show this screen again
      final uid = p.firebaseUser!.uid;
      await p.db.updateUser(uid, {'defaultPasswordChanged': true});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Password updated successfully!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ));
        // Pop — AdminShell will render normally
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error   = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // cannot dismiss
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(28),
            children: [
              const SizedBox(height: 24),

              // Warning header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.accent, Color(0xFFB03A1A)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: AppColors.accent.withOpacity(0.3),
                      blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: const Column(children: [
                  Icon(Icons.security_rounded, color: Colors.white, size: 48),
                  SizedBox(height: 12),
                  Text('Security Action Required',
                      style: TextStyle(color: Colors.white, fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: 6),
                  Text(
                    'You are using the default super-admin password. '
                    'You must change it before accessing the admin panel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                ]),
              ),
              const SizedBox(height: 28),

              // Current credentials info box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: AppColors.amberLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.amber.withOpacity(0.4))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Row(children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppColors.amber, size: 16),
                    SizedBox(width: 6),
                    Text('Current default credentials',
                        style: TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w700, color: AppColors.amber)),
                  ]),
                  const SizedBox(height: 8),
                  _CredRow('Email',    'admin@fairprice.et'),
                  const SizedBox(height: 4),
                  _CredRow('Password', 'Admin@FairPrice2025'),
                  const SizedBox(height: 8),
                  const Text(
                    '⚠️  Never share these credentials. '
                    'Store your new password securely.',
                    style: TextStyle(fontSize: 11, color: AppColors.amber)),
                ]),
              ),
              const SizedBox(height: 24),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!,
                        style: const TextStyle(
                            color: AppColors.accent, fontSize: 13))),
                  ]),
                ),
                const SizedBox(height: 14),
              ],

              _Label('New Password'),
              TextField(
                controller: _newCtrl,
                obscureText: _obscure1,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'Min 8 characters',
                  prefixIcon: const Icon(Icons.lock_rounded,
                      color: AppColors.gray400, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure1
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                        color: AppColors.gray400, size: 20),
                    onPressed: () => setState(() => _obscure1 = !_obscure1),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              _Label('Confirm New Password'),
              TextField(
                controller: _confCtrl,
                obscureText: _obscure2,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Re-enter new password',
                  prefixIcon: const Icon(Icons.lock_rounded,
                      color: AppColors.gray400, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure2
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                        color: AppColors.gray400, size: 20),
                    onPressed: () => setState(() => _obscure2 = !_obscure2),
                  ),
                ),
              ),

              // Password strength tips
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(10)),
                child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Strong password tips:',
                      style: TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w600, color: AppColors.gray400)),
                  SizedBox(height: 6),
                  _Tip('✅ At least 8 characters'),
                  _Tip('✅ Mix of UPPERCASE and lowercase'),
                  _Tip('✅ Include numbers (0–9)'),
                  _Tip('✅ Use special characters (!@#\$%^&*)'),
                  _Tip('❌ Do not reuse old passwords'),
                ]),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(width: 24, height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_reset_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Update Password & Enter Admin Panel',
                              style: TextStyle(fontSize: 15)),
                        ]),
              ),
              const SizedBox(height: 12),

              // Sign out option
              Center(child: TextButton.icon(
                onPressed: () => context.read<AppProvider>().signOut(),
                icon: const Icon(Icons.logout_rounded,
                    color: AppColors.gray400, size: 16),
                label: const Text('Sign out instead',
                    style: TextStyle(color: AppColors.gray400, fontSize: 13)),
              )),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w600)),
  );
}

class _CredRow extends StatelessWidget {
  final String label, value;
  const _CredRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(children: [
    SizedBox(width: 68,
        child: Text('$label:', style: const TextStyle(
            fontSize: 12, color: AppColors.amber))),
    Expanded(child: Text(value, style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: AppColors.amber, fontFamily: 'monospace'))),
  ]);
}

class _Tip extends StatelessWidget {
  final String text;
  const _Tip(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Text(text, style: const TextStyle(
        fontSize: 11, color: AppColors.gray400)),
  );
}
