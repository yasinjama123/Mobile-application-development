import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/app_provider.dart';
import '../utils/theme.dart';
import 'shopping_list_screen.dart';
import 'favorites_screen.dart';
import 'leaderboard_screen.dart';
import 'top_deals_screen.dart';
import 'edit_profile_screen.dart';
import 'admin_screen.dart'; // exports AdminShell
import '../main.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.appUser;
    final fbUser = provider.firebaseUser;
    final photoUrl = user?.photoUrl ?? fbUser?.photoURL;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero AppBar ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EditProfileScreen())),
              ),
              if (user?.isAdmin == true)
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.white),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminShell())), // FIXED
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const EditProfileScreen())),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 12)
                            ],
                          ),
                          child: ClipOval(
                            child: photoUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: photoUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) =>
                                        const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                    errorWidget: (_, __, ___) =>
                                        _AvatarFallback(
                                            name: user?.displayName ?? ''),
                                  )
                                : _AvatarFallback(
                                    name: user?.displayName ?? ''),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(user?.displayName ?? fbUser?.displayName ?? 'User',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.3)),
                      const SizedBox(height: 3),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.email_outlined,
                                size: 12, color: Colors.white60),
                            const SizedBox(width: 4),
                            Text(user?.email ?? fbUser?.email ?? '',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white70)),
                          ]),
                      if (user?.location != null) ...[
                        const SizedBox(height: 2),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 12, color: Colors.white60),
                              const SizedBox(width: 3),
                              Text(user!.location!,
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.white60)),
                            ]),
                      ],
                      const SizedBox(height: 6),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (user?.isAdmin == true)
                              _HeroBadge('Admin', AppColors.amber),
                            if (user?.banned == true)
                              _HeroBadge('Banned', AppColors.accent),
                            _HeroBadge('Group 5 · AAU MAD',
                                Colors.white.withOpacity(0.2)),
                          ]),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(children: [
                    _StatBox(
                        label: 'Reports',
                        value: '${user?.reportCount ?? 0}',
                        color: AppColors.primary),
                    const SizedBox(width: 8),
                    _StatBox(
                        label: 'Verified',
                        value: '${user?.verifyCount ?? 0}',
                        color: AppColors.blue),
                    const SizedBox(width: 8),
                    _StatBox(
                        label: 'Points',
                        value: '${user?.points ?? 0}',
                        color: AppColors.amber),
                    const SizedBox(width: 8),
                    _StatBox(
                        label: 'Badges', value: '3', color: AppColors.accent),
                  ]),
                  const SizedBox(height: 20),

                  // Points progress
                  _PointsProgressCard(points: user?.points ?? 0),
                  const SizedBox(height: 20),

                  // Quick Links
                  _SectionLabel('Quick Access'),
                  _MenuCard(children: [
                    _MenuTile(
                      icon: Icons.edit_rounded,
                      label: 'Edit Profile',
                      subtitle: 'Update name, photo & location',
                      color: AppColors.primary,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EditProfileScreen())),
                    ),
                    const Divider(indent: 52),
                    _MenuTile(
                      icon: Icons.favorite_outlined,
                      label: 'Favorite Products',
                      subtitle: 'Your saved products',
                      color: AppColors.accent,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const FavoritesScreen())),
                    ),
                    const Divider(indent: 52),
                    _MenuTile(
                      icon: Icons.shopping_cart_outlined,
                      label: 'Shopping List',
                      subtitle: 'Your grocery checklist',
                      color: AppColors.blue,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ShoppingListScreen())),
                    ),
                    const Divider(indent: 52),
                    _MenuTile(
                      icon: Icons.emoji_events_outlined,
                      label: 'Leaderboard',
                      subtitle: 'Community rankings',
                      color: AppColors.amber,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LeaderboardScreen())),
                    ),
                    const Divider(indent: 52),
                    _MenuTile(
                      icon: Icons.local_offer_outlined,
                      label: 'Top Deals',
                      subtitle: 'Cheapest products today',
                      color: AppColors.primary,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TopDealsScreen())),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Settings
                  _SectionLabel('Settings'),
                  _MenuCard(children: [
                    // Dark Mode
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                              color: AppColors.gray800.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.dark_mode_outlined,
                              color: AppColors.gray800, size: 18),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('Dark Mode', style: TextStyle(fontSize: 14)),
                              Text('Switch to dark theme',
                                  style: TextStyle(
                                      fontSize: 12, color: AppColors.gray400)),
                            ])),
                        Switch.adaptive(
                          value: provider.darkMode,
                          onChanged: provider.toggleDarkMode,
                          activeColor: AppColors.primary,
                        ),
                      ]),
                    ),
                    const Divider(indent: 52),
                    // Language
                    _MenuTile(
                      icon: Icons.language_rounded,
                      label: 'Language',
                      subtitle: provider.locale.languageCode == 'am'
                          ? 'አማርኛ (Amharic)'
                          : 'English',
                      color: AppColors.blue,
                      onTap: () => _showLanguagePicker(context, provider),
                    ),
                    const Divider(indent: 52),
                    _MenuTile(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      subtitle: 'FCM push alerts configured',
                      color: AppColors.amber,
                      onTap: () {},
                      trailing: _Badge('Active', AppColors.primary),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Admin section
                  if (user?.isAdmin == true) ...[
                    _SectionLabel('Administration'),
                    _MenuCard(children: [
                      _MenuTile(
                        icon: Icons.admin_panel_settings_rounded,
                        label: 'Admin Panel',
                        subtitle: 'Manage users, products & reports',
                        color: AppColors.primary,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminShell())), // FIXED
                        trailing: _Badge('Admin', AppColors.primary),
                      ),
                    ]),
                    const SizedBox(height: 16),
                  ],

                  // About
                  _SectionLabel('About'),
                  _MenuCard(children: [
                    _MenuTile(
                      icon: Icons.info_outline_rounded,
                      label: 'About FairPrice',
                      subtitle: 'v1.0.0 · Firebase · Flutter',
                      color: AppColors.gray400,
                      onTap: () => _showAbout(context),
                    ),
                    const Divider(indent: 52),
                    _MenuTile(
                      icon: Icons.people_outline_rounded,
                      label: 'Group 5 — Team',
                      subtitle: 'AAU Mobile App Dev · 2025/2026',
                      color: AppColors.amber,
                      onTap: () => _showTeam(context),
                    ),
                    const Divider(indent: 52),
                    _MenuTile(
                      icon: Icons.cloud_outlined,
                      label: 'Firebase Status',
                      subtitle: 'Auth + Firestore + Storage + FCM',
                      color: AppColors.primary,
                      onTap: () {},
                      trailing: _Badge('Live 🔥', AppColors.primary),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Sign out
                  OutlinedButton.icon(
                    onPressed: () => _confirmSignOut(context, provider),
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.accent, size: 18),
                    label: const Text('Sign Out',
                        style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: AppColors.accent, width: 1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  void _showLanguagePicker(BuildContext ctx, AppProvider p) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Select Language',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
            title: const Text('English'),
            trailing: p.locale.languageCode == 'en'
                ? const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary)
                : null,
            onTap: () {
              p.setLocale('en');
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Text('🇪🇹', style: TextStyle(fontSize: 24)),
            title: const Text('አማርኛ (Amharic)'),
            trailing: p.locale.languageCode == 'am'
                ? const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary)
                : null,
            onTap: () {
              p.setLocale('am');
              Navigator.pop(ctx);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showAbout(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Text('🏷️', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Text('FairPrice / BirrWise'),
        ]),
        content: const Text(
          'A crowdsourced product price transparency app for Ethiopian consumers.\n\n'
          '🔥 Firebase: Auth · Firestore · Storage · FCM\n'
          '🗺️ Maps: OpenStreetMap via flutter_map\n'
          '📊 Charts: fl_chart\n'
          '📱 Built with Flutter & Dart\n\n'
          'Group 5 · AAU Mobile App Dev · 2025/2026',
          style: TextStyle(fontSize: 13, color: AppColors.gray400, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close',
                  style: TextStyle(color: AppColors.primary)))
        ],
      ),
    );
  }

  void _showTeam(BuildContext ctx) {
    const members = [
      ('Getamesay Hailemichael', 'Developer', '🛠️', 'ATE/5152/13'),
      ('Sisay Leykun', 'UI/UX Designer', '🎨', 'ATE/0493/15'),
      ('Tamrat Arage', 'Tester', '🧪', 'ATE/8888/15'),
      ('Yasin Jama', 'Team Leader', '👑', 'ATE/4368/15'),
    ];
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Group 5 — Team',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('AAU Mobile App Dev · Sem 2, 2025/2026',
              style: TextStyle(fontSize: 12, color: AppColors.gray400)),
          const SizedBox(height: 16),
          ...members.map((m) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        color: AppColors.primaryLight, shape: BoxShape.circle),
                    child: Center(
                        child:
                            Text(m.$3, style: const TextStyle(fontSize: 18)))),
                title: Text(m.$1,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                subtitle: Text('${m.$2} · ${m.$4}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.gray400)),
              )),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext ctx, AppProvider p) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (ok == true) await p.signOut();
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────

class _AvatarFallback extends StatelessWidget {
  final String name;
  const _AvatarFallback({required this.name});
  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : '?';
    return Container(
      color: Colors.white.withOpacity(0.2),
      child: Center(
          child: Text(initials,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white))),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _HeroBadge(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      );
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBox(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2), width: 0.5)),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.3)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 10, color: AppColors.gray400)),
          ]),
        ),
      );
}

class _PointsProgressCard extends StatelessWidget {
  final int points;
  const _PointsProgressCard({required this.points});
  @override
  Widget build(BuildContext context) {
    // Levels: Bronze(0), Silver(100), Gold(300), Platinum(600), Diamond(1000)
    final levels = [
      ('🥉 Bronze', 0, 100, AppColors.amber),
      ('🥈 Silver', 100, 300, AppColors.gray400),
      ('🥇 Gold', 300, 600, AppColors.amber),
      ('💎 Platinum', 600, 1000, AppColors.blue),
      ('👑 Diamond', 1000, 2000, AppColors.primary),
    ];
    final level =
        levels.lastWhere((l) => points >= l.$2, orElse: () => levels.first);
    final progress = (points - level.$2) / (level.$3 - level.$2);
    final clamped = progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14000000), width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(level.$1,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('$points pts',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: level.$4)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 8,
            backgroundColor: AppColors.gray50,
            valueColor: AlwaysStoppedAnimation(level.$4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
            '${level.$3 - points} points to ${points < level.$3 ? levels[levels.indexOf(level) + 1 < levels.length ? levels.indexOf(level) + 1 : levels.length - 1].$1 : "Max"}',
            style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.gray400,
                letterSpacing: 0.5)),
      );
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  const _MenuCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: const Border.fromBorderSide(
                BorderSide(color: Color(0x14000000), width: 0.5))),
        child: Column(children: children),
      );
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;
  const _MenuTile(
      {required this.icon,
      required this.label,
      this.subtitle,
      required this.color,
      required this.onTap,
      this.trailing});
  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18)),
        title: Text(label, style: const TextStyle(fontSize: 14)),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style: const TextStyle(fontSize: 12, color: AppColors.gray400))
            : null,
        trailing: trailing ??
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.gray400, size: 18),
        onTap: onTap,
      );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      );
}
