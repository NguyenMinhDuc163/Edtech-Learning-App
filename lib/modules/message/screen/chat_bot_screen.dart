import 'package:easy_localization/easy_localization.dart';
import 'package:ed_tech/core/ads/ad_manager.dart';
import 'package:ed_tech/core/ads/chat_ai_quota_manager.dart';
import 'package:ed_tech/core/ads/models/ad_show_result.dart';
import 'package:ed_tech/core/ads/widgets/adaptive_banner_ad_widget.dart';
import 'package:ed_tech/core/constants/api_path.dart';
import 'package:ed_tech/init.dart';
import 'package:ed_tech/modules/message/bloc/chat_controller.dart';
import 'package:ed_tech/modules/message/bloc/chatbot_cubit.dart';
import 'package:ed_tech/modules/message/screen/chat_history_screen.dart';
import 'package:ed_tech/modules/message/repository/chat_sessions_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});
  static const String routeName = '/chatBotScreen';
  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSessionIfNeeded();
    });
  }

  Future<void> _loadSessionIfNeeded() async {
    final sessionId = ModalRoute.of(context)?.settings.arguments as String?;
    if (sessionId == null || sessionId.isEmpty) return;

    try {
      if (!mounted) return;
      final repo = context.read<ChatSessionsRepo>();
      final response = await repo.getSessionMessages(sessionId: sessionId);

      if (!mounted) return;
      if (response.status == 200 && response.data != null) {
        final controller = context.read<ChatController>();
        controller.resetSession();
        controller.setSessionId(sessionId);

        for (final msg in response.data!.messages) {
          controller.addMessage(
            ChatMessage(
              content: msg.content,
              isUser: msg.role == 'user',
              timestamp: msg.createdAt ?? DateTime.now(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('chat.load_history_error'.tr()),
            backgroundColor: AppColors.crimson,
          ),
        );
      }
    }
  }

  Future<void> _showQuotaDialog(BuildContext context) async {
    final quotaManager = ChatAiQuotaManager.instance;

    if (!quotaManager.canWatchRewardedForQuestions) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('chat.quota_limit_reached'.tr()),
          backgroundColor: AppColors.crimson,
        ),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('chat.quota_title'.tr()),
        content: Text('chat.quota_rewarded_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('chat.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('chat.watch_ad'.tr()),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final adResult = await AdManager.instance.showRewarded(
        onRewardEarned: (reward) async {
          quotaManager.grantRewardedQuestions();
        },
      );

      if (adResult == AdShowResult.rewardEarned && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('chat.reward_granted'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FunctionScreenTemplate(
      title: "chat.title".tr(),
      isShowDrawer: true,
      isShowBottomButton: false,
      actionsWidget: [
        InkWell(
          onTap: () {
            final controller = context.read<ChatController>();
            controller.resetSession();
          },
          child: const Icon(
            Icons.add,
            color: Colors.black,
            size: 22,
          ),
        ),
        InkWell(
          onTap:
              () => Navigator.pushNamed(context, ChatHistoryScreen.routeName),
          child: SvgPicture.asset(IconPath.iconHistory),
        ),
      ],
      screen: BlocListener<ChatbotCubit, ChatbotState>(
        listener: (context, state) {
          final controller = context.read<ChatController>();
          if (state is ChatbotSuccess) {
            controller.addMessage(
              ChatMessage(
                content: state.responseHtml,
                isUser: false,
                timestamp: DateTime.now(),
              ),
            );
            controller.setSessionId(state.sessionId);
            controller.setBotResponding(false);
          } else if (state is ChatbotFailure || state is ChatbotError) {
            controller.addMessage(
              ChatMessage(
                content:
                    state is ChatbotFailure
                        ? state.message
                        : (state as ChatbotError).message,
                isUser: false,
                timestamp: DateTime.now(),
              ),
            );
            controller.setBotResponding(false);
          }
        },
        child: Column(
          children: [
            const AdaptiveBannerAdWidget(),
            Expanded(
              child: ValueListenableBuilder<List<ChatMessage>>(
                valueListenable: context.read<ChatController>().messages,
                builder: (context, messages, child) {
                  return ValueListenableBuilder<bool>(
                    valueListenable:
                        context.read<ChatController>().isBotResponding,
                    builder: (context, isBotResponding, child) {
                      if (messages.isEmpty && !isBotResponding) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 56,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'chat.empty_state_message'.tr(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: messages.length + (isBotResponding ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == messages.length && isBotResponding) {
                            return _LoadingMessageCard();
                          }
                          final message = messages[index];
                          return _MessageCard(message: message);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            _ChatInput(
              controller: _textController,
              onSend: () {
                final text = _textController.text.trim();
                if (text.isEmpty) return;

                final quotaManager = ChatAiQuotaManager.instance;

                if (!quotaManager.canAskQuestion) {
                  // Show rewarded ad dialog
                  _showQuotaDialog(context);
                  return;
                }

                // Consume question quota
                quotaManager.consumeFreeQuestion();

                final controller = context.read<ChatController>();
                final cubit = context.read<ChatbotCubit>();

                controller.addMessage(
                  ChatMessage(
                    content: text,
                    isUser: true,
                    timestamp: DateTime.now(),
                  ),
                );

                controller.setBotResponding(true);

                cubit.sendMessage(
                  message: text,
                  sessionId: controller.currentSessionId.value,
                  customUrl: ApiPath.chatBase,
                );

                _textController.clear();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final ChatMessage message;
  const _MessageCard({required this.message});

  void _copyToClipboard(BuildContext context, String text) {
    final cleanText = text.replaceAll(RegExp(r'<[^>]*>'), '');
    Clipboard.setData(ClipboardData(text: cleanText));

    // Hiển thị thông báo copy thành công
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('chat.copied'.tr()),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.isUser;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFEDEBFF),
            child: const Icon(
              Icons.smart_toy,
              size: 18,
              color: Color(0xFF6C56F9),
            ),
          ),
          const SizedBox(width: 10),
        ],

        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF6C56F9) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isUser ? const Color(0xFF6C56F9) : const Color(0xFFE7EAF0),
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser)
                    Text(
                      'chat.assistant_label'.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C2439),
                      ),
                    ),
                  if (!isUser) const SizedBox(height: 2),
                  if (isUser)
                    Text(
                      message.content,
                      style: const TextStyle(
                        color: Colors.white,
                        height: 1.4,
                        fontSize: 14,
                      ),
                    )
                  else
                    Html(
                      data: message.content,
                      style: {
                        "body": Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          color: const Color(0xFF1C2439),
                          fontSize: FontSize(14),
                          lineHeight: LineHeight(1.4),
                        ),
                      },
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (!isUser) ...[
                        _ActionIcon(
                          icon: Icons.copy_outlined,
                          label: 'chat.copy_text'.tr(),
                          onTap:
                              () => _copyToClipboard(context, message.content),
                        ),
                        const SizedBox(width: 10),
                        const _ActionIcon(icon: Icons.thumb_up_alt_outlined),
                        const SizedBox(width: 10),
                        const _ActionIcon(icon: Icons.thumb_down_alt_outlined),
                      ] else ...[
                        _ActionIcon(
                          icon: Icons.copy_outlined,
                          label: 'chat.copy_text'.tr(),
                          isWhite: true,
                          onTap:
                              () => _copyToClipboard(context, message.content),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isUser) ...[
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFDEE7FF),
            child: const Icon(Icons.person, size: 18, color: Color(0xFF386BF6)),
          ),
        ],
      ],
    );
  }
}

class _LoadingMessageCard extends StatelessWidget {
  const _LoadingMessageCard();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFEDEBFF),
          child: const Icon(
            Icons.smart_toy,
            size: 18,
            color: Color(0xFF6C56F9),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE7EAF0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF6C56F9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'chat.thinking'.tr(),
                    style: const TextStyle(color: Color(0xFF1C2439)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool isWhite;
  final VoidCallback? onTap;
  const _ActionIcon({
    required this.icon,
    this.label,
    this.isWhite = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color =
        isWhite ? Colors.white.withOpacity(0.8) : const Color(0xFF8491A5);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          if (label != null) ...[
            const SizedBox(width: 6),
            Text(
              label!,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _ChatInput({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE7EAF0)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFF8491A5),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: AppTextStyles.text,
                      decoration: InputDecoration(
                        hintText: 'chat.input_hint'.tr(),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  // TODO: Re-enable when file attachment support is implemented.
                  // IconButton(
                  //   icon: const Icon(
                  //     Icons.attachment,
                  //     color: Color(0xFF8491A5),
                  //   ),
                  //   onPressed: () {},
                  // ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF6C56F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
