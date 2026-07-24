import 'package:easy_localization/easy_localization.dart';
import 'package:ed_tech/init.dart';
import 'package:ed_tech/core/ads/ad_frequency_manager.dart';
import 'package:ed_tech/core/ads/ad_manager.dart';
import 'package:ed_tech/core/ads/models/ad_show_result.dart';
import 'package:ed_tech/core/ads/rewarded_interstitial_reward_manager.dart';
import 'package:ed_tech/core/ads/widgets/native_ad_widget.dart';
import 'package:ed_tech/core/theme/app_colors.dart';
import 'package:ed_tech/core/theme/app_text_styles.dart';
import 'package:ed_tech/core/theme/app_pad.dart';
import 'package:ed_tech/modules/dashboard/screen/dashboard_screen.dart';
import 'package:ed_tech/modules/assessment/models/submit_quiz_model.dart';
import 'package:ed_tech/modules/course/screen/course_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:super_tooltip/super_tooltip.dart';

class QuizResultScreen extends StatefulWidget {
  const QuizResultScreen({super.key});

  static const String routeName = '/quiz-result';

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  SubmitQuizModel? result;
  Duration? timeSpent;
  SuperTooltipController? _tooltipController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    result = args?['result'] as SubmitQuizModel?;
    timeSpent = args?['timeSpent'] as Duration?;
  }

  @override
  Widget build(BuildContext context) {
    if (result?.data == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          title: Text('assessment.quiz_result_title'.tr(), style: AppTextStyles.appbarTitle),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final data = result!.data!;
    final score = double.tryParse(data.score ?? '0') ?? 0;
    final passingScore = double.tryParse(data.passingScore ?? '70') ?? 70;
    final percentage = (data.totalQuestions ?? 0) > 0
        ? ((data.correctAnswers ?? 0) / (data.totalQuestions ?? 1)) * 100
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text('assessment.quiz_result_title'.tr(), style: AppTextStyles.appbarTitle),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.primary),
          onPressed: () => _goToHome(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildResultHeader(data, score, passingScore, percentage),
            const SizedBox(height: 16),
            _buildStatisticsCard(data),
            const SizedBox(height: 16),
            _buildQuestionResults(data),
            const SizedBox(height: 20),
            const NativeAdWidget(height: 100),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildResultHeader(Data data, double score, double passingScore, double percentage) {
    final isPassed = data.isPassed ?? false;

    return Container(
      margin: AppPad.a16,
      padding: AppPad.a24,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPassed
              ? [AppColors.success, AppColors.success.withOpacity(0.8)]
              : [AppColors.error, AppColors.error.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPassed ? AppColors.success : AppColors.error).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isPassed ? Icons.emoji_events : Icons.sentiment_dissatisfied,
            size: 64,
            color: AppColors.white,
          ),
          const SizedBox(height: 16),
          Text(
            isPassed ? 'assessment.congratulations'.tr() : 'assessment.need_improvement'.tr(),
            style: AppTextStyles.textHeader1.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPassed
                ? 'assessment.passed_message'.tr()
                : 'assessment.not_passed_message'.tr(),
            style: AppTextStyles.textContent2.copyWith(
              color: AppColors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildHeaderStat(
                icon: Icons.check_circle_outline,
                label: 'assessment.score'.tr(),
                value: '${score.toStringAsFixed(1)}',
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.white.withOpacity(0.3),
              ),
              _buildHeaderStat(
                icon: Icons.trending_up,
                label: 'assessment.achieved'.tr(),
                value: '${percentage.toStringAsFixed(0)}%',
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.white.withOpacity(0.3),
              ),
              _buildHeaderStat(
                icon: Icons.timer_outlined,
                label: 'assessment.time'.tr(),
                value: _formatDuration(timeSpent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.textHeader3.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.textContent4.copyWith(
            color: AppColors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard(Data data) {
    final suggestion = data.adaptiveSuggestion;

    return Container(
      margin: AppPad.h16,
      padding: AppPad.a20,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowBlack15,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'assessment.detailed_statistics'.tr(),
                  style: AppTextStyles.textHeader3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (suggestion?.targetContent != null)
                _buildAITooltipIcon(suggestion!),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatRow(
            icon: Icons.quiz,
            label: 'assessment.total_questions'.tr(),
            value: '${data.totalQuestions ?? 0}',
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            icon: Icons.check_circle,
            label: 'assessment.correct_answers'.tr(),
            value: '${data.correctAnswers ?? 0}',
            color: AppColors.success,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            icon: Icons.cancel,
            label: 'assessment.wrong_answers'.tr(),
            value: '${(data.totalQuestions ?? 0) - (data.correctAnswers ?? 0)}',
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            icon: Icons.flag,
            label: 'assessment.passing_score'.tr(),
            value: '${data.passingScore}',
            color: AppColors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: AppPad.a12,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: AppPad.a8,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.textContent2.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.textContent2.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionResults(Data data) {
    return Container(
      margin: AppPad.h16,
      padding: AppPad.a20,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowBlack15,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'assessment.question_details'.tr(),
                style: AppTextStyles.textHeader3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.questionResults.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final question = data.questionResults[index];
              return _buildQuestionItem(question, index + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionItem(QuestionResult question, int number) {
    final isCorrect = question.isCorrect ?? false;

    return Container(
      padding: AppPad.a16,
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.success.withOpacity(0.05)
            : AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect
              ? AppColors.success.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCorrect ? AppColors.success : AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: AppTextStyles.textContent2.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question.questionText ?? '',
                  style: AppTextStyles.textContent2.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCorrect ? AppColors.success : AppColors.error,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCorrect ? Icons.check : Icons.close,
                      size: 16,
                      color: AppColors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCorrect ? 'assessment.correct'.tr() : 'assessment.wrong'.tr(),
                      style: AppTextStyles.textContent3.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: AppPad.a12,
            decoration: BoxDecoration(
              color: AppColors.lightGray.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'assessment.your_answer_label'.tr(),
                      style: AppTextStyles.textContent3.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  question.userAnswer?.answerId ?? 'assessment.not_answered'.tr(),
                  style: AppTextStyles.textContent3.copyWith(
                    color: isCorrect ? AppColors.success : AppColors.error,
                  ),
                ),
                if (!isCorrect) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.lightbulb, size: 16, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text(
                        'assessment.correct_answer_label'.tr(),
                        style: AppTextStyles.textContent3.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    question.correctAnswerId ?? '',
                    style: AppTextStyles.textContent3.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: AppPad.h16,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _goToHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home, size: 24, color: AppColors.white),
                  const SizedBox(width: 8),
                  Text(
                    'assessment.go_home'.tr(),
                    style: AppTextStyles.textContent2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goToHome() {
    // Show Interstitial on leaving quiz result
    AdManager.instance.showInterstitialIfAllowed().then((_) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        DashboardScreen.routeName,
        (route) => false,
      );
    });
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0 ${'assessment.minutes'.tr()}';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}${'assessment.hours'.tr()} ${minutes}${'assessment.minutes'.tr()}';
    } else if (minutes > 0) {
      return '${minutes} ${'assessment.minutes'.tr()}';
    } else {
      return '${seconds} ${'assessment.seconds'.tr()}';
    }
  }

  Widget _buildAITooltipIcon(AdaptiveSuggestion suggestion) {
    _tooltipController = SuperTooltipController();

    return SuperTooltip(
      controller: _tooltipController,
      popupDirection: TooltipDirection.down,
      backgroundColor: const Color(0xFF93C0F3),
      borderColor: const Color(0xFFB3C3D6),
      borderWidth: 0,
      arrowTipDistance: 10,
      arrowLength: 8,
      arrowBaseWidth: 12,
      content: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _tooltipController?.hideTooltip();
            if (suggestion.targetContent != null) {
              _navigateToLesson(suggestion.targetContent!);
            }
          },
          child: Container(
            padding: AppPad.a12,
            constraints: BoxConstraints(maxWidth: 250),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: AppColors.white, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'assessment.improve'.tr(),
                        style: AppTextStyles.textContent3.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  suggestion.reason ?? '',
                  style: AppTextStyles.textContent3.copyWith(
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'assessment.tapToViewLesson'.tr(),
                  style: AppTextStyles.textContent4.copyWith(
                    color: AppColors.deepBlue,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      child: GestureDetector(
        onTap: () => _tooltipController?.showTooltip(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF6BA6E8).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF7DB0EA).withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                color: const Color(0xFF5B9FED),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Cải thiện',
                style: AppTextStyles.textContent3.copyWith(
                  color: const Color(0xFF87B3E6),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToLesson(TargetContent targetContent) {
    if (targetContent.courseId == null) return;

    Navigator.pushNamed(
      context,
      CourseDetailScreen.routeName,
      arguments: {
        'courseId': targetContent.courseId,
        'title': targetContent.title ?? '',
      },
    );
  }
}
