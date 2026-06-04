import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/app_provider.dart';
import '../utils/theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _oldPassCtrl  = TextEditingController();
  final _newPassCtrl  = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _savingProfile  = false;
  bool _savingPassword = false;
  bool _uploadingPhoto = false;
  bool _obscureOld     = true;
  bool _obscureNew     = true;
  bool _obscureConf    = true;
  String? _profileError;
  String? _passwordError;
  String? _profileSuccess;
  String? _passwordSuccess;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppProvider>().appUser;
    _nameCtrl.text     = user?.displayName ?? '';
    _locationCtrl.text = user?.location ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _locationCtrl.dispose();
    _oldPassCtrl.dispose(); _newPassCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 75, maxWidth: 600);
    if (xFile == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final p   = context.read<AppProvider>();
      final uid = p.firebaseUser!.uid;
      final ref = FirebaseStorage.instance
          .ref('profile_photos/$uid.jpg');
      await ref.putFile(File(xFile.path));
      final url = await ref.getDownloadURL();
      await p.db.updateUser(uid, {'photoUrl': url});
      await p.firebaseUser!.updatePhotoURL(url);
      if (mounted) {
        setState(() => _uploadingPhoto = false);
        _showSnack('Profile photo updated!', success: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
        _showSnack('Upload failed: $e');
      }
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _profileError = 'Name cannot be empty'); return;
    }
    setState(() { _savingProfile = true; _profileError = null; _profileSuccess = null; });
    try {
      final p   = context.read<AppProvider>();
      final uid = p.firebaseUser!.uid;
      await p.db.updateUser(uid, {
        'displayName': name,
        'location':    _locationCtrl.text.trim(),
      });
      await p.firebaseUser!.updateDisplayName(name);
      if (mounted) setState(() {
        _savingProfile = false;
        _profileSuccess = 'Profile updated successfully!';
      });
    } catch (e) {
      if (mounted) setState(() {
        _savingProfile = false;
        _profileError = 'Update failed: $e';
      });
    }
  }

  Future<void> _changePassword() async {
    final oldPass  = _oldPassCtrl.text;
    final newPass  = _newPassCtrl.text;
    final confPass = _confirmCtrl.text;

    if (oldPass.isEmpty || newPass.isEmpty) {
      setState(() => _passwordError = 'All fields required'); return;
    }
    if (newPass.length < 6) {
      setState(() => _passwordError = 'Min 6 characters'); return;
    }
    if (newPass != confPass) {
      setState(() => _passwordError = 'Passwords do not match'); return;
    }

    setState(() { _savingPassword = true; _passwordError = null; _passwordSuccess = null; });
    try {
      final p = context.read<AppProvider>();
      await p.reauthenticate(oldPass);
      await p.changePassword(newPass);
      if (mounted) {
        setState(() {
          _savingPassword = false;
          _passwordSuccess = 'Password changed successfully!';
        });
        _oldPassCtrl.clear(); _newPassCtrl.clear(); _confirmCtrl.clear();
      }
    } catch (e) {
      if (mounted) setState(() {
        _savingPassword = false;
        _passwordError  = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? AppColors.primary : AppColors.accent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final appUser = context.watch<AppProvider>().appUser;
    final fbUser  = context.read<AppProvider>().firebaseUser;
    final photoUrl = appUser?.photoUrl ?? fbUser?.photoURL;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Avatar ──────────────────────────────────────────────────
          Center(
            child: Stack(children: [
              GestureDetector(
                onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                child: Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                    boxShadow: [BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 12)],
                  ),
                  child: ClipOval(child: _uploadingPhoto
                      ? const Center(child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary))
                      : photoUrl != null
                          ? CachedNetworkImage(imageUrl: photoUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                              errorWidget: (_, __, ___) =>
                                  _AvatarFallback(name: appUser?.displayName ?? ''))
                          : _AvatarFallback(name: appUser?.displayName ?? '')),
                ),
              ),
              Positioned(bottom: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 14),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 6),
          const Center(child: Text('Tap to change photo',
              style: TextStyle(fontSize: 12, color: AppColors.gray400))),
          const SizedBox(height: 24),

          // ── Profile Info ──────────────────────────────────────────────
          _SectionCard(
            title: 'Personal Information',
            icon: Icons.person_outline_rounded,
            children: [
              _buildField('Full Name', _nameCtrl,
                  icon: Icons.badge_outlined,
                  hint: 'Your full name'),
              const SizedBox(height: 12),
              _buildField('Location', _locationCtrl,
                  icon: Icons.location_on_outlined,
                  hint: 'e.g. Bole, Addis Ababa'),
              const SizedBox(height: 6),
              // Email (read-only)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x1A000000), width: 0.5)),
                child: Row(children: [
                  const Icon(Icons.email_outlined, color: AppColors.gray400, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(fbUser?.email ?? '',
                      style: const TextStyle(fontSize: 14, color: AppColors.gray400))),
                  const Text('Not editable',
                      style: TextStyle(fontSize: 11, color: AppColors.gray400)),
                ]),
              ),
              if (_profileError != null) ...[
                const SizedBox(height: 8),
                _ErrorBanner(msg: _profileError!),
              ],
              if (_profileSuccess != null) ...[
                const SizedBox(height: 8),
                _SuccessBanner(msg: _profileSuccess!),
              ],
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _savingProfile ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
                child: _savingProfile
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('Save Profile'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Stats ─────────────────────────────────────────────────────
          _SectionCard(
            title: 'Activity Stats',
            icon: Icons.bar_chart_rounded,
            children: [
              Row(children: [
                _StatTile('Reports', '${appUser?.reportCount ?? 0}',
                    AppColors.primary, Icons.receipt_long_rounded),
                const SizedBox(width: 8),
                _StatTile('Verified', '${appUser?.verifyCount ?? 0}',
                    AppColors.blue, Icons.verified_rounded),
                const SizedBox(width: 8),
                _StatTile('Points',   '${appUser?.points ?? 0}',
                    AppColors.amber, Icons.star_rounded),
              ]),
            ],
          ),
          const SizedBox(height: 16),

          // ── Change Password ───────────────────────────────────────────
          _SectionCard(
            title: 'Change Password',
            icon: Icons.lock_outline_rounded,
            children: [
              _buildPassField('Current password', _oldPassCtrl,
                  obs: _obscureOld,
                  toggle: () => setState(() => _obscureOld = !_obscureOld)),
              const SizedBox(height: 12),
              _buildPassField('New password', _newPassCtrl,
                  obs: _obscureNew,
                  toggle: () => setState(() => _obscureNew = !_obscureNew),
                  hint: 'Min 6 characters'),
              const SizedBox(height: 12),
              _buildPassField('Confirm new password', _confirmCtrl,
                  obs: _obscureConf,
                  toggle: () => setState(() => _obscureConf = !_obscureConf)),
              if (_passwordError != null) ...[
                const SizedBox(height: 8),
                _ErrorBanner(msg: _passwordError!),
              ],
              if (_passwordSuccess != null) ...[
                const SizedBox(height: 8),
                _SuccessBanner(msg: _passwordSuccess!),
              ],
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _savingPassword ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: AppColors.gray800),
                child: _savingPassword
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('Update Password'),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {required IconData icon, String? hint}) =>
      TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 18, color: AppColors.gray400),
        ),
      );

  Widget _buildPassField(String label, TextEditingController ctrl,
      {required bool obs, required VoidCallback toggle, String? hint}) =>
      TextField(
        controller: ctrl,
        obscureText: obs,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: const Icon(Icons.lock_outline_rounded,
              size: 18, color: AppColors.gray400),
          suffixIcon: IconButton(
            icon: Icon(obs ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 18, color: AppColors.gray400),
            onPressed: toggle,
          ),
        ),
      );
}

class _AvatarFallback extends StatelessWidget {
  final String name;
  const _AvatarFallback({required this.name});
  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    return Container(
      color: AppColors.primaryLight,
      child: Center(child: Text(
        initials.isEmpty ? '?' : initials,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
            color: AppColors.primaryDark),
      )),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title; final IconData icon; final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.children});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0x14000000), width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 14),
      const Divider(height: 0),
      const SizedBox(height: 14),
      ...children,
    ]),
  );
}

class _StatTile extends StatelessWidget {
  final String label, value; final Color color; final IconData icon;
  const _StatTile(this.label, this.value, this.color, this.icon);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18,
            fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(
            fontSize: 10, color: AppColors.gray400)),
      ]),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String msg;
  const _ErrorBanner({required this.msg});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded,
          color: AppColors.accent, size: 16),
      const SizedBox(width: 6),
      Expanded(child: Text(msg, style: const TextStyle(
          fontSize: 12, color: AppColors.accent))),
    ]),
  );
}

class _SuccessBanner extends StatelessWidget {
  final String msg;
  const _SuccessBanner({required this.msg});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      const Icon(Icons.check_circle_outline_rounded,
          color: AppColors.primary, size: 16),
      const SizedBox(width: 6),
      Expanded(child: Text(msg, style: const TextStyle(
          fontSize: 12, color: AppColors.primaryDark))),
    ]),
  );
}
