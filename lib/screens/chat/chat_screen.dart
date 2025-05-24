import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quickrepair/services/supabase_service.dart';
import 'package:quickrepair/models/message_model.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  User? _currentUser;
  String? _chatId;
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  String? _adminName;
  String? _adminAvatarUrl;
  bool _isTyping = false;
  bool _isSending = false;
  FocusNode _focusNode = FocusNode();
  bool _showAttachmentOptions = false;
  late AnimationController _typingAnimationController;

  @override
  void initState() {
    super.initState();
    _currentUser = SupabaseService.currentUser;
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    // Using the real admin ID from the Supabase database
    const adminId = '37eef3ed-9fb4-4ae8-b4e8-9afb73340922'; // rasyaravy@gmail.com

    try {
      // Fetch admin profile info
      final adminProfile = await supabase
          .from('profiles')
          .select('email, full_name, avatar_url')
          .eq('id', adminId)
          .single();
      
      if (adminProfile != null) {
        _adminName = adminProfile['full_name'] ?? adminProfile['email']?.toString().split('@').first;
        _adminAvatarUrl = adminProfile['avatar_url'];
      }

      // Try to find an existing chat with admin
      final response = await supabase
          .from('admin_chats')
          .select('id')
          .or('user_id.eq.${_currentUser!.id},admin_id.eq.${_currentUser!.id}')
          .or('user_id.eq.$adminId,admin_id.eq.$adminId')
          .limit(1)
          .maybeSingle();

      if (response != null && response['id'] != null) {
        _chatId = response['id'] as String;
      } else {
        // Create a new chat
        final newChatResponse = await supabase.from('admin_chats').insert({
          'user_id': _currentUser!.id,
          'admin_id': adminId,
        }).select('id').single();
        _chatId = newChatResponse['id'] as String;
      }

      if (_chatId != null) {
        await _fetchMessages();
        _setupMessageSubscription();
        
        // Scroll to bottom after messages are loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading chat: ${e.toString()}'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMessages() async {
    if (_chatId == null || _currentUser == null) return;

    final response = await supabase
        .from('admin_chat_messages')
        .select()
        .eq('chat_id', _chatId!)
        .order('created_at', ascending: true);

    setState(() {
      _messages = response
          .map((item) => Message.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _chatId == null || _currentUser == null || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
      _showAttachmentOptions = false;
    });

    try {
      // Determine receiver_id
      const adminId = '37eef3ed-9fb4-4ae8-b4e8-9afb73340922';
      final receiverId = _currentUser!.id == adminId ? 
          (await supabase.from('admin_chats').select('user_id').eq('id', _chatId!).single())['user_id'] : 
          adminId;

      // Add optimistic message first
      final temporaryId = DateTime.now().millisecondsSinceEpoch.toString();
      final optimisticMessage = Message(
        id: temporaryId,
        chatId: _chatId!,
        senderId: _currentUser!.id,
        receiverId: receiverId,
        messageContent: messageText,
        createdAt: DateTime.now(),
      );
      
      setState(() {
        _messages.add(optimisticMessage);
      });
      
      _messageController.clear();
      _scrollToBottom();

      // Then send to server
      await supabase.from('admin_chat_messages').insert({
        'chat_id': _chatId!,
        'sender_id': _currentUser!.id,
        'receiver_id': receiverId,
        'message_content': messageText,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: ${e.toString()}'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _setupMessageSubscription() {
    if (_chatId == null) return;

    supabase
        .channel('public:admin_chat_messages:chat_id=eq.$_chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'admin_chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: _chatId!,
          ),
          callback: (payload) {
            final newMessage = Message.fromJson(payload.newRecord);
            // Avoid adding duplicate messages (for example our own optimistic ones)
            if (!_messages.any((msg) => msg.id == newMessage.id || 
                (msg.messageContent == newMessage.messageContent && 
                msg.senderId == newMessage.senderId &&
                DateTime.now().difference(msg.createdAt).inSeconds < 5))) {
              setState(() {
                _messages.add(newMessage);
                _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                
                // Show typing indicator briefly when receiving message
                if (newMessage.senderId != _currentUser!.id) {
                  _isTyping = false;
                }
                
                // Scroll to bottom when new message arrives
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });
              });
            }
          },
        )
        .subscribe();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients && _messages.isNotEmpty) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleAttachmentOptions() {
    setState(() {
      _showAttachmentOptions = !_showAttachmentOptions;
    });
  }

  void _handleAttachmentOption(String type) {
    // Handle different attachment types
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type attachment coming soon!'),
        duration: const Duration(seconds: 1),
      ),
    );
    setState(() {
      _showAttachmentOptions = false;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingAnimationController.dispose();
    if (_chatId != null) {
      supabase.removeChannel(supabase.channel('public:admin_chat_messages:chat_id=eq.$_chatId'));
    }
    super.dispose();
  }

  String _formatMessageTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  String _formatMessageDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMMM d').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.lock, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                "Please log in to access chat",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                icon: const Icon(LucideIcons.logIn),
                label: const Text("Log In"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
        ),
      );
    }
    
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Loading chat...",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Chat header
            _buildChatHeader(),
            
            // Messages list
            Expanded(
              child: _buildMessagesList(),
            ),
            
            // Attachment options
            if (_showAttachmentOptions) _buildAttachmentOptions(),
            
            // Message input area
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          // Back button (for mobile navigation)
          IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: Colors.grey.shade800, size: 22),
            onPressed: () {
              Navigator.pop(context);
            },
            splashRadius: 20,
          ),
          // Admin avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.orange.shade200,
                backgroundImage: _adminAvatarUrl != null ? NetworkImage(_adminAvatarUrl!) : null,
                child: _adminAvatarUrl == null ? Icon(LucideIcons.user, color: Colors.orange.shade700, size: 20) : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green.shade500,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Admin info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _adminName ?? 'Admin',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'QuickRepair Support',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Actions
          IconButton(
            icon: Icon(LucideIcons.phoneCall, color: Colors.grey.shade700, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Call feature coming soon!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAttachmentButton(
            icon: LucideIcons.image,
            label: 'Photo',
            color: Colors.blue.shade600,
            onTap: () => _handleAttachmentOption('Photo'),
          ),
          _buildAttachmentButton(
            icon: LucideIcons.camera,
            label: 'Camera',
            color: Colors.green.shade600,
            onTap: () => _handleAttachmentOption('Camera'),
          ),
          _buildAttachmentButton(
            icon: LucideIcons.fileText,
            label: 'Document',
            color: Colors.orange.shade600,
            onTap: () => _handleAttachmentOption('Document'),
          ),
          _buildAttachmentButton(
            icon: LucideIcons.mapPin,
            label: 'Location',
            color: Colors.red.shade600,
            onTap: () => _handleAttachmentOption('Location'),
          ),
        ],
      ).animate().slideY(begin: 1, end: 0, duration: 200.ms),
    );
  }
  
  Widget _buildAttachmentButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.messageCircle,
                size: 64,
                color: Colors.orange.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Send your first message to get help from our support team',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      );
    }

    // Group messages by date
    final Map<String, List<Message>> groupedMessages = {};
    for (final message in _messages) {
      final dateStr = _formatMessageDate(message.createdAt);
      if (!groupedMessages.containsKey(dateStr)) {
        groupedMessages[dateStr] = [];
      }
      groupedMessages[dateStr]!.add(message);
    }

    final List<String> dateKeys = groupedMessages.keys.toList();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: dateKeys.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // Show typing indicator at the end if needed
        if (_isTyping && index == dateKeys.length) {
          return _buildTypingIndicator();
        }
        
        final dateStr = dateKeys[index];
        final messagesForDate = groupedMessages[dateStr]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Date header
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12.0),
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                dateStr,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            // Messages for this date
            ...messagesForDate.asMap().entries.map((entry) {
              final index = entry.key;
              final message = entry.value;
              final isMe = message.senderId == _currentUser!.id;
              final showTime = index == 0 || 
                  messagesForDate[index - 1].senderId != message.senderId ||
                  message.createdAt.difference(messagesForDate[index - 1].createdAt).inMinutes > 5;
              final isLastInGroup = index == messagesForDate.length - 1 || 
                  messagesForDate[index + 1].senderId != message.senderId;
                  
              // Determine message bubble shape based on its position in the group
              BorderRadius borderRadius;
              if (isMe) {
                borderRadius = BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: index == 0 || messagesForDate[index - 1].senderId != message.senderId 
                      ? const Radius.circular(16) : const Radius.circular(5),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: isLastInGroup 
                      ? const Radius.circular(16) : const Radius.circular(5),
                );
              } else {
                borderRadius = BorderRadius.only(
                  topLeft: index == 0 || messagesForDate[index - 1].senderId != message.senderId 
                      ? const Radius.circular(16) : const Radius.circular(5),
                  topRight: const Radius.circular(16),
                  bottomLeft: isLastInGroup 
                      ? const Radius.circular(16) : const Radius.circular(5),
                  bottomRight: const Radius.circular(16),
                );
              }
              
              return Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      margin: EdgeInsets.only(
                        top: index > 0 && messagesForDate[index - 1].senderId == message.senderId ? 2 : 8,
                        bottom: isLastInGroup ? 8 : 2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.orange.shade500 : Colors.grey.shade200,
                        borderRadius: borderRadius,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.messageContent,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                          if (showTime) const SizedBox(height: 4),
                          if (showTime)
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatMessageTime(message.createdAt),
                                    style: TextStyle(
                                      color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey.shade600,
                                      fontSize: 10,
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      LucideIcons.check, 
                                      size: 10, 
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms, delay: 50.ms * index.toDouble());
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(delay: 0),
            _buildDot(delay: 0.2),
            _buildDot(delay: 0.4),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildDot({required double delay}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      height: 8,
      width: 8,
      decoration: BoxDecoration(
        color: Colors.grey.shade600,
        shape: BoxShape.circle,
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).fadeIn(
      delay: Duration(milliseconds: (delay * 1000).toInt()),
      duration: 300.ms,
    ).fadeOut(
      delay: 700.ms,
      duration: 300.ms,
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            onPressed: _toggleAttachmentOptions,
            icon: Icon(
              LucideIcons.paperclip, 
              color: _showAttachmentOptions 
                  ? Colors.orange.shade600 
                  : Colors.grey.shade600,
              size: 22,
            ),
            splashRadius: 20,
          ),
          // Text field
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                suffixIcon: IconButton(
                  icon: Icon(LucideIcons.smile, color: Colors.grey.shade600, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Emoji picker coming soon!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  splashRadius: 20,
                ),
              ),
              onTap: () {
                if (_showAttachmentOptions) {
                  setState(() {
                    _showAttachmentOptions = false;
                  });
                }
              },
              onSubmitted: (_) => _sendMessage(),
              onChanged: (text) {
                if (text.isNotEmpty && !_focusNode.hasFocus) {
                  _focusNode.requestFocus();
                }
              },
            ),
          ),
          const SizedBox(width: 8.0),
          // Send button
          InkWell(
            onTap: _sendMessage,
            borderRadius: BorderRadius.circular(50),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _messageController.text.trim().isEmpty ? Colors.grey.shade300 : Colors.orange.shade500,
                shape: BoxShape.circle,
                boxShadow: [
                  if (_messageController.text.trim().isNotEmpty)
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: _isSending 
                ? SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    _messageController.text.trim().isEmpty ? LucideIcons.mic : LucideIcons.send,
                    color: Colors.white,
                    size: 20,
                  ),
            ),
          ),
        ],
      ),
    );
  }
} 