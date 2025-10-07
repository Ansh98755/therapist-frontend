part of 'app_routing.dart';

enum AppRouteEnum {
  splashScreen(AppRouteName.splashScreen, "/${AppRouteName.splashScreen}"),
  authScreen(AppRouteName.authScreen, "/${AppRouteName.authScreen}"),
  homeScreen(AppRouteName.homeScreen, "/${AppRouteName.homeScreen}"),
  communityScreen(
      AppRouteName.communityScreen, "/${AppRouteName.communityScreen}"),
  communityReplyScreen(AppRouteName.communityReplyScreen,
      "/${AppRouteName.communityReplyScreen}"),  newPostScreen(AppRouteName.newPostScreen, "/${AppRouteName.newPostScreen}"),
  postDetailsScreen(AppRouteName.postDetailsScreen, "/${AppRouteName.postDetailsScreen}"),
  profileScreen(AppRouteName.profileScreen, "/${AppRouteName.profileScreen}"),
  analyticsScreen(AppRouteName.analyticsScreen, "/${AppRouteName.analyticsScreen}"),
  loginScreen(AppRouteName.loginScreen, "/${AppRouteName.loginScreen}"),
  forgotPasswordScreen(AppRouteName.forgotPasswordScreen, "/${AppRouteName.forgotPasswordScreen}"),
  myPostScreen(AppRouteName.myPostScreen, "/${AppRouteName.myPostScreen}"),
  notificationScreen(AppRouteName.notificationScreen, "/${AppRouteName.notificationScreen}");

  final String name;
  final String path;
  const AppRouteEnum(this.name, this.path);
}
