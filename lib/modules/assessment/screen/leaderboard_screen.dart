import 'package:ed_tech/core/ads/admob_config.dart';
import 'package:ed_tech/core/ads/widgets/native_ad_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ed_tech/init.dart';
import 'package:ed_tech/modules/assessment/bloc/leaderboard_cubit.dart';
import 'package:ed_tech/modules/assessment/bloc/leaderboard_controller.dart';
import 'package:ed_tech/modules/assessment/models/leaderboard_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  static const String routeName = '/leaderboardScreen';

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaderboardCubit>().getLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeaderboardCubit, LeaderboardState>(
      listener: (context, state) {
        final controller = context.read<LeaderboardController>();

        if (state is LeaderboardInProgress) {
          controller.setLoading(true);
          controller.clearError();
        } else if (state is LeaderboardSuccess) {
          controller.setLoading(false);

          final items = state.data.data.leaderboard;
          controller.setLeaderboardItems(items, append: false);
        } else if (state is LeaderboardError) {
          controller.setLoading(false);
          controller.setError(state.message);
        }
      },
      child: FunctionScreenTemplate(
        title: 'assessment.leaderboard_title'.tr(),
        isShowAppBar: true,
        isShowBottomButton: false,
        screen: ValueListenableBuilder<bool>(
          valueListenable: context.read<LeaderboardController>().isLoading,
          builder: (context, isLoading, child) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return ValueListenableBuilder<List<LeaderboardItem>>(
              valueListenable: context.read<LeaderboardController>().leaderboardItems,
              builder: (context, items, child) {
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'assessment.leaderboard_no_data'.tr(),
                      style: AppTextStyles.textStyleDefault,
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: SingleChildScrollView(
                    padding: AppPad.a16,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        if (items.length >= 3) ...[
                          _buildTopThreePodium(items.take(3).toList()),
                          const SizedBox(height: 16),
                          if (items.length > 3)
                            ..._buildRankedListWithAds(items.skip(3).toList()),
                        ] else
                          ...items.asMap().entries.map((entry) {
                            return _buildRankedCard(entry.value, entry.key + 1);
                          }),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopThreePodium(List<LeaderboardItem> top3) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.colorF4F3FD,
            AppColors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (top3.length > 1) _buildPodiumItem(top3[1], 2),
              if (top3.isNotEmpty) _buildPodiumItem(top3[0], 1),
              if (top3.length > 2) _buildPodiumItem(top3[2], 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(LeaderboardItem item, int rank) {
    Color getMedalColor(int r) {
      if (r == 1) return const Color(0xFFFFD700);
      if (r == 2) return const Color(0xFFC0C0C0);
      return const Color(0xFFCD7F32);
    }

    Color getMedalGradientEnd(int r) {
      if (r == 1) return const Color(0xFFFFE55C);
      if (r == 2) return const Color(0xFFE8E8E8);
      return const Color(0xFFE89B6B);
    }

    Color getPodiumColor(int r) {
      if (r == 1) return AppColors.primary;
      if (r == 2) return AppColors.lavenderColor;
      return AppColors.color0961F5;
    }

    final isFirst = rank == 1;
    final height = isFirst ? 100.0 : rank == 2 ? 85.0 : 70.0;
    final avatarSize = isFirst ? 64.0 : 56.0;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.topCenter,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        getPodiumColor(rank).withValues(alpha: 0.2),
                        getPodiumColor(rank).withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: getPodiumColor(rank).withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      item.username.isNotEmpty ? item.username[0].toUpperCase() : '?',
                      style: AppTextStyles.textStyleDefaultBold.copyWith(
                        fontSize: isFirst ? 28 : 22,
                        color: getPodiumColor(rank),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: isFirst ? 32 : 26,
                  height: isFirst ? 32 : 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [getMedalColor(rank), getMedalGradientEnd(rank)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: getMedalColor(rank).withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: AppColors.white,
                    size: isFirst ? 18 : 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.username,
              style: AppTextStyles.textStyleDefaultBold.copyWith(
                fontSize: isFirst ? 14 : 12,
                color: AppColors.text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    getPodiumColor(rank).withValues(alpha: 0.15),
                    getPodiumColor(rank).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: getPodiumColor(rank).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    item.totalScore.toStringAsFixed(1),
                    style: AppTextStyles.textHeader3.copyWith(
                      color: getPodiumColor(rank),
                      fontSize: isFirst ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'assessment.leaderboard_total_score'.tr(),
                    style: AppTextStyles.textContent4.copyWith(
                      color: AppColors.color8F959E,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    getPodiumColor(rank),
                    getPodiumColor(rank).withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                boxShadow: [
                  BoxShadow(
                    color: getPodiumColor(rank).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: AppTextStyles.textHeader1.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isFirst ? 28 : 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankedCard(LeaderboardItem item, int rank) {
    Color getRankColor(int r) {
      if (r == 1) return const Color(0xFFFFD700);
      if (r == 2) return const Color(0xFFC0C0C0);
      if (r == 3) return const Color(0xFFCD7F32);
      return AppColors.primary;
    }

    bool isTopThree = rank <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: isTopThree
            ? Border.all(
                color: getRankColor(rank).withValues(alpha: 0.3),
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isTopThree
                ? getRankColor(rank).withValues(alpha: 0.15)
                : AppColors.shadowBlack15,
            blurRadius: isTopThree ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(item, rank),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.studentName,
                        style: AppTextStyles.textHeader3.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isTopThree ? 16 : 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isTopThree)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              getRankColor(rank),
                              getRankColor(rank).withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: getRankColor(rank).withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.emoji_events,
                              color: AppColors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '#$rank',
                              style: AppTextStyles.textContent3.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatBadge(
                      Icons.quiz_outlined,
                      '${item.totalQuizzes} quizzes',
                      AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    _buildStatBadge(
                      Icons.check_circle_outline,
                      '${item.quizzesPassed} passed',
                      AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 18,
                      color: getRankColor(rank),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Avg Score: ',
                      style: AppTextStyles.textContent3.copyWith(
                        color: AppColors.color8F959E,
                      ),
                    ),
                    Text(
                      item.averageScore.toStringAsFixed(1),
                      style: AppTextStyles.textContent2.copyWith(
                        color: getRankColor(rank),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.passRate >= 70
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.passRate.toStringAsFixed(0)}% pass rate',
                        style: AppTextStyles.textContent4.copyWith(
                          color: item.passRate >= 70 ? AppColors.success : AppColors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isTopThree) ...[
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: AppTextStyles.textContent2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(LeaderboardItem item, int rank) {
    Color getRankColor(int r) {
      if (r == 1) return const Color(0xFFFFD700);
      if (r == 2) return const Color(0xFFC0C0C0);
      if (r == 3) return const Color(0xFFCD7F32);
      return AppColors.primary;
    }

    final size = rank <= 3 ? 60.0 : 56.0;
    final hasAvatar = item.avatarUrl != null && item.avatarUrl!.isNotEmpty;

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                getRankColor(rank).withValues(alpha: 0.2),
                getRankColor(rank).withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: getRankColor(rank).withValues(alpha: 0.4),
              width: 3,
            ),
            image: hasAvatar
                ? DecorationImage(
                    image: NetworkImage(item.avatarUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: hasAvatar
              ? null
              : Center(
                  child: Text(
                    item.studentName.isNotEmpty
                        ? item.studentName[0].toUpperCase()
                        : '?',
                    style: AppTextStyles.textHeader2.copyWith(
                      fontSize: rank <= 3 ? 24 : 20,
                      color: getRankColor(rank),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        if (rank <= 3)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [getRankColor(rank), getRankColor(rank).withValues(alpha: 0.8)],
                ),
                border: Border.all(color: AppColors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: getRankColor(rank).withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: AppTextStyles.textContent4.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.textContent4.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onRefresh() async {
    await context.read<LeaderboardCubit>().getLeaderboard();
  }

  List<Widget> _buildRankedListWithAds(List<LeaderboardItem> items) {
    final widgets = <Widget>[];
    final adPosition = AdMobConfig.leaderboardNativePosition - 4; // offset from rank 4

    for (int i = 0; i < items.length; i++) {
      widgets.add(_buildRankedCard(items[i], i + 4));

      // Insert native ad after the item at adPosition
      if (i == adPosition && i < items.length - 1) {
        widgets.add(const SizedBox(height: 12));
        widgets.add(const NativeAdWidget(height: 120));
        widgets.add(const SizedBox(height: 12));
      }
    }

    return widgets;
  }
}
