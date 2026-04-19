import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/esp_service.dart';
import 'controllers/neural_controller.dart';
import 'widgets/neural_graph.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => NeuralController(EspService()),
      child: const NeuralGateApp(),
    ),
  );
}

class NeuralGateApp extends StatelessWidget {
  const NeuralGateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050505),
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF007AFF), brightness: Brightness.dark),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0B10), Color(0xFF050505)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    const Text("NEURALGATE",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: Colors.white)),
                    const SizedBox(height: 5),
                    Consumer<NeuralController>(
                      builder: (context, ctrl, _) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(ctrl.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_searching, 
                            size: 14, 
                            color: ctrl.isConnected ? Colors.greenAccent : Colors.white54),
                          const SizedBox(width: 5),
                          Text(ctrl.isConnected ? "Bluetooth Connected" : "Disconnected",
                              style: TextStyle(
                                fontSize: 12, 
                                color: ctrl.isConnected ? Colors.greenAccent : Colors.white54,
                                fontWeight: FontWeight.bold
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // GRAPH CARD
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Consumer<NeuralController>(
                    builder: (context, ctrl, _) => AnimatedBuilder(
                      animation: Listenable.merge([ctrl.pointsNotifier, ctrl.graphMaxNotifier]),
                      builder: (context, _) => NeuralGraph(
                        points: ctrl.pointsNotifier.value,
                        threshold: ctrl.threshold,
                        graphMax: ctrl.graphMaxNotifier.value,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // CONTROL CARD
              Expanded(
                flex: 4,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121214),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: const SingleChildScrollView(child: ControlLayout()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ControlLayout extends StatelessWidget {
  const ControlLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<NeuralController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("SELECT DEVICE",
            style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
        Selector<NeuralController, String>(
          selector: (_, c) => c.activeMode,
          builder: (context, mode, _) => DropdownButton<String>(
            value: mode,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: const Color(0xFF1C1C1E),
            items: const [
              DropdownMenuItem(value: "relay", child: Text("Relay Module")),
              DropdownMenuItem(value: "phone", child: Text("Smartphone")),
              DropdownMenuItem(value: "sos", child: Text("SOS Mode")),
            ],
            onChanged: (v) => controller.setMode(v!),
          ),
        ),
        const Divider(color: Colors.white10, height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("LIMIT",
                style: TextStyle(
                    color: Color(0xFF007AFF), fontWeight: FontWeight.bold)),
            Selector<NeuralController, double>(
              selector: (_, c) => c.threshold,
              builder: (context, th, _) => Text("${th.toInt()}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        Selector<NeuralController, double>(
          selector: (_, c) => c.threshold,
          builder: (context, th, _) => Slider(
            value: th,
            min: 10,
            max: 500,
            activeColor: const Color(0xFF007AFF),
            onChanged: (v) => controller.setThreshold(v),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () => controller.triggerManual(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 65),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 10,
            shadowColor: const Color(0xFF007AFF).withValues(alpha: 0.4),
          ),
          child: const Text("MANUAL TRIGGER",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
