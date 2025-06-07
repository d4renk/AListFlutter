import 'dart:developer';
import 'dart:ffi';

import 'package:alist_flutter/contant/native_bridge.dart';
import 'package:alist_flutter/generated_api.dart';
import 'package:alist_flutter/pages/settings/preference_widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:alist_flutter/utils/http_client.dart';

import '../../generated/l10n.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() {
    return _SettingsScreenState();
  }
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    _lifecycleListener = AppLifecycleListener(
      onResume: () async {
        final controller = Get.put(_SettingsController());
        controller.updateData();
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_SettingsController());
    return Scaffold(
        body: Obx(
      () => ListView(
        children: [
          // SizedBox(height: MediaQuery.of(context).padding.top),
          Visibility(
            visible: !controller._managerStorageGranted.value ||
                !controller._notificationGranted.value ||
                !controller._storageGranted.value,
            child: DividerPreference(title: S.of(context).importantSettings),
          ),
          Visibility(
            visible: !controller._managerStorageGranted.value,
            child: BasicPreference(
              title: S.of(context).grantManagerStoragePermission,
              subtitle: S.of(context).grantStoragePermissionDesc,
              onTap: () {
                Permission.manageExternalStorage.request();
              },
            ),
          ),
          Visibility(
              visible: !controller._storageGranted.value,
              child: BasicPreference(
                title: S.of(context).grantStoragePermission,
                subtitle: S.of(context).grantStoragePermissionDesc,
                onTap: () {
                  Permission.storage.request();
                },
              )),

          Visibility(
              visible: !controller._notificationGranted.value,
              child: BasicPreference(
                title: S.of(context).grantNotificationPermission,
                subtitle: S.of(context).grantNotificationPermissionDesc,
                onTap: () {
                  Permission.notification.request();
                },
              )),

          DividerPreference(title: S.of(context).general),

          SwitchPreference(
            title: S.of(context).autoCheckForUpdates,
            subtitle: S.of(context).autoCheckForUpdatesDesc,
            icon: const Icon(Icons.system_update),
            value: controller.autoUpdate,
            onChanged: (value) {
              controller.autoUpdate = value;
            },
          ),
          SwitchPreference(
            title: S.of(context).wakeLock,
            subtitle: S.of(context).wakeLockDesc,
            icon: const Icon(Icons.screen_lock_portrait),
            value: controller.wakeLock,
            onChanged: (value) {
              controller.wakeLock = value;
            },
          ),
          SwitchPreference(
            title: S.of(context).bootAutoStartService,
            subtitle: S.of(context).bootAutoStartServiceDesc,
            icon: const Icon(Icons.power_settings_new),
            value: controller.startAtBoot,
            onChanged: (value) {
              controller.startAtBoot = value;
            },
          ),
          // AutoStartWebPage
          SwitchPreference(
            title: S.of(context).autoStartWebPage,
            subtitle: S.of(context).autoStartWebPageDesc,
            icon: const Icon(Icons.open_in_browser),
            value: controller._autoStartWebPage.value,
            onChanged: (value) {
              controller.autoStartWebPage = value;
            },
          ),

          BasicPreference(
            title: S.of(context).dataDirectory,
            subtitle: controller._dataDir.value,
            leading: const Icon(Icons.folder),
            onTap: () async {
              final path = await FilePicker.platform.getDirectoryPath();

              if (path == null) {
                Get.showSnackbar(GetSnackBar(
                    message: S.current.setDefaultDirectory,
                    duration: const Duration(seconds: 3),
                    mainButton: TextButton(
                      onPressed: () {
                        controller.setDataDir("");
                        Get.back();
                      },
                      child: Text(S.current.confirm),
                    )));
              } else {
                controller.setDataDir(path);
              }
            },
          ),
          DividerPreference(title: S.of(context).uiSettings),
          SwitchPreference(
              icon: const Icon(Icons.pan_tool_alt_outlined),
              title: S.of(context).silentJumpApp,
              subtitle: S.of(context).silentJumpAppDesc,
              value: controller._silentJumpApp.value,
              onChanged: (value) {
                controller.silentJumpApp = value;
              }),

          // Proxy Settings Section
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'HTTP Proxy Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Obx(() => SwitchListTile(
                      title: const Text('Enable Proxy'),
                      value: controller.proxyEnabled,
                      onChanged: (bool value) {
                        controller.proxyEnabled = value;
                      },
                    )),
                Obx(() => Visibility(
                      visible: controller.proxyEnabled,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextField(
                              decoration: const InputDecoration(
                                labelText: 'Proxy Host',
                                hintText: 'Enter proxy host (e.g., 127.0.0.1)',
                              ),
                              controller: TextEditingController(
                                  text: controller.proxyHost),
                              onChanged: (value) {
                                controller.proxyHost = value;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              decoration: const InputDecoration(
                                labelText: 'Proxy Port',
                                hintText: 'Enter proxy port (e.g., 8080)',
                              ),
                              keyboardType: TextInputType.number,
                              controller: TextEditingController(
                                  text: controller.proxyPort.toString()),
                              onChanged: (value) {
                                controller.proxyPort =
                                    int.tryParse(value) ?? 0;
                              },
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}

class _SettingsController extends GetxController {
  final _dataDir = "".obs;
  final _autoUpdate = true.obs;
  final _managerStorageGranted = true.obs;
  final _notificationGranted = true.obs;
  final _storageGranted = true.obs;

  // Proxy settings
  final _proxyEnabled = false.obs;
  final _proxyHost = "".obs;
  final _proxyPort = 0.obs;

  setDataDir(String value) async {
    NativeBridge.appConfig.setDataDir(value);
    _dataDir.value = await NativeBridge.appConfig.getDataDir();
  }

  get dataDir => _dataDir.value;

  set autoUpdate(value) => {
        _autoUpdate.value = value,
        NativeBridge.appConfig.setAutoCheckUpdateEnabled(value)
      };

  get autoUpdate => _autoUpdate.value;

  final _wakeLock = true.obs;

  set wakeLock(value) => {
        _wakeLock.value = value,
        NativeBridge.appConfig.setWakeLockEnabled(value)
      };

  get wakeLock => _wakeLock.value;

  final _autoStart = true.obs;

  set startAtBoot(value) => {
        _autoStart.value = value,
        NativeBridge.appConfig.setStartAtBootEnabled(value)
      };

  get startAtBoot => _autoStart.value;

  final _autoStartWebPage = false.obs;

  set autoStartWebPage(value) => {
        _autoStartWebPage.value = value,
        NativeBridge.appConfig.setAutoOpenWebPageEnabled(value)
      };

  get autoStartWebPage => _autoStartWebPage.value;

  final _silentJumpApp = false.obs;

  get silentJumpApp => _silentJumpApp.value;

  set silentJumpApp(value) => {
        _silentJumpApp.value = value,
        NativeBridge.appConfig.setSilentJumpAppEnabled(value)
      };

  get proxyEnabled => _proxyEnabled.value;
  set proxyEnabled(value) => {
        _proxyEnabled.value = value,
        NativeBridge.appConfig.setProxyEnabled(value),
        _updateProxySettings()
      };

  get proxyHost => _proxyHost.value;
  set proxyHost(value) => {
        _proxyHost.value = value,
        NativeBridge.appConfig.setProxyHost(value),
        _updateProxySettings()
      };

  get proxyPort => _proxyPort.value;
  set proxyPort(value) => {
        _proxyPort.value = value,
        NativeBridge.appConfig.setProxyPort(value),
        _updateProxySettings()
      };

  void _updateProxySettings() async {
<<<<<<< HEAD
    await ProxyHttpClient.instance._updateProxySettings();
=======
    await ProxyHttpClient.instance.updateProxySettings();
>>>>>>> 38f7e93 (http proxy)
  }

  @override
  void onInit() async {
    updateData();

    super.onInit();
  }

  void updateData() async {
    final cfg = AppConfig();
    cfg.isAutoCheckUpdateEnabled().then((value) => autoUpdate = value);
    cfg.isWakeLockEnabled().then((value) => wakeLock = value);
    cfg.isStartAtBootEnabled().then((value) => startAtBoot = value);
    cfg.isAutoOpenWebPageEnabled().then((value) => autoStartWebPage = value);
    cfg.isSilentJumpAppEnabled().then((value) => silentJumpApp = value);
    
    // Load proxy settings
    cfg.isProxyEnabled().then((value) => proxyEnabled = value);
    cfg.getProxyHost().then((value) => proxyHost = value);
    cfg.getProxyPort().then((value) => proxyPort = value);

    _dataDir.value = await cfg.getDataDir();

    final sdk = await NativeBridge.common.getDeviceSdkInt();
    // A11
    if (sdk >= 30) {
      _managerStorageGranted.value =
          await Permission.manageExternalStorage.isGranted;
    } else {
      _managerStorageGranted.value = true;
      _storageGranted.value = await Permission.storage.isGranted;
    }

    // A12
    if (sdk >= 32) {
      _notificationGranted.value = await Permission.notification.isGranted;
    } else {
      _notificationGranted.value = true;
    }
  }
}
