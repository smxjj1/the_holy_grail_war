import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'dart:math' as math;
import 'basic_control_page.dart';
import 'more_features_page.dart';

class DevicePage extends StatefulWidget {
  const DevicePage({Key? key}) : super(key: key);

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  BluetoothDevice? connectedDevice;
  List<BluetoothDevice> discoveredDevices = [];
  bool isScanning = false;
  
  // 添加订阅变量以便于在dispose中取消
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<bool>? _isScanningSubscription;

  @override
  void initState() {
    super.initState();
    // 检查蓝牙状态
    _checkBluetoothState();
  }
  
  @override
  void dispose() {
    // 取消所有订阅，防止内存泄漏
    _adapterStateSubscription?.cancel();
    _scanResultsSubscription?.cancel();
    _isScanningSubscription?.cancel();
    
    // 确保停止扫描
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  // 检查蓝牙状态
  void _checkBluetoothState() async {
    try {
      // 检查蓝牙是否支持
      if (await FlutterBluePlus.isSupported == false) {
        _showError('设备不支持蓝牙');
        return;
      }

      // 监听蓝牙状态变化
      _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
        if (state == BluetoothAdapterState.on) {
          // 蓝牙已开启
        } else {
          // 蓝牙未开启
          _showError('请开启蓝牙');
          // 尝试请求用户开启蓝牙
          FlutterBluePlus.turnOn();
        }
      });
    } catch (e) {
      _showError('蓝牙初始化失败: $e');
    }
  }

  // 开始扫描设备
  void _startScan() async {
    setState(() {
      discoveredDevices.clear();
      isScanning = true;
    });

    try {
      // 确保蓝牙已开启
      if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on) {
        // 取消之前的订阅
        _scanResultsSubscription?.cancel();
        _isScanningSubscription?.cancel();
        
        // 监听扫描结果
        _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
          setState(() {
            discoveredDevices = results.map((result) => result.device).toList();
          });
        });

        // 监听扫描状态
        _isScanningSubscription = FlutterBluePlus.isScanning.listen((scanning) {
          setState(() {
            isScanning = scanning;
          });
        });
        
        // 开始扫描
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 60));
        
        // 显示搜索对话框
        _showSearchDialog();
      } else {
        _showError('请开启蓝牙');
        // 尝试请求用户开启蓝牙
        FlutterBluePlus.turnOn();
      }
    } catch (e) {
      _showError('扫描失败: $e');
      setState(() {
        isScanning = false;
      });
    }
  }

  // 连接设备
  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      // 先显示连接中的提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('正在连接设备...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // 使用基本连接方法，添加超时处理
      await device.connect().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('连接超时，请重试');
        },
      );
      
      // 如果没有抛出异常，说明连接成功
      setState(() {
        connectedDevice = device;
      });
      
      // 关闭搜索对话框
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      _showConnectSuccessSnackBar();
    } catch (e) {
      String errorMsg = '连接失败: $e';
      
      // 提供更详细的错误信息
      if (e.toString().contains('requestMtu') || e.toString().contains('Timed out')) {
        errorMsg = '连接超时，设备MTU协商失败。尝试再次连接或选择其他设备。';
        
        // 可选：尝试在MTU错误后使用不同的方式连接
        try {
          // 停止之前的连接尝试
          await device.disconnect().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              // 忽略断开连接超时
              return;
            },
          );
          
          // 短暂延迟后重试连接
          await Future.delayed(const Duration(seconds: 2));
          
          // 重新尝试连接，不做额外处理
          await device.connect().timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('重试连接也超时');
            },
          );
          
          setState(() {
            connectedDevice = device;
          });
          
          // 关闭搜索对话框
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          
          _showConnectSuccessSnackBar();
          return; // 连接成功，直接返回
        } catch (retryError) {
          // 重试也失败，继续使用原来的错误信息
          print('重试连接也失败: $retryError');
        }
      }
      
      _showError(errorMsg);
      
      // 即使连接失败也关闭对话框
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  // 断开设备连接
  Future<void> _disconnectDevice() async {
    if (connectedDevice != null) {
      try {
        await connectedDevice!.disconnect();
        setState(() {
          connectedDevice = null;
        });
        _showDisconnectSnackBar();
      } catch (e) {
        _showError('断开连接失败: $e');
      }
    }
  }

  // 显示搜索对话框
  void _showSearchDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1B1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: Colors.amber.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.wifi,
                        color: Colors.amber,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        isScanning ? '设备搜寻中...' : '可用设备',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      FlutterBluePlus.stopScan();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                constraints: BoxConstraints(maxHeight: 300),
                child: StreamBuilder<List<ScanResult>>(
                  stream: FlutterBluePlus.scanResults,
                  initialData: const [],
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final result = snapshot.data![index];
                        final device = result.device;
                        
                        // 修改获取设备名称的逻辑，按优先级检查多个可能的名称来源
                        final deviceName = _getDeviceName(device, result.advertisementData);
                        
                        final rssi = result.rssi; // 信号强度
                        final macAddress = device.remoteId.toString(); // MAC 地址或设备 ID

                        return ListTile(
                          title: Text(
                            deviceName,
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MAC: $macAddress',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                '信号强度: $rssi dBm',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: Icon(Icons.chevron_right, color: Colors.white),
                          onTap: () => _connectToDevice(device),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // 显示连接成功的提示
  void _showConnectSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('成功连接到 ${_getDeviceName(connectedDevice!, null)}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // 显示断开连接的提示
  void _showDisconnectSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已断开设备连接'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // 添加一个辅助方法来获取设备名称
  String _getDeviceName(BluetoothDevice device, AdvertisementData? advertisementData) {
    // 按照优先级检查不同的名称来源
    // 1. 检查广播数据中的名称
    if (advertisementData != null && advertisementData.advName.isNotEmpty) {
      return advertisementData.advName;
    }
    
    // 2. 检查设备的平台名称
    if (device.platformName.isNotEmpty) {
      return device.platformName;
    }
    
    // 3. 检查设备的本地名称（如果 flutter_blue_plus 版本支持）
    try {
      if (device.localName.isNotEmpty) {
        return device.localName;
      }
    } catch (e) {
      // 忽略错误，可能是旧版本的 flutter_blue_plus 不支持 localName
    }
    
    // 4. 使用设备ID的最后几位作为标识
    final id = device.remoteId.toString();
    if (id.isNotEmpty) {
      return "设备_${id.substring(math.max(0, id.length - 5))}";
    }
    
    // 5. 最后才返回未知设备
    return '未知设备';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B1E), // 深色背景
      body: SafeArea(
        child: Column(
          children: [
            // 顶部用户信息
            _buildUserHeader(),

            // 主要内容区域
            Expanded(
              child: Stack(
                children: [
                  // 网格背景
                  _buildGridBackground(),

                  // 主要内容
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // 功能模块
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildFeatureItem(
                              context,
                              '基础控制',
                                  () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BasicControlPage(),
                                ),
                              ),
                            ),
                            _buildFeatureItem(
                              context,
                              '更多玩法',
                                  () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MoreFeaturesPage(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        // 当前设备
                        _buildCurrentDevice(),
                      ],
                    ),
                  ),
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
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withOpacity(0.1),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.purple.withOpacity(0.5), Colors.blue.withOpacity(0.5)],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '您好！头号玩家',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Icon(Icons.more_horiz, color: Colors.white.withOpacity(0.7)),
        ],
      ),
    );
  }

  Widget _buildGridBackground() {
    return CustomPaint(
      size: Size.infinite,
      painter: GridPainter(),
    );
  }

  Widget _buildFeatureItem(
      BuildContext context,
      String title,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.cyan.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  colors: [
                    Colors.cyan.withOpacity(0.5),
                    Colors.blue.withOpacity(0.5),
                  ],
                ),
              ),
              child: Icon(
                title == '基础控制' ? Icons.gamepad : Icons.more_horiz,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentDevice() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.cyan.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.pink.withOpacity(0.5),
                  Colors.purple.withOpacity(0.5),
                ],
              ),
            ),
            child: const Icon(
              Icons.devices,
              color: Colors.white,
              size: 80,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '当前设备：${connectedDevice?.platformName ?? "未连接"}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildControlButton(Icons.add, '搜索', onTap: _startScan),
              _buildControlButton(Icons.remove, '断开', onTap: _disconnectDevice),
              _buildControlButton(Icons.delete, '删除'),
              _buildControlButton(
                Icons.bluetooth,
                '蓝牙',
                onTap: _checkBluetoothState,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.cyan.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.cyan,
        ),
      ),
    );
  }
}

// 网格背景绘制
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.1)
      ..strokeWidth = 0.5;

    final spacing = 30.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}