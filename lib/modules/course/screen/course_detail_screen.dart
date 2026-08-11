import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:ed_tech/modules/payment/screen/order_confirmation_screen.dart';
import 'package:ed_tech/modules/reviews/screen/review_screen.dart';
import 'package:ed_tech/init.dart';
import 'package:ed_tech/modules/course/widgets/course_lesson_bottom_sheet.dart';
import 'package:ed_tech/modules/course/bloc/course_cubit.dart';
import 'package:ed_tech/modules/course/screen/course_cancellation_screen.dart';
import 'package:ed_tech/modules/course/screen/document_viewer_screen.dart';
import 'package:ed_tech/modules/assessment/screen/quiz_taking_screen.dart';
import 'package:ed_tech/modules/assessment/models/quiz_model.dart';
import 'package:ed_tech/modules/home/repository/home_repo.dart';
import 'package:ed_tech/data/api_client.dart';
import 'package:ed_tech/modules/message/repository/chat_bot_repo.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:ed_tech/core/constants/app_constants.dart';
import 'package:ed_tech/core/constants/ai_consent_constants.dart';
import 'package:ed_tech/core/constants/video_tracking_action.dart';
import 'package:sp_util/sp_util.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ed_tech/modules/iap/bloc/iap_cubit.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class CourseDetailScreen extends StatefulWidget {
  static const String routeName = '/CourseDetailScreen';

  const CourseDetailScreen({super.key});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Gọi API chỉ 1 lần khi widget được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        final String courseId = args['courseId'] ?? '';
        context.read<CourseCubit>().getCourseDetail(courseId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null) {
      return Scaffold(body: Center(child: Text('course.no_course_info'.tr())));
    }

    final String courseId = args['courseId'] ?? '';
    final String title = args['title'] ?? 'course.untitled'.tr();
    final String instructor =
        args['instructor'] ?? 'course.unknown_teacher'.tr();
    final String price = args['price'] ?? '0';
    final String duration = args['duration'] ?? '0h 0m';
    final String? imageUrl = args['imageUrl'];
    final String? description = args['description'];

    return BlocBuilder<CourseCubit, CourseState>(
      builder: (context, state) {
        if (state is CourseDetailProgress) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (state is CourseDetailSuccess) {
          final courseData = state.courseDetail;
          return _CourseDetailContent(
            courseId: courseId,
            title: courseData.title ?? title,
            instructor: instructor,
            price: courseData.price ?? price,
            duration: duration,
            imageUrl: imageUrl,
            description: courseData.description ?? description,
            courseDetail: courseData,
          );
        }

        return _CourseDetailContent(
          courseId: courseId,
          title: title,
          instructor: instructor,
          price: price,
          duration: duration,
          imageUrl: imageUrl,
          description: description,
        );
      },
    );
  }
}

class _CourseDetailContent extends StatefulWidget {
  final String courseId;
  final String title;
  final String instructor;
  final String price;
  final String duration;
  final String? imageUrl;
  final String? description;
  final dynamic courseDetail;

  const _CourseDetailContent({
    required this.courseId,
    required this.title,
    required this.instructor,
    required this.price,
    required this.duration,
    this.imageUrl,
    this.description,
    this.courseDetail,
  });

  @override
  State<_CourseDetailContent> createState() => _CourseDetailContentState();
}

class _CourseDetailContentState extends State<_CourseDetailContent> {
  static final Uri _privacyPolicyUri = Uri.parse(
    AiConsentConstants.privacyPolicyUrl,
  );

  bool _showBottomButton = true;
  bool _isDescriptionExpanded = false;
  bool _isShowingAiConsentDialog = false;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  String? _currentContentId;
  String? _loadedProductId;
  bool _freeEnrollmentRequested = false;

  String get _serverAccessLevel => widget.courseDetail?.accessLevel ?? 'FREE';

  bool get _hasFullAccess => _serverAccessLevel == 'FULL';

  bool get _canBuy =>
      kIsWeb
          ? widget.courseDetail?.isPaid == true && !_hasFullAccess
          : widget.courseDetail?.purchase?.isAvailable == true;

  StoreProduct? get _storeProduct {
    if (kIsWeb) return null;
    final state = context.read<IapCubit>().state;
    if (state is IapReady) return state.product;
    if (state is IapPurchasing) return state.product;
    if (state is IapFailure) return state.product;
    return null;
  }

  String get _effectiveAccessLevel =>
      _hasFullAccess ? 'FULL' : _serverAccessLevel;

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(_onSheetChanged);
    _initializeCommerce();
  }

  @override
  void didUpdateWidget(covariant _CourseDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courseDetail != widget.courseDetail) _initializeCommerce();
  }

  void _initializeCommerce() {
    if (!_freeEnrollmentRequested &&
        widget.courseDetail?.isPaid == false &&
        widget.courseDetail?.purchase?.owned != true) {
      _freeEnrollmentRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<CourseCubit>().enrollFree(widget.courseId);
      });
    }
    if (!kIsWeb) {
      final productId =
          widget.courseDetail?.purchase?.mobileIap?.productId as String?;
      if (productId != null &&
          productId.isNotEmpty &&
          productId != _loadedProductId) {
        _loadedProductId = productId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.read<IapCubit>().loadProduct(productId);
        });
      }
    }
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetChanged);
    _sheetController.dispose();
    super.dispose();
  }

  void _onSheetChanged() {
    final size = _sheetController.size;
    final shouldShow = size <= 0.65;
    if (shouldShow != _showBottomButton) {
      setState(() {
        _showBottomButton = shouldShow;
      });
    }
  }

  void _showLessonBottomSheet(BuildContext context) {
    final sections = widget.courseDetail?.sections ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => CourseLessonBottomSheet(
            courseTitle: widget.title,
            sections: sections,
            accessLevel: _effectiveAccessLevel,
            onPlayVideo:
                (videoUrl, title, contentId) =>
                    _playVideo(context, videoUrl, title, contentId),
            onContentSelected: (contentId) {
              if (contentId != null) {
                setState(() {
                  _currentContentId = contentId;
                });
              }
            },
          ),
    );
  }

  String? _getFirstVideoUrl() {
    if (widget.courseDetail?.sections == null) return null;

    for (var section in widget.courseDetail.sections) {
      for (var content in section.contents) {
        if (content.files.isNotEmpty) {
          for (var file in content.files) {
            if (file.fileType == 'video') {
              return file.url;
            }
          }
        }
      }
    }
    return null;
  }

  String? _getFirstVideoContentId() {
    if (widget.courseDetail?.sections == null) return null;

    for (var section in widget.courseDetail.sections) {
      for (var content in section.contents) {
        if (content.files.isNotEmpty) {
          for (var file in content.files) {
            if (file.fileType == 'video') {
              return content.contentId;
            }
          }
        }
      }
    }
    return null;
  }

  void _playVideo(
    BuildContext context,
    String videoUrl,
    String title,
    String? contentId,
  ) {
    if (contentId != null) {
      setState(() {
        _currentContentId = contentId;
      });
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => _VideoPlayerScreen(
              courseId: widget.courseId,
              videoUrl: videoUrl,
              title: title,
              contentId: contentId,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFullAccess = _hasFullAccess;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          _buildVideoPlayerSection(context),
          _buildBottomSheet(context),
          if (hasFullAccess)
            _buildFloatingActionButton(context)
          else ...[
            if (_showBottomButton) _buildBottomActionButtons(context),
            if (!_showBottomButton) _buildFloatingActionButton(context),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoPlayerSection(BuildContext context) {
    String? videoUrl = _getFirstVideoUrl();
    String? contentId = _getFirstVideoContentId();
    String? thumbnail = widget.courseDetail?.thumbnailUrl ?? widget.imageUrl;

    return _InlineVideoPlayer(
      courseId: widget.courseId,
      videoUrl: videoUrl,
      contentId: contentId,
      thumbnail: thumbnail,
      title: widget.title,
      onBack: () => Navigator.of(context).pop(),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.6,
      minChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(50),
              topRight: Radius.circular(50),
            ),
            border: Border.all(
              color: AppColors.lightGray.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, -2),
                blurRadius: 10,
                color: Colors.black.withOpacity(0.1),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                _buildCourseDetailsSection(),

                _buildAboutSection(),

                _buildLessonsPreviewSection(context),

                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomActionButtons(BuildContext context) {
    final hasFullAccess = _hasFullAccess;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: _showBottomButton ? 0 : -100,
      left: 0,
      right: 0,
      child: Container(
        padding: AppPad.h24.add(AppPad.v20),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, -2),
              blurRadius: 10,
              color: Colors.black.withAlpha(26),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  ReviewScreen.routeName,
                  arguments: {'courseId': widget.courseId},
                );
              },
              child: Container(
                width: 60,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.colorFFEBF0,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.colorFF6905),
                ),
                child: const Icon(
                  Icons.star_border,
                  color: AppColors.colorFF6905,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child:
                  hasFullAccess
                      ? _buildEnrolledButton(context)
                      : _buildBuyButton(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    final hasFullAccess = _hasFullAccess;
    final daysLeftToCancel = widget.courseDetail?.daysLeftToCancel ?? 0;

    return Positioned(
      bottom: 24,
      right: 24,
      child:
          hasFullAccess
              ? SpeedDial(
                icon: Icons.menu,
                activeIcon: Icons.close,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                activeBackgroundColor: AppColors.primary,
                activeForegroundColor: AppColors.white,
                elevation: 6,
                overlayOpacity: 0.4,
                overlayColor: AppColors.text,
                spacing: 12,
                spaceBetweenChildren: 12,
                children: [
                  SpeedDialChild(
                    child: const Icon(
                      Icons.play_circle_filled,
                      color: AppColors.primary,
                    ),
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.primary,
                    label: 'course.continue_learning_short'.tr(),
                    labelStyle: AppTextStyles.textContent2.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    labelBackgroundColor: AppColors.white,
                    onTap: () => _showLessonBottomSheet(context),
                  ),
                  SpeedDialChild(
                    child: const Icon(
                      Icons.star_border,
                      color: AppColors.primary,
                    ),
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.primary,
                    label: 'course.review_course'.tr(),
                    labelStyle: AppTextStyles.textContent2.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    labelBackgroundColor: AppColors.white,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        ReviewScreen.routeName,
                        arguments: {'courseId': widget.courseId},
                      );
                    },
                  ),
                  SpeedDialChild(
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.primary,
                    ),
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.primary,
                    label: 'chat.chat_with_ai'.tr(),
                    labelStyle: AppTextStyles.textContent2.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    labelBackgroundColor: AppColors.white,
                    onTap: () => _openChatBubbleWithConsent(context),
                  ),
                  if (daysLeftToCancel > 0)
                    SpeedDialChild(
                      child: const Icon(
                        Icons.cancel_outlined,
                        color: AppColors.error,
                      ),
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.error,
                      label: 'course.cancel_course_short'.tr(),
                      labelStyle: AppTextStyles.textContent2.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.error,
                      ),
                      labelBackgroundColor: AppColors.white,
                      onTap:
                          () => _showCancelCourseDialog(
                            context,
                            daysLeftToCancel,
                          ),
                    ),
                ],
              )
              : FloatingActionButton.extended(
                onPressed: () {
                  if (hasFullAccess) {
                    _showLessonBottomSheet(context);
                  } else {
                    _handleBuyAction(context);
                  }
                },
                backgroundColor:
                    hasFullAccess ? AppColors.success : AppColors.primary,
                elevation: 6,
                label: Row(
                  children: [
                    Icon(
                      hasFullAccess
                          ? Icons.play_circle_filled
                          : Icons.shopping_cart,
                      color: AppColors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasFullAccess
                          ? 'course.continue_learning'.tr()
                          : 'course.buy_now'.tr(),
                      style: AppTextStyles.button.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Future<void> _handleBuyAction(BuildContext context) async {
    final productId =
        widget.courseDetail?.purchase?.mobileIap?.productId as String?;
    if (!_canBuy ||
        (!kIsWeb &&
            (productId == null ||
                productId.isEmpty ||
                _storeProduct == null))) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('payment.iap_unavailable'.tr())));
      return;
    }
    final result = await Navigator.pushNamed(
      context,
      OrderConfirmationScreen.routeName,
      arguments: {
        'courseId': widget.courseId,
        'title': widget.title,
        'instructor': widget.instructor,
        'price': widget.price,
        'productId': productId,
        'storePrice': _storeProduct?.priceString,
        'duration': widget.duration,
        'thumbnailUrl': widget.courseDetail?.thumbnailUrl ?? widget.imageUrl,
      },
    );

    if (result == true && context.mounted) {
      context.read<CourseCubit>().getCourseDetail(widget.courseId);
    }
  }

  Future<void> _openChatBubbleWithConsent(BuildContext context) async {
    final acceptedVersion = SpUtil.getString(
      AiConsentConstants.consentVersionStorageKey,
    );
    final hasAcceptedCurrentConsent =
        acceptedVersion == AiConsentConstants.currentConsentVersion;

    if (!hasAcceptedCurrentConsent) {
      final accepted = await _showAiDataConsentDialog(context);
      if (!mounted || !accepted) return;
    }

    if (context.mounted) {
      _showChatBubble(context);
    }
  }

  void _showChatBubble(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (bottomSheetContext) => _ChatBubbleOverlay(
            courseId: widget.courseId,
            courseTitle: widget.title,
            contentId: _currentContentId,
          ),
    );
  }

  Future<bool> _showAiDataConsentDialog(BuildContext context) async {
    if (_isShowingAiConsentDialog) return false;
    _isShowingAiConsentDialog = true;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'chat.ai_consent_title'.tr(),
              style: AppTextStyles.textStyleDefaultBold,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAiConsentText('chat.ai_consent_description'),
                  _buildAiConsentText('chat.ai_consent_data_sent'),
                  _buildAiConsentText('chat.ai_consent_sent_to'),
                  _buildAiConsentText('chat.ai_consent_purpose'),
                  _buildAiConsentText('chat.ai_consent_privacy_notice'),
                  _buildAiConsentText('chat.ai_consent_permission'),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openPrivacyPolicy(dialogContext),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text('chat.ai_consent_privacy_policy'.tr()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  'chat.ai_consent_cancel'.tr(),
                  style: AppTextStyles.textButton.copyWith(
                    color: AppColors.coolGray,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await SpUtil.putString(
                    AiConsentConstants.consentVersionStorageKey,
                    AiConsentConstants.currentConsentVersion,
                  );
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: Text(
                  'chat.ai_consent_confirm'.tr(),
                  style: AppTextStyles.button,
                ),
              ),
            ],
          ),
    );

    _isShowingAiConsentDialog = false;
    return accepted ?? false;
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    try {
      final opened = await launchUrl(
        _privacyPolicyUri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        _showPrivacyPolicyError(context);
      }
    } catch (_) {
      if (context.mounted) {
        _showPrivacyPolicyError(context);
      }
    }
  }

  void _showPrivacyPolicyError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('chat.ai_consent_privacy_policy_error'.tr())),
    );
  }

  Widget _buildAiConsentText(String translationKey) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(translationKey.tr(), style: AppTextStyles.textContent2),
    );
  }

  void _showCancelCourseDialog(BuildContext context, int daysLeft) async {
    final courseCubit = context.read<CourseCubit>();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BlocProvider.value(
              value: courseCubit,
              child: CourseCancellationScreen(
                courseId: widget.courseId,
                courseTitle: widget.title,
                daysLeftToCancel: daysLeft,
              ),
            ),
      ),
    );

    if (result == true && context.mounted) {
      courseCubit.getCourseDetail(widget.courseId);
    }
  }

  Widget _buildBuyButton(BuildContext context) {
    final iapState = kIsWeb ? null : context.watch<IapCubit>().state;
    final productReady = kIsWeb || iapState is IapReady;
    final loading = iapState is IapLoading;
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.primary, AppColors.color0961F5],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(102),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextButton(
        onPressed:
            productReady
                ? () => _handleBuyAction(context)
                : iapState is IapFailure
                ? () {
                  final id =
                      widget.courseDetail?.purchase?.mobileIap?.productId
                          as String?;
                  if (id != null) context.read<IapCubit>().loadProduct(id);
                }
                : null,
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              loading ? 'payment.loading'.tr() : 'course.buy_now'.tr(),
              style: AppTextStyles.button.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: AppColors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrolledButton(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.success, AppColors.success.withAlpha(204)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withAlpha(77),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextButton(
        onPressed: () {
          _showLessonBottomSheet(context);
        },
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: AppColors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'course.continue_learning'.tr(),
              style: AppTextStyles.button.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseDetailsSection() {
    final hasFullAccess = _hasFullAccess;

    return Container(
      padding: AppPad.h24.add(AppPad.v20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: AppTextStyles.textHeader2.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!hasFullAccess && _canBuy) ...[
            const SizedBox(width: 16),
            Text(
              kIsWeb
                  ? widget.price
                  : (_storeProduct?.priceString ?? 'payment.store_price'.tr()),
              style: AppTextStyles.textHeader2.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    if (widget.description == null || widget.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: AppPad.h24.add(const EdgeInsets.only(bottom: 12)),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.lightGray),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'course.about_this_course'.tr(),
                      style: AppTextStyles.textHeader3.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      _isDescriptionExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.color8F959E,
                    ),
                  ],
                ),
              ),
            ),
            if (_isDescriptionExpanded)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.lightGray.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                child: Text(
                  widget.description!,
                  style: AppTextStyles.textContent2.copyWith(
                    color: AppColors.text,
                    height: 1.6,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsPreviewSection(BuildContext context) {
    final sections = widget.courseDetail?.sections ?? [];
    final totalLessons = _getTotalLessonsCount(sections);
    final sectionsToShow =
        totalLessons > 5 ? sections.take(2).toList() : sections;
    final hasMore = totalLessons > 5;

    return Padding(
      padding: AppPad.h24.add(const EdgeInsets.only(top: 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text('course.lessons_title'.tr(), style: AppTextStyles.textHeader3.copyWith(fontWeight: FontWeight.bold)),
          // const SizedBox(height: 16),
          ...sectionsToShow.map(
            (section) => _SectionItem(
              section: section,
              onPlayVideo:
                  (videoUrl, title, contentId) =>
                      _playVideo(context, videoUrl, title, contentId),
              onContentSelected: (contentId) {
                if (contentId != null) {
                  setState(() {
                    _currentContentId = contentId;
                  });
                }
              },
            ),
          ),

          if (hasMore) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _showLessonBottomSheet(context),
              child: Container(
                width: double.infinity,
                padding: AppPad.v12,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'course.view_all_lessons'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.textButton.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _getTotalLessonsCount(List sections) {
    int count = 0;
    for (var section in sections) {
      count += (section.contents as List).length;
    }
    return count;
  }
}

class _InlineVideoPlayer extends StatefulWidget {
  final String courseId;
  final String? videoUrl;
  final String? contentId;
  final String? thumbnail;
  final String title;
  final VoidCallback onBack;

  const _InlineVideoPlayer({
    required this.courseId,
    required this.videoUrl,
    this.contentId,
    required this.thumbnail,
    required this.title,
    required this.onBack,
  });

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isPlaying = false;
  DateTime? _playingStartTime;
  int _totalPlayingDuration = 0;
  Timer? _trackingTimer;
  Timer? _videoStateTimer;
  bool _hasStarted = false;
  bool _lastPlayingState = false;

  @override
  void dispose() {
    _trackingTimer?.cancel();
    _videoStateTimer?.cancel();

    if (_isPlaying && _playingStartTime != null) {
      _totalPlayingDuration +=
          DateTime.now().difference(_playingStartTime!).inSeconds;
    }

    if (widget.contentId != null &&
        _videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      final currentPosition =
          _videoPlayerController!.value.position.inSeconds.toDouble();
      final totalDuration = _videoPlayerController!.value.duration.inSeconds;

      if (totalDuration > 0) {
        final progress = currentPosition / totalDuration;
        if (progress >= AppConst.videoCompleteThreshold) {
          _trackVideoProgress(
            VideoTrackingAction.videoComplete,
            currentPosition,
            totalDuration,
          );
        } else if (_hasStarted) {
          _trackVideoProgress(
            VideoTrackingAction.videoPause,
            currentPosition,
            totalDuration,
          );
        }
      }
    }

    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _trackVideoProgress(
    VideoTrackingAction action,
    double currentPosition,
    int totalDuration,
  ) {
    if (widget.contentId == null) return;

    try {
      final repo = HomeRepo(apiClient: ApiClient());
      repo.trackVideoProgress(
        courseId: widget.courseId,
        contentId: widget.contentId!,
        action: action,
        videoTimestamp: currentPosition,
        durationWatched: _totalPlayingDuration,
        totalDuration: totalDuration,
      );
    } catch (_) {}
  }

  void _startPlayingTracking() {
    _playingStartTime = DateTime.now();

    if (!_hasStarted &&
        _videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      _hasStarted = true;
      final currentPosition =
          _videoPlayerController!.value.position.inSeconds.toDouble();
      final totalDuration = _videoPlayerController!.value.duration.inSeconds;
      _trackVideoProgress(
        VideoTrackingAction.videoStart,
        currentPosition,
        totalDuration,
      );
    }

    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(
      Duration(seconds: AppConst.videoTrackingIntervalInSeconds),
      (_) {
        if (_videoPlayerController != null &&
            _videoPlayerController!.value.isInitialized &&
            _videoPlayerController!.value.isPlaying) {
          final currentPosition =
              _videoPlayerController!.value.position.inSeconds.toDouble();
          final totalDuration =
              _videoPlayerController!.value.duration.inSeconds;
          _trackVideoProgress(
            VideoTrackingAction.videoWatching,
            currentPosition,
            totalDuration,
          );
        }
      },
    );
  }

  void _stopPlayingTracking() {
    if (_playingStartTime != null) {
      _totalPlayingDuration +=
          DateTime.now().difference(_playingStartTime!).inSeconds;
      _playingStartTime = null;
    }
    _trackingTimer?.cancel();

    if (_hasStarted &&
        _videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      final currentPosition =
          _videoPlayerController!.value.position.inSeconds.toDouble();
      final totalDuration = _videoPlayerController!.value.duration.inSeconds;
      _trackVideoProgress(
        VideoTrackingAction.videoPause,
        currentPosition,
        totalDuration,
      );
    }
  }

  void _monitorVideoState() {
    _videoStateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_videoPlayerController != null &&
          _videoPlayerController!.value.isInitialized) {
        final isCurrentlyPlaying = _videoPlayerController!.value.isPlaying;

        if (isCurrentlyPlaying != _lastPlayingState) {
          _lastPlayingState = isCurrentlyPlaying;

          if (isCurrentlyPlaying) {
            _startPlayingTracking();
          } else {
            _stopPlayingTracking();
          }
        }
      }
    });
  }

  Future<void> _initializePlayer() async {
    if (widget.videoUrl == null) return;

    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl!),
    );

    await _videoPlayerController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: false,
      allowFullScreen: false,
      allowMuting: true,
      showControls: true,
      playbackSpeeds: [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0],
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.colorFF6905,
        handleColor: AppColors.colorFF6905,
        backgroundColor: Colors.grey,
        bufferedColor: AppColors.colorFF6905.withOpacity(0.3),
      ),
      autoInitialize: true,
    );

    setState(() {
      _isPlaying = true;
    });

    _monitorVideoState();
  }

  void _openFullscreenPlayer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => _VideoPlayerScreen(
              courseId: widget.courseId,
              videoUrl: widget.videoUrl!,
              title: widget.title,
              contentId: widget.contentId,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      color: Colors.black,
      child: Stack(
        children: [
          if (_isPlaying && _chewieController != null)
            Positioned.fill(child: Chewie(controller: _chewieController!))
          else
            Positioned.fill(
              child:
                  widget.thumbnail != null
                      ? Image.network(
                        widget.thumbnail!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFFFEBF0), Color(0xFFFFF0F5)],
                              ),
                            ),
                          );
                        },
                      )
                      : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFEBF0), Color(0xFFFFF0F5)],
                          ),
                        ),
                      ),
            ),

          if (!_isPlaying)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: widget.onBack,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          if (!_isPlaying && widget.videoUrl != null)
            Center(
              child: GestureDetector(
                onTap: _initializePlayer,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          if (_isPlaying && widget.videoUrl != null)
            Positioned(
              bottom: 20,
              right: 20,
              child: GestureDetector(
                onTap: () => _openFullscreenPlayer(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VideoPlayerScreen extends StatefulWidget {
  final String courseId;
  final String videoUrl;
  final String title;
  final String? contentId;

  const _VideoPlayerScreen({
    required this.courseId,
    required this.videoUrl,
    required this.title,
    this.contentId,
  });

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  DateTime? _playingStartTime;
  int _totalPlayingDuration = 0;
  Timer? _trackingTimer;
  Timer? _videoStateTimer;
  bool _hasStarted = false;
  bool _lastPlayingState = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
      playbackSpeeds: [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0],
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.primary,
        handleColor: AppColors.primary,
        backgroundColor: Colors.grey,
        bufferedColor: AppColors.primary.withOpacity(0.3),
      ),
      placeholder: Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      autoInitialize: true,
    );

    setState(() {});

    _monitorVideoState();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    _videoStateTimer?.cancel();

    if (_lastPlayingState && _playingStartTime != null) {
      _totalPlayingDuration +=
          DateTime.now().difference(_playingStartTime!).inSeconds;
    }

    if (widget.contentId != null &&
        _videoPlayerController.value.isInitialized) {
      final currentPosition =
          _videoPlayerController.value.position.inSeconds.toDouble();
      final totalDuration = _videoPlayerController.value.duration.inSeconds;

      if (totalDuration > 0) {
        final progress = currentPosition / totalDuration;
        if (progress >= AppConst.videoCompleteThreshold) {
          _trackVideoProgress(
            VideoTrackingAction.videoComplete,
            currentPosition,
            totalDuration,
          );
        } else if (_hasStarted) {
          _trackVideoProgress(
            VideoTrackingAction.videoPause,
            currentPosition,
            totalDuration,
          );
        }
      }
    }

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _trackVideoProgress(
    VideoTrackingAction action,
    double currentPosition,
    int totalDuration,
  ) {
    if (widget.contentId == null) return;

    try {
      final repo = HomeRepo(apiClient: ApiClient());
      repo.trackVideoProgress(
        courseId: widget.courseId,
        contentId: widget.contentId!,
        action: action,
        videoTimestamp: currentPosition,
        durationWatched: _totalPlayingDuration,
        totalDuration: totalDuration,
      );
    } catch (_) {}
  }

  void _startPlayingTracking() {
    _playingStartTime = DateTime.now();

    if (!_hasStarted && _videoPlayerController.value.isInitialized) {
      _hasStarted = true;
      final currentPosition =
          _videoPlayerController.value.position.inSeconds.toDouble();
      final totalDuration = _videoPlayerController.value.duration.inSeconds;
      _trackVideoProgress(
        VideoTrackingAction.videoStart,
        currentPosition,
        totalDuration,
      );
    }

    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(
      Duration(seconds: AppConst.videoTrackingIntervalInSeconds),
      (_) {
        if (_videoPlayerController.value.isInitialized &&
            _videoPlayerController.value.isPlaying) {
          final currentPosition =
              _videoPlayerController.value.position.inSeconds.toDouble();
          final totalDuration = _videoPlayerController.value.duration.inSeconds;
          _trackVideoProgress(
            VideoTrackingAction.videoWatching,
            currentPosition,
            totalDuration,
          );
        }
      },
    );
  }

  void _stopPlayingTracking() {
    if (_playingStartTime != null) {
      _totalPlayingDuration +=
          DateTime.now().difference(_playingStartTime!).inSeconds;
      _playingStartTime = null;
    }
    _trackingTimer?.cancel();

    if (_hasStarted && _videoPlayerController.value.isInitialized) {
      final currentPosition =
          _videoPlayerController.value.position.inSeconds.toDouble();
      final totalDuration = _videoPlayerController.value.duration.inSeconds;
      _trackVideoProgress(
        VideoTrackingAction.videoPause,
        currentPosition,
        totalDuration,
      );
    }
  }

  void _monitorVideoState() {
    _videoStateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_videoPlayerController.value.isInitialized) {
        final isCurrentlyPlaying = _videoPlayerController.value.isPlaying;

        if (isCurrentlyPlaying != _lastPlayingState) {
          _lastPlayingState = isCurrentlyPlaying;

          if (isCurrentlyPlaying) {
            _startPlayingTracking();
          } else {
            _stopPlayingTracking();
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: AppTextStyles.textHeader3.copyWith(color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Center(
        child:
            _chewieController != null &&
                    _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : const CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

class _SectionItem extends StatefulWidget {
  final dynamic section;
  final Function(String videoUrl, String title, String? contentId) onPlayVideo;
  final Function(String? contentId) onContentSelected;

  const _SectionItem({
    required this.section,
    required this.onPlayVideo,
    required this.onContentSelected,
  });

  @override
  State<_SectionItem> createState() => _SectionItemState();
}

class _SectionItemState extends State<_SectionItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final contents = widget.section.contents as List;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightGray),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.section.title ?? '',
                          style: AppTextStyles.textContent1.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.section.description != null &&
                            widget.section.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.section.description ?? '',
                            style: AppTextStyles.textContent3.copyWith(
                              color: AppColors.color8F959E,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.color8F959E,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              decoration: BoxDecoration(
                color: AppColors.lightGray.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children:
                    contents.map((content) {
                      String? videoUrl;
                      String? documentUrl;
                      if (content.files.isNotEmpty) {
                        for (var file in content.files) {
                          if (file.fileType == 'video') {
                            videoUrl = file.url;
                            break;
                          } else if (file.fileType == 'document') {
                            documentUrl = file.url;
                            break;
                          }
                        }
                      }

                      final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
                      final hasDocument =
                          documentUrl != null && documentUrl.isNotEmpty;
                      final hasQuiz = content.quiz != null;

                      return InkWell(
                        onTap:
                            hasQuiz
                                ? () {
                                  widget.onContentSelected(content.contentId);
                                  final quiz = content.quiz!;
                                  final quizModel = QuizModel(
                                    id: quiz.questionBankId ?? '',
                                    title: quiz.quizTitle ?? '',
                                    type: 'ASSIGNMENT',
                                    timeLimit: 0,
                                    questionCount: 0,
                                    status: QuizStatus.notTaken,
                                    attempts: 0,
                                    subject: '',
                                  );
                                  Navigator.pushNamed(
                                    context,
                                    QuizTakingScreen.routeName,
                                    arguments: {'quiz': quizModel},
                                  );
                                }
                                : hasVideo
                                ? () => widget.onPlayVideo(
                                  videoUrl!,
                                  content.title ?? '',
                                  content.contentId,
                                )
                                : hasDocument
                                ? () {
                                  widget.onContentSelected(content.contentId);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => DocumentViewerScreen(
                                            documentUrl: documentUrl!,
                                            title: content.title ?? '',
                                          ),
                                    ),
                                  );
                                }
                                : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: AppColors.lightGray.withOpacity(0.5),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              if (hasQuiz)
                                Icon(
                                  Icons.quiz_outlined,
                                  color: AppColors.success,
                                  size: 24,
                                )
                              else if (hasVideo)
                                Icon(
                                  Icons.play_circle_outline,
                                  color: AppColors.primary,
                                  size: 24,
                                )
                              else
                                Icon(
                                  Icons.description_outlined,
                                  color: AppColors.colorFF6905,
                                  size: 24,
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      content.title ?? '',
                                      style: AppTextStyles.textContent2
                                          .copyWith(
                                            color: AppColors.text,
                                            fontWeight:
                                                hasVideo ||
                                                        hasQuiz ||
                                                        hasDocument
                                                    ? FontWeight.w500
                                                    : FontWeight.normal,
                                          ),
                                    ),
                                    if (content.description != null &&
                                        content.description!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        content.description ?? '',
                                        style: AppTextStyles.textContent3
                                            .copyWith(
                                              color: AppColors.color8F959E,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChatBubbleOverlay extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String? contentId;

  const _ChatBubbleOverlay({
    required this.courseId,
    required this.courseTitle,
    this.contentId,
  });

  @override
  State<_ChatBubbleOverlay> createState() => _ChatBubbleOverlayState();
}

class _ChatBubbleOverlayState extends State<_ChatBubbleOverlay> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  late final ChatBotRepo _chatRepo;

  @override
  void initState() {
    super.initState();
    _chatRepo = ChatBotRepo(apiClient: ApiClient());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(text: message, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _chatRepo.sendMessage(
        message: message,
        courseId: widget.courseId,
        contentId: widget.contentId,
      );

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: response.data?.responseRaw ?? 'Không có phản hồi',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
      }

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Lỗi: ${e.toString()}',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.smart_toy,
                            color: AppColors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'chat.chat_with_ai'.tr(),
                              style: AppTextStyles.textHeader3.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    _messages.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: AppColors.lightGray,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'chat.input_hint'.tr(),
                                style: AppTextStyles.textContent2.copyWith(
                                  color: AppColors.coolGray,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return _buildMessageBubble(message);
                          },
                        ),
              ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'chat.thinking'.tr(),
                        style: AppTextStyles.textContent3.copyWith(
                          color: AppColors.coolGray,
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(
                    top: BorderSide(color: AppColors.lightGray, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'chat.type_message'.tr(),
                          hintStyle: AppTextStyles.textContent2.copyWith(
                            color: AppColors.color8F959E,
                          ),
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: AppColors.lightGray),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: AppColors.lightGray),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        style: AppTextStyles.textContent2,
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: AppColors.white,
                          size: 20,
                        ),
                        onPressed: _isLoading ? null : _sendMessage,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                message.isUser
                    ? const Radius.circular(16)
                    : const Radius.circular(4),
            bottomRight:
                message.isUser
                    ? const Radius.circular(4)
                    : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: AppTextStyles.textContent2.copyWith(
                color: message.isUser ? AppColors.white : AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
