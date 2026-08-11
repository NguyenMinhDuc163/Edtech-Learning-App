import 'package:disposable_provider/disposable_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ed_tech/core/widgets/app_gap.dart';
import 'package:ed_tech/data/services/user_service.dart';
import 'package:ed_tech/init.dart';
import 'package:ed_tech/modules/profile/bloc/profile_controller.dart';
import 'package:ed_tech/modules/profile/screen/edit_profile_screen.dart';
import 'package:ed_tech/modules/iap/bloc/iap_cubit.dart';
import 'package:ed_tech/modules/iap/service/iap_platform.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  static const String routeName = '/profile';

  @override
  Widget build(BuildContext context) {
    final ProfileController controller =
        DisposableProvider.of<ProfileController>(context);
    return _ProfileContent(controller: controller);
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserData?>(
      valueListenable: UserService.instance.userDataNotifier,
      builder: (context, userData, _) {
        if (userData == null) {
          return FunctionScreenTemplate(
            isShowAppBar: true,
            title: 'profile.title'.tr(),
            isShowBottomButton: false,
            screen: Center(child: Text('profile.no_data'.tr())),
          );
        }

        return FunctionScreenTemplate(
          isShowAppBar: true,
          title: 'profile.title'.tr(),
          isShowBottomButton: false,
          actionsWidget: [
            GestureDetector(
              onTap: () async {
                await Navigator.pushNamed(context, EditProfileScreen.routeName);
              },
              child: Icon(Icons.edit, color: AppColors.primary, size: 20),
            ),
          ],
          screen: SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(userData),
                AppGap.h30,
                Padding(
                  padding: AppPad.h20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPersonalInfo(userData),
                      if (IapPlatform.isSupported) ...[
                        AppGap.h20,
                        _buildRestorePurchases(context),
                      ],
                      AppGap.h30,
                      if (userData.certificates != null &&
                          userData.certificates!.isNotEmpty)
                        _buildCertificates(userData.certificates!),
                    ],
                  ),
                ),
                AppGap.h30,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(UserData userData) {
    return Container(
      width: double.infinity,
      padding: AppPad.a30,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.electricBlue],
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 55,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.offWhite,
                  backgroundImage:
                      userData.avatarUrl != null &&
                              userData.avatarUrl!.isNotEmpty
                          ? NetworkImage(userData.avatarUrl!) as ImageProvider
                          : null,
                  onBackgroundImageError:
                      userData.avatarUrl != null
                          ? (exception, stackTrace) {}
                          : null,
                  child:
                      userData.avatarUrl == null || userData.avatarUrl!.isEmpty
                          ? Icon(
                            Icons.person,
                            size: 50,
                            color: AppColors.coolGray,
                          )
                          : null,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: AppPad.a8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.verified,
                    color: AppColors.electricBlue,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          AppGap.h20,
          Text(
            userData.fullName ?? userData.username,
            style: AppTextStyles.textHeader2.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          AppGap.h8,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              userData.role.toUpperCase(),
              style: AppTextStyles.textContent2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          AppGap.h8,
        ],
      ),
    );
  }

  Widget _buildPersonalInfo(UserData userData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person_outline, color: AppColors.primary, size: 24),
            AppGap.w8,
            Text(
              'profile.personal_info'.tr(),
              style: AppTextStyles.textHeader3.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        AppGap.h20,
        _buildInfoGrid(userData),
      ],
    );
  }

  Widget _buildRestorePurchases(BuildContext context) {
    return BlocConsumer<IapCubit, IapState>(
      listener: (context, state) {
        if (state is IapRestoreSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.activatedCourseIds.isEmpty
                    ? 'profile.restore_empty'.tr()
                    : 'profile.restore_success'.tr(),
              ),
            ),
          );
        } else if (state is IapFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final restoring = state is IapRestoring;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.restore, color: AppColors.primary),
          title: Text('profile.restore_purchases'.tr()),
          subtitle: Text('profile.restore_purchases_hint'.tr()),
          trailing:
              restoring
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.chevron_right),
          onTap: restoring ? null : () => context.read<IapCubit>().restore(),
        );
      },
    );
  }

  Widget _buildInfoGrid(UserData userData) {
    final List<Map<String, dynamic>> infoItems = [
      {
        'icon': Icons.account_circle_outlined,
        'label': 'Username',
        'value': userData.username,
      },
      {'icon': Icons.badge_outlined, 'label': 'ID', 'value': userData.id},
      {
        'icon': Icons.email_outlined,
        'label': 'profile.email'.tr(),
        'value': userData.email,
      },
      if (userData.phone != null && userData.phone!.isNotEmpty)
        {
          'icon': Icons.phone_outlined,
          'label': 'profile.phone'.tr(),
          'value': userData.phone!,
        },
      if (userData.grade != null && userData.grade!.isNotEmpty)
        {
          'icon': Icons.school_outlined,
          'label': 'profile.grade'.tr(),
          'value': userData.grade!,
        },
      if (userData.subjectSpecialty != null &&
          userData.subjectSpecialty!.isNotEmpty)
        {
          'icon': Icons.book_outlined,
          'label': 'profile.subject'.tr(),
          'value': userData.subjectSpecialty!,
        },
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (int i = 0; i < infoItems.length; i++)
            Column(
              children: [
                _buildInfoRow(
                  icon: infoItems[i]['icon'] as IconData,
                  label: infoItems[i]['label'] as String,
                  value: infoItems[i]['value'] as String,
                ),
                if (i < infoItems.length - 1)
                  Divider(height: 1, color: AppColors.divider),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: AppPad.h16v14,
      child: Row(
        children: [
          Container(
            padding: AppPad.a8,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          AppGap.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.textContent3.copyWith(
                    color: AppColors.coolGray,
                  ),
                ),
                AppGap.h4,
                Text(
                  value,
                  style: AppTextStyles.textContent2.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificates(List<CertificateData> certificates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: AppPad.a8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.electricBlue],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 20,
              ),
            ),
            AppGap.w8,
            Text(
              'profile.certificates'.tr(),
              style: AppTextStyles.textHeader3.copyWith(
                color: AppColors.primary,
              ),
            ),
            Spacer(),
            Text(
              '${certificates.length}',
              style: AppTextStyles.textHeader3.copyWith(
                color: AppColors.coolGray,
              ),
            ),
          ],
        ),
        AppGap.h20,
        ...certificates.map((cert) => _buildCertificateCard(cert)),
      ],
    );
  }

  Widget _buildCertificateCard(CertificateData certificate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (certificate.fileUrl != null && certificate.fileUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Image.network(
                certificate.fileUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.electricBlue.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: AppColors.coolGray,
                          ),
                          AppGap.h8,
                          Text(
                            'Image not available',
                            style: AppTextStyles.textContent3.copyWith(
                              color: AppColors.coolGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: AppPad.a16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  certificate.title ?? 'Untitled',
                  style: AppTextStyles.textHeader3.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                if (certificate.description != null &&
                    certificate.description!.isNotEmpty) ...[
                  AppGap.h8,
                  Text(
                    certificate.description!,
                    style: AppTextStyles.textContent2.copyWith(
                      color: AppColors.coolGray,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                AppGap.h12,
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (certificate.issuedBy != null &&
                        certificate.issuedBy!.isNotEmpty)
                      _buildChip(
                        icon: Icons.business,
                        label: certificate.issuedBy!,
                      ),
                    if (certificate.issuedAt != null)
                      _buildChip(
                        icon: Icons.calendar_today,
                        label: _formatDate(certificate.issuedAt!),
                      ),
                    if (certificate.expiresAt != null)
                      _buildChip(
                        icon: Icons.event_available,
                        label: 'Exp: ${_formatDate(certificate.expiresAt!)}',
                        color: AppColors.crimson,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppColors.primary),
          AppGap.w4,
          Text(
            label,
            style: AppTextStyles.textContent3.copyWith(
              color: color ?? AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
