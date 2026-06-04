import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/models.dart';
import '../services/app_provider.dart';
import '../utils/theme.dart';
import 'change_default_password_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  ADMIN SHELL — its own Navigator so it feels like a separate app
// ═══════════════════════════════════════════════════════════════════════════

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _idx = 0;
  final _pages = const [
    _OverviewTab(),
    _AdminRequestsTab(),
    _UsersTab(),
    _ProductsTab(),
    _ShopsTab(),
    _ReportsTab(),
  ];

  static const _labels = [
    ('Overview',  Icons.dashboard_rounded,          Icons.dashboard_outlined),
    ('Requests',  Icons.mark_email_unread_rounded,  Icons.mark_email_unread_outlined),
    ('Users',     Icons.people_rounded,             Icons.people_outline_rounded),
    ('Products',  Icons.inventory_2_rounded,        Icons.inventory_2_outlined),
    ('Shops',     Icons.store_rounded,              Icons.store_outlined),
    ('Reports',   Icons.receipt_long_rounded,       Icons.receipt_long_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().appUser;
    if (user == null || !user.isAdmin) {
      return Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.lock_rounded, size: 72, color: AppColors.gray100),
        const SizedBox(height: 16),
        const Text('Admin Access Only', style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('You need the admin role to access this area.',
            style: TextStyle(color: AppColors.gray400)),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: () => Navigator.pop(context),
            child: const Text('Go Back')),
      ])));
    }

    // Super-admin: force password change on first login
    final isSuperAdmin = context.read<AppProvider>().appUser?.role == 'admin';
    final rawDoc = context.read<AppProvider>().firebaseUser;
    if (isSuperAdmin) {
      // Check Firestore flag asynchronously via FutureBuilder
      return FutureBuilder<bool>(
        future: _checkNeedsPasswordChange(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary)));
          }
          if (snap.data == true) {
            return const ChangeDefaultPasswordScreen();
          }
          return _adminBody(context, user);
        },
      );
    }
    return _adminBody(context, user);
  }

  Future<bool> _checkNeedsPasswordChange() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return false;
    // Only the isSuperAdmin flag account needs to change password on first login
    final isSuperAdmin = data['isSuperAdmin'] as bool? ?? false;
    final changed      = data['defaultPasswordChanged'] as bool? ?? false;
    return isSuperAdmin && !changed;
  }

  Widget _adminBody(BuildContext context, AppUser user) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: Row(children: [
          Container(padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 18)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('FairPrice Admin', style: TextStyle(fontSize: 15,
                fontWeight: FontWeight.w700, color: Colors.white)),
            Text(user.displayName, style: const TextStyle(
                fontSize: 10, color: Colors.white60)),
          ]),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
        ],
      ),
      body: _pages[_idx],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.primaryDark,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: SafeArea(child: SizedBox(
          height: 58,
          child: Row(
            children: _labels.asMap().entries.map((e) {
              final active = e.key == _idx;
              final (label, iconOn, iconOff) = e.value;
              // Badge for requests tab
              final showBadge = e.key == 1;
              return Expanded(child: GestureDetector(
                onTap: () => setState(() => _idx = e.key),
                behavior: HitTestBehavior.opaque,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Stack(children: [
                    Icon(active ? iconOn : iconOff, size: 20,
                        color: active ? Colors.white : Colors.white38),
                    if (showBadge)
                      Positioned(right: 0, top: 0,
                          child: Container(width: 7, height: 7,
                              decoration: const BoxDecoration(
                                  color: AppColors.accent, shape: BoxShape.circle))),
                  ]),
                  const SizedBox(height: 3),
                  Text(label, style: TextStyle(fontSize: 9,
                      fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                      color: active ? Colors.white : Colors.white38)),
                ]),
              ));
            }).toList(),
          ),
        )),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  OVERVIEW TAB
// ═══════════════════════════════════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();
  @override
  Widget build(BuildContext context) {
    final db = context.read<AppProvider>().db;
    return ListView(padding: const EdgeInsets.all(16), children: [
      // Hero banner
      Container(padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark]),
              borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Icon(Icons.shield_rounded, color: Colors.white, size: 40),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Admin Dashboard', style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              Text('Real-time platform overview — FairPrice/BirrWise',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
          ])),
      const SizedBox(height: 16),

      // Live count grid
      GridView.count(
        crossAxisCount: 2, childAspectRatio: 1.6,
        crossAxisSpacing: 10, mainAxisSpacing: 10,
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        children: [
          StreamBuilder<List<AppUser>>(stream: db.allUsersStreamFull(),
              builder: (_, s) => _StatCard('Total Users',
                  '${s.data?.length ?? 0}', Icons.people_rounded, AppColors.blue)),
          StreamBuilder<List<Product>>(stream: db.allProductsStream(),
              builder: (_, s) => _StatCard('Products',
                  '${s.data?.length ?? 0}', Icons.inventory_2_rounded, AppColors.primary)),
          StreamBuilder<List<Shop>>(stream: db.allShopsStream(),
              builder: (_, s) => _StatCard('Shops',
                  '${s.data?.length ?? 0}', Icons.store_rounded, AppColors.amber)),
          StreamBuilder<List<PriceReport>>(stream: db.allReportsStreamFull(),
              builder: (_, s) => _StatCard('Reports',
                  '${s.data?.length ?? 0}', Icons.receipt_long_rounded, AppColors.accent)),
          StreamBuilder<List<AdminRequest>>(stream: db.pendingAdminRequestsStream(),
              builder: (_, s) => _StatCard('Pending Requests',
                  '${s.data?.length ?? 0}', Icons.hourglass_top_rounded, AppColors.amber,
                  urgent: (s.data?.isNotEmpty ?? false))),
          StreamBuilder<List<AppUser>>(stream: db.allUsersStreamFull(),
              builder: (_, s) {
                final banned = s.data?.where((u) => u.banned).length ?? 0;
                return _StatCard('Banned Users', '$banned',
                    Icons.block_rounded, AppColors.accent);
              }),
        ],
      ),
      const SizedBox(height: 20),

      // Pending requests alert
      StreamBuilder<List<AdminRequest>>(
        stream: db.pendingAdminRequestsStream(),
        builder: (_, snap) {
          final pending = snap.data ?? [];
          if (pending.isEmpty) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AppColors.amberLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.amber.withOpacity(0.4))),
            child: Row(children: [
              const Icon(Icons.notification_important_rounded,
                  color: AppColors.amber, size: 22),
              const SizedBox(width: 10),
              Expanded(child: Text(
                '${pending.length} admin request${pending.length > 1 ? 's' : ''} awaiting your review',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.amber))),
            ]),
          );
        },
      ),

      // Recent reports
      const _SectionLabel('Recent Price Reports'),
      StreamBuilder<List<PriceReport>>(
        stream: db.recentReportsStream(),
        builder: (_, snap) {
          final reports = snap.data?.take(8).toList() ?? [];
          return Card(child: Column(
            children: reports.isEmpty
                ? [const Padding(padding: EdgeInsets.all(20),
                    child: Text('No reports yet',
                        style: TextStyle(color: AppColors.gray400)))]
                : reports.asMap().entries.map((e) => Column(children: [
                    _ReportTile(report: e.value, onDelete: () =>
                        db.deleteReport(e.value.id)),
                    if (e.key < reports.length - 1) const Divider(height: 0),
                  ])).toList(),
          ));
        },
      ),
      const SizedBox(height: 32),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  final bool urgent;
  const _StatCard(this.label, this.value, this.icon, this.color,
      {this.urgent = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: urgent ? color.withOpacity(0.15) : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(urgent ? 0.4 : 0.2), width: 0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 20),
        if (urgent) ...[const Spacer(),
          Container(width: 8, height: 8, decoration: BoxDecoration(
              color: AppColors.accent, shape: BoxShape.circle))],
      ]),
      const Spacer(),
      Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
          color: color, letterSpacing: -0.5)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  ADMIN REQUESTS TAB
// ═══════════════════════════════════════════════════════════════════════════

class _AdminRequestsTab extends StatefulWidget {
  const _AdminRequestsTab();
  @override
  State<_AdminRequestsTab> createState() => _AdminRequestsTabState();
}

class _AdminRequestsTabState extends State<_AdminRequestsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tc;
  @override
  void initState() { super.initState(); _tc = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final db  = context.read<AppProvider>().db;
    final uid = context.read<AppProvider>().firebaseUser!.uid;
    return Column(children: [
      Container(color: Theme.of(context).colorScheme.surface,
          child: TabBar(controller: _tc,
              labelColor: AppColors.primary, unselectedLabelColor: AppColors.gray400,
              indicatorColor: AppColors.primary,
              tabs: const [Tab(text: 'Pending'), Tab(text: 'All Requests')])),
      Expanded(child: TabBarView(controller: _tc, children: [
        // Pending
        StreamBuilder<List<AdminRequest>>(
          stream: db.pendingAdminRequestsStream(),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary));
            }
            final reqs = snap.data ?? [];
            if (reqs.isEmpty) return _emptyState(
                '✅', 'No pending requests', 'All admin requests have been reviewed');
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: reqs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _RequestCard(
                  request: reqs[i], reviewerUid: uid, db: db),
            );
          },
        ),
        // All
        StreamBuilder<List<AdminRequest>>(
          stream: db.allAdminRequestsStream(),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary));
            }
            final reqs = snap.data ?? [];
            if (reqs.isEmpty) return _emptyState(
                '📋', 'No requests yet', 'Admin requests will appear here');
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: reqs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _RequestCard(
                  request: reqs[i], reviewerUid: uid, db: db,
                  showActions: reqs[i].status == AdminRequestStatus.pending),
            );
          },
        ),
      ])),
    ]);
  }
}

class _RequestCard extends StatelessWidget {
  final AdminRequest request;
  final String reviewerUid;
  final db;
  final bool showActions;
  const _RequestCard({required this.request, required this.reviewerUid,
      required this.db, this.showActions = true});

  @override
  Widget build(BuildContext context) {
    final statusColor = request.status == AdminRequestStatus.approved
        ? AppColors.primary : request.status == AdminRequestStatus.rejected
            ? AppColors.accent : AppColors.amber;
    final statusLabel = request.status == AdminRequestStatus.approved
        ? '✅ Approved' : request.status == AdminRequestStatus.rejected
            ? '❌ Rejected' : '⏳ Pending';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 44, height: 44, decoration: const BoxDecoration(
                color: AppColors.amberLight, shape: BoxShape.circle),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    color: AppColors.amber, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(request.displayName, style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700)),
              Text(request.email, style: const TextStyle(
                  fontSize: 12, color: AppColors.gray400)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(statusLabel, style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: statusColor))),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 0),
          const SizedBox(height: 12),
          _InfoRow(Icons.business_outlined, 'Organization', request.organization),
          const SizedBox(height: 6),
          _InfoRow(Icons.access_time_rounded, 'Requested',
              timeago.format(request.requestedAt)),
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Reason for request:', style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.gray400)),
                const SizedBox(height: 4),
                Text(request.reason, style: const TextStyle(
                    fontSize: 13, height: 1.4)),
              ])),
          if (showActions) ...[
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _reject(context),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent)),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(
                onPressed: () => _approve(context),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Approve'),
              )),
            ]),
          ],
        ]),
      ),
    );
  }

  Future<void> _approve(BuildContext context) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Approve Admin Request'),
      content: Text('Grant admin access to ${request.displayName}? '
          'They will have full control over the platform.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve')),
      ],
    ));
    if (ok == true && context.mounted) {
      await db.approveAdminRequest(request.uid, reviewerUid);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${request.displayName} is now an admin'),
        backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _reject(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Reject Admin Request'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Reject ${request.displayName}\'s request?'),
        const SizedBox(height: 12),
        TextField(controller: reasonCtrl,
            decoration: const InputDecoration(labelText: 'Reason (optional)')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Reject')),
      ],
    ));
    if (ok == true && context.mounted) {
      await db.rejectAdminRequest(request.uid, reviewerUid, reasonCtrl.text.trim());
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Admin request rejected'),
        backgroundColor: AppColors.accent, behavior: SnackBarBehavior.floating));
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final String label, value;
  const _InfoRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: AppColors.gray400),
    const SizedBox(width: 6),
    Text('$label: ', style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
    Expanded(child: Text(value, style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis)),
  ]);
}

// ═══════════════════════════════════════════════════════════════════════════
//  USERS TAB
// ═══════════════════════════════════════════════════════════════════════════

class _UsersTab extends StatefulWidget {
  const _UsersTab();
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final db = context.read<AppProvider>().db;
    return Column(children: [
      Padding(padding: const EdgeInsets.all(12),
          child: TextField(onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                  hintText: 'Search by name or email…',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gray400, size: 20),
                  filled: true, fillColor: AppColors.gray50,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.zero))),
      Expanded(child: StreamBuilder<List<AppUser>>(
        stream: db.allUsersStreamFull(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary));
          }
          var users = snap.data ?? [];
          if (_q.isNotEmpty) users = users.where((u) =>
              u.displayName.toLowerCase().contains(_q.toLowerCase()) ||
              u.email.toLowerCase().contains(_q.toLowerCase())).toList();
          if (users.isEmpty) return _emptyState('👥', 'No users found', '');
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 0, indent: 60),
            itemBuilder: (_, i) => _UserTile(user: users[i], db: db),
          );
        },
      )),
    ]);
  }
}

class _UserTile extends StatelessWidget {
  final AppUser user; final db;
  const _UserTile({required this.user, required this.db});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: CircleAvatar(radius: 20,
          backgroundColor: AppColors.primaryLight,
          backgroundImage: user.photoUrl != null
              ? CachedNetworkImageProvider(user.photoUrl!) : null,
          child: user.photoUrl == null ? Text(
              user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700)) : null),
      title: Row(children: [
        Flexible(child: Text(user.displayName, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 6),
        if (user.isAdmin)     _Badge('Admin',  AppColors.primary),
        if (user.isPending)   _Badge('Pending',AppColors.amber),
        if (user.banned)      _Badge('Banned', AppColors.accent),
      ]),
      subtitle: Text('${user.email} · ${user.reportCount} reports · ${user.points} pts',
          style: const TextStyle(fontSize: 11, color: AppColors.gray400),
          overflow: TextOverflow.ellipsis),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.gray400),
        onSelected: (v) => _handleAction(context, v),
        itemBuilder: (_) => [
          _menuItem('view',         Icons.info_outline_rounded,             'View Details'),
          _menuItem(user.isAdmin ? 'remove_admin' : 'make_admin',
              Icons.admin_panel_settings_outlined,
              user.isAdmin ? 'Remove Admin' : 'Make Admin'),
          _menuItem(user.banned ? 'unban' : 'ban',
              user.banned ? Icons.check_circle_outline : Icons.block_rounded,
              user.banned ? 'Unban User' : 'Ban User',
              color: user.banned ? null : AppColors.accent),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String v, IconData icon, String label,
      {Color? color}) => PopupMenuItem(value: v,
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color)),
      ]));

  void _handleAction(BuildContext ctx, String action) async {
    switch (action) {
      case 'view': _showDetails(ctx); break;
      case 'make_admin':
        await db.setUserRole(user.uid, 'admin');
        _snack(ctx, '${user.displayName} is now admin', true); break;
      case 'remove_admin':
        await db.setUserRole(user.uid, 'user');
        _snack(ctx, 'Admin role removed', true); break;
      case 'ban':
        await db.banUser(user.uid, true);
        _snack(ctx, '${user.displayName} banned', false); break;
      case 'unban':
        await db.banUser(user.uid, false);
        _snack(ctx, '${user.displayName} unbanned', true); break;
    }
  }

  void _snack(BuildContext ctx, String msg, bool good) =>
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg),
          backgroundColor: good ? AppColors.primary : AppColors.accent,
          behavior: SnackBarBehavior.floating));

  void _showDetails(BuildContext ctx) => showModalBottomSheet(
    context: ctx,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => Padding(padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(
            color: AppColors.gray100, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        CircleAvatar(radius: 32, backgroundColor: AppColors.primaryLight,
            child: Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark))),
        const SizedBox(height: 10),
        Text(user.displayName, style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700)),
        Text(user.email, style: const TextStyle(fontSize: 13, color: AppColors.gray400)),
        if (user.location != null) ...[
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.gray400),
            const SizedBox(width: 3),
            Text(user.location!, style: const TextStyle(
                fontSize: 12, color: AppColors.gray400)),
          ]),
        ],
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _DetailStat('Reports', user.reportCount, AppColors.primary),
          _DetailStat('Verified', user.verifyCount, AppColors.blue),
          _DetailStat('Points', user.points, AppColors.amber),
        ]),
        const SizedBox(height: 8),
      ]),
    ),
  );
}

class _DetailStat extends StatelessWidget {
  final String label; final int value; final Color color;
  const _DetailStat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
  ]);
}

// ═══════════════════════════════════════════════════════════════════════════
//  PRODUCTS TAB
// ═══════════════════════════════════════════════════════════════════════════

class _ProductsTab extends StatefulWidget {
  const _ProductsTab();
  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final db = context.read<AppProvider>().db;
    return Column(children: [
      Padding(padding: const EdgeInsets.all(12),
          child: TextField(onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(hintText: 'Search products…',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.gray400, size: 20),
                  filled: true, fillColor: AppColors.gray50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.zero))),
      Expanded(child: StreamBuilder<List<Product>>(
        stream: db.allProductsStream(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary));
          }
          var products = snap.data ?? [];
          if (_q.isNotEmpty) products = products.where((p) =>
              p.name.toLowerCase().contains(_q.toLowerCase()) ||
              p.category.toLowerCase().contains(_q.toLowerCase())).toList();
          if (products.isEmpty) return _emptyState('📦', 'No products', '');
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: products.length,
            separatorBuilder: (_, __) => const Divider(height: 0, indent: 60),
            itemBuilder: (_, i) {
              final p = products[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: Container(width: 42, height: 42,
                    decoration: BoxDecoration(color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text(p.emoji,
                        style: const TextStyle(fontSize: 20)))),
                title: Text(p.name, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
                subtitle: Text('${p.category} · ${p.unit} · ETB ${p.avgPrice.toStringAsFixed(0)} avg · ${p.reportCount} reports',
                    style: const TextStyle(fontSize: 11)),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      size: 18, color: AppColors.gray400),
                  onSelected: (action) async {
                    if (action == 'delete') {
                      final ok = await _confirmDelete(ctx, p.name);
                      if (ok == true) {
                        await db.deleteProduct(p.id);
                        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Product deleted'),
                                backgroundColor: AppColors.accent,
                                behavior: SnackBarBehavior.floating));
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.accent),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: AppColors.accent)),
                        ])),
                  ],
                ),
              );
            },
          );
        },
      )),
    ]);
  }
  Future<bool?> _confirmDelete(BuildContext ctx, String name) =>
      showDialog<bool>(context: ctx, builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product'),
        content: Text('Delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              child: const Text('Delete')),
        ],
      ));
}

// ═══════════════════════════════════════════════════════════════════════════
//  SHOPS TAB
// ═══════════════════════════════════════════════════════════════════════════

class _ShopsTab extends StatelessWidget {
  const _ShopsTab();
  @override
  Widget build(BuildContext context) {
    final db = context.read<AppProvider>().db;
    return StreamBuilder<List<Shop>>(
      stream: db.allShopsStream(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primary));
        }
        final shops = snap.data ?? [];
        if (shops.isEmpty) return _emptyState('🏪', 'No shops yet', '');
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: shops.length,
          separatorBuilder: (_, __) => const Divider(height: 0, indent: 60),
          itemBuilder: (_, i) {
            final s = shops[i];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              leading: Container(width: 42, height: 42,
                  decoration: BoxDecoration(color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.store_rounded,
                      color: AppColors.primary, size: 20)),
              title: Row(children: [
                Expanded(child: Text(s.name, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500))),
                Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                        color: s.isOpen ? AppColors.primaryLight : AppColors.accentLight,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(s.isOpen ? 'Open' : 'Closed',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                            color: s.isOpen ? AppColors.primaryDark : AppColors.accent))),
              ]),
              subtitle: Text('${s.area} · ${s.reportCount} reports · ⭐ ${s.rating.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 11)),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.gray400),
                onSelected: (v) async {
                  if (v == 'toggle') {
                    await db.toggleShopOpen(s.id, !s.isOpen);
                  } else if (v == 'delete') {
                    final ok = await showDialog<bool>(context: ctx,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('Delete Shop'),
                          content: Text('Delete "${s.name}"? This cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel')),
                            ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                                child: const Text('Delete')),
                          ],
                        ));
                    if (ok == true) await db.deleteShop(s.id);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'toggle',
                      child: Row(children: [
                        Icon(s.isOpen ? Icons.close_rounded : Icons.check_rounded,
                            size: 16, color: s.isOpen ? AppColors.accent : AppColors.primary),
                        const SizedBox(width: 8),
                        Text(s.isOpen ? 'Mark Closed' : 'Mark Open'),
                      ])),
                  const PopupMenuItem(value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.accent),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.accent)),
                      ])),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  REPORTS TAB
// ═══════════════════════════════════════════════════════════════════════════

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();
  @override
  Widget build(BuildContext context) {
    final db = context.read<AppProvider>().db;
    return StreamBuilder<List<PriceReport>>(
      stream: db.allReportsStreamFull(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primary));
        }
        final reports = snap.data ?? [];
        if (reports.isEmpty) return _emptyState('📋', 'No reports yet', '');
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: reports.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (_, i) => _ReportTile(
              report: reports[i], onDelete: () => db.deleteReport(reports[i].id)),
        );
      },
    );
  }
}

class _ReportTile extends StatelessWidget {
  final PriceReport report; final VoidCallback onDelete;
  const _ReportTile({required this.report, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    final typeColors = {
      ReportType.reported: AppColors.blue,
      ReportType.verified: AppColors.primary,
      ReportType.alert:    AppColors.amber,
      ReportType.scanned:  AppColors.accent,
    };
    final typeLabels = {
      ReportType.reported: 'Reported',
      ReportType.verified: 'Verified',
      ReportType.alert:    'Alert',
      ReportType.scanned:  'Scanned',
    };
    final color = typeColors[report.type] ?? AppColors.gray400;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      title: Row(children: [
        Expanded(child: Text('${report.productName} @ ${report.shopName}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis)),
        Text('ETB ${report.price.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: AppColors.primary)),
      ]),
      subtitle: Row(children: [
        Text(report.reporterName, style: const TextStyle(
            fontSize: 11, color: AppColors.gray400)),
        const Text(' · ', style: TextStyle(color: AppColors.gray400)),
        Text(timeago.format(report.reportedAt), style: const TextStyle(
            fontSize: 11, color: AppColors.gray400)),
        const Spacer(),
        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text(typeLabels[report.type] ?? '', style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w700, color: color))),
      ]),
      trailing: IconButton(icon: const Icon(Icons.delete_outline_rounded,
          size: 18, color: AppColors.accent), onPressed: onDelete,
          style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap)),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────

Widget _emptyState(String emoji, String title, String sub) => Center(
  child: Column(mainAxisSize: MainAxisSize.min, children: [
    Text(emoji, style: const TextStyle(fontSize: 48)),
    const SizedBox(height: 12),
    Text(title, style: const TextStyle(
        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray800)),
    if (sub.isNotEmpty) Text(sub, style: const TextStyle(
        fontSize: 13, color: AppColors.gray400)),
  ]),
);

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text.toUpperCase(), style: const TextStyle(
        fontSize: 11, fontWeight: FontWeight.w600,
        color: AppColors.gray400, letterSpacing: 0.5)),
  );
}

class _Badge extends StatelessWidget {
  final String label; final Color color;
  const _Badge(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(left: 4),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3))),
    child: Text(label, style: TextStyle(fontSize: 9,
        fontWeight: FontWeight.w700, color: color)),
  );
}

// Extension for easy access to pending check
extension on AppUser {
  bool get isPending => role == 'pending_admin';
}
