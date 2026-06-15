import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'user_management_controller.dart';

class UserManagementPage extends StatefulWidget {
  final bool autoOpenAddDialog;
  const UserManagementPage({super.key, this.autoOpenAddDialog = false});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final UserManagementController _controller = Get.put(
    UserManagementController(),
  );

  @override
  void initState() {
    super.initState();
    if (widget.autoOpenAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddUserDialog();
      });
    }
  }

  void _showAddUserDialog() {
    String username = '';
    String password = '';
    String role = 'Kasir';

    Get.dialog(
      AlertDialog(
        title: const Text('Tambah Pengguna'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Username'),
                  onChanged: (val) => username = val,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  onChanged: (val) => password = val,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'Kasir', child: Text('Kasir')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => role = val);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => _controller.addUser(username, password, role),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(int userId, String username) {
    String newPassword = '';
    Get.dialog(
      AlertDialog(
        title: Text('Reset Password - $username'),
        content: TextField(
          decoration: const InputDecoration(labelText: 'Password Baru'),
          obscureText: true,
          onChanged: (val) => newPassword = val,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => _controller.resetPassword(userId, newPassword),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Manajemen Pengguna (Admin)',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: _showAddUserDialog,
            tooltip: 'Tambah Pengguna',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _controller.usersList.length,
          itemBuilder: (context, index) {
            final user = _controller.usersList[index];
            bool isActive = user['is_active'] == 1;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isActive ? AppColors.primary : Colors.grey,
                  child: Icon(
                    user['role'] == 'Admin'
                        ? Icons.admin_panel_settings
                        : Icons.person,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  user['username'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Role: ${user['role']} | Status: ${isActive ? 'Aktif' : 'Nonaktif'}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.lock_reset, color: Colors.orange),
                      tooltip: 'Reset Password',
                      onPressed: () => _showResetPasswordDialog(
                        user['id'] as int,
                        user['username'],
                      ),
                    ),
                    Switch(
                      value: isActive,
                      onChanged: (val) => _controller.toggleUserStatus(
                        user['id'] as int,
                        user['is_active'] as int,
                      ),
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
