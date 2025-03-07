import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'basic_control_page.dart';
import 'more_features_page.dart';

class DevicePage extends StatefulWidget {
  const DevicePage({Key? key}) : super(key: key);

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  BluetoothDevice? _connectedDevice;
  final List<BluetoothDevice> _discoveredDevices = [];
  bool _isScanning = false;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  void _initBluetooth() async {
    try {
      if (!await FlutterBluePlus.isSupported) {
        _showError('设备不支持蓝牙');
        return;
      }

      _adapterStateSub = FlutterBluePlus.adapterState.listen((state) {
        if (state != BluetoothAdapterState.on) {
          _cleanupConnection();
        }
      });
    } catch (e) {
      _showError('蓝牙初始化失败: $e');
    }
  }

  void _cleanupConnection() {
    if (mounted) {
      setState(() => _connectedDevice = null);
    }
    _connectionSub?.cancel();
  }

  void _startScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _discoveredDevices.clear();
    });

    try {
      _showSearchDialog();

      if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on) {
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

        FlutterBluePlus.scanResults.listen((results) {
          if (mounted) {
            setState(() {
              _discoveredDevices.addAll(results.map((r) => r.device));
            });
          }
        });

        FlutterBluePlus.isScanning.listen((scanning) {
          if (mounted) {
            setState(() => _isScanning = scanning);
          }
        });
      }
    } catch (e) {
      _showError('扫描失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _connectDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      _setupConnectionListener(device);
      if (mounted) {
        setState(() => _connectedDevice = device);
      }
      if (Navigator.canPop(context)) Navigator.pop(context);
      _showSuccess('已连接 ${device.platformName}');
    } catch (e) {
      _showError('连接失败: $e');
    }
  }

  void _setupConnectionListener(BluetoothDevice device) {
    _connectionSub?.cancel();
    _connectionSub = device.connectionState.listen((state) {
      debugPrint('连接状态: $state');
      if (state == BluetoothConnectionState.disconnected) {
        _cleanupConnection();
        _showDisconnectSnackBar();
      }
    });
  }


  Future<void> _disconnectDevice() async {
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
        setState(() => _connectedDevice = null);
        _showDisconnectSnackBar();
      } catch (e) {
        _showError('断开失败: $e');
      }
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1B1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.amber.withOpacity(0.5), width: 1),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogHeader(),
              const SizedBox(height: 20),
              _buildDeviceList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.bluetooth, color: Colors.amber, size: 24),
            const SizedBox(width: 8),
            Text(
              _isScanning ? '搜索中...' : '发现设备',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            FlutterBluePlus.stopScan();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _buildDeviceList() {
    return SizedBox(
      height: 300,
      child: StreamBuilder<List<ScanResult>>(
        stream: FlutterBluePlus.scanResults,
        builder: (context, snapshot) {
          final devices = snapshot.data ?? [];
          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final result = devices[index];
              return ListTile(
                title: Text(
                  result.device.platformName.isEmpty
                      ? '未知设备'
                      : result.device.platformName,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '信号强度: ${result.rssi} dBm\nMAC: ${result.device.remoteId}',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white),
                onTap: () => _connectDevice(result.device),
              );
            },
          );
        },
      ),
    );
  }

  // 提示消息方法
  void _showError(String msg) => _showMessage(msg, Colors.red);
  void _showSuccess(String msg) => _showMessage(msg, Colors.green);

  void _showMessage(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDisconnectSnackBar() {
    _showMessage('设备已断开', Colors.orange);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B1E),
      body: SafeArea(
        child: Column(
          children: [
            _buildUserHeader(),
            Expanded(
              child: Stack(
                children: [
                  _buildGridBackground(),
                  _buildMainContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFF2C2D31),
            child: Icon(Icons.person, color: Colors.white),
          ),
          SizedBox(width: 12),
          Text('您好！头号玩家', style: TextStyle(color: Colors.white)),
          Spacer(),
          Icon(Icons.more_horiz, color: Colors.white54),
        ],
      ),
    );
  }

  Widget _buildGridBackground() {
    return CustomPaint(
      painter: _GridPainter(),
      size: Size.infinite,
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildFeatureButtons(),
          const SizedBox(height: 40),
          _buildConnectedDeviceCard(),
        ],
      ),
    );
  }

  Widget _buildFeatureButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildFeatureItem(
          title: '基础控制',
          icon: Icons.speed,
          onTap: () {
            if (_connectedDevice?.isConnected ?? false) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BasicControlPage(
                    device: _connectedDevice!,
                    serviceUUID: "5052494d-2dab-0341-6972-6f6861424c45",
                    characteristicUUID: "43484152-2dab-3241-6972-6f6861424c45",
                  ),
                ),
              );
            } else {
              _showError('请先连接设备');
            }
          },
        ),
        _buildFeatureItem(
            title: '更多功能',
            icon: Icons.more_horiz,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MoreFeaturesPage(), // 导航到 MoreFeaturesPage
                ),
              );
            }
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.cyan.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF2196F3)],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedDeviceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyan.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.devices, size: 80, color: Colors.white),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '当前设备：${_connectedDevice?.platformName ?? "未连接"}',
              style: const TextStyle(color: Colors.black),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildControlButton(Icons.search, '搜索', _startScan),
              _buildControlButton(Icons.link_off, '断开', _disconnectDevice),
              _buildControlButton(Icons.bluetooth, '蓝牙', _initBluetooth),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.cyan),
            ),
            child: Icon(icon, color: Colors.cyan),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _adapterStateSub?.cancel();
    _connectionSub?.cancel();
    _connectedDevice?.disconnect();
    super.dispose();
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.1)
      ..strokeWidth = 0.5;

    const spacing = 30.0;

    // 绘制垂直网格
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 绘制水平网格
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}