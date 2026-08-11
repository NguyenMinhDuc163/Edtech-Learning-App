import 'package:disposable_provider/disposable_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ed_tech/init.dart';
import 'package:ed_tech/modules/course/bloc/search_course_controller.dart';
import 'package:ed_tech/modules/course/bloc/search_course_cubit.dart';
import 'package:ed_tech/modules/course/model/search_course_result.dart';
import 'package:ed_tech/modules/course/model/search_history.dart';
import 'package:ed_tech/modules/course/model/autocomplete_suggestion.dart';
import 'package:ed_tech/modules/course/screen/course_detail_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ed_tech/utils/helpers/currency_extension.dart';

class SearchCourseScreen extends StatefulWidget {
  const SearchCourseScreen({super.key});
  static const String routeName = '/SearchCourseScreen';

  @override
  State<SearchCourseScreen> createState() => _SearchCourseScreenState();
}

class _SearchCourseScreenState extends State<SearchCourseScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchCourseCubit>().loadSearchHistory();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final initialQuery = args?['initialQuery'] as String?;

      if (initialQuery != null && initialQuery.isNotEmpty) {
        _textController.text = initialQuery;
        Future.microtask(() {
          if (mounted) {
            context.read<SearchCourseCubit>().searchCourses(initialQuery);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      context.read<SearchCourseCubit>().reset();
      return;
    }

    context.read<SearchCourseCubit>().getAutocompleteSuggestions(query);
  }

  @override
  Widget build(BuildContext context) {
    final SearchCourseController controller =
        DisposableProvider.of<SearchCourseController>(context);

    return FunctionScreenTemplate(
      isShowAppBar: true,
      isShowBottomButton: false,
      title: 'search.title'.tr(),
      screen: Column(
        children: [
          Padding(
            padding: AppPad.h24v12,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.colorF4F3FD,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.colorB8B8D2),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      autofocus: true,
                      onChanged: _onSearchChanged,
                      style: AppTextStyles.text,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'search.search_placeholder'.tr(),
                        hintStyle: AppTextStyles.inputHintText,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_textController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _textController.clear();
                        controller.clearSearch();
                        context.read<SearchCourseCubit>().reset();
                      },
                      child: const Icon(
                        Icons.clear,
                        color: AppColors.colorB8B8D2,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<SearchCourseCubit, SearchCourseState>(
              builder: (context, state) {
                if (state is SearchCourseInitial) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 80,
                          color: AppColors.colorB8B8D2.withAlpha(128),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'search.search_placeholder'.tr(),
                          style: AppTextStyles.text.copyWith(
                            color: AppColors.colorB8B8D2,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is AutocompleteSuggestionsLoaded) {
                  final suggestions = state.suggestions;

                  if (suggestions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 80,
                            color: AppColors.colorB8B8D2.withAlpha(128),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'search.no_suggestions'.tr(),
                            style: AppTextStyles.text.copyWith(
                              color: AppColors.colorB8B8D2,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 12,
                      bottom: 16,
                    ),
                    itemCount: suggestions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final suggestion =
                          suggestions[index] as AutocompleteSuggestion;
                      return _SuggestionItem(
                        keyword: suggestion.keyword ?? '',
                        onTap: () {
                          _textController.text = suggestion.keyword ?? '';
                          context.read<SearchCourseCubit>().searchCourses(
                            suggestion.keyword ?? '',
                          );
                        },
                      );
                    },
                  );
                }

                if (state is SearchHistoryLoaded) {
                  final history = state.historyList;

                  if (history.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 80,
                            color: AppColors.colorB8B8D2.withAlpha(128),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'search.no_history'.tr(),
                            style: AppTextStyles.text.copyWith(
                              color: AppColors.colorB8B8D2,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: AppPad.h24v12,
                        child: Text(
                          'search.recent_searches'.tr(),
                          style: AppTextStyles.textMedium,
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.only(
                            left: 24,
                            right: 24,
                            bottom: 16,
                          ),
                          itemCount: history.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = history[index] as SearchHistory;
                            return _HistoryItem(
                              keyword: item.keyword ?? '',
                              onTap: () {
                                _textController.text = item.keyword ?? '';
                                context.read<SearchCourseCubit>().searchCourses(
                                  item.keyword ?? '',
                                );
                              },
                              onDelete: () {
                                context.read<SearchCourseCubit>().deleteHistory(
                                  item.searchId ?? '',
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }

                if (state is SearchCourseProgress) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is SearchCourseSuccess) {
                  final results = state.results;

                  if (results.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 80,
                            color: AppColors.colorB8B8D2.withAlpha(128),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'search.no_results'.tr(),
                            style: AppTextStyles.text.copyWith(
                              color: AppColors.colorB8B8D2,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 24,
                          right: 24,
                          bottom: 12,
                        ),
                        child: Text(
                          '${results.length} ${'search.results_count'.tr()}',
                          style: AppTextStyles.textMedium.copyWith(
                            color: AppColors.colorB8B8D2,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.only(
                            left: 24,
                            right: 24,
                            bottom: 16,
                          ),
                          itemCount: results.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final result = results[index] as SearchCourseResult;
                            return _SearchResultCard(
                              result: result,
                              onTap:
                                  () =>
                                      _navigateToCourseDetail(context, result),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }

                if (state is SearchCourseError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: AppColors.colorB8B8D2.withAlpha(128),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: AppTextStyles.text.copyWith(
                            color: AppColors.colorB8B8D2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCourseDetail(
    BuildContext context,
    SearchCourseResult result,
  ) {
    Navigator.pushNamed(
      context,
      CourseDetailScreen.routeName,
      arguments: {
        'courseId': result.courseId ?? '',
        'title': result.title ?? 'course.untitled'.tr(),
        'instructor': 'course.unknown_teacher'.tr(),
        'price': result.price ?? '0',
        'duration': '0h 0m',
        'imageUrl': result.thumbnailUrl,
        'description': result.description,
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final SearchCourseResult result;
  final VoidCallback onTap;

  const _SearchResultCard({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const showPrice = false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 1),
              blurRadius: 2,
              color: Color.fromRGBO(0, 0, 0, 0.06),
            ),
            BoxShadow(
              offset: Offset(0, 10),
              blurRadius: 20,
              color: AppColors.shadowBlack15,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.colorF4F3FD,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child:
                    result.thumbnailUrl != null
                        ? Image.network(
                          result.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image_not_supported,
                              color: AppColors.colorB8B8D2,
                              size: 40,
                            );
                          },
                        )
                        : const Icon(
                          Icons.image_not_supported,
                          color: AppColors.colorB8B8D2,
                          size: 40,
                        ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: AppPad.a16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title ?? 'course.untitled'.tr(),
                      style: AppTextStyles.textMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (result.description != null) ...[
                      Text(
                        result.description!,
                        style: AppTextStyles.text.copyWith(
                          color: AppColors.coolGray,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (showPrice) const SizedBox(height: 8),
                    ],
                    if (showPrice)
                      Row(
                        children: [
                          Text(
                            result.price != null
                                ? result.price.formatCurrency()
                                : 'course.free'.tr(),
                            style: AppTextStyles.textMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionItem extends StatelessWidget {
  final String keyword;
  final VoidCallback onTap;

  const _SuggestionItem({required this.keyword, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppPad.h16v12,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.colorF4F3FD, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.colorB8B8D2, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                keyword,
                style: AppTextStyles.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String keyword;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryItem({
    required this.keyword,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppPad.h16v12,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.colorF4F3FD, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.history, color: AppColors.colorB8B8D2, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                keyword,
                style: AppTextStyles.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.close,
                  color: AppColors.colorB8B8D2,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
