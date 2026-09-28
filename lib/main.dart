import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// TEMPORAIRE (Phase F0) : sera déplacé dans une config d'environnement en F1.
// 10.0.2.2 = le "localhost" de ton PC vu depuis l'émulateur Android.
const String apiBaseUrl = 'http://10.0.2.2:3000';

void main() => runApp(const AfriMarketApp());

class AfriMarketApp extends StatelessWidget {
  const AfriMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AfriMarket',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const HealthCheckPage(),
    );
  }
}

class HealthCheckPage extends StatefulWidget {
  const HealthCheckPage({super.key});

  @override
  State<HealthCheckPage> createState() => _HealthCheckPageState();
}

class _HealthCheckPageState extends State<HealthCheckPage> {
  bool _loading = false;
  bool? _success;
  String _message = 'Appuie sur le bouton pour tester le backend';

  Future<void> _checkBackend() async {
    setState(() => _loading = true);

    try {
      final response = await http
          .get(Uri.parse('$apiBaseUrl/api/health'))
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      setState(() {
        _success = response.statusCode == 200 && data['status'] == 'ok';
        _message = 'Status : ${data['status']}\n'
            'Base de données : ${data['database']}\n'
            'WebSocket : ${data['websocket']}';
      });
    } on TimeoutException {
      setState(() {
        _success = false;
        _message = 'Délai dépassé : le backend est-il démarré ?';
      });
    } catch (e) {
      setState(() {
        _success = false;
        _message = 'Erreur de connexion :\n$e';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _success == null
        ? Icons.cloud_outlined
        : (_success! ? Icons.check_circle : Icons.error);
    final color = _success == null
        ? Colors.grey
        : (_success! ? Colors.green : Colors.red);

    return Scaffold(
      appBar: AppBar(title: const Text('AfriMarket – Test backend')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 80, color: color),
              const SizedBox(height: 24),
              Text(_message, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loading ? null : _checkBackend,
                icon: _loading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.wifi_tethering),
                label: const Text('Tester la connexion'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}