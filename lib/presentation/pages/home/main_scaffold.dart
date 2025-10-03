import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/core/theme/app_constants.dart';
import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/presentation/widgets/app_header.dart';
import 'package:manna_donate_app/presentation/widgets/app_drawer.dart';
import 'package:manna_donate_app/presentation/pages/bank/bank_accounts_screen.dart';
import 'package:manna_donate_app/presentation/pages/profile/profile_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';

// --- GoRouter setup (put this in your main.dart or router config) ---
// final GoRouter _router = GoRouter(
//   routes: [
//     GoRoute(
//       path: '/home',
//       builder: (context, state) => MainScaffold(child: HomeTab()),
//     ),
//     GoRoute(
//       path: '/bank',
//       builder: (context, state) => MainScaffold(child: BankTab()),
//     ),
//     GoRoute(
//       path: '/donate',
//       builder: (context, state) => MainScaffold(child: DonateTab()),
//     ),
//     GoRoute(
//       path: '/profile',
//       builder: (context, state) => MainScaffold(child: ProfileTab()),
//     ),
//   ],
// );
// --- End GoRouter setup ---

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key, required this.child});

  final Widget child;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _routes = [
    '/home',
    '/donation-dashboard',
    '/donate',
    '/bank-accounts',
    '/profile',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocation = GoRouterState.of(context).uri.toString();
    final idx = _routes.indexWhere((r) => currentLocation.startsWith(r));
    if (idx != -1 && idx != _currentIndex) {
      setState(() {
        _currentIndex = idx;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        // Don't call bank API methods here as they're already called in HomeScreen
        // Provider.of<BankProvider>(context, listen: false).fetchDashboard();
        // Provider.of<BankProvider>(context, listen: false).fetchDonationHistory();
      }
    });
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          // Navigate to the selected route
          context.go(_routes[index]);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = authProvider.isDarkMode;

    // Check if user is authenticated
    if (!authProvider.isAuthenticated) {
      // Redirect to login if not authenticated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/login');
        }
      });
      // Return a loading screen while redirecting
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppHeader(title: 'Home'),
      drawer: AppDrawer(),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppConstants.pagePadding,
            AppConstants.headerHeight + AppConstants.pagePadding,
            AppConstants.pagePadding,
            AppConstants.pagePadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(isDark),
              const SizedBox(height: 24),
              _buildQuickActions(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    return Column(
      children: [
        Ink(
          decoration: ShapeDecoration(
            color: AppColors.primary.withAlpha(25),
            shape: const CircleBorder(),
          ),
          child: IconButton(
            icon: Icon(icon, color: AppColors.primary),
            onPressed: () => context.go(route),
            iconSize: 32,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome Back!', style: AppTextStyles.getHeader(isDark: isDark)),
        const SizedBox(height: 8),
        Text(
          'Ready to make a difference?',
          style: AppTextStyles.getSubtitle(isDark: isDark).copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTextStyles.getSubtitle(isDark: isDark)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuickAction(
              context,
              Icons.volunteer_activism,
              'Donate',
              '/roundup-donate',
            ),
            _buildQuickAction(
              context,
              Icons.history,
              'History',
              '/donation-history',
            ),
            _buildQuickAction(
              context,
              Icons.credit_card,
              'Bank',
              '/bank-accounts',
            ),
            _buildQuickAction(context, Icons.settings, 'Settings', '/settings'),
          ],
        ),
      ],
    );
  }
}

// --- Tab Screens ---
class HomeTab extends StatelessWidget {
  const HomeTab({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // Donate-themed carousel (unified style)
              CarouselSlider(
                options: CarouselOptions(
                  height: 200,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: 0.9,
                  aspectRatio: 2.0,
                  initialPage: 0,
                ),
                items: List.generate(_donateCarouselImages.length, (index) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                _donateCarouselImages[index],
                                fit: BoxFit.cover,
                              ),
                              Container(color: Colors.black.withAlpha(102)),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _donateCarouselTexts[index][0],
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 8,
                                              color: Colors.black45,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _donateCarouselTexts[index][1],
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 8,
                                              color: Colors.black38,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary
                                              .withAlpha(230),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        onPressed: () => context.go('/donate'),
                                        child: Text('Donate Now'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 24),
              // Giving summary card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Giving Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Donated',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                ' 2,500',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'This Month',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                ' 500',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: 0.5,
                        color: AppColors.primary,
                        backgroundColor: AppColors.disabled,
                        minHeight: 8,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Quick actions row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickAction(
                      context,
                      Icons.volunteer_activism,
                      'Donate',
                      '/roundup-donate',
                    ),
                    _buildQuickAction(
                      context,
                      Icons.history,
                      'History',
                      '/donation-history',
                    ),
                    _buildQuickAction(
                      context,
                      Icons.credit_card,
                      'Bank',
                      '/bank-accounts',
                    ),
                    _buildQuickAction(
                      context,
                      Icons.settings,
                      'Settings',
                      '/settings',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // ... (rest of the HomeTab content, e.g., SubmitButtons, can be kept or removed as needed)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    return Column(
      children: [
        Ink(
          decoration: ShapeDecoration(
            color: AppColors.primary.withAlpha(25),
            shape: const CircleBorder(),
          ),
          child: IconButton(
            icon: Icon(icon, color: AppColors.primary),
            onPressed: () => context.go(route),
            iconSize: 32,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }
}

// Add these static lists to HomeTab (or move to a shared location if needed)
const List<String> _donateCarouselImages = [
  'assets/images/donate_carousel/donate1.jpg',
  'assets/images/donate_carousel/donate2.jpg',
  'assets/images/donate_carousel/donate3.jpg',
];
const List<List<String>> _donateCarouselTexts = [
  ['Give Hope', 'Your donation brings hope to those in need.'],
  ['Support Your Community', 'Every gift helps us make a difference together.'],
  ['Every Gift Matters', 'Join the mission. Make an impact today.'],
];

class BankTab extends StatelessWidget {
  const BankTab({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return BankAccountsScreen();
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ProfileScreen();
  }
}
