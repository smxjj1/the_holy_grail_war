import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'device_page.dart';

class BasicControlPage extends StatefulWidget {
  final ConnectedDevice connectedDevice;
  final BluetoothCharacteristic characteristic;

  const BasicControlPage({
    Key? key,
    required this.connectedDevice,
    required this.characteristic,
  }) : super(key: key);

  @override
  State<BasicControlPage> createState() => _BasicControlPageState();
}

class _BasicControlPageState extends State<BasicControlPage> {
  bool _isSwitchOn = false; // 开关状态
  bool _isConnected = true;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  StreamSubscription<List<int>>? _valueSub;

  @override
  void initState() {
    super.initState();
    _initializeConnection();
  }

  Future<void> _initializeConnection() async {
    try {
      if (!await widget.connectedDevice.device.isConnected) {
        throw Exception('设备未连接');
      }

      _connectionSub = widget.connectedDevice.device.connectionState.listen((state) {
        final connected = state == BluetoothConnectionState.connected;
        if (!connected && mounted) {
          setState(() => _isConnected = false);
          Navigator.pop(context);
        }
      });

      if (widget.characteristic.properties.notify) {
        await widget.characteristic.setNotifyValue(true);
        _valueSub = widget.characteristic.value.listen((value) {
          _handleReceivedData(value);
        });
      }

      if (mounted) setState(() => _isConnected = true);

    } catch (e) {
      _showError(e.toString());
      if (mounted) Navigator.pop(context);
    }
  }

  void _handleReceivedData(List<int> value) {
    String hexValue = value.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' ');
    debugPrint('接收到数据: $hexValue');
    _showMessage('HEX: $hexValue', Colors.blue);
  }

  static final _onCommand = utf8.encode('c');  // 生成[99]
  static final _offCommand = utf8.encode('b'); // 生成[98]
  // 发送开关信号
  Future<void> _sendSwitchSignal(bool isOn) async {
    try {
      final data = isOn ? _onCommand : _offCommand;

      // 调试输出实际发送的十进制值
      debugPrint('发送原始字节: $data (DEC)');

      // 强制使用无响应式写入（根据BLE特征属性）
      await widget.characteristic.write(data,
          withoutResponse: widget.characteristic.properties.writeWithoutResponse);

      // 增加物理层延迟（确保数据包间隔）
      await Future.delayed(Duration(milliseconds: 50));

      if (mounted) setState(() => _isSwitchOn = isOn);
    } catch (e) {
      debugPrint('发送错误: ${e.toString()}');
      if (mounted) setState(() => _isSwitchOn = !isOn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('基础控制'),
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
              '当前状态: ${_isSwitchOn ? "开 (c)" : "关 (b)"}', // 显示对应指令
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Switch(
              value: _isSwitchOn,
              onChanged: (value) => _sendSwitchSignal(value),
              activeColor: Colors.blueAccent,
              inactiveThumbColor: Colors.blueGrey,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    _valueSub?.cancel();
    if (widget.characteristic.properties.notify) {
      widget.characteristic.setNotifyValue(false);
    }
    super.dispose();
  }

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
}
