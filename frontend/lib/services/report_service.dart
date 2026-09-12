import '../services/api_config.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// A week's AI-written summary & real-time biometric analysis.
class WeeklyReport {
  const WeeklyReport({
    required this.headline,
    required this.summary,
    required this.insights,
    required this.advice,
    required this.disclaimer,
    required this.generatedAt,
    required this.cached,
    this.avgBpmAnalysis = '',
    this.maxBpmAnalysis = '',
    this.minBpmAnalysis = '',
    this.overallGuide = '',
    this.todaysQuote = '',
  });

  final String headline;
  final String summary;
  final List<String> insights;
  final List<String> advice;
  final String disclaimer;
  final DateTime generatedAt;
  final bool cached;

  // New Step 6 AI Fields
  final String avgBpmAnalysis;
  final String maxBpmAnalysis;
  final String minBpmAnalysis;
  final String overallGuide;
  final String todaysQuote;

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    // Extract nested data if returned in envelope { success: true, data: { report: { ... } } }
    final raw = json.containsKey('report') ? (json['report'] as Map<String, dynamic>) : json;

    final headline = raw['headline'] as String? ?? raw['summary'] as String? ?? '';
    final avgBpmAnalysis = raw['avgBpmAnalysis'] as String? ?? '';
    final maxBpmAnalysis = raw['maxBpmAnalysis'] as String? ?? '';
    final minBpmAnalysis = raw['minBpmAnalysis'] as String? ?? '';
    final overallGuide = raw['overallGuide'] as String? ?? raw['advice'] as String? ?? '';
    final todaysQuote = raw['todaysQuote'] as String? ?? '';

    final insightsList = <String>[];
    if (avgBpmAnalysis.isNotEmpty) insightsList.add(avgBpmAnalysis);
    if (maxBpmAnalysis.isNotEmpty) insightsList.add(maxBpmAnalysis);
    if (minBpmAnalysis.isNotEmpty) insightsList.add(minBpmAnalysis);

    return WeeklyReport(
      headline: headline,
      summary: raw['summaryText'] as String? ?? raw['summary'] as String? ?? headline,
      insights: insightsList.isNotEmpty
          ? insightsList
          : (raw['insights'] as List?)?.cast<String>() ?? const [],
      advice: overallGuide.isNotEmpty
          ? [overallGuide]
          : (raw['advice'] as List?)?.cast<String>() ?? const [],
      disclaimer: raw['disclaimer'] as String? ?? '',
      generatedAt: raw['createdAt'] != null
          ? DateTime.parse(raw['createdAt'] as String).toLocal()
          : DateTime.now(),
      cached: raw['isCached'] as bool? ?? raw['cached'] as bool? ?? false,
      avgBpmAnalysis: avgBpmAnalysis,
      maxBpmAnalysis: maxBpmAnalysis,
      minBpmAnalysis: minBpmAnalysis,
      overallGuide: overallGuide,
      todaysQuote: todaysQuote,
    );
  }
}

/// Breathing session completion feedback response model
class BreathingFeedback {
  const BreathingFeedback({
    required this.headline,
    required this.summaryText,
    required this.feedbackText,
    required this.todaysQuote,
  });

  final String headline;
  final String summaryText;
  final String feedbackText;
  final String todaysQuote;

  factory BreathingFeedback.fromJson(Map<String, dynamic> json) => BreathingFeedback(
        headline: json['headline'] as String? ?? '',
        summaryText: json['summaryText'] as String? ?? '',
        feedbackText: json['feedbackText'] as String? ?? '',
        todaysQuote: json['todaysQuote'] as String? ?? '',
      );
}

class ReportService {
  const ReportService();

  static const ReportService instance = ReportService();

  /// This week's report, or null when none has been made yet.
  Future<WeeklyReport?> weekly() async {
    try {
      final data = await ApiClient.instance.get('/api/reports/latest');
      if (data is Map<String, dynamic> && data['hasReport'] == false) {
        return null;
      }
      return WeeklyReport.fromJson(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.code == 'NOT_FOUND') return null;
      rethrow;
    }
  }

  /// Real-time biometric AI report generation
  Future<WeeklyReport> generate({
    int? avgBpm,
    int? maxBpm,
    int? minBpm,
    int? hrvSdnnMs,
    int? conditionScore,
  }) async {
    final data = await ApiClient.instance.post(
      '/api/reports/analyze',
      body: {
        if (avgBpm != null) 'avgBpm': avgBpm,
        if (maxBpm != null) 'maxBpm': maxBpm,
        if (minBpm != null) 'minBpm': minBpm,
        if (hrvSdnnMs != null) 'hrvSdnnMs': hrvSdnnMs,
        if (conditionScore != null) 'conditionScore': conditionScore,
      },
      timeout: ApiConfig.reportTimeout,
    );
    return WeeklyReport.fromJson(data as Map<String, dynamic>);
  }

  /// Real-time breathing completion feedback generation (+ todaysQuote)
  Future<BreathingFeedback> generateFeedback({
    required String routineName,
    required int durationSeconds,
    required int cycleCount,
    int conditionScore = 80,
  }) async {
    final data = await ApiClient.instance.post(
      '/api/reports/feedback',
      body: {
        'routineName': routineName,
        'durationSeconds': durationSeconds,
        'cycleCount': cycleCount,
        'conditionScore': conditionScore,
      },
      timeout: ApiConfig.reportTimeout,
    );
    return BreathingFeedback.fromJson(data as Map<String, dynamic>);
  }
}
