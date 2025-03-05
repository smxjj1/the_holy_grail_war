import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BasicControlPage extends StatefulWidget {
  final BluetoothDevice device;
  final String serviceUUID;
  final String characteristicUUID;

  const BasicControlPage({
    Key? key,
    required this.device,
    required this.serviceUUID,
    required this.characteristicUUID,
  }) : super(key: key);

  @override
  State<BasicControlPage> createState() => _BasicControlPageState();
}

class _BasicControlPageState extends State<BasicControlPage> {
  BluetoothCharacteristic? _controlChar;
  double _motorSpeed = 0;
  bool _isConnected = true;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;

  @override
  void initState() {
    super.initState();
    _initializeConnection();
  }

  Future<void> _initializeConnection() async {
    try {
      // 检查当前连接状态
      if (!await widget.device.isConnected) {
        throw Exception('设备未连接');
      }

      // 发现服务（带超时）
      final services = await widget.device.discoverServices()
          .timeout(const Duration(seconds: 5));

      // 查找目标服务
      final targetService = services.firstWhere(
            (s) => s.uuid.toString().toLowerCase() == widget.serviceUUID.toLowerCase(),
        orElse: () => throw Exception('找不到服务: ${widget.serviceUUID}'),
      );

      // 查找特征值
      _controlChar = targetService.characteristics.firstWhere(
            (c) => c.uuid.toString().toLowerCase() == widget.characteristicUUID.toLowerCase(),
        orElse: () => throw Exception('找不到特征: ${widget.characteristicUUID}'),
      );

      // 验证写入权限
      if (!_controlChar!.properties.write) {
        throw Exception('特征不可写');
      }

      // 设置连接监听
      _connectionSub = widget.device.connectionState.listen((state) {
        final connected = state == BluetoothConnectionState.connected;
        if (!connected) {
          if (mounted) {
            setState(() => _isConnected = false);
            Navigator.pop(context);
          }
        }
      });

      if (mounted) setState(() => _isConnected = true);

    } catch (e) {
      _showError(e.toString());
      if (mounted) Navigator.pop(context);
    }
  }

  void _sendSpeedCommand(double speed) async {
    try {
      final value = speed.toInt().clamp(0, 100);
      await _controlChar?.write([0x01, value]);
      if (mounted) setState(() => _motorSpeed = speed);
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('电机调速'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFF1A1B1E),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '当前转速: ${_motorSpeed.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Slider(
              value: _motorSpeed,
              min: 0,
              max: 100,
              divisions: 100,
              label: _motorSpeed.toStringAsFixed(0),
              activeColor: Colors.blueAccent,
              inactiveColor: Colors.blueGrey,
              onChanged: (value) => setState(() => _motorSpeed = value),
              onChangeEnd: _sendSpeedCommand,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 15,
              children: [25, 50, 75, 100].map((speed) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _motorSpeed == speed
                        ? Colors.blue
                        : Colors.blue.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                  onPressed: () => _sendSpeedCommand(speed.toDouble()),
                  child: Text(
                    '$speed%',
                    style: TextStyle(
                      color: _motorSpeed == speed
                          ? Colors.white
                          : Colors.blue,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    super.dispose();
  }
}