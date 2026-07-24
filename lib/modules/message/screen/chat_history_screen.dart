import 'package:ed_tech/init.dart';
import 'package:ed_tech/core/ads/admob_config.dart';
import 'package:ed_tech/core/ads/widgets/adaptive_banner_ad_widget.dart';
import 'package:ed_tech/core/ads/widgets/native_ad_widget.dart';
import 'package:ed_tech/modules/message/bloc/chat_history_cubit.dart';
import 'package:ed_tech/modules/message/model/sessions_response.dart';
import 'package:ed_tech/modules/message/screen/chat_bot_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});
  static const String routeName = '/chatHistoryScreen';

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ChatHistoryCubit>().loadSessions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final state = context.read<ChatHistoryCubit>().state;
      if (state is ChatHistorySuccess && state.hasMore) {
        context.read<ChatHistoryCubit>().loadMoreSessions();
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${'chat_history.today'.tr()} ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return '${'chat_history.yesterday'.tr()} ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE HH:mm').format(date);
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
  }

  void _showDeleteConfirmDialog(String sessionId) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('chat_history.delete_confirm_title'.tr()),
            content: Text('chat_history.delete_confirm_message'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('chat_history.cancel'.tr()),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.read<ChatHistoryCubit>().deleteSession(sessionId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.crimson,
                  foregroundColor: Colors.white,
                ),
                child: Text('chat_history.delete'.tr()),
              ),
            ],
          ),
    );
  }

  void _showDeleteAllConfirmDialog() {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('chat_history.delete_confirm_title'.tr()),
            content: Text('chat_history.delete_all_confirm_message'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('chat_history.cancel'.tr()),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.read<ChatHistoryCubit>().deleteAllSessions();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.crimson,
                  foregroundColor: Colors.white,
                ),
                child: Text('chat_history.delete_all'.tr()),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FunctionScreenTemplate(
      title: 'chat_history.title'.tr(),
      isShowBottomButton: false,
      actionsWidget: [
        BlocBuilder<ChatHistoryCubit, ChatHistoryState>(
          builder: (context, state) {
            final hasSessions =
                state is ChatHistorySuccess && state.sessions.isNotEmpty;
            return InkWell(
              onTap:
                  hasSessions
                      ? () {
                        _showDeleteAllConfirmDialog();
                      }
                      : null,
              child: SvgPicture.asset(
                IconPath.iconTrash,
                color: hasSessions ? AppColors.crimson : Colors.grey,
                width: 25,
                height: 25,
              ),
            );
          },
        ),
      ],
      screen: BlocListener<ChatHistoryCubit, ChatHistoryState>(
        listener: (context, state) {
          if (state is ChatHistoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.crimson,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: BlocBuilder<ChatHistoryCubit, ChatHistoryState>(
          builder: (context, state) {
            if (state is ChatHistoryLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C56F9)),
                ),
              );
            }

            if (state is ChatHistorySuccess) {
              if (state.sessions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'chat_history.no_history'.tr(),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  const NativeAdWidget(height: 100),
                  Expanded(
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      itemCount: state.sessions.length +
                          (state.hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        if (index == state.sessions.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF6C56F9),
                                ),
                              ),
                            ),
                          );
                        }

                        final session = state.sessions[index];

                        return _HistoryItem(
                          session: session,
                          formattedDate: _formatDate(session.lastActiveAt),
                          onTap: () async {
                            await Navigator.pushNamed(
                              context,
                              ChatBotScreen.routeName,
                              arguments: session.sessionId,
                            );
                            if (mounted) {
                              context.read<ChatHistoryCubit>().loadSessions();
                            }
                          },
                          onDelete: () {
                            _showDeleteConfirmDialog(session.sessionId);
                          },
                        );
                      },
                    ),
                  ),
                  if (state.sessions.length <= 5)
                    const AdaptiveBannerAdWidget(),
                ],
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final ChatSession session;
  final String formattedDate;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryItem({
    required this.session,
    required this.formattedDate,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F7FF),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE7EAF0)),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: Color(0xFF6C56F9),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.firstMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1C2439),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.message_outlined,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${session.messageCount} ${'chat_history.messages'.tr()}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _ActionSquare(
          icon: Icons.delete_outline,
          bgColor: const Color(0xFFFFE9E7),
          iconColor: const Color(0xFFFF6B60),
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _ActionSquare extends StatelessWidget {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;
  const _ActionSquare({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor),
      ),
    );
  }
}
