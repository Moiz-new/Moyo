import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../constants/colorConstant/color_constant.dart';

class Message {
  final String id;
  final String text;
  final bool isSentByMe;
  final DateTime timestamp;
  final MessageStatus status;
  final String? imageUrl;

  Message({
    required this.id,
    required this.text,
    required this.isSentByMe,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.imageUrl,
  });
}

enum MessageStatus { sending, sent, delivered, read }

class UserChatScreen extends StatefulWidget {
  final String? userName;
  final String? userImage;
  final String? userId;
  final bool isOnline;
  final String? userPhone;

  const UserChatScreen({
    super.key,
    this.userName = "Provider Name",
    this.userImage,
    this.userId,
    this.isOnline = false,
    this.userPhone,
  });

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<Message> messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadDummyMessages();
    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _isTyping = _messageController.text.trim().isNotEmpty;
    });
  }

  void _loadDummyMessages() {
    // Dummy messages for demonstration
    messages = [
      Message(
        id: '1',
        text: 'Hi! I need help with the plumbing service.',
        isSentByMe: true,
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
        status: MessageStatus.read,
      ),
      Message(
        id: '2',
        text:
            'Hello! I can definitely help you with that. What seems to be the issue?',
        isSentByMe: false,
        timestamp: DateTime.now().subtract(Duration(hours: 2, minutes: 58)),
      ),
      Message(
        id: '3',
        text: 'My kitchen sink is leaking and I need it fixed urgently.',
        isSentByMe: true,
        timestamp: DateTime.now().subtract(Duration(hours: 1, minutes: 55)),
        status: MessageStatus.read,
      ),
      Message(
        id: '4',
        text:
            'I understand. I can come over today at 3 PM. Will that work for you?',
        isSentByMe: false,
        timestamp: DateTime.now().subtract(Duration(hours: 1, minutes: 50)),
      ),
      Message(
        id: '5',
        text: 'Yes, that works perfectly! See you then.',
        isSentByMe: true,
        timestamp: DateTime.now().subtract(Duration(hours: 1, minutes: 45)),
        status: MessageStatus.delivered,
      ),
    ];
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: _messageController.text.trim(),
      isSentByMe: true,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    setState(() {
      messages.add(newMessage);
      _messageController.clear();
    });

    // Scroll to bottom
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Simulate message sent status update
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        final index = messages.indexWhere((m) => m.id == newMessage.id);
        if (index != -1) {
          messages[index] = Message(
            id: newMessage.id,
            text: newMessage.text,
            isSentByMe: newMessage.isSentByMe,
            timestamp: newMessage.timestamp,
            status: MessageStatus.sent,
          );
        }
      });
    });
  }




  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.scaffoldGray,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Color(0xFF1D1B20)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorConstant.moyoOrange.withOpacity(0.3),
                    width: 2.w,
                  ),
                ),
                child: ClipOval(
                  child: widget.userImage != null
                      ? CachedNetworkImage(
                          imageUrl: widget.userImage!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: ColorConstant.moyoOrangeFade,
                            child: Icon(
                              Icons.person,
                              color: ColorConstant.moyoOrange,
                              size: 20.sp,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: ColorConstant.moyoOrangeFade,
                            child: Icon(
                              Icons.person,
                              color: ColorConstant.moyoOrange,
                              size: 20.sp,
                            ),
                          ),
                        )
                      : Container(
                          color: ColorConstant.moyoOrangeFade,
                          child: Icon(
                            Icons.person,
                            color: ColorConstant.moyoOrange,
                            size: 20.sp,
                          ),
                        ),
                ),
              ),
              if (widget.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: ColorConstant.moyoGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.w),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName ?? "Provider Name",
                  style: GoogleFonts.roboto(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1B20),
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final showDate =
            index == 0 ||
            !_isSameDay(message.timestamp, messages[index - 1].timestamp);

        return Column(
          children: [
            if (showDate) _buildDateDivider(message.timestamp),
            _buildMessageBubble(message),
            SizedBox(height: 8.h),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildDateDivider(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    String dateText;

    if (difference == 0) {
      dateText = 'Today';
    } else if (difference == 1) {
      dateText = 'Yesterday';
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        children: [
          Expanded(child: Divider(color: Color(0xFFE6E6E6))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              dateText,
              style: GoogleFonts.roboto(
                fontSize: 12.sp,
                color: Color(0xFF7A7A7A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Color(0xFFE6E6E6))),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Align(
      alignment: message.isSentByMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isSentByMe) ...[
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorConstant.moyoOrangeFade,
              ),
              child: Icon(
                Icons.person,
                size: 14.sp,
                color: ColorConstant.moyoOrange,
              ),
            ),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: 280.w),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: message.isSentByMe
                    ? ColorConstant.moyoOrange
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                  bottomLeft: Radius.circular(message.isSentByMe ? 16.r : 4.r),
                  bottomRight: Radius.circular(message.isSentByMe ? 4.r : 16.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: GoogleFonts.roboto(
                      fontSize: 14.sp,
                      color: message.isSentByMe
                          ? Colors.white
                          : Color(0xFF1D1B20),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: GoogleFonts.roboto(
                          fontSize: 11.sp,
                          color: message.isSentByMe
                              ? Colors.white.withOpacity(0.8)
                              : Color(0xFF7A7A7A),
                        ),
                      ),
                      if (message.isSentByMe) ...[
                        SizedBox(width: 4.w),
                        _buildMessageStatusIcon(message.status),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (message.isSentByMe) SizedBox(width: 8.w),
        ],
      ),
    );
  }

  Widget _buildMessageStatusIcon(MessageStatus status) {
    IconData iconData;
    Color color = Colors.white.withOpacity(0.8);

    switch (status) {
      case MessageStatus.sending:
        iconData = Icons.access_time;
        break;
      case MessageStatus.sent:
        iconData = Icons.check;
        break;
      case MessageStatus.delivered:
        iconData = Icons.done_all;
        break;
      case MessageStatus.read:
        iconData = Icons.done_all;
        color = Colors.white;
        break;
    }

    return Icon(iconData, size: 14.sp, color: color);
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(25.r),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  style: GoogleFonts.roboto(
                    fontSize: 14.sp,
                    color: Color(0xFF1D1B20),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: GoogleFonts.roboto(
                      fontSize: 14.sp,
                      color: Color(0xFF7A7A7A),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 10.h,
                    ),

                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            InkWell(
              onTap: _isTyping ? _sendMessage : null,
              borderRadius: BorderRadius.circular(25.r),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: _isTyping
                      ? ColorConstant.moyoOrange
                      : ColorConstant.moyoOrangeFade,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send,
                  color: _isTyping ? Colors.white : ColorConstant.moyoOrange,
                  size: 20.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
