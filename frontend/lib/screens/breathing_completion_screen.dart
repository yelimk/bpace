import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../utils/schedule_storage_service.dart';
import '../services/api_client.dart';
import '../services/report_service.dart';
import 'breathing_exercise_screen.dart';
import 'ritual_history_screen.dart';

/// Breathing Completion Screen (Ritual Feedback - 스크롤 가능한 호흡 종료 피드백 화면)
class BreathingCompletionScreen extends StatefulWidget {
  final String title;
  final String bgImagePath;
  final String durationString;
  final int cycleCount;
  final String hrvChange;
  final String? targetScheduleId;

  const BreathingCompletionScreen({
    super.key,
    this.title = '4-7-8 호흡',
    this.bgImagePath = 'assets/images/bg_breath_478.png',
    this.durationString = '05:04',
    this.cycleCount = 1,
    this.hrvChange = '-8 bpm',
    this.targetScheduleId,
  });

  @override
  State<BreathingCompletionScreen> createState() =>
      _BreathingCompletionScreenState();
}

class _BreathingCompletionScreenState extends State<BreathingCompletionScreen> {
  bool _isSaved = false;
  bool _isBookmarked = false;

  BreathingFeedback? _aiFeedback;
  bool _isLoadingFeedback = false;
  String? _aiErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadBookmarkStatus();
    _fetchAiFeedback();
    if (widget.targetScheduleId != null && widget.targetScheduleId!.isNotEmpty) {
      ScheduleStorageService.completeSchedule(widget.targetScheduleId);
    }
  }

  Future<void> _fetchAiFeedback() async {
    if (mounted) setState(() => _isLoadingFeedback = true);
    try {
      int durationSec = 300;
      if (widget.durationString.contains(':')) {
        final parts = widget.durationString.split(':');
        if (parts.length == 2) {
          final m = int.tryParse(parts[0]) ?? 0;
          final s = int.tryParse(parts[1]) ?? 0;
          durationSec = m * 60 + s;
        }
      } else {
        durationSec = int.tryParse(widget.durationString) ?? 300;
      }

      final feedback = await ReportService.instance.generateFeedback(
        routineName: widget.title,
        durationSeconds: durationSec,
        cycleCount: widget.cycleCount,
      );
      if (mounted) {
        setState(() {
          _aiFeedback = feedback;
          _aiErrorMessage = null;
          _isLoadingFeedback = false;
        });
      }
    } catch (e) {
      debugPrint('[BreathingCompletionScreen] Gemini AI feedback fetch error: $e');
      if (mounted) {
        setState(() {
          _aiFeedback = null;
          _aiErrorMessage = '현재 AI 피드백을 불러올 수 없습니다. 잠시 후 다시 시도해 주세요.';
          _isLoadingFeedback = false;
        });
      }
    }
  }

  String _getRoutineIdByTitle(String title) {
    if (title.contains('한숨')) return '1';
    if (title.contains('4-7-8')) return '2';
    if (title.contains('4-6')) return '3';
    if (title.contains('공명')) return '4';
    if (title.contains('세미') || title.contains('4-2-4-2')) return '5';
    if (title.contains('박스') || title.contains('4-4-4-4')) return '6';
    if (title.contains('횡격막') || title.contains('2-1-4-1')) return '7';
    if (title.contains('각성') || title.contains('4-1-2-1')) return '8';
    return '2';
  }

  Future<void> _loadBookmarkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarkedIds = prefs.getStringList('bookmarked_ritual_ids') ?? [];
    final routineId = _getRoutineIdByTitle(widget.title);
    if (mounted) {
      setState(() {
        _isBookmarked = bookmarkedIds.contains(routineId);
      });
    }
  }

  Future<void> _onSaveRecord() async {
    final prefs = await SharedPreferences.getInstance();

    if (!_isSaved) {
      setState(() {
        _isSaved = true;
      });

      // 1. Format current timestamp
      final now = DateTime.now();
      final month = now.month.toString().padLeft(2, '0');
      final day = now.day.toString().padLeft(2, '0');
      final period = now.hour < 12 ? '오전' : '오후';
      final hour = now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
      final minute = now.minute.toString().padLeft(2, '0');
      final timestampStr = '${now.year}.$month.$day $period $hour:$minute';

      int durationSec = 304;
      if (widget.durationString.contains(':')) {
        final parts = widget.durationString.split(':');
        if (parts.length == 2) {
          final m = int.tryParse(parts[0]) ?? 0;
          final s = int.tryParse(parts[1]) ?? 0;
          durationSec = m * 60 + s;
        }
      }

      final recordMap = {
        'title': widget.title,
        'timestamp': timestampStr,
        'bgImagePath': widget.bgImagePath,
        'durationSeconds': durationSec,
        'cycleCount': widget.cycleCount,
      };

      // 2. Save record to SharedPreferences (Local Storage)
      final historyList = prefs.getStringList('saved_ritual_history_v1') ?? [];
      historyList.insert(0, jsonEncode(recordMap));
      await prefs.setStringList('saved_ritual_history_v1', historyList);

      // 3. Save record to Render Server DB (/api/breathing-logs)
      try {
        ApiClient.instance.post('/api/breathing-logs', body: {
          'category': '이완',
          'routineName': widget.title,
          'durationSeconds': durationSec,
          'completionRate': 100.0,
        });
      } catch (e) {
        debugPrint('[BreathingCompletionScreen] Server DB upload error: $e');
      }

      // 4. Update weekly ritual count & total ritual minutes & streak
      final currentWeeklyCount = prefs.getInt('weekly_ritual_count') ?? 4;
      await prefs.setInt('weekly_ritual_count', currentWeeklyCount + 1);

      final durationMinutes = (durationSec / 60).round().clamp(1, 60);
      final currentTotalMinutes = prefs.getInt('total_ritual_minutes') ?? 326;
      await prefs.setInt('total_ritual_minutes', currentTotalMinutes + durationMinutes);

      // Update continuous streak days if first ritual of today
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final lastDate = prefs.getString('last_ritual_date');
      final currentStreak = prefs.getInt('ritual_streak_days') ?? 7;

      if (lastDate != todayStr) {
        await prefs.setInt('ritual_streak_days', currentStreak + 1);
        await prefs.setString('last_ritual_date', todayStr);
      }
    }

    // 4. Navigate directly to RitualHistoryScreen (Ritual 기록 화면)
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const RitualHistoryScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        bottom: false,
        child: ResponsiveContainer(
          maxWidth: 600,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Top Bar Row (Back Arrow Circle Button)
              _buildTopHeader(context),
              const SizedBox(height: 16),

              // Main Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Page Title: "Ritual Feedback"
                      Text(
                        'Ritual Feedback',
                        style: GoogleFonts.outfit(
                          fontSize: 34,
                          fontWeight: FontWeight.w400,
                          color: AppColors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. Center Hero Card with "88 /100" Score Tag
                      _buildHeroCard(context),
                      const SizedBox(height: 20),

                      // 3. Stats Row Cards (진행 시간: 05:04 초 | 사이클: 16 회)
                      _buildStatsRow(),
                      const SizedBox(height: 28),

                      // 4. Section Title: "AI 분석 · 피드백"
                      const Text(
                        'AI 분석 · 피드백',
                        style: TextStyle(
                          fontFamily: AppFonts.pretendard,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 5. AI Analysis Main Container Card
                      _buildAiAnalysisCard(),
                      const SizedBox(height: 24),

                      // 6. Bottom Disclaimer Subtext (왼쪽 정렬)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          '이 결과는 의료 진단·치료·응급 판단을 위한 정보가 아닌 웰빙 참고용입니다.\n심각한 증상이나 응급 상황이라면 의료기관 또는 119에 연락하세요.',
                          style: TextStyle(
                            fontFamily: AppFonts.pretendard,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6E7178),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomSaveBar(),
    );
  }

  /// Top Bar Header Row
  Widget _buildTopHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF2B2C2E),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  /// 2. Center Hero Card Component with Clockwise Tilt Angle & Floating Top-Left Badge
  Widget _buildHeroCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14.0, bottom: 24.0, left: 28.0, right: 28.0),
      child: Transform.rotate(
        angle: 0.065, // 반대 방향(시계 방향) 기울임
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Vertical & Slim Tilted Card Container
            Container(
              height: 345, // 세로 높이 미세 축소 (380 -> 345)
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: const Color(0xFF2B2D32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(140),
                    blurRadius: 30,
                    spreadRadius: 2,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image
                    Image.asset(
                      widget.bgImagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF384656), Color(0xFF252C36)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        );
                      },
                    ),

                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withAlpha(20),
                            Colors.black.withAlpha(120),
                            Colors.black.withAlpha(220),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                    // Top-Right Bookmark Ribbon Icon (실제 북마크 연동 상태 조회 전용)
                    Positioned(
                      top: 18,
                      right: 18,
                      child: Icon(
                        _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: _isBookmarked ? const Color(0xFFE2FBA1) : AppColors.white.withAlpha(200),
                        size: 26,
                      ),
                    ),

                    // Bottom Information Overlay & Action Buttons
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontFamily: AppFonts.pretendard,
                              fontSize: 21,
                              fontWeight: FontWeight.w500,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '긴장을 천천히 가라앉히는 호흡',
                            style: TextStyle(
                              fontFamily: AppFonts.pretendard,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: AppColors.white.withAlpha(210),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Single Unified Integrated Glass Pill Bar Button matching recommended screen
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => BreathingExerciseScreen(
                                    title: widget.title,
                                    bgImagePath: widget.bgImagePath,
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                width: double.infinity,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(55),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(80),
                                    width: 1,
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Perfectly Centered Text: 시작하기
                                    const Text(
                                      '시작하기',
                                      style: TextStyle(
                                        fontFamily: AppFonts.pretendard,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.white,
                                        letterSpacing: 0.2,
                                      ),
                                    ),

                                    // Right Positioned White Circle Arrow Button
                                    Positioned(
                                      right: 3,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: const BoxDecoration(
                                          color: AppColors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: AppColors.darkBg,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Floating Top-Left Large Badge Image (더 왼쪽 아래로 위치 조절: top: 6, left: -28)
            Positioned(
              top: 6,
              left: -28,
              child: Image.asset(
                'assets/images/ic_completion_badge.png',
                width: 125,
                height: 125,
                errorBuilder: (context, error, stackTrace) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(22),
                        ),
                      ),
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withAlpha(80),
                          border: Border.all(
                            color: const Color(0xFFE2FBA1),
                            width: 2.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE2FBA1).withAlpha(60),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Color(0xFFE2FBA1),
                          size: 44,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Stats Row Cards (진행 시간: 05:04 초 | 사이클: 16 회)
  Widget _buildStatsRow() {
    return Row(
      children: [
        // Left Card: 진행 시간
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF28292B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '진행 시간',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFACAEB3),
                      ),
                    ),
                    Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFFACAEB3),
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      widget.durationString,
                      style: const TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFEFF8A8), // Light yellow tint matching screenshot
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '초',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFACAEB3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Right Card: 사이클
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF28292B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '사이클',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFACAEB3),
                      ),
                    ),
                    Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFFACAEB3),
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${widget.cycleCount}',
                      style: const TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '회',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFACAEB3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 5. AI Analysis Container Card (Gemini AI 피드백 실시간 연동)
  Widget _buildAiAnalysisCard() {
    if (_isLoadingFeedback) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF28292B),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.lightMint,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Gemini AI가 이번 호흡 리추얼 결과 분석 중...',
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 13.5,
                color: Color(0xFFACAEB3),
              ),
            ),
          ],
        ),
      );
    }

    if (_aiErrorMessage != null || _aiFeedback == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF28292B),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _aiErrorMessage ?? '현재 AI 분석을 불러올 수 없습니다. 잠시 후 다시 시도해 주세요.',
          style: const TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.slateGray,
            height: 1.5,
          ),
        ),
      );
    }

    final subheader = _aiFeedback!.todaysQuote.isNotEmpty
        ? '"${_aiFeedback!.todaysQuote}"'
        : (_aiFeedback!.headline.isNotEmpty ? '"${_aiFeedback!.headline}"' : '');

    final bodyAnalysis = _aiFeedback!.feedbackText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF28292B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subheader.isNotEmpty) ...[
            Text(
              subheader,
              style: const TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 14.5,
                fontWeight: FontWeight.w400,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Green Stat Line: X분 Y초 동안 Z번의 호흡을 마쳤어요.
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 14,
                color: Color(0xFFACAEB3),
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: widget.durationString.contains(':')
                      ? '${int.tryParse(widget.durationString.split(':')[0]) ?? 0}분 ${int.tryParse(widget.durationString.split(':')[1]) ?? 0}초 동안 ${widget.cycleCount}번의 호흡'
                      : '${widget.durationString}초 동안 ${widget.cycleCount}번의 호흡',
                  style: const TextStyle(
                    color: Color(0xFFE2FBA1),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const TextSpan(text: '을 마쳤어요.'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Body Analysis Text
          Text(
            bodyAnalysis,
            style: const TextStyle(
              fontFamily: AppFonts.pretendard,
              fontSize: 13.5,
              color: Color(0xFFBAC0CB),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Fixed Action Bar: "Ritual 기록 저장"
  Widget _buildBottomSaveBar() {
    return Container(
      color: AppColors.darkBg,
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 20.0),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: GestureDetector(
              onTap: _onSaveRecord,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _isSaved ? const Color(0xFF384534) : const Color(0xFFE2FFDA),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(90),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSaved) ...[
                      const Icon(Icons.check_rounded, color: AppColors.lightMint, size: 20),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      _isSaved ? 'Ritual 기록 저장됨' : 'Ritual 기록 저장',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: _isSaved ? AppColors.lightMint : AppColors.darkBg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
