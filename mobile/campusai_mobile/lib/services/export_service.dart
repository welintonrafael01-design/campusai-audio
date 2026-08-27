import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'auth_service.dart';
import 'platform_file_service.dart';

class ExportService {
  static Future<void> exportTextToPdf({
    required String title,
    required String content,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/export/pdf'),
          headers: {
            'Content-Type': 'application/json',
            ...AuthService.authHeaders,
          },
          body: jsonEncode({
            'title': title,
            'content': content,
          }),
        )
        .timeout(ApiService.timeoutDuration);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwExportError('No se pudo exportar PDF.', response);
    }

    await PlatformFileService.saveBinaryFile(
      filename: '${_safeFileName(title)}.pdf',
      bytes: response.bodyBytes,
      dialogTitle: 'Guardar PDF',
    );
  }

  static Future<void> exportTextToDocx({
    required String title,
    required String content,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/export/docx'),
          headers: {
            'Content-Type': 'application/json',
            ...AuthService.authHeaders,
          },
          body: jsonEncode({
            'title': title,
            'content': content,
          }),
        )
        .timeout(ApiService.timeoutDuration);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwExportError('No se pudo exportar DOCX.', response);
    }

    await PlatformFileService.saveBinaryFile(
      filename: '${_safeFileName(title)}.docx',
      bytes: response.bodyBytes,
      dialogTitle: 'Guardar documento Word',
    );
  }

  static Future<void> exportTextToPptx({
    required String title,
    required String content,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/export/pptx'),
          headers: {
            'Content-Type': 'application/json',
            ...AuthService.authHeaders,
          },
          body: jsonEncode({
            'title': title,
            'content': content,
          }),
        )
        .timeout(ApiService.timeoutDuration);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwExportError('No se pudo exportar PPTX.', response);
    }

    await PlatformFileService.saveBinaryFile(
      filename: '${_safeFileName(title)}.pptx',
      bytes: response.bodyBytes,
      dialogTitle: 'Guardar presentación',
    );
  }

  static Future<void> exportRowsToXlsx({
    required String title,
    required List<Map<String, dynamic>> rows,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/export/xlsx'),
          headers: {
            'Content-Type': 'application/json',
            ...AuthService.authHeaders,
          },
          body: jsonEncode({
            'title': title,
            'rows': rows,
          }),
        )
        .timeout(ApiService.timeoutDuration);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwExportError('No se pudo exportar Excel.', response);
    }

    await PlatformFileService.saveBinaryFile(
      filename: '${_safeFileName(title)}.xlsx',
      bytes: response.bodyBytes,
      dialogTitle: 'Guardar archivo Excel',
    );
  }

  static Future<void> exportFinalReportToPdf({
    required String title,
    required String courseName,
    required List<Map<String, dynamic>> rows,
    required Map<String, dynamic> stats,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/export/final-report-pdf'),
          headers: {
            'Content-Type': 'application/json',
            ...AuthService.authHeaders,
          },
          body: jsonEncode({
            'title': title,
            'course_name': courseName,
            'rows': rows,
            'stats': stats,
          }),
        )
        .timeout(ApiService.timeoutDuration);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwExportError('No se pudo exportar Acta PDF.', response);
    }

    await PlatformFileService.saveBinaryFile(
      filename: '${_safeFileName(title)}_acta_final.pdf',
      bytes: response.bodyBytes,
      dialogTitle: 'Guardar acta final',
    );
  }

  static Future<void> exportTeachingPlanToPdf({
    required String title,
    required Map<String, dynamic> plan,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/export/teaching-plan-pdf'),
          headers: {
            'Content-Type': 'application/json',
            ...AuthService.authHeaders,
          },
          body: jsonEncode({
            'title': title,
            'plan': plan,
          }),
        )
        .timeout(ApiService.timeoutDuration);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwExportError('No se pudo exportar planificación PDF.', response);
    }

    await PlatformFileService.saveBinaryFile(
      filename: '${_safeFileName(title)}_planificacion.pdf',
      bytes: response.bodyBytes,
      dialogTitle: 'Guardar planificación',
    );
  }

  static Future<void> exportRubricToPdf({
    required String title,
    required Map<String, dynamic> rubric,
    Map<String, dynamic>? student,
    Map<String, dynamic>? scores,
    Map<String, dynamic>? observations,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/export/rubric-pdf'),
          headers: {
            'Content-Type': 'application/json',
            ...AuthService.authHeaders,
          },
          body: jsonEncode({
            'title': title,
            'rubric': rubric,
            'student': student ?? {},
            'scores': scores ?? {},
            'observations': observations ?? {},
          }),
        )
        .timeout(ApiService.timeoutDuration);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwExportError('No se pudo exportar rúbrica PDF.', response);
    }

    await PlatformFileService.saveBinaryFile(
      filename: '${_safeFileName(title)}_rubrica.pdf',
      bytes: response.bodyBytes,
      dialogTitle: 'Guardar rúbrica',
    );
  }

  static Future<void> exportExamToPdf({
    required String title,
    required List<Map<String, dynamic>> questions,
    bool includeAnswers = false,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/export/exam-pdf'),
          headers: {
            'Content-Type': 'application/json',
            ...AuthService.authHeaders,
          },
          body: jsonEncode({
            'title': title,
            'questions': questions,
            'include_answers': includeAnswers,
          }),
        )
        .timeout(ApiService.timeoutDuration);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwExportError('No se pudo exportar examen PDF.', response);
    }

    await PlatformFileService.saveBinaryFile(
      filename: '${_safeFileName(title)}_examen.pdf',
      bytes: response.bodyBytes,
      dialogTitle: 'Guardar examen',
    );
  }

  static Future<void> exportCertificateToPdf({
    required String studentName,
    required String studentCode,
    required String courseName,
    required String average,
    String period = '',
    String certificateTitle = 'CERTIFICADO ACADÉMICO',
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/export/certificate-pdf'),
          headers: {
            'Content-Type': 'application/json',
            ...AuthService.authHeaders,
          },
          body: jsonEncode({
            'student_name': studentName,
            'student_code': studentCode,
            'course_name': courseName,
            'average': average,
            'period': period,
            'certificate_title': certificateTitle,
          }),
        )
        .timeout(ApiService.timeoutDuration);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwExportError('No se pudo exportar certificado PDF.', response);
    }

    await PlatformFileService.saveBinaryFile(
      filename: '${_safeFileName(studentName)}_certificado.pdf',
      bytes: response.bodyBytes,
      dialogTitle: 'Guardar certificado',
    );
  }

  static Future<void> exportAcademicBadgeToPdf({
    required String studentName,
    required String studentCode,
    required String courseName,
    required String average,
    String badgeTitle = 'Curso Aprobado',
    String certificateId = '',
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/export/academic-badge-pdf'),
          headers: {
            'Content-Type': 'application/json',
            ...AuthService.authHeaders,
          },
          body: jsonEncode({
            'student_name': studentName,
            'student_code': studentCode,
            'course_name': courseName,
            'badge_title': badgeTitle,
            'average': average,
            'certificate_id': certificateId,
          }),
        )
        .timeout(ApiService.timeoutDuration);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwExportError(
        'No se pudo exportar insignia académica PDF.',
        response,
      );
    }

    await PlatformFileService.saveBinaryFile(
      filename: '${_safeFileName(studentName)}_insignia.pdf',
      bytes: response.bodyBytes,
      dialogTitle: 'Guardar insignia académica',
    );
  }

  static Future<void> exportStudentTranscriptToPdf({
    required String studentName,
    required String studentCode,
    required String generalAverage,
    required String attendanceAverage,
    required String gpa4,
    required String academicStanding,
    required List<String> distinctions,
    required int rankingPosition,
    required int rankingTotal,
    required double rankingPercentile,
    required List<Map<String, dynamic>> courses,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/export/student-transcript-pdf'),
          headers: {
            'Content-Type': 'application/json',
            ...AuthService.authHeaders,
          },
          body: jsonEncode({
            'student_name': studentName,
            'student_code': studentCode,
            'general_average': generalAverage,
            'attendance_average': attendanceAverage,
            'gpa4': gpa4,
            'academic_standing': academicStanding,
            'distinctions': distinctions,
            'ranking_position': rankingPosition,
            'ranking_total': rankingTotal,
            'ranking_percentile': rankingPercentile,
            'courses': courses,
          }),
        )
        .timeout(ApiService.timeoutDuration);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwExportError(
        'No se pudo exportar expediente académico PDF.',
        response,
      );
    }

    await PlatformFileService.saveBinaryFile(
      filename: '${_safeFileName(studentName)}_expediente.pdf',
      bytes: response.bodyBytes,
      dialogTitle: 'Guardar expediente académico',
    );
  }

  static String _safeFileName(String title) {
    final clean = title.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');

    if (clean.isEmpty) {
      return 'studybook_export';
    }

    return clean.length > 80 ? clean.substring(0, 80) : clean;
  }

  static Never _throwExportError(String action, http.Response response) {
    final detail = ApiService.safeErrorMessage(
      statusCode: response.statusCode,
      body: response.body,
    );
    throw Exception('$action $detail');
  }
}
