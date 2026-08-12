import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ed_tech/core/ads/ad_frequency_manager.dart';
import 'package:ed_tech/core/constants/icon_path.dart';
import 'package:ed_tech/core/theme/app_colors.dart';
import 'package:ed_tech/core/theme/app_pad.dart';
import 'package:ed_tech/core/theme/app_text_styles.dart';
import 'package:ed_tech/core/widgets/drawer_widget.dart';
import 'package:ed_tech/core/widgets/template/button_widget.dart';
import 'package:ed_tech/core/widgets/template/opacity_widget.dart';
import 'package:ed_tech/core/widgets/will_unfocus_form_scope.dart';

// ignore: must_be_immutable
class FunctionScreenTemplate extends StatefulWidget {
  String? title, titleButtonBottom;
  Widget? screen,
      titleWidget,
      floatingActionButton,
      background,
      customBottomNavigationBar,
      drawer;
  bool resizeToAvoidBottomInset;
  bool isShowDrawer, isShowBottomButton, isShowAppBar;
  Widget? leadingWidget;
  List<Widget>? actionsWidget;
  Function? onClickBottomButton, onBack;
  Color? backgroundColor;
  Color? appbarColor;

  FunctionScreenTemplate({
    super.key,
    this.title,
    this.screen,
    this.titleButtonBottom,
    this.isShowBottomButton = true,
    this.onBack,
    this.resizeToAvoidBottomInset = true,
    this.titleWidget,
    this.floatingActionButton,
    this.isShowAppBar = true,
    this.isShowDrawer = false,
    this.background,
    this.customBottomNavigationBar,
    this.leadingWidget,
    this.actionsWidget,
    this.onClickBottomButton,
    this.backgroundColor,
    this.drawer,
    this.appbarColor,
  });

  @override
  State<FunctionScreenTemplate> createState() => _FunctionScreenTemplateState();
}

class _FunctionScreenTemplateState extends State<FunctionScreenTemplate>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isOpacity = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    try {
      if (state == AppLifecycleState.paused) {
        _setOpacity(true);
      } else if (state == AppLifecycleState.inactive) {
        _setOpacity(!AdFrequencyManager.instance.isPaymentFlowActive);
      } else if (state == AppLifecycleState.resumed) {
        _setOpacity(false);
      }
    } catch (e) {
      print(e);
    }
  }

  void _setOpacity(bool value) {
    if (!mounted || isOpacity == value) return;
    setState(() => isOpacity = value);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.background != null)
          Positioned.fill(child: widget.background!),
        _buildScaffold(
          body: widget.screen ?? const SizedBox(),
          appBar: widget.isShowAppBar,
        ),
        if (isOpacity) const OpacityWidget(),
      ],
    );
  }

  Widget _buildScaffold({required Widget body, required bool appBar}) {
    return WillUnfocusFormScope(
      child: Scaffold(
        extendBodyBehindAppBar: widget.background != null,
        resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
        key: _scaffoldKey,
        backgroundColor:
            widget.background != null
                ? Colors.transparent
                : widget.backgroundColor ?? AppColors.white,
        appBar: appBar ? appBarWidget() : null,
        drawer: DrawerWidget(), // Thêm drawer property
        body: SafeArea(
          // top: false,
          child: body,
        ),
        bottomNavigationBar:
            widget.isShowBottomButton
                ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    (widget.customBottomNavigationBar ??
                        ButtonWidget(
                          title: widget.titleButtonBottom,
                          padding: AppPad.v24,
                          onPressed: widget.onClickBottomButton ?? () {},
                        )),
                  ],
                )
                : null,
        floatingActionButton: widget.floatingActionButton,
      ),
    );
  }

  // TODO tang kich thuoc nut back
  PreferredSizeWidget appBarWidget() {
    return AppBar(
      backgroundColor: widget.appbarColor ?? AppColors.white,
      toolbarHeight: 55,
      actionsPadding: AppPad.h16,
      elevation: 0,
      leading: Container(
        margin: AppPad.l16,
        child: CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.lightGray,
          child:
              widget.leadingWidget ??
              (widget.isShowDrawer
                  ? IconButton(
                    icon: SvgPicture.asset(
                      IconPath.iconMenu,
                      width: 20,
                      height: 20,
                    ),
                    iconSize: 10,
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  )
                  : IconButton(
                    icon: Icon(Icons.arrow_back, color: AppColors.divider),
                    onPressed: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                  )),
        ),
      ),
      title:
          widget.titleWidget ??
          (widget.title != null
              ? Text(widget.title!, style: AppTextStyles.textHeader3)
              : null),
      centerTitle: true,
      actions:
          widget.actionsWidget
              ?.map(
                (e) => Padding(
                  padding: AppPad.a8,
                  child: CircleAvatar(
                    backgroundColor: AppColors.lightGray,
                    child: e,
                  ),
                ),
              )
              .toList(),
    );
  }
}
