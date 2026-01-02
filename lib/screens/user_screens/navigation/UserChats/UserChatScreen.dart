import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../../../constants/colorConstant/color_constant.dart';
import 'UserChatProvider.dart';

class UserChatScreen extends StatefulWidget {
  final String? userName;
  final String? userImage;
  final String? userId;
  final bool isOnline;
  final String? userPhone;
  final String? serviceId;
  final String? providerId;

  const UserChatScreen({
    super.key,
    this.userName = "Provider Name",
    this.userImage,
    this.userId,
    this.isOnline = false,
    this.userPhone,
    this.serviceId,
    this.providerId,
  });

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isTyping = false;
  bool _chatInitialized = false;
  bool _isSending = false;

  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageController.addListener(_onTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _startPolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopPolling();
    }
  }

  Future<void> _initializeChat() async {
    if (widget.serviceId == null || widget.providerId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Missing service or provider information'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'GO BACK',
              textColor: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        );
      }
      return;
    }

    try {
      final chatProvider = Provider.of<UserChatProvider>(context, listen: false);

      final success = await chatProvider.initiateChat(
        serviceId: widget.serviceId!,
        providerId: widget.providerId!,
      );

      if (success) {
        setState(() {
          _chatInitialized = true;
        });

        _startPolling();

        // ✅ SCROLL TO BOTTOM AFTER LOADING MESSAGES
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom(immediate: true);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chat loaded successfully'),
              backgroundColor: ColorConstant.moyoGreen,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted && chatProvider.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(chatProvider.error!),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'RETRY',
                textColor: Colors.white,
                onPressed: () => _initializeChat(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize chat'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _initializeChat(),
            ),
          ),
        );
      }
    }
  }

  void _startPolling() {
    if (_pollingTimer != null && _pollingTimer!.isActive) {
      return;
    }

    final chatProvider = Provider.of<UserChatProvider>(context, listen: false);
    chatProvider.setScreenActive(true);

    _pollingTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (!mounted || !_chatInitialized) {
        timer.cancel();
        return;
      }

      if (chatProvider.chatId != null) {
        await chatProvider.fetchChatHistory(
          chatId: chatProvider.chatId!,
          silent: true,
        );
      }
    });
  }

  void _stopPolling() {
    if (_pollingTimer != null) {
      _pollingTimer!.cancel();
      _pollingTimer = null;
    }

    if (mounted) {
      final chatProvider = Provider.of<UserChatProvider>(context, listen: false);
      chatProvider.setScreenActive(false);
    }
  }

  void _onTextChanged() {
    setState(() {
      _isTyping = _messageController.text.trim().isNotEmpty;
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    if (!_chatInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please wait for chat to initialize'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final messageText = _messageController.text.trim();
    final chatProvider = Provider.of<UserChatProvider>(context, listen: false);

    setState(() {
      _messageController.clear();
      _isSending = true;
      _isTyping = false;
    });

    try {
      final success = await chatProvider.sendMessage(message: messageText);

      setState(() {
        _isSending = false;
      });

      if (success) {
        // ✅ SCROLL TO BOTTOM AFTER SENDING
        _scrollToBottom();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(chatProvider.error ?? 'Failed to send message'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
              action: SnackBarAction(
                label: 'RETRY',
                textColor: Colors.white,
                onPressed: () {
                  _messageController.text = messageText;
                  _sendMessage();
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isSending = false;
      });
    }
  }

  // ✅ SMOOTH SCROLL TO BOTTOM
  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: immediate ? 100 : 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
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
      body: Consumer<UserChatProvider>(
        builder: (context, chatProvider, child) {
          // ✅ AUTO SCROLL WHEN NEW MESSAGE ARRIVES
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (chatProvider.messages.isNotEmpty && mounted) {
              _scrollToBottom();
            }
          });

          if (chatProvider.isLoading && !_chatInitialized) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: ColorConstant.moyoOrange),
                  SizedBox(height: 16.h),
                  Text(
                    'Loading chat...',
                    style: GoogleFonts.roboto(
                      fontSize: 14.sp,
                      color: Color(0xFF7A7A7A),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: chatProvider.messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessagesList(chatProvider),
              ),
              _buildMessageInput(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64.sp,
            color: Color(0xFFE0E0E0),
          ),
          SizedBox(height: 16.h),
          Text(
            'No messages yet',
            style: GoogleFonts.roboto(
              fontSize: 16.sp,
              color: Color(0xFF7A7A7A),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Start the conversation!',
            style: GoogleFonts.roboto(
              fontSize: 14.sp,
              color: Color(0xFFB0B0B0),
            ),
          ),
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

  // ✅ WHATSAPP STYLE LIST - OLDEST TO NEWEST (TOP TO BOTTOM)
  Widget _buildMessagesList(UserChatProvider chatProvider) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: chatProvider.messages.length,
      itemBuilder: (context, index) {
        final message = chatProvider.messages[index];
        final showDate = index == 0 ||
            !_isSameDay(
              message.createdAt,
              chatProvider.messages[index - 1].createdAt,
            );

        final isSentByMe = message.senderType.toLowerCase() == 'user';

        return Column(
          children: [
            if (showDate) _buildDateDivider(message.createdAt),
            _buildMessageBubble(message, isSentByMe),
            SizedBox(height: 4.h),
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

  Widget _buildMessageBubble(ChatMessage message, bool isSentByMe) {
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isSentByMe) ...[
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorConstant.moyoOrangeFade,
                ),
                child: Icon(
                  Icons.person,
                  size: 18.sp,
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
                  color: isSentByMe ? ColorConstant.moyoOrange : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18.r),
                    topRight: Radius.circular(18.r),
                    bottomLeft: Radius.circular(isSentByMe ? 18.r : 6.r),
                    bottomRight: Radius.circular(isSentByMe ? 6.r : 18.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.message,
                      style: GoogleFonts.roboto(
                        fontSize: 14.sp,
                        color: isSentByMe ? Colors.white : Color(0xFF1D1B20),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.createdAt),
                          style: GoogleFonts.roboto(
                            fontSize: 11.sp,
                            color: isSentByMe
                                ? Colors.white.withOpacity(0.85)
                                : Color(0xFF7A7A7A),
                          ),
                        ),
                        if (isSentByMe) ...[
                          SizedBox(width: 6.w),
                          Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            size: 14.sp,
                            color: message.isRead
                                ? Colors.white.withOpacity(0.9)
                                : Colors.white.withOpacity(0.7),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isSentByMe) SizedBox(width: 8.w),
          ],
        ),
      ),
    );
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
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(25.r),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  enabled: _chatInitialized && !_isSending,
                  style: GoogleFonts.roboto(
                    fontSize: 14.sp,
                    color: Color(0xFF1D1B20),
                  ),
                  decoration: InputDecoration(
                    hintText: _chatInitialized
                        ? 'Type a message...'
                        : 'Loading chat...',
                    hintStyle: GoogleFonts.roboto(
                      fontSize: 14.sp,
                      color: Color(0xFF9E9E9E),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 14.h,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            GestureDetector(
              onTap: (_isTyping && _chatInitialized && !_isSending)
                  ? _sendMessage
                  : null,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: (_isTyping && _chatInitialized && !_isSending)
                      ? ColorConstant.moyoOrange
                      : Colors.grey.shade300,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: _isSending
                    ? Padding(
                  padding: EdgeInsets.all(12.w),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
                    : Icon(
                  Icons.send,
                  color: (_isTyping && _chatInitialized)
                      ? Colors.white
                      : Colors.grey.shade500,
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