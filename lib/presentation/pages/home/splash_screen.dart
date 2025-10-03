import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';
import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/data/repository/bank_provider.dart';
import 'package:manna_donate_app/core/navigation_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  Timer? _fallbackTimer;
  bool _hasStartedNavigation = false;

  @override
  void initState() {
    super.initState();

    // Initialize video controller
    _initializeVideoController();

    // Initialize splash screen
    _initializeSplash();
  }

  Future<void> _initializeVideoController() async {
    try {
      _controller = VideoPlayerController.asset('assets/logo/logo.mp4');
      await _controller.initialize();

      // Don't loop the video - play it once
      await _controller.setLooping(false);

      // Get the actual video duration
      final videoDuration = _controller.value.duration;
      print('Splash Screen - Video duration: $videoDuration');

      // Handle invalid video duration
      if (videoDuration <= Duration.zero) {
        print(
          'Splash Screen - Invalid video duration, using default 4 seconds',
        );
        Timer(const Duration(seconds: 4), () {
          if (mounted && !_hasStartedNavigation) {
            _checkUserSetup();
          }
        });
        return;
      }

      // Add listener to detect when video completes
      _controller.addListener(() {
        final currentPosition = _controller.value.position;
        final totalDuration = _controller.value.duration;

        // Debug: Log position every 500ms
        if (currentPosition.inMilliseconds % 500 < 50) {
          print(
            'Splash Screen - Video position: $currentPosition / $totalDuration',
          );
        }

        // Check if video has completed (with a small tolerance)
        if (totalDuration > Duration.zero &&
            currentPosition >=
                totalDuration - const Duration(milliseconds: 200)) {
          // Video has completed, trigger navigation
          print('Splash Screen - Video completed, triggering navigation');
          if (mounted && !_hasStartedNavigation) {
            _onVideoCompleted();
          }
        }
      });

      await _controller.play();
      if (mounted) {
        setState(() {});
        print('Splash Screen - Video started playing');

        // Set a timer based on actual video duration (with some buffer)
        // Ensure minimum display time of 4 seconds
        final minDisplayTime = const Duration(seconds: 4);
        final videoBasedDelay =
            videoDuration + const Duration(milliseconds: 500);
        final navigationDelay = videoBasedDelay > minDisplayTime
            ? videoBasedDelay
            : minDisplayTime;

        print(
          'Splash Screen - Will navigate after: $navigationDelay (video: $videoDuration, min: $minDisplayTime)',
        );

        Timer(navigationDelay, () {
          if (mounted && !_hasStartedNavigation) {
            print('Splash Screen - Video duration timer expired, navigating');
            _checkUserSetup();
          }
        });
      }
    } catch (e) {
      print('Splash Screen - Error initializing video: $e');
      // If video fails to load, we'll just show the loading state
      // The controller will remain uninitialized and the loading UI will show
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _initializeSplash() {
    // Start fallback timer (in case video fails to load or takes too long)
    _fallbackTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && !_hasStartedNavigation) {
        print('Splash Screen - Fallback timer expired, navigating to login');
        NavigationHelper.navigateToLogin(context);
      }
    });

    // No fixed timer here - navigation is now handled by video completion
    // or the timer set in _initializeVideoController
  }

  void _onVideoCompleted() {
    // Video has completed, check if we should navigate
    // Only navigate if we haven't already started the process
    if (mounted && !_hasStartedNavigation) {
      _checkUserSetup();
    }
  }

  Future<void> _checkUserSetup() async {
    // Prevent multiple calls
    if (_hasStartedNavigation) return;
    _hasStartedNavigation = true;

    try {
      // Check authentication status first
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Wait for auth provider to finish loading
      while (authProvider.isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Add a small delay to ensure token validation is complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if user is authenticated
      if (!authProvider.isAuthenticated) {
        // User is not authenticated, redirect to login
        print('Splash Screen - User not authenticated, going to login');
        if (mounted) {
          NavigationHelper.navigateToLogin(context);
        }
        return;
      }

      // User is authenticated - fetch user data and save to cache
      print('Splash Screen - User authenticated, fetching user data');
      try {
        // Fetch user profile data
        await authProvider.getProfile();

        // Fetch other essential data in background
        final bankProvider = Provider.of<BankProvider>(context, listen: false);
        await bankProvider.smartFetchBankAccounts();
        await bankProvider.smartFetchPreferences();
        await bankProvider.smartFetchPaymentMethods();

        print('Splash Screen - User data fetched successfully, going to home');
        if (mounted) {
          await NavigationHelper.navigateToHome(context);
        }
      } catch (e) {
        print('Splash Screen - Error fetching user data: $e');
        // If there's an error fetching data, still go to home
        // The home screen will handle data loading
        if (mounted) {
          await NavigationHelper.navigateToHome(context);
        }
      }
    } catch (e) {
      print('Splash Screen - Error in _checkUserSetup: $e');
      // If there's an error, redirect to login for safety
      if (mounted) {
        NavigationHelper.navigateToLogin(context);
      }
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    try {
      if (_controller.value.isInitialized) {
        _controller.dispose();
      }
    } catch (e) {
      // Ignore disposal errors
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isVideoInitialized = false;
    try {
      isVideoInitialized = _controller.value.isInitialized;
    } catch (e) {
      isVideoInitialized = false;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: isVideoInitialized
          ? GestureDetector(
              onTap: () {
                // Skip splash screen when tapped
                if (!_hasStartedNavigation) {
                  print('Splash Screen - Skipped by user tap');
                  _checkUserSetup();
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background video
                  SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                  ),

                  // Top shadow (20%)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.2,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                    ),
                  ),

                  // Bottom shadow (30%)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.3,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black,
                            Colors.black,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : GestureDetector(
              onTap: () {
                // Skip loading state when tapped
                if (!_hasStartedNavigation) {
                  print('Splash Screen - Skipped loading state by user tap');
                  _checkUserSetup();
                }
              },
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  ),
                ),
                child: const Center(
                  child: LoadingWave(
                    color: Colors.white,
                    size: 50,
                    isDark: true,
                  ),
                ),
              ),
            ),
    );
  }
}
