import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class CertificateVerifyScreen extends StatefulWidget {
  final String certificateId;

  const CertificateVerifyScreen({
    super.key,
    required this.certificateId,
  });

  @override
  State<CertificateVerifyScreen> createState() =>
      _CertificateVerifyScreenState();
}

class _CertificateVerifyScreenState extends State<CertificateVerifyScreen> {
  bool loading = true;
  String error = '';
  Map<String, dynamic>? certificate;

  @override
  void initState() {
    super.initState();
    verifyCertificate();
  }

  String get resolvedCertificateId {
    final uri = Uri.base;
    final fromQuery = uri.queryParameters['id'] ??
        uri.queryParameters['certificate_id'] ??
        uri.queryParameters['code'];

    final raw = fromQuery?.trim().isNotEmpty == true
        ? fromQuery!.trim()
        : widget.certificateId.trim();

    return raw;
  }

  Future<void> verifyCertificate() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final id = resolvedCertificateId;

      if (id.isEmpty) {
        throw Exception('Debe indicar un código de certificado.');
      }

      final uri = Uri.parse(
        '${ApiService.baseUrl}/certificates/verify/$id',
      );

      final response = await http.get(uri).timeout(ApiService.timeoutDuration);

      if (response.statusCode != 200) {
        throw Exception('Certificado no encontrado.');
      }

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        certificate = Map<String, dynamic>.from(data);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  String formatIssuedAt(String raw) {
    if (raw.trim().isEmpty) return 'No especificado';

    final parsed = DateTime.tryParse(raw);

    if (parsed == null) return raw;

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();

    return '$day/$month/$year';
  }

  String formatStatus(String raw) {
    final clean = raw.toLowerCase().trim();

    if (clean == 'valid') return 'Certificado vigente';
    if (clean == 'revoked') return 'Certificado revocado';
    if (clean == 'expired') return 'Certificado expirado';

    return raw.isEmpty ? 'No especificado' : raw;
  }

  String recognitionLabel(String type) {
    final clean = type.trim().toLowerCase();

    return switch (clean) {
      'gold_medal' => 'Medalla Oro',
      'silver_medal' => 'Medalla Plata',
      'bronze_medal' => 'Medalla Bronce',
      'excellence' => 'Excelencia Académica',
      'honor' => 'Honor Académico',
      'badge' => 'Insignia Académica',
      'certificate' => 'Certificado Académico',
      _ => 'Reconocimiento Académico',
    };
  }

  @override
  Widget build(BuildContext context) {
    final valid = certificate?['valid'] == true;
    final id = resolvedCertificateId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación Pública'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'STUDYBOOK AI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sistema de Certificación Académica Verificable',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 24),
                    Icon(
                      loading
                          ? Icons.hourglass_top_rounded
                          : valid
                              ? Icons.verified_rounded
                              : Icons.error_rounded,
                      size: 78,
                      color: loading
                          ? AppTheme.accent
                          : valid
                              ? AppTheme.success
                              : Colors.orange,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      loading
                          ? 'Verificando certificado...'
                          : valid
                              ? 'Certificado válido'
                              : 'Certificado no válido',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      id,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (error.isNotEmpty)
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'No fue posible verificar este certificado.',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ),
                )
              else if (certificate != null)
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Datos verificados',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Tipo',
                        value: recognitionLabel(
                          '${certificate?['recognition_type'] ?? 'certificate'}',
                        ),
                      ),
                      _InfoRow(
                        label: 'Estudiante',
                        value: '${certificate?['student_name'] ?? ''}',
                      ),
                      _InfoRow(
                        label: 'Matrícula',
                        value: '${certificate?['student_code'] ?? ''}',
                      ),
                      _InfoRow(
                        label: 'Curso',
                        value: '${certificate?['course_name'] ?? ''}',
                      ),
                      _InfoRow(
                        label: 'Promedio',
                        value: '${certificate?['average'] ?? ''}',
                      ),
                      _InfoRow(
                        label: 'Período',
                        value: '${certificate?['period'] ?? 'No especificado'}',
                      ),
                      _InfoRow(
                        label: 'Fecha de emisión',
                        value: formatIssuedAt(
                          '${certificate?['issued_at'] ?? ''}',
                        ),
                      ),
                      _InfoRow(
                        label: 'Estado',
                        value: formatStatus('${certificate?['status'] ?? ''}'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              SectionCard(
                child: const Text(
                  'Este portal permite verificar la autenticidad de certificados, insignias y reconocimientos emitidos por StudyBook AI.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
