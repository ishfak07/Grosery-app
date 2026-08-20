import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import 'admin_general_notes_screen.dart';
import 'admin_screens.dart';

const _accountBackground = Color(0xFFF4F7F4);
const _accountSurface = Color(0xFFFFFFFF);
const _accountInk = Color(0xFF14231C);
const _accountMuted = Color(0xFF627168);
const _accountLine = Color(0xFFDDE8DF);
const _accountPrimary = Color(0xFF176B45);

/// Hub for the signed-in admin's own account: existing login/password
/// options plus the new personal General Notes workspace. Reached from the
/// dashboard's "Admin Account" tile.
class AdminAccountScreen extends StatelessWidget {
  const AdminAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppState>().profile;
    return Scaffold(
      backgroundColor: _accountBackground,
      appBar: AppBar(
        title: const Text(
          'Admin Account',
          style: TextStyle(color: _accountInk, fontWeight: FontWeight.w900),
        ),
        backgroundColor: _accountBackground,
        foregroundColor: _accountInk,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          physics: appRefreshScrollPhysics,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            _ProfileCard(profile: profile),
            const SizedBox(height: 18),
            _AccountOptionTile(
              icon: Icons.lock_reset,
              title: 'Change password',
              subtitle: 'Update your admin login password',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdminLoginPasswordResetScreen(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _AccountOptionTile(
              icon: Icons.sticky_note_2_outlined,
              title: 'General Notes',
              subtitle: 'Personal notes, reminders, and a quick calculator',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdminGeneralNotesScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _accountSurface,
        border: Border.all(color: _accountLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _accountPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: _accountPrimary,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.fullName.isNotEmpty == true
                      ? profile!.fullName
                      : 'Admin account',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _accountInk,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  profile?.phone.isNotEmpty == true
                      ? profile!.phone
                      : 'Current login',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _accountMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountOptionTile extends StatelessWidget {
  const _AccountOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _accountSurface,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: _accountLine),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _accountPrimary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _accountPrimary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _accountInk,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _accountMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _accountMuted),
            ],
          ),
        ),
      ),
    );
  }
}
