import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'clinic_models.dart';

class ClinicApiException implements Exception {
  const ClinicApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ClinicSnapshot {
  const ClinicSnapshot(this.branches, this.reports, this.inventory);
  final List<Branch> branches;
  final List<DailyReport> reports;
  final List<MedicineBatch> inventory;
}

String defaultApiBaseUrl() {
  const configured = String.fromEnvironment('API_BASE_URL');
  if (configured.isNotEmpty) return configured;
  final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : '127.0.0.1';
  return 'http://$host:8000/api/v1';
}

class ClinicApi {
  ClinicApi({String? baseUrl, http.Client? client})
    : baseUrl = (baseUrl ?? defaultApiBaseUrl()).replaceFirst(
        RegExp(r'/+$'),
        '',
      ),
      _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<dynamic> _request(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    try {
      final request = http.Request(method, Uri.parse('$baseUrl/$path'));
      request.headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      });
      if (body != null) request.body = jsonEncode(body);
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 12));
      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errors = decoded['errors'] as Map<String, dynamic>?;
        final message = errors == null
            ? decoded['message'] as String?
            : errors.values.expand((v) => v as List).join('\n');
        throw ClinicApiException(
          message ??
              'The server could not complete this request (${response.statusCode}).',
        );
      }
      return decoded['data'];
    } on TimeoutException {
      throw const ClinicApiException(
        'The server took too long to respond. Check the connection and retry.',
      );
    } on http.ClientException {
      throw const ClinicApiException(
        'Cannot connect to the clinic server. Check that it is available and retry.',
      );
    } on FormatException {
      throw const ClinicApiException(
        'The server returned an invalid response. Check the API URL.',
      );
    }
  }

  Future<ClinicSnapshot> load() async {
    final data = await Future.wait([
      _request('GET', 'branches'),
      _request('GET', 'reports'),
      _request('GET', 'medicine-batches'),
    ]);
    return ClinicSnapshot(
      (data[0] as List)
          .map((j) => Branch.fromJson(j as Map<String, dynamic>))
          .toList(),
      (data[1] as List)
          .map((j) => DailyReport.fromJson(j as Map<String, dynamic>))
          .toList(),
      (data[2] as List)
          .map((j) => MedicineBatch.fromJson(j as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<DailyReport> saveReport(DailyReport report, int branchId) async =>
      DailyReport.fromJson(
        await _request(
          'PUT',
          'branches/$branchId/reports/${apiDate(report.date)}',
          report.toJson(),
        ) as Map<String, dynamic>,
      );

  Future<MedicineBatch> addBatch(MedicineBatch batch, int branchId) async =>
      MedicineBatch.fromJson(
        await _request('POST', 'medicine-batches', {
          'branch_id': branchId,
          'name': batch.name,
          'quantity': batch.quantity,
          'unit': batch.unit,
          'expiry': apiDate(batch.expiry),
          'threshold': batch.threshold,
        }) as Map<String, dynamic>,
      );

  Future<MedicineBatch> updateStock(
    int id,
    int quantity, {
    required bool adding,
  }) async => MedicineBatch.fromJson(
    await _request('PATCH', 'medicine-batches/$id', {
      'operation': adding ? 'restock' : 'set',
      'quantity': quantity,
    }) as Map<String, dynamic>,
  );

  void close() => _client.close();
}
