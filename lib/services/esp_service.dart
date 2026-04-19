import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class EspService {
  final StreamController<double> _dataController = StreamController<double>.broadcast();
  final StreamController<bool> _connectionStateController = StreamController<bool>.broadcast();
  
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;
  bool isConnected = false;

  // The EXACT UUIDs from your ESP32 code
  final String serviceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  final String notifyUuid = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";
  final String writeUuid = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";

  Stream<double> get signalStream => _dataController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  EspService({String host = ""}) {
    _initBle();
  }

  void _initBle() {
    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        _scanForDevice();
      }
    });
  }

  void _scanForDevice() async {
    // Start scanning for the specific name
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        // Checking both platformName and advName for compatibility
        if (r.device.platformName == 'NeuralGate_Pro_BLE' || r.device.advName == 'NeuralGate_Pro_BLE') {
          FlutterBluePlus.stopScan();
          _connectToDevice(r.device);
          break;
        }
      }
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    _device = device;
    
    // Monitor connection state
    device.connectionState.listen((BluetoothConnectionState state) {
      isConnected = state == BluetoothConnectionState.connected;
      _connectionStateController.add(isConnected);
      if (state == BluetoothConnectionState.disconnected) {
        _scanForDevice(); // Auto-reconnect
      }
    });

    try {
      await device.connect(autoConnect: false);
      
      // Request MTU increase for smooth data
      await device.requestMtu(512);

      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      
      for (var service in services) {
        if (service.uuid.toString().toUpperCase() == serviceUuid) {
          for (var char in service.characteristics) {
            String cUuid = char.uuid.toString().toUpperCase();
            
            // 1. Setup Data Stream (Notify)
            if (cUuid == notifyUuid) {
              await char.setNotifyValue(true);
              char.lastValueStream.listen((value) {
                if (value.isNotEmpty) {
                  try {
                    String decoded = utf8.decode(value);
                    // Parse the raw float string sent by ESP32: pSignalChar->setValue(data.c_str());
                    double? val = double.tryParse(decoded.trim());
                    if (val != null) {
                      _dataController.add(val);
                    }
                  } catch (e) {
                    print("Decoding error: $e");
                  }
                }
              });
            } 
            
            // 2. Setup Command Channel (Write)
            if (cUuid == writeUuid) {
              _writeCharacteristic = char;
            }
          }
        }
      }
    } catch (e) {
      print("BLE connection error: $e");
    }
  }

  // Updated to match your ESP32 Logic
  Future<void> sendCommand(String command) async {
    if (_writeCharacteristic != null && isConnected) {
      try {
        // command will be "M" for manual or "T:value" for threshold
        await _writeCharacteristic!.write(utf8.encode(command), withoutResponse: false);
        print("Sent command: $command");
      } catch (e) {
        print("Write failed: $e");
      }
    }
  }

  void dispose() {
    _device?.disconnect();
    _dataController.close();
    _connectionStateController.close();
  }
}