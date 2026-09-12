import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import 'breathing_exercise_screen.dart';
import 'breathing_completion_screen.dart';

class RitualRecordItem {
  final String title;
  final String timestamp;
  final String bgImagePath;
  final String durationString;
  final int cycleCount;
  final String? aiHeadline;
  final String? aiQuote;
  final String? aiFeedbackText;
  final double? inhaleSec;
  final double? inhale2Sec;
  final double? holdSec;
  final double? exhaleSec;
  final double? hold2Sec;

  const RitualRecordItem({
    required this.title,
    required this.timestamp,
    required this.bgImagePath,
    this.durationString = '05:04',
    this.cycleCount = 1,
    this.aiHeadline,
    this.aiQuote,
    this.aiFeedbackText,
    this.inhaleSec,
    this.inhale2Sec,
    this.holdSec,
    this.exhaleSec,
    this.hold2Sec,
  });
}

class RitualMonthGroup {
  final String monthHeader;
  final List<RitualRecordItem> items;
  bool isExpanded;

  RitualMonthGroup({
    required this.monthHeader,
    required this.items,
    this.isExpanded = false,
  });
}

class RitualHistoryScreen extends StatefulWidget {
  final int initialTabIndex;

  const RitualHistoryScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<RitualHistoryScreen> createState() => _RitualHistoryScreenState();
}

class _RitualHistoryScreenState extends State<RitualHistoryScreen> {
  late int _selectedTabIndex; // 0: 이번 주, 1: 전체 기록

  List<RitualRecordItem> _thisWeekRecords = [];
  List<RitualMonthGroup> _monthGroups = [];

  static const List<RitualRecordItem> _defaultThisWeekRecords = [
    RitualRecordItem(
      title: '4-7-8 호흡',
      timestamp: '2026.09.07 오후 8:30',
      bgImagePath: 'assets/images/bg_breath_478.png',
      durationString: '05:04',
      cycleCount: 16,
      aiHeadline: '4-7-8 호흡 세션을 완주했어요.',
      aiQuote: '깊은 숨을 내쉴 때마다 마음에 쌓인 부담은 아득히 멀어집니다.',
      aiFeedbackText: '4-7-8 호흡은 날숨을 길게 유지하여 부교감신경을 활성화하는 데 탁월한 리듬이에요. 하루 일과 후 복잡했던 머릿속을 차분하게 가라앉히고 깊은 휴식 상태로 전환하셨습니다.',
      inhaleSec: 4.0,
      holdSec: 7.0,
      exhaleSec: 8.0,
    ),
    RitualRecordItem(
      title: '생리학적 한숨',
      timestamp: '2026.09.07 오후 12:30',
      bgImagePath: 'assets/images/bg_breath_sigh.png',
      durationString: '03:15',
      cycleCount: 20,
      aiHeadline: '생리학적 한숨으로 긴장을 완화했어요.',
      aiQuote: '두 번의 짧은 들이쉼과 긴 내쉼으로, 마음에 신선한 여유가 차오릅니다.',
      aiFeedbackText: '생리학적 한숨은 폐포를 활짝 열어 뇌에 즉각적인 산소를 공급하고 급격한 자율신경계 긴장을 수 초 내에 가라앉히는 가장 빠른 리셋 호흡입니다.',
      inhaleSec: 2.0,
      inhale2Sec: 1.5,
      exhaleSec: 4.5,
    ),
    RitualRecordItem(
      title: '4-4-4-4 호흡',
      timestamp: '2026.09.07 오전 11:00',
      bgImagePath: 'assets/images/bg_breath_box_4444.png',
      durationString: '04:00',
      cycleCount: 15,
      aiHeadline: '박스 호흡으로 흔들림 없는 평정을 찾았어요.',
      aiQuote: '네 변이 균등한 상자처럼, 흐트러진 생각의 중심을 단단히 잡았습니다.',
      aiFeedbackText: '들숨과 날숨, 그리고 멈춤의 길이가 같은 박스 호흡은 교감과 부교감 신경의 균형을 유지하여 감정 동요를 줄이고 맑은 집중 상태를 유지하도록 도와줍니다.',
      inhaleSec: 4.0,
      holdSec: 4.0,
      exhaleSec: 4.0,
      hold2Sec: 4.0,
    ),
    RitualRecordItem(
      title: '4-1-2-1 호흡',
      timestamp: '2026.09.07 오전 9:30',
      bgImagePath: 'assets/images/bg_breath_awakening.png',
      durationString: '03:00',
      cycleCount: 18,
      aiHeadline: '활력을 깨우는 각성 리듬을 완주했어요.',
      aiQuote: '산뜻한 숨결로 하루의 리듬을 활기차게 시작해 보세요.',
      aiFeedbackText: '경쾌한 템포 속에서 심박과 호흡수를 가볍게 올려주어 나른한 피로감을 털어내고 활기찬 오전 집중력을 끌어올리는 좋은 활력 루틴입니다.',
      inhaleSec: 4.0,
      holdSec: 1.0,
      exhaleSec: 2.0,
      hold2Sec: 1.0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _thisWeekRecords = List.from(_defaultThisWeekRecords);
    _monthGroups = [
      RitualMonthGroup(
        monthHeader: '2026년 9월',
        isExpanded: true,
        items: List.from(_defaultThisWeekRecords),
      ),
      RitualMonthGroup(
        monthHeader: '2026년 8월',
        isExpanded: false,
        items: const [
          RitualRecordItem(
            title: '4-7-8 호흡',
            timestamp: '2026.08.28 오후 9:15',
            bgImagePath: 'assets/images/bg_breath_478.png',
            inhaleSec: 4.0,
            holdSec: 7.0,
            exhaleSec: 8.0,
          ),
          RitualRecordItem(
            title: '세미 박스 호흡',
            timestamp: '2026.08.15 오후 2:40',
            bgImagePath: 'assets/images/bg_breath_semi_box.png',
            inhaleSec: 4.0,
            holdSec: 2.0,
            exhaleSec: 4.0,
            hold2Sec: 2.0,
          ),
        ],
      ),
    ];
    _loadSavedRecords();
  }

  Future<void> _loadSavedRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJsonList = prefs.getStringList('saved_ritual_history_v1') ?? [];

    final List<RitualRecordItem> dynamicSavedItems = [];
    for (final raw in savedJsonList) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        dynamicSavedItems.add(
          RitualRecordItem(
            title: decoded['title'] as String? ?? '4-7-8 호흡',
            timestamp: decoded['timestamp'] as String? ?? '',
            bgImagePath: decoded['bgImagePath'] as String? ?? 'assets/images/bg_breath_478.png',
            durationString: decoded['durationString'] as String? ?? '05:04',
            cycleCount: decoded['cycleCount'] as int? ?? 1,
            aiHeadline: decoded['aiHeadline'] as String?,
            aiQuote: decoded['aiQuote'] as String?,
            aiFeedbackText: decoded['aiFeedbackText'] as String?,
          ),
        );
      } catch (_) {}
    }

    if (dynamicSavedItems.isNotEmpty) {
      final combined = [...dynamicSavedItems, ..._defaultThisWeekRecords];
      final currentMonthStr = '${DateTime.now().year}년 ${DateTime.now().month}월';

      if (mounted) {
        setState(() {
          _thisWeekRecords = combined;
          _monthGroups = [
            RitualMonthGroup(
              monthHeader: currentMonthStr,
              isExpanded: true,
              items: combined,
            ),
            RitualMonthGroup(
              monthHeader: '2026년 8월',
              isExpanded: false,
              items: const [
                RitualRecordItem(
                  title: '4-7-8 호흡',
                  timestamp: '2026.08.28 오후 9:15',
                  bgImagePath: 'assets/images/bg_breath_478.png',
                  inhaleSec: 4.0,
                  holdSec: 7.0,
                  exhaleSec: 8.0,
                ),
                RitualRecordItem(
                  title: '세미 박스 호흡',
                  timestamp: '2026.08.15 오후 2:40',
                  bgImagePath: 'assets/images/bg_breath_semi_box.png',
                  inhaleSec: 4.0,
                  holdSec: 2.0,
                  exhaleSec: 4.0,
                  hold2Sec: 2.0,
                ),
              ],
            ),
          ];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Back arrow + Title "Ritual 기록"
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Ritual 기록',
                    style: TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Segmented Tab Switcher Bar ("이번 주" vs "전체 기록")
              _buildSegmentedTabBar(),
              const SizedBox(height: 20),

              // Main Content Area (0: 이번 주, 1: 전체 기록 - 월별 아코디언)
              Expanded(
                child: _selectedTabIndex == 0
                    ? _buildThisWeekView()
                    : _buildAllRecordsAccordionView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Segmented Tab Bar ("이번 주" | "전체 기록")
  Widget _buildSegmentedTabBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.darkCharcoal,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              title: '이번 주',
              isSelected: _selectedTabIndex == 0,
              onTap: () => setState(() => _selectedTabIndex = 0),
            ),
          ),
          Expanded(
            child: _buildTabButton(
              title: '전체 기록',
              isSelected: _selectedTabIndex == 1,
              onTap: () => setState(() => _selectedTabIndex = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.slateDarkGray.withAlpha(200)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: isSelected ? AppColors.white : AppColors.slateGray,
          ),
        ),
      ),
    );
  }

  /// Content for Tab 0: "이번 주"
  Widget _buildThisWeekView() {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: _thisWeekRecords.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _thisWeekRecords[index];
        return _buildRecordCard(item);
      },
    );
  }

  /// Content for Tab 1: "전체 기록" (Monthly Accordion List)
  Widget _buildAllRecordsAccordionView() {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: _monthGroups.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final group = _monthGroups[index];
        return _buildMonthAccordionGroup(group);
      },
    );
  }

  /// Month Accordion Group Component
  Widget _buildMonthAccordionGroup(RitualMonthGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month Accordion Header Card
        GestureDetector(
          onTap: () {
            setState(() {
              group.isExpanded = !group.isExpanded;
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.darkCharcoal.withAlpha(180),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  group.monthHeader,
                  style: const TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.white,
                  ),
                ),
                const Spacer(),
                Icon(
                  group.isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.lightGray,
                  size: 24,
                ),
              ],
            ),
          ),
        ),

        // Expanded List of Items under this Month
        if (group.isExpanded) ...[
          const SizedBox(height: 10),
          ...group.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: _buildRecordCard(item),
              )),
        ],
      ],
    );
  }

  /// Individual Record Card Component
  Widget _buildRecordCard(RitualRecordItem item) {
    return GestureDetector(
      onTap: () => _openFeedbackDetail(item),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.darkCharcoal,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            // Left Square Image Container (Background image of breathing routine)
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.black26,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  item.bgImagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.air_rounded,
                    color: AppColors.lightGray,
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Routine Title & Timestamp with clock icon
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppColors.slateGray,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        item.timestamp,
                        style: const TextStyle(
                          fontFamily: AppFonts.pretendard,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.slateGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Play Icon Button on the right (Re-starts breathing exercise)
            GestureDetector(
              onTap: () => _startBreathing(item),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.slateDarkGray.withAlpha(120),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFeedbackDetail(RitualRecordItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BreathingCompletionScreen(
          title: item.title,
          bgImagePath: item.bgImagePath,
          durationString: item.durationString,
          cycleCount: item.cycleCount,
          initialHeadline: item.aiHeadline,
          initialQuote: item.aiQuote,
          initialFeedbackText: item.aiFeedbackText,
          isAlreadySaved: true,
        ),
      ),
    ).then((_) => _loadSavedRecords());
  }

  void _startBreathing(RitualRecordItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BreathingExerciseScreen(
          title: item.title,
          bgImagePath: item.bgImagePath,
          targetInhaleSec: item.inhaleSec,
          targetInhale2Sec: item.inhale2Sec,
          targetHoldSec: item.holdSec,
          targetExhaleSec: item.exhaleSec,
          targetHold2Sec: item.hold2Sec,
        ),
      ),
    );
  }
}
