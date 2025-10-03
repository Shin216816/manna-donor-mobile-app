import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/core/theme/app_constants.dart';
import 'package:manna_donate_app/data/repository/church_provider.dart';
import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/data/models/church.dart';
import 'package:manna_donate_app/presentation/widgets/app_header.dart';
import 'package:manna_donate_app/presentation/widgets/app_drawer.dart';
import 'package:manna_donate_app/presentation/widgets/modern_input_field.dart';

class ChurchSelectionScreen extends StatefulWidget {
  final bool isFromPreferences;

  const ChurchSelectionScreen({super.key, this.isFromPreferences = false});

  @override
  State<ChurchSelectionScreen> createState() => _ChurchSelectionScreenState();
}

class _ChurchSelectionScreenState extends State<ChurchSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  int _currentPage = 1;
  final int _churchesPerPage = 5;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Defer loading churches until after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChurches();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we have extra data from GoRouter
    final extra = GoRouterState.of(context).extra;
    if (extra != null && extra is Map<String, dynamic>) {
      final isFromPreferences = extra['isFromPreferences'] as bool? ?? false;
      if (isFromPreferences != widget.isFromPreferences) {
        // Update the widget's isFromPreferences if it came from GoRouter
        // Note: This is a workaround since we can't modify the widget directly
        // The actual logic will be handled in the navigation
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChurches() async {
    final churchProvider = Provider.of<ChurchProvider>(context, listen: false);
    await churchProvider.forceRefreshChurches();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
      _currentPage = 1; // Reset to first page when searching
    });

    if (query.isNotEmpty) {
      final churchProvider = Provider.of<ChurchProvider>(
        context,
        listen: false,
      );
      churchProvider.searchChurches(query);
    } else {
      final churchProvider = Provider.of<ChurchProvider>(
        context,
        listen: false,
      );
      churchProvider.clearSearch();
    }
  }

  List<Church> _getFilteredChurches(List<Church> churches) {
    if (_searchQuery.isEmpty) return churches;
    
    return churches.where((church) {
      final query = _searchQuery.toLowerCase();
      return church.name.toLowerCase().contains(query) ||
             church.address.toLowerCase().contains(query) ||
             (church.city?.toLowerCase().contains(query) ?? false) ||
             (church.state?.toLowerCase().contains(query) ?? false) ||
             (church.type?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  List<Church> _getPaginatedChurches(List<Church> churches) {
    final filteredChurches = _getFilteredChurches(churches);
    final startIndex = (_currentPage - 1) * _churchesPerPage;
    final endIndex = startIndex + _churchesPerPage;
    
    if (startIndex >= filteredChurches.length) {
      return [];
    }
    
    return filteredChurches.sublist(
      startIndex,
      endIndex > filteredChurches.length ? filteredChurches.length : endIndex,
    );
  }

  int _getTotalPages(List<Church> churches) {
    final filteredChurches = _getFilteredChurches(churches);
    return (filteredChurches.length / _churchesPerPage).ceil();
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
    // Scroll to top of the list
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _selectChurch(Church church) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final churchProvider = Provider.of<ChurchProvider>(context, listen: false);

    if (authProvider.user == null) {
      _showSnackBar(
        'Please log in to select a church',
        backgroundColor: Colors.red,
      );
      return;
    }

    try {
      final response = await churchProvider.selectChurch(
        authProvider.user!.id,
        church,
      );

      if (response.success) {
        // Refresh user profile to get updated church IDs
        await authProvider.getProfile();

        // Church selected successfully: ${church.name} (ID: ${church.id})
        // User Church IDs after selection: ${authProvider.userChurchIds}

        _showSnackBar(
          'Church selected successfully!',
          backgroundColor: Colors.green,
        );

        // Navigate back or to next screen
        if (Navigator.canPop(context)) {
          Navigator.pop(
            context,
            true,
          ); // Return true to indicate successful selection
        } else {
          context.go('/home');
        }
      } else {
        _showSnackBar(response.message, backgroundColor: Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error selecting church: $e', backgroundColor: Colors.red);
    }
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleBackPress() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      context.go('/home');
    }
  }

  void _handleSkip() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      context.go('/home');
    }
  }

  void _handleContinue() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: AppDrawer(),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppHeader(
        title: widget.isFromPreferences
            ? 'Select Church'
            : 'Choose Your Church',
        actions: [
          if (_isSearching)
            IconButton(
              icon: Icon(
                Icons.clear,
                color: isDark ? AppColors.darkTextSecondary : Colors.grey[600],
              ),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppConstants.pagePadding,
            AppConstants.headerHeight + AppConstants.pagePadding,
            AppConstants.pagePadding,
            AppConstants.pagePadding,
          ),
          child: Column(
            children: [
              // Auto-scroll card container
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Search and Filter Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.surface,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Single Search/Filter Input (Full Width)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : Colors.grey[300]!,
                                  width: 1,
                                ),
                                color: isDark ? AppColors.darkInputFill : AppColors.inputFill,
                              ),
                              child: ModernInputField(
                                controller: _searchController,
                                label: '',
                                hint: 'Search churches by name, location, or type...',
                                prefixIcon: Icons.search,
                                suffixIcon: _searchQuery.isNotEmpty ? Icons.clear : null,
                                isDark: isDark,
                                onChanged: _onSearchChanged,
                                onSuffixIconPressed: _searchQuery.isNotEmpty ? () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                } : null,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3, end: 0),

                      // Churches List Section
                      Expanded(
                        child: Consumer<ChurchProvider>(
                          builder: (context, churchProvider, child) {
                            if (churchProvider.loading) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    EnhancedLoadingWidget(
                                      type: LoadingType.spinner,
                                      message: 'Loading churches...',
                                      color: isDark
                                          ? AppColors.darkPrimary
                                          : AppColors.primary,
                                      size: 40,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Please wait while we load available churches',
                                                          style: AppTextStyles.getBody(isDark: isDark).copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : Colors.grey[700],
                    ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (churchProvider.error != null) {
                              return _buildErrorState(churchProvider, isDark);
                            }

                            final churches = churchProvider.churches;

                            if (churches.isEmpty) {
                              return _buildEmptyState(isDark);
                            }

                            final paginatedChurches = _getPaginatedChurches(churches);
                            final totalPages = _getTotalPages(churches);
                            final filteredChurches = _getFilteredChurches(churches);

                            return Column(
                              children: [
                                // Results count
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Showing ${paginatedChurches.length} of ${filteredChurches.length} churches',
                                        style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : Colors.grey[600],
                                        ),
                                      ),
                                      const Spacer(),
                                      if (totalPages > 1)
                                        Text(
                                          'Page $_currentPage of $totalPages',
                                          style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : Colors.grey[600],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Churches List
                                Expanded(
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    itemCount: paginatedChurches.length,
                                    itemBuilder: (context, index) {
                                      final church = paginatedChurches[index];
                                      return _buildChurchCard(church, churchProvider, isDark, index)
                                          .animate()
                                          .fadeIn(duration: 600.ms, delay: (index * 100).ms)
                                          .slideY(
                                            begin: 0.3,
                                            end: 0,
                                            duration: 600.ms,
                                            delay: (index * 100).ms,
                                          );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Pagination Section
              const SizedBox(height: 8),
              Consumer<ChurchProvider>(
                builder: (context, churchProvider, child) {
                  final churches = churchProvider.churches;
                  final totalPages = _getTotalPages(churches);
                  
                  // Always show pagination, even with few churches
                  return _buildPagination(totalPages, isDark);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(ChurchProvider churchProvider, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDark ? AppColors.error : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: AppTextStyles.getHeader(isDark: isDark).copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              churchProvider.error!,
              style: AppTextStyles.getBody(isDark: isDark).copyWith(
                color: isDark ? AppColors.darkTextSecondary : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadChurches,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.darkPrimary
                    : AppColors.primary,
                foregroundColor: isDark
                    ? AppColors.darkOnPrimary
                    : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(int totalPages, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          IconButton(
            onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
            icon: Icon(
              Icons.chevron_left,
              color: _currentPage > 1
                  ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                  : (isDark ? AppColors.darkTextSecondary : Colors.grey[400]),
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: _currentPage > 1
                  ? (isDark ? AppColors.darkPrimary.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1))
                  : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.all(4),
              minimumSize: const Size(32, 32),
            ),
          ),
          const SizedBox(width: 4),

          // Page numbers or single page indicator
          if (totalPages <= 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkPrimary : AppColors.primary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '1',
                style: AppTextStyles.getBody(isDark: isDark).copyWith(
                  color: (isDark ? AppColors.darkOnPrimary : Colors.white),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ...List.generate(totalPages, (index) {
              final pageNumber = index + 1;
              final isCurrentPage = pageNumber == _currentPage;
              
              // Show first page, last page, current page, and pages around current
              final shouldShow = pageNumber == 1 ||
                  pageNumber == totalPages ||
                  (pageNumber >= _currentPage - 1 && pageNumber <= _currentPage + 1);
              
              if (!shouldShow) {
                // Show ellipsis if there's a gap
                if (pageNumber == _currentPage - 2 || pageNumber == _currentPage + 2) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      '...',
                      style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                        color: isDark ? AppColors.darkTextSecondary : Colors.grey[700],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  onTap: () => _goToPage(pageNumber),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCurrentPage
                          ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: isCurrentPage
                          ? null
                          : Border.all(
                              color: isDark ? AppColors.darkBorder : Colors.grey[300]!,
                              width: 1,
                            ),
                    ),
                    child: Text(
                      pageNumber.toString(),
                      style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                        color: isCurrentPage
                            ? (isDark ? AppColors.darkOnPrimary : Colors.white)
                            : (isDark ? AppColors.darkTextPrimary : Colors.black87),
                        fontWeight: isCurrentPage ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }),

          const SizedBox(width: 4),

          // Next button
          IconButton(
            onPressed: _currentPage < totalPages ? () => _goToPage(_currentPage + 1) : null,
            icon: Icon(
              Icons.chevron_right,
              color: _currentPage < totalPages
                  ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                  : (isDark ? AppColors.darkTextSecondary : Colors.grey[400]),
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: _currentPage < totalPages
                  ? (isDark ? AppColors.darkPrimary.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1))
                  : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.all(4),
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.church,
              size: 64,
              color: isDark ? AppColors.darkTextSecondary : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching ? 'No churches found' : 'No churches available',
              style: AppTextStyles.getHeader(isDark: isDark).copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSearching
                  ? 'Try searching with different terms'
                  : 'Check back later for available churches',
              style: AppTextStyles.getBody(isDark: isDark).copyWith(
                color: isDark ? AppColors.darkTextSecondary : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildChurchCard(
    Church church,
    ChurchProvider churchProvider,
    bool isDark,
    int index,
  ) {
    final isSelected = churchProvider.selectedChurch?.id == church.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: isDark
                    ? [
                        AppColors.darkPrimary.withValues(alpha: 0.1),
                        AppColors.darkPrimary.withValues(alpha: 0.05),
                      ]
                    : [
                        AppColors.primary.withValues(alpha: 0.1),
                        AppColors.primary.withValues(alpha: 0.05),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected
            ? null
            : (isDark ? AppColors.darkCard : AppColors.card),
        borderRadius: BorderRadius.circular(20),
        border: isSelected
            ? Border.all(
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                width: 2,
              )
            : Border.all(
                color: isDark ? AppColors.darkBorder : Colors.grey[200]!,
                width: 1,
              ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 4),
            spreadRadius: isSelected ? 2 : 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectChurch(church),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row with Church Icon and Name
                Row(
                  children: [
                    // Enhanced Church icon with gradient
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: isDark
                                    ? [
                                        AppColors.darkPrimary,
                                        AppColors.darkPrimary.withValues(alpha: 0.8),
                                      ]
                                    : [
                                        AppColors.primary,
                                        AppColors.primary.withValues(alpha: 0.8),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: isDark
                                    ? [
                                        AppColors.darkSurface,
                                        AppColors.darkSurface.withValues(alpha: 0.8),
                                      ]
                                    : [
                                        AppColors.surface,
                                        AppColors.surface.withValues(alpha: 0.8),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.3)
                                : Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.church,
                        color: isSelected
                            ? (isDark ? AppColors.darkOnPrimary : Colors.white)
                            : (isDark ? AppColors.darkPrimary : AppColors.primary),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Church Name and Status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            church.name,
                            style: AppTextStyles.getTitle(isDark: isDark).copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                                  : (isDark ? AppColors.darkTextPrimary : Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Status badges
                          Row(
                            children: [
                              if (church.isVerified)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified,
                                        size: 12,
                                        color: Colors.green[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Verified',
                                        style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (church.isVerified && church.isActive)
                                const SizedBox(width: 6),
                              if (church.isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 12,
                                        color: Colors.blue[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Active',
                                        style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Selection indicator
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkPrimary : AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check,
                          color: isDark ? AppColors.darkOnPrimary : Colors.white,
                          size: 20,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Church Details Grid
                Row(
                  children: [
                    // Left Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Address
                          if (church.address.isNotEmpty)
                            _buildDetailRow(
                              isDark,
                              Icons.location_on,
                              'Address',
                              church.address,
                            ),
                          
                          // City & State
                          if (church.city != null && church.state != null)
                            _buildDetailRow(
                              isDark,
                              Icons.location_city,
                              'Location',
                              '${church.city}, ${church.state}',
                            ),
                        ],
                      ),
                    ),

                    // Right Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Phone
                          if (church.phone != null && church.phone!.isNotEmpty)
                            _buildDetailRow(
                              isDark,
                              Icons.phone,
                              'Phone',
                              church.phone!,
                            ),
                          
                          // Website
                          if (church.website != null && church.website!.isNotEmpty)
                            _buildDetailRow(
                              isDark,
                              Icons.language,
                              'Website',
                              church.website!,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Church Type (if available)
                if (church.type != null && church.type!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.category,
                          size: 14,
                          color: isDark ? AppColors.darkTextSecondary : Colors.grey[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          church.type!,
                          style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                            color: isDark ? AppColors.darkTextSecondary : Colors.grey[700],
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }

  Widget _buildDetailRow(bool isDark, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
              size: 12,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                    color: isDark ? AppColors.darkTextSecondary : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.getBody(isDark: isDark).copyWith(
                    color: isDark ? AppColors.darkTextPrimary : Colors.black87,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
