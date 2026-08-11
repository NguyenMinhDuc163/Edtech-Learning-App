import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ed_tech/core/widgets/switch_botton_widget.dart';
import 'package:ed_tech/core/widgets/toast.dart';
import 'package:ed_tech/core/theme/locale_cubit.dart';
import 'package:ed_tech/init.dart';
import 'package:ed_tech/modules/auth/sign_in/repository/sign_in_repo.dart';
import 'package:ed_tech/modules/auth/sign_in/screen/sign_in_screen.dart';
import 'package:ed_tech/common/app_event_service.dart';
import 'package:ed_tech/data/services/user_service.dart';

class DrawerWidget extends StatelessWidget {
  const DrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: AppPad.v40,
          children: <Widget>[
            Padding(
              padding: AppPad.h20,
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: CircleAvatar(
                    backgroundColor: AppColors.offWhite,
                    child: SvgPicture.asset(IconPath.iconMenu),
                  ),
                ),
              ),
            ),

            Container(
              padding: AppPad.a20,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Builder(builder: _buildDrawerHeader),
            ),
            Row(
              children: [
                Expanded(
                  child: _buildDrawerItem(
                    icon: IconPath.iconSun,
                    title: 'common.dark_mode'.tr(),
                    onTap: () {
                      showToastTop(
                        message: 'common.dark_mode_coming_soon'.tr(),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ),
                Padding(
                  padding: AppPad.h10,
                  child: SwitchBottomWidget(
                    onChanged: (value) {
                      showToastTop(
                        message: 'common.dark_mode_coming_soon'.tr(),
                      );
                      // Dark mode chưa được hỗ trợ. Giữ switch để minh họa
                      // nhưng không cập nhật theme của ứng dụng.
                      // final newThemeMode =
                      //     value ? ThemeMode.dark : ThemeMode.light;
                      // context.read<ThemeCubit>().setThemeMode(newThemeMode);
                    },
                  ),
                ),
              ],
            ),
            // Language switcher
            Row(
              children: [
                Expanded(
                  child: _buildDrawerItem(
                    icon: IconPath.iconAssigment,
                    title: 'common.language'.tr(),
                    onTap: () {}, // Không làm gì - chỉ để hiển thị label
                  ),
                ),
                Padding(
                  padding: AppPad.h10,
                  child: BlocBuilder<LocaleCubit, Locale>(
                    builder: (context, locale) {
                      final isEnglish = locale.languageCode == 'en';
                      return GestureDetector(
                        onTap: () {
                          final localeCubit = context.read<LocaleCubit>();
                          localeCubit.toggleLocale(context);
                        },
                        child: Container(
                          padding: AppPad.a8,
                          decoration: BoxDecoration(
                            color: AppColors.offWhite,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isEnglish
                                ? 'common.lang_en_short'.tr()
                                : 'common.lang_vi_short'.tr(),
                            style: AppTextStyles.textContent3.copyWith(
                              color: AppColors.coolGray,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            _buildPaymentDrawerItem(context),
            _buildDrawerItem(
              icon: IconPath.iconSetting,
              title: 'common.change_password'.tr(),
              iconSize: 20,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/changePassword');
              },
            ),
            _buildDrawerItem(
              icon: IconPath.iconTrash,
              title: 'common.delete_account'.tr(),
              iconColor: AppColors.crimson,
              textStyle: AppTextStyles.textContent2.copyWith(
                color: AppColors.crimson,
              ),
              onTap: () => _showDeleteAccountConfirmDialog(context),
            ),
            _buildDrawerItem(
              icon: IconPath.iconLogout,
              title: 'common.logout'.tr(),
              iconColor: Colors.red,
              textStyle: AppTextStyles.textContent2.copyWith(color: Colors.red),
              onTap: () async {
                final navigator = Navigator.of(context);

                context.read<SignInRepo>().logout();
                await AppEventService.notifyUserSignOut();

                navigator.pushReplacementNamed(SignInScreen.routeName);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('common.delete_account_confirm_title'.tr()),
            content: Text('common.delete_account_confirm_message'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('common.cancel'.tr()),
              ),
              ElevatedButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final repo = context.read<SignInRepo>();

                  Navigator.pop(dialogContext);
                  Navigator.pop(context);

                  try {
                    final message = await repo.deleteAccount();
                    showToastTop(
                      message:
                          message.isNotEmpty
                              ? message
                              : 'common.delete_account_success'.tr(),
                    );
                    navigator.pushNamedAndRemoveUntil(
                      SignInScreen.routeName,
                      (route) => false,
                    );
                  } catch (e) {
                    showToastTop(message: e.toString());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.crimson,
                  foregroundColor: Colors.white,
                ),
                child: Text('common.confirm'.tr()),
              ),
            ],
          ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return ValueListenableBuilder<UserData?>(
      valueListenable: UserService.instance.userDataNotifier,
      builder: (context, userData, _) {
        final username = userData?.username ?? 'User';
        final email = userData?.email ?? '';

        return GestureDetector(
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/profile');
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: width_8,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.grey[200],
                    backgroundImage:
                        userData?.avatarUrl != null &&
                                userData!.avatarUrl!.isNotEmpty
                            ? NetworkImage(userData.avatarUrl!)
                            : null,
                    child:
                        userData?.avatarUrl == null ||
                                userData!.avatarUrl!.isEmpty
                            ? Icon(Icons.person)
                            : null,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(username, style: AppTextStyles.textHeader3),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            style: AppTextStyles.textContent3.copyWith(
                              color: AppColors.coolGray,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentDrawerItem(BuildContext context) {
    return _buildDrawerItem(
      icon: IconPath.iconCredit,
      title: 'common.payments'.tr(),
      iconSize: 25,
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/myPaymentsScreen');
      },
    );
  }

  Widget _buildDrawerItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
    TextStyle? textStyle,
    Color? iconColor,
    double? iconSize,
  }) {
    return ListTile(
      leading: SizedBox(
        width: iconSize ?? 24,
        height: iconSize ?? 24,
        child: SvgPicture.asset(
          icon,
          color: iconColor ?? Colors.grey[700],
          width: iconSize ?? 24,
          height: iconSize ?? 24,
        ),
      ),
      title: Text(title, style: textStyle ?? AppTextStyles.textContent2),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      dense: true,
    );
  }
}
