import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expenses_tracker/Auth/login_screen.dart';
import 'package:expenses_tracker/Provider/expenses_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _avatarUrl;
  String _userName = 'User';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // 1. Load Profile Image & Username
  Future<void> _loadUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Fallback Username from Email
    String fallbackName = 'User';
    if (user.email != null && user.email!.contains('@')) {
      final prefix = user.email!.split('@').first;
      if (prefix.isNotEmpty) {
        fallbackName = prefix[0].toUpperCase() + prefix.substring(1);
      }
    }

    try {
      final response = await supabase
          .from('profiles')
          .select('avatar_url, full_name')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        if (mounted) {
          setState(() {
            _avatarUrl = response['avatar_url'];
            _userName = (response['full_name'] != null &&
                response['full_name'].toString().trim().isNotEmpty)
                ? response['full_name']
                : fallbackName;
          });
        }
      } else {
        if (mounted) setState(() => _userName = fallbackName);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) setState(() => _userName = fallbackName);
    }
  }

  // 2. Pick & Upload Image ONLY
  Future<void> _pickAndUploadImage() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final file = File(image.path);
      final fileExt = image.path.split('.').last;
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await supabase.storage.from('profiles').upload(
        fileName,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final publicUrl = supabase.storage.from('profiles').getPublicUrl(fileName);

      await supabase.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'full_name': _userName,
        'avatar_url': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (context.mounted) {
        setState(() {
          _avatarUrl = publicUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 3. Sync Daily Expenses ONLY
  Future<void> _syncExpensesToCloud() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isSyncing = true);

    try {
      final expensesProvider = Provider.of<ExpensesProvider>(context, listen: false);
      final localTransactions = expensesProvider.transactions;

      if (localTransactions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No local expenses found to sync.'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
        return;
      }

      final List<Map<String, dynamic>> payload = localTransactions.map((tx) {
        return {
          'user_id': user.id,
          'title': tx.title,
          'amount': tx.amount,
          'category': tx.category,
          'created_at': tx.date.toIso8601String(),
          'is_income': tx.isIncome,
        };
      }).toList();

      await supabase.from('expenses').upsert(payload);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily expenses successfully synced to Cloud!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  // Helper Dialog Method
  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.poppins(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'User Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Avatar with Camera Badge
                    GestureDetector(
                      onTap: _isLoading ? null : _pickAndUploadImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.white24,
                            backgroundImage:
                            _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                            child: _avatarUrl == null
                                ? const Icon(Icons.person, size: 50, color: Colors.white70)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: Colors.cyanAccent,
                              shape: BoxShape.circle,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                                : const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // BOLD USERNAME
                    Text(
                      _userName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // EMAIL UNDER USERNAME
                    Text(
                      user?.email ?? 'user@example.com',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Upload / Sync Data Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSyncing ? null : _syncExpensesToCloud,
                        icon: _isSyncing
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                            : const Icon(Icons.cloud_upload_outlined),
                        label: Text(
                          _isSyncing ? 'Syncing Expenses...' : 'Upload / Sync Data to Cloud',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Divider(color: Colors.white.withValues(alpha: 0.15), thickness: 1),
                    const SizedBox(height: 10),

                    // Settings & Menu Options Group
                    _buildMenuTile(
                      icon: Icons.security_outlined,
                      title: 'Reset Password',
                      subtitle: 'Send password reset link to email',
                      onTap: () async {
      if (user?.email != null) {
        await supabase.auth.resetPasswordForEmail(user!.email!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset link sent to your email!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
                      },
                    ),

                    _buildMenuTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'How we protect your financial data',
                      onTap: () {
                        _showInfoDialog(
                          'Privacy Policy',
                          'Your data privacy is our highest priority. All transactions and profile details stored in Daily Expenses Tracker are encrypted and synced securely via Supabase Cloud.',
                        );
                      },
                    ),

                    _buildMenuTile(
                      icon: Icons.description_outlined,
                      title: 'Terms & Conditions',
                      subtitle: 'Rules and guidelines for usage',
                      onTap: () {
                        _showInfoDialog(
                          'Terms & Conditions',
                          'By using this application, you agree to manage your daily income and expense entries responsibly. The app stores data locally and syncs to cloud on demand.',
                        );
                      },
                    ),

                    _buildMenuTile(
                      icon: Icons.info_outline,
                      title: 'App Version',
                      subtitle: 'v1.0.0 (Build 102)',
                      onTap: () {},
                    ),

                    const SizedBox(height: 15),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await supabase.auth.signOut();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  (route) => false,
                            );
                          }
                        },
                        icon: const Icon(Icons.logout, color: Colors.redAccent),
                        label: Text(
                          'Logout',
                          style: GoogleFonts.poppins(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Icon(icon, color: Colors.cyanAccent, size: 22),
        title: Text(
          title,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
        onTap: onTap,
      ),
    );
  }
}