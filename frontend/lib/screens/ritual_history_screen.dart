import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import 'breathing_exercise_screen.dart';

class RitualRecordItem {
  final String title;
  final String timestamp;
  final String bgImagePath;
  final double? inhaleSec;
  final double? inhale2Sec;
  final double? holdSec;
  final double? exhaleSec;
  final double? hold2Sec;

  const RitualRecordItem({
    required this.title,
    required this.timestamp,
    required this.bgImagePath,
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

  late List<RitualMonthGroup> _monthGroups;

  // Data for "이번 주"
  static const List<RitualRecordItem> _thisWeekRecords = [
    RitualRecordItem(
      title: '4-7-8 호흡',
      timestamp: '2026.09.07 오후 8:30',
      bgImagePath: 'assets/images/bg_breath_478.png',
      inhaleSec: 4.0,
      holdSec: 7.0,
      exhaleSec: 8.0,
    ),
    RitualRecordItem(
      title: '생리학적 한숨',
      timestamp: '2026.09.07 오후 12:30',
      bgImagePath: 'assets/images/bg_breath_sigh.png',
      inhaleSec: 2.0,
      inhale2Sec: 1.5,
      exhaleSec: 4.5,
    ),
    RitualRecordItem(
      title: '4-4-4-4 호흡',
      timestamp: '2026.09.07 오전 11:00',
      bgImagePath: 'assets/images/bg_breath_box_4444.png',
      inhaleSec: 4.0,
      holdSec: 4.0,
      exhaleSec: 4.0,
      hold2Sec: 4.0,
    ),
    RitualRecordItem(
      title: '4-1-2-1 호흡',
      timestamp: '2026.09.07 오전 9:30',
      bgImagePath: 'assets/images/bg_breath_awakening.png',
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
    _monthGroups = [
      RitualMonthGroup(
        monthHeader: '2026년 9월',
        isExpanded: true, // Expand current month by default
        items: const [
          RitualRecordItem(
            title: '4-7-8 호흡',
            timestamp: '2026.09.07 오후 8:30',
            bgImagePath: 'assets/images/bg_breath_478.png',
            inhaleSec: 4.0,
            holdSec: 7.0,
            exhaleSec: 8.0,
          ),
          RitualRecordItem(
            title: '생리학적 한숨',
            timestamp: '2026.09.07 오후 12:30',
            bgImagePath: 'assets/images/bg_breath_sigh.png',
            inhaleSec: 2.0,
            inhale2Sec: 1.5,
            exhaleSec: 4.5,
          ),
          RitualRecordItem(
            title: '4-4-4-4 호흡',
            timestamp: '2026.09.07 오전 11:00',
            bgImagePath: 'assets/images/bg_breath_box_4444.png',
            inhaleSec: 4.0,
            holdSec: 4.0,
            exhaleSec: 4.0,
            hold2Sec: 4.0,
          ),
          RitualRecordItem(
            title: '4-1-2-1 호흡',
            timestamp: '2026.09.07 오전 9:30',
            bgImagePath: 'assets/images/bg_breath_awakening.png',
            inhaleSec: 4.0,
            holdSec: 1.0,
            exhaleSec: 2.0,
            hold2Sec: 1.0,
          ),
        ],
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
      onTap: () => _startBreathing(item),
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

            // Play Icon Button on the right
            GestureDetector(
              onTap: () => _startBreathing(item),
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
