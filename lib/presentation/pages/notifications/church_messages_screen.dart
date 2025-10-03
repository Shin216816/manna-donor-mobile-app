import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/data/repository/church_message_provider.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/data/models/church_message.dart';
import 'package:manna_donate_app/presentation/widgets/app_header.dart';
import 'package:manna_donate_app/presentation/widgets/app_drawer.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';


class ChurchMessagesScreen extends StatefulWidget {
  const ChurchMessagesScreen({super.key});

  @override
  State<ChurchMessagesScreen> createState() => _ChurchMessagesScreenState();
}

class _ChurchMessagesScreenState extends State<ChurchMessagesScreen> {
  String _selectedFilter = 'all'; // 'all', 'unread', 'read'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final provider = Provider.of<ChurchMessageProvider>(
        context,
        listen: false,
      );
      // Use cache-first approach with loading spinners
      await provider.fetchMessagesWithLoading();
      await provider.fetchUnreadCountWithLoading();
    } catch (e) {
      // Handle error silently, will show in UI if needed
    }
  }

  List<ChurchMessage> _getFilteredMessages(ChurchMessageProvider provider) {
    switch (_selectedFilter) {
      case 'unread':
        return provider.unreadMessages;
      case 'read':
        return provider.readMessages;
      default:
        return provider.messages;
    }
  }

  Future<void> _markAllAsRead(ChurchMessageProvider provider) async {
    try {
      await provider.markAllMessagesAsRead();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All messages marked as read'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark messages as read'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Remove extendBodyBehindAppBar to fix spacing issues
      appBar: AppHeader(
        title: 'Church Messages',
        actions: [
          // Refresh button
          Consumer<ChurchMessageProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: provider.loading
                    ? SizedBox(
                        width: 20.sp,
                        height: 20.sp,
                        child: LoadingWave(
                          color: Colors.white,
                          size: 20,
                          isDark: isDark,
                        ),
                      )
                    : Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                onPressed: provider.loading
                    ? null
                    : () async {
                        // Show loading state immediately
                        provider.setLoading(true);
                        try {
                          await provider.refreshMessages();
                          await provider.refreshUnreadCount();
                        } finally {
                          // Ensure loading state is cleared
                          if (mounted) {
                            provider.setLoading(false);
                          }
                        }
                      },
                tooltip: 'Refresh messages',
              );
            },
          ),
          // Mark all as read button
          Consumer<ChurchMessageProvider>(
            builder: (context, provider, _) {
              final hasUnreadMessages = provider.unreadMessages.isNotEmpty;
              if (hasUnreadMessages) {
                return IconButton(
                  icon: Icon(
                    Icons.mark_email_read,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                  onPressed: () => _markAllAsRead(provider),
                  tooltip: 'Mark all as read',
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      drawer: AppDrawer(),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Consumer<ChurchMessageProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.messages.isEmpty) {
            return Center(
              child: LoadingWave(
                message: 'Loading messages...',
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                size: 50,
                isDark: isDark,
              ),
            );
          }

          if (provider.error != null && provider.messages.isEmpty) {
            return _buildErrorState(provider, isDark);
          }

          if (provider.messages.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return Column(
            children: [
              // Add proper top spacing after removing extendBodyBehindAppBar
              SizedBox(height: 20.sp),
              
              // Enhanced filter tabs with better spacing
              _buildEnhancedFilterTabs(isDark, provider),

              SizedBox(height: 16.sp),

              // Messages list with enhanced animations
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    // Fetch fresh data from backend (bypass cache)
                    await provider.refreshMessages();
                    await provider.refreshUnreadCount();
                  },
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  child: AnimationLimiter(
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        20.sp, // Better horizontal padding
                        0,     // No top padding since we added it above
                        20.sp, // Better horizontal padding
                        20.sp, // Bottom padding for scroll area
                      ),
                      itemCount: _getFilteredMessages(provider).length,
                      itemBuilder: (context, index) {
                        final message = _getFilteredMessages(provider)[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 600),
                          child: SlideAnimation(
                            verticalOffset: 30.0,
                            child: FadeInAnimation(
                              child: ScaleAnimation(
                                scale: 0.95,
                                child: _buildEnhancedMessageCard(
                                  message,
                                  provider,
                                  isDark,
                                  index,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEnhancedFilterTabs(bool isDark, ChurchMessageProvider provider) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.sp),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1F2937).withValues(alpha: 0.8),
                  const Color(0xFF111827).withValues(alpha: 0.95),
                ]
              : [
                  Colors.white.withValues(alpha: 0.95),
                  const Color(0xFFF9FAFB).withValues(alpha: 0.8),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.sp),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.9),
            blurRadius: 2,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(6.sp),
        child: Row(
          children: [
            _buildEnhancedFilterTab(
              'all', 
              'All', 
              provider.messages.length, 
              Icons.list_alt,
              isDark,
            ),
            _buildEnhancedFilterTab(
              'unread',
              'Unread',
              provider.unreadMessages.length,
              Icons.mark_email_unread,
              isDark,
            ),
            _buildEnhancedFilterTab(
              'read', 
              'Read', 
              provider.readMessages.length, 
              Icons.mark_email_read,
              isDark,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3, end: 0);
  }

  Widget _buildFilterTabs(bool isDark, ChurchMessageProvider provider) {
    // Keep the old method for backward compatibility
    return _buildEnhancedFilterTabs(isDark, provider);
  }

  Widget _buildEnhancedFilterTab(
    String filter, 
    String label, 
    int count, 
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _selectedFilter == filter;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(vertical: 12.sp, horizontal: 12.sp),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: isDark
                        ? [AppColors.darkPrimary, AppColors.darkPrimary.withValues(alpha: 0.8)]
                        : [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(14.sp),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (isDark ? AppColors.darkPrimary : AppColors.primary)
                          .withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(8.sp),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : (isDark ? AppColors.darkPrimary : AppColors.primary)
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.sp),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.darkPrimary : AppColors.primary),
                  size: 18.sp,
                ),
              ),
              SizedBox(height: 8.sp),
              Text(
                label,
                style: AppTextStyles.bodyMedium(
                  isDark: isDark,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.8)
                            : Colors.black.withValues(alpha: 0.7)),
                ).copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 4.sp),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 2.sp),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : (isDark ? AppColors.darkPrimary : AppColors.primary)
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.sp),
                ),
                child: Text(
                  count.toString(),
                  style: AppTextStyles.bodySmall(
                    isDark: isDark,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.9)
                        : (isDark ? AppColors.darkPrimary : AppColors.primary),
                  ).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(
      begin: const Offset(0.95, 0.95),
      end: const Offset(1.0, 1.0),
      duration: 200.ms,
    );
  }

  Widget _buildFilterTab(String filter, String label, int count, bool isDark) {
    // Keep the old method for backward compatibility
    return _buildEnhancedFilterTab(filter, label, count, Icons.filter_alt, isDark);
  }

  Widget _buildEnhancedMessageCard(
    ChurchMessage message,
    ChurchMessageProvider provider,
    bool isDark,
    int index,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.sp),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showMessageDetails(message, provider, isDark),
          borderRadius: BorderRadius.circular(20.sp),
          splashColor: message.messageTypeColor.withValues(alpha: 0.1),
          highlightColor: message.messageTypeColor.withValues(alpha: 0.05),
          child: Container(
            padding: EdgeInsets.all(16.sp),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF1F2937).withValues(alpha: 0.8),
                        const Color(0xFF111827).withValues(alpha: 0.95),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.95),
                        const Color(0xFFF9FAFB).withValues(alpha: 0.8),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.sp),
              border: Border.all(
                color: message.isRead
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06))
                    : message.messageTypeColor.withValues(alpha: 0.4),
                width: message.isRead ? 1 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : message.messageTypeColor.withValues(alpha: 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.white.withValues(alpha: 0.8),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced church avatar with better styling
                Hero(
                  tag: 'message_${message.id}',
                  child: Container(
                    width: 48.sp,
                    height: 48.sp,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          message.messageTypeColor,
                          message.messageTypeColor.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18.sp),
                      boxShadow: [
                        BoxShadow(
                          color: message.messageTypeColor.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: EdgeInsets.all(2.sp),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16.sp),
                      ),
                      child: Icon(
                        message.messageTypeIcon,
                        color: Colors.white,
                        size: 22.sp,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 16.sp),

                // Enhanced message content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Enhanced header row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              message.churchName,
                              style: AppTextStyles.bodyMedium(
                                isDark: isDark,
                                weight: message.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w700,
                              ).copyWith(fontSize: 15.sp),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 12.sp),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.sp,
                              vertical: 4.sp,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(10.sp),
                            ),
                            child: Text(
                              message.formattedDate,
                              style: AppTextStyles.bodySmall(
                                isDark: isDark,
                                color: (isDark
                                        ? Colors.white.withValues(alpha: 0.7)
                                        : Colors.black.withValues(alpha: 0.6)),
                              ).copyWith(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 8.sp),

                      // Enhanced subject with better typography
                      Text(
                        message.title,
                        style: AppTextStyles.bodyMedium(
                          isDark: isDark,
                          weight: message.isRead
                              ? FontWeight.w600
                              : FontWeight.w700,
                        ).copyWith(
                          fontSize: 16.sp,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.black.withValues(alpha: 0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 6.sp),

                      // Enhanced message preview
                      Text(
                        message.message,
                        style: AppTextStyles.bodySmall(
                          isDark: isDark,
                          color: (isDark
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : Colors.black.withValues(alpha: 0.6))
                        ).copyWith(
                          fontSize: 13.sp,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 12.sp),

                      // Enhanced message type badge and status row
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.sp,
                              vertical: 6.sp,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  message.messageTypeColor.withValues(alpha: 0.15),
                                  message.messageTypeColor.withValues(alpha: 0.08),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12.sp),
                              border: Border.all(
                                color: message.messageTypeColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6.sp,
                                  height: 6.sp,
                                  decoration: BoxDecoration(
                                    color: message.messageTypeColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 6.sp),
                                Text(
                                  message.messageTypeDisplay,
                                  style: AppTextStyles.getCaption(
                                    isDark: isDark,
                                    color: message.messageTypeColor,
                                  ).copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.sp,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Spacer(),
                          // Enhanced unread indicator
                          if (!message.isRead)
                            Container(
                              padding: EdgeInsets.all(6.sp),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    message.messageTypeColor,
                                    message.messageTypeColor.withValues(alpha: 0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: message.messageTypeColor.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Container(
                                width: 8.sp,
                                height: 8.sp,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGmailStyleMessageCard(
    ChurchMessage message,
    ChurchMessageProvider provider,
    bool isDark,
    int index,
  ) {
    // Keep the old method for backward compatibility
    return _buildEnhancedMessageCard(message, provider, isDark, index);
  }

  void _showMessageDetails(
    ChurchMessage message,
    ChurchMessageProvider provider,
    bool isDark,
  ) {
    // Mark as read if unread
    if (!message.isRead) {
      provider.markMessageAsRead(message.id.toString() as int);
    }

    showDialog(
      context: context,
      builder: (context) => _buildMessageDetailsDialog(message, provider, isDark),
    );
  }

  Widget _buildMessageDetailsDialog(
    ChurchMessage message,
    ChurchMessageProvider provider,
    bool isDark,
  ) {
    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.sp),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with better spacing
            Container(
              padding: EdgeInsets.all(20.sp),
              decoration: BoxDecoration(
                color: isDark 
                    ? AppColors.darkPrimary.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.sp),
                  topRight: Radius.circular(20.sp),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56.sp,
                    height: 56.sp,
                    decoration: BoxDecoration(
                      color: message.messageTypeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(28.sp),
                      border: Border.all(
                        color: message.messageTypeColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      message.messageTypeIcon,
                      color: message.messageTypeColor,
                      size: 28.sp,
                    ),
                  ),

                  SizedBox(width: 16.sp),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.churchName,
                          style: AppTextStyles.titleMedium(
                            isDark: isDark,
                            weight: FontWeight.bold,
                          ).copyWith(fontSize: 18.sp),
                        ),
                        SizedBox(height: 6.sp),
                        Text(
                          message.formattedDate,
                          style: AppTextStyles.bodySmall(
                            isDark: isDark,
                            color: (isDark
                                    ? AppColors.darkOnSurface
                                    : AppColors.onSurface)
                                .withValues(alpha: 0.7),
                          ).copyWith(fontSize: 13.sp),
                        ),
                      ],
                    ),
                  ),

                  // Message type badge with better styling
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.sp,
                      vertical: 8.sp,
                    ),
                    decoration: BoxDecoration(
                      color: message.messageTypeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20.sp),
                      border: Border.all(
                        color: message.messageTypeColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      message.messageTypeDisplay,
                      style: AppTextStyles.getBodySmall(
                        isDark: isDark,
                        color: message.messageTypeColor,
                        weight: FontWeight.w600,
                      ).copyWith(fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
            ),

            // Content with better spacing
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with better spacing
                    if (message.title.isNotEmpty) ...[
                      Text(
                        message.title,
                        style: AppTextStyles.titleMedium(
                          isDark: isDark,
                          weight: FontWeight.w600,
                        ).copyWith(fontSize: 18.sp),
                      ),
                      SizedBox(height: 16.sp),
                    ],

                    // Message body with better typography
                    Container(
                      padding: EdgeInsets.all(16.sp),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkOnSurface.withValues(alpha: 0.05)
                            : AppColors.onSurface.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12.sp),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkOnSurface.withValues(alpha: 0.1)
                              : AppColors.onSurface.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        message.message,
                        style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
                          fontSize: 15.sp,
                          height: 1.5,
                        ),
                      ),
                    ),

                    // Metadata if exists with better spacing
                    if (message.metadata != null && message.metadata!.isNotEmpty) ...[
                      SizedBox(height: 20.sp),
                      Container(
                        padding: EdgeInsets.all(16.sp),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkPrimary.withValues(alpha: 0.05)
                              : AppColors.primary.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12.sp),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkPrimary.withValues(alpha: 0.1)
                                : AppColors.primary.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 18.sp,
                                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                ),
                                SizedBox(width: 8.sp),
                                Text(
                                  'Additional Information',
                                  style: AppTextStyles.getBodySmall(
                                    isDark: isDark,
                                    weight: FontWeight.w600,
                                  ).copyWith(fontSize: 14.sp),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.sp),
                            ...message.metadata!.entries.map(
                              (entry) => Padding(
                                padding: EdgeInsets.only(bottom: 8.sp),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.sp,
                                        vertical: 4.sp,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (isDark
                                                ? AppColors.darkPrimary
                                                : AppColors.primary)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6.sp),
                                      ),
                                      child: Text(
                                        '${entry.key}:',
                                        style: AppTextStyles.getBodySmall(
                                          isDark: isDark,
                                          weight: FontWeight.w600,
                                        ).copyWith(fontSize: 12.sp),
                                      ),
                                    ),
                                    SizedBox(width: 8.sp),
                                    Expanded(
                                      child: Text(
                                        entry.value.toString(),
                                        style: AppTextStyles.getBodySmall(
                                          isDark: isDark,
                                        ).copyWith(fontSize: 13.sp),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Actions with better spacing
            Container(
              padding: EdgeInsets.all(20.sp),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface.withValues(alpha: 0.8)
                    : AppColors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20.sp),
                  bottomRight: Radius.circular(20.sp),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48.sp,
                      child: OutlinedButton(
                        onPressed: () => _deleteMessage(message, provider),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error, width: 2),
                          padding: EdgeInsets.symmetric(vertical: 12.sp),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.sp),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline, size: 18.sp),
                            SizedBox(width: 8.sp),
                            Text(
                              'Delete',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 16.sp),

                  Expanded(
                    child: SizedBox(
                      height: 48.sp,
                      child: ElevatedButton(
                        onPressed: () => context.pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.darkPrimary
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.sp),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.sp),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close, size: 18.sp),
                            SizedBox(width: 8.sp),
                            Text(
                              'Close',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteMessage(ChurchMessage message, ChurchMessageProvider provider) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.card,
        title: Text(
          'Delete Message',
          style: AppTextStyles.getTitle(isDark: isDark),
        ),
        content: Text(
          'Are you sure you want to delete this message?',
          style: AppTextStyles.getBody(isDark: isDark),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.getBody(
                isDark: isDark,
                color: AppColors.getOnSurfaceColor(isDark),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Close the delete confirmation dialog first
                context.pop();
                
                // Wait a bit for the dialog to close
                await Future.delayed(Duration(milliseconds: 100));
                
                // Close the message details dialog using the root navigator
                if (mounted) {
                  final navigator = Navigator.of(context, rootNavigator: true);
                  if (navigator.canPop()) {
                    navigator.pop();
                  }
                }

                await provider.deleteMessage(message.id);
                if (mounted) {
                  // Refresh the messages list after successful deletion
                  await provider.refreshMessages();
                  
                  // Force refresh the church messages screen
                  setState(() {});
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Message deleted successfully'),
                      backgroundColor: AppColors.success,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete message: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: AppTextStyles.getBody(
                isDark: isDark,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ChurchMessageProvider provider, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
          SizedBox(height: 16.sp),
          Text(
            'Failed to load messages',
            style: AppTextStyles.titleMedium(isDark: isDark),
          ),
          SizedBox(height: 8.sp),
          Text(
            provider.error ?? 'An error occurred',
            style: AppTextStyles.bodyMedium(
              isDark: isDark,
              color: (isDark ? AppColors.darkOnSurface : AppColors.onSurface)
                  .withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.sp),
          SizedBox(
            height: 40.sp,
            child: ElevatedButton(
              onPressed: () => _loadData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.darkPrimary
                    : AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64.sp,
            color: (isDark ? AppColors.darkOnSurface : AppColors.onSurface)
                .withValues(alpha: 0.5),
          ),
          SizedBox(height: 16.sp),
          Text(
            'No messages yet',
            style: AppTextStyles.titleMedium(isDark: isDark),
          ),
          SizedBox(height: 8.sp),
          Text(
            'You\'ll see messages from churches here when they send you updates.',
            style: AppTextStyles.bodyMedium(
              isDark: isDark,
              color: (isDark ? AppColors.darkOnSurface : AppColors.onSurface)
                  .withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

