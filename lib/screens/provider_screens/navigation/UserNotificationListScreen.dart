import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/colorConstant/color_constant.dart';
import 'UserNotificationProvider.dart';

class UserNotificationListScreen extends StatefulWidget {
  @override
  _UserNotificationListScreenState createState() =>
      _UserNotificationListScreenState();
}

class _UserNotificationListScreenState
    extends State<UserNotificationListScreen> {
  String? _userToken;

  @override
  void initState() {
    super.initState();
    _initializeTokenAndFetch();
  }

  Future<void> _initializeTokenAndFetch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userToken = prefs.getString('auth_token');

      print(_userToken);
      if (_userToken != null && _userToken!.isNotEmpty) {
        Provider.of<UserNotificationProvider>(
          context,
          listen: false,
        ).fetchNotifications(_userToken!);
      } else {
        if (mounted) {
          _showErrorSnackBar('No authentication token found');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error initializing app');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _markNotificationAsRead(int notificationId) async {
    if (_userToken != null) {
      final success = await Provider.of<UserNotificationProvider>(
        context,
        listen: false,
      ).markAsRead(_userToken!, notificationId);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification marked as read'),
            backgroundColor: ColorConstant.moyoGreen,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as read'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    if (_userToken != null) {
      final success = await Provider.of<UserNotificationProvider>(
        context,
        listen: false,
      ).markAllAsRead(_userToken!);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: ColorConstant.moyoGreen,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark all as read'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: ColorConstant.scaffoldGray,
          appBar: AppBar(
            title: Text(
              'Notifications',
              style: TextStyle(
                color: ColorConstant.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: ColorConstant.moyoOrange,
            elevation: 0,
            iconTheme: IconThemeData(color: ColorConstant.white),
            actions: [
              Consumer<UserNotificationProvider>(
                builder: (context, provider, child) {
                  if (provider.hasUnreadNotifications) {
                    return Padding(
                      padding: EdgeInsets.only(right: 16.sp),
                      child: TextButton.icon(
                        onPressed: _markAllAsRead,
                        icon: Icon(
                          Icons.mark_chat_read,
                          color: ColorConstant.white,
                          size: 20.sp,
                        ),
                        label: Text(
                          '${provider.unreadCount}',
                          style: TextStyle(
                            color: ColorConstant.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ],
          ),
          body: Consumer<UserNotificationProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    color: ColorConstant.moyoOrange,
                    strokeWidth: 3.sp,
                  ),
                );
              }

              if (provider.error != null && provider.error!.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16.sp),
                      Text(
                        provider.error!,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: ColorConstant.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20.sp),
                      ElevatedButton(
                        onPressed: _initializeTokenAndFetch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstant.moyoOrange,
                          padding: EdgeInsets.symmetric(
                            horizontal: 32.sp,
                            vertical: 12.sp,
                          ),
                        ),
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            color: ColorConstant.white,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (provider.notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: 64.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16.sp),
                      Text(
                        'No notifications found',
                        style: TextStyle(
                          fontSize: 18.sp,
                          color: ColorConstant.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8.sp),
                      Text(
                        'Check back later for new updates',
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(12.sp),
                itemCount: provider.notifications.length,
                itemBuilder: (context, index) {
                  final notification = provider.notifications[index];
                  final isRead = notification['is_read'] ?? false;

                  return GestureDetector(
                    onTap: () => _markNotificationAsRead(notification['id']),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 12.sp),
                      decoration: BoxDecoration(
                        color: isRead
                            ? ColorConstant.white
                            : ColorConstant.moyoOrangeFade,
                        borderRadius: BorderRadius.circular(12.sp),
                        border: isRead
                            ? null
                            : Border.all(
                                color: ColorConstant.moyoOrange.withOpacity(
                                  0.3,
                                ),
                                width: 1,
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8.sp,
                            offset: Offset(0, 2.sp),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16.sp),
                        leading: Container(
                          width: 48.sp,
                          height: 48.sp,
                          decoration: BoxDecoration(
                            color: isRead
                                ? ColorConstant.moyoGreen.withOpacity(0.2)
                                : ColorConstant.moyoOrange.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12.sp),
                          ),
                          child: Icon(
                            Icons.notifications_active,
                            color: isRead
                                ? ColorConstant.moyoGreen
                                : ColorConstant.moyoOrange,
                            size: 24.sp,
                          ),
                        ),
                        title: Text(
                          notification['title'] ?? 'No title',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: isRead
                                ? FontWeight.w500
                                : FontWeight.w600,
                            color: isRead
                                ? ColorConstant.onSurface.withOpacity(0.8)
                                : ColorConstant.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4.sp),
                            Text(
                              notification['message'] ?? 'No message',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[700],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: isRead
                            ? Icon(
                                Icons.check_circle,
                                color: ColorConstant.moyoGreen,
                                size: 20.sp,
                              )
                            : Container(
                                width: 12.sp,
                                height: 12.sp,
                                decoration: BoxDecoration(
                                  color: ColorConstant.moyoOrange,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4.sp,
                                      offset: Offset(0, 2.sp),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
