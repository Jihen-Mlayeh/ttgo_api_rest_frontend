import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/sensor_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/api_endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/success_animation.dart';
import '../connection/connection_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        centerTitle: true,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('Mode de fonctionnement', Icons.settings_suggest),
              const SizedBox(height: 12),
              _buildModeSection(settings),
              const SizedBox(height: 24),

              _buildSectionHeader('Seuils d\'activation', Icons.tune),
              const SizedBox(height: 12),
              _buildThresholdsSection(settings),
              const SizedBox(height: 24),

              _buildSectionHeader('Configuration', Icons.settings),
              const SizedBox(height: 12),
              _buildConfigSection(settings),
              const SizedBox(height: 24),

              _buildSectionHeader('Synchronisation', Icons.cloud),
              const SizedBox(height: 12),
              _buildFirebaseSection(settings),
              const SizedBox(height: 24),

              _buildSectionHeader('Apparence', Icons.palette),
              const SizedBox(height: 12),
              _buildAppearanceSection(settings),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildModeSection(SettingsProvider settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModeOption(settings, 'MANUEL', 'Contrôle manuel de la LED', Icons.touch_app),
            const Divider(height: 24),
            _buildModeOption(settings, 'AUTO-TEMP', 'LED s\'allume si température > seuil', Icons.thermostat),
            const Divider(height: 24),
            _buildModeOption(settings, 'AUTO-LIGHT', 'LED s\'allume si luminosité < seuil', Icons.wb_sunny),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(SettingsProvider settings, String mode, String description, IconData icon) {
    final isSelected = settings.currentMode == mode;

    return InkWell(
      onTap: () => settings.setMode(mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdsSection(SettingsProvider settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Température', style: TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${settings.tempThreshold.toStringAsFixed(1)}°C',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                  ),
                ),
              ],
            ),
            Slider(
              value: settings.tempThreshold,
              min: 0,
              max: 50,
              divisions: 100,
              label: '${settings.tempThreshold.toStringAsFixed(1)}°C',
              onChanged: (value) => settings.setTempThreshold(value),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lumière', style: TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${settings.lightThreshold}%',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning),
                  ),
                ),
              ],
            ),
            Slider(
              value: settings.lightThreshold.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              label: '${settings.lightThreshold}%',
              onChanged: (value) => settings.setLightThreshold(value.toInt()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await settings.applyThresholds();
                  if (mounted) {
                    showSuccessDialog(context, 'Seuils appliqués avec succès !');
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Appliquer les seuils'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSection(SettingsProvider settings) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.wifi),
            title: const Text('Adresse IP ESP32'),
            subtitle: Text(ApiEndpoints.baseUrl.replaceAll('http://', '')),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('esp32_ip');
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const ConnectionScreen()),
                      (route) => false,
                );
              }
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Intervalle de rafraîchissement'),
            subtitle: Text('${settings.refreshInterval} secondes'),
            trailing: DropdownButton<int>(
              value: settings.refreshInterval,
              items: [1, 2, 5, 10].map((seconds) {
                return DropdownMenuItem(value: seconds, child: Text('${seconds}s'));
              }).toList(),
              onChanged: (value) {
                if (value != null) settings.setRefreshInterval(value);
              },
            ),
          ),
          const Divider(height: 1),
          // ✅ CORRECTION ICI : toggleNotifications au lieu de toggleFirebase
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text('Alertes pour les seuils dépassés'),
            value: settings.notificationsEnabled,
            onChanged: (value) async {
              await settings.toggleNotifications();
              // ✨ Synchronise avec le SensorProvider
              if (mounted) {
                context.read<SensorProvider>().setNotificationsEnabled(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFirebaseSection(SettingsProvider settings) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.cloud),
            title: const Text('Synchronisation Firebase'),
            subtitle: const Text('Sauvegarde automatique des données'),
            value: settings.firebaseEnabled,
            onChanged: (value) => settings.toggleFirebase(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.cloud_done,
              color: settings.firebaseEnabled ? Colors.green : Colors.grey,
            ),
            title: const Text('État de connexion'),
            subtitle: Text(
              settings.firebaseEnabled ? 'Connecté' : 'Désactivé',
              style: TextStyle(
                color: settings.firebaseEnabled ? Colors.green : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(SettingsProvider settings) {
    return Card(
      child: SwitchListTile(
        secondary: Icon(settings.isDarkMode ? Icons.dark_mode : Icons.light_mode),
        title: const Text('Mode sombre'),
        subtitle: const Text('Thème sombre pour l\'application'),
        value: settings.isDarkMode,
        onChanged: (value) => settings.toggleDarkMode(), // ✅ CORRECTION ICI aussi
      ),
    );
  }
}