import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class FinancialDashboardScreen extends StatefulWidget {
  const FinancialDashboardScreen({super.key});

  @override
  State<FinancialDashboardScreen> createState() =>
      _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends State<FinancialDashboardScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadDashboard();
  }

  Future<Map<String, dynamic>> _loadDashboard() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/billing/admin/financial-dashboard'),
      headers: AuthService.authHeaders,
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      final detail = decoded is Map<String, dynamic>
          ? decoded['detail']?.toString()
          : null;
      throw Exception(detail ?? 'No se pudo cargar el dashboard financiero.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Respuesta inválida del servidor.');
    }

    return decoded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Dashboard financiero'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data ?? {};
          final plans = data['plans'] is Map<String, dynamic>
              ? data['plans'] as Map<String, dynamic>
              : <String, dynamic>{};

          return ListView(
            padding: const EdgeInsets.all(22),
            children: [
              const Text(
                'Monetización StudyBook AI',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'MRR, ARR, conversión, usuarios y margen bruto estimado.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _MetricCard(label: 'MRR', value: _money(data['mrr'])),
                  _MetricCard(label: 'ARR', value: _money(data['arr'])),
                  _MetricCard(
                    label: 'Usuarios pagos',
                    value: '${data['paid_users'] ?? 0}',
                  ),
                  _MetricCard(
                    label: 'Usuarios free',
                    value: '${data['free_users'] ?? 0}',
                  ),
                  _MetricCard(
                    label: 'Conversión',
                    value: '${data['conversion_rate'] ?? 0}%',
                  ),
                  _MetricCard(
                    label: 'Margen bruto',
                    value: _money(data['estimated_gross_margin']),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Planes',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ...plans.entries.map((entry) {
                final value = entry.value is Map<String, dynamic>
                    ? entry.value as Map<String, dynamic>
                    : <String, dynamic>{};

                return Card(
                  child: ListTile(
                    title: Text(
                      entry.key.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      'Usuarios: ${value['users'] ?? 0} | Activos: ${value['active_users'] ?? 0}',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                    trailing: Text(
                      _money(value['mrr']),
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  static String _money(dynamic value) {
    final number = value is num ? value.toDouble() : 0.0;
    return 'US\$${number.toStringAsFixed(2)}';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
