import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/domain/models/badge_model.dart';
import '../../../../core/domain/models/xp_profile.dart';
import '../../../../core/gamification/badges_catalog.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/gamification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/theme/theme_cubit.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      create: (_) => sl<ProfileBloc>()..add(const LoadProfile()),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: tokens.surfaceElevated,
      body: SafeArea(
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileDataCleared) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile data cleared successfully.')),
              );
              Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.homeRoute, (_) => false);
            }
          },
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final loaded = state is ProfileLoaded ? state : null;
            final xpProfile = loaded?.xpProfile ??
                const XPProfile(earnedBadges: [], xpHistory: {}, updatedAt: '');
            final displayName = loaded?.displayName ?? 'Sundaramoorthy.S';
            final email = loaded?.email ?? 'sundar@goalforge.app';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1380),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── TOP HEADER ──
                      _buildHeader(context, theme, tokens),
                      const SizedBox(height: 24),

                      // ── MAIN RESPONSIVE CONTENT GRID ──
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isDesktop = constraints.maxWidth >= 900;

                          if (isDesktop) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // LEFT MAIN COLUMN (65%)
                                Expanded(
                                  flex: 65,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildHeroCard(context, tokens, xpProfile, displayName, email),
                                      const SizedBox(height: 20),
                                      _buildIdentityBadgesSection(context, tokens, loaded),
                                      const SizedBox(height: 20),
                                      _buildStoryMomentsSection(context, tokens, xpProfile),
                                      const SizedBox(height: 20),
                                      _buildRecentXpGainsFeed(context, tokens, xpProfile),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),

                                // RIGHT SIDEBAR COLUMN (35%)
                                Expanded(
                                  flex: 35,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLevelRoadmapCard(context, tokens, xpProfile),
                                      const SizedBox(height: 16),
                                      _buildLifetimeStatsCard(context, tokens, loaded),
                                      const SizedBox(height: 16),
                                      _buildDisciplineScoreCard(context, tokens, loaded),
                                      const SizedBox(height: 16),
                                      _buildAppSettingsCard(context, tokens, loaded),
                                      const SizedBox(height: 16),
                                      _buildDangerZoneCard(context, tokens),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }

                          // MOBILE / TABLET SINGLE COLUMN LAYOUT
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeroCard(context, tokens, xpProfile, displayName, email),
                              const SizedBox(height: 16),
                              _buildIdentityBadgesSection(context, tokens, loaded),
                              const SizedBox(height: 16),
                              _buildStoryMomentsSection(context, tokens, xpProfile),
                              const SizedBox(height: 16),
                              _buildRecentXpGainsFeed(context, tokens, xpProfile),
                              const SizedBox(height: 20),
                              _buildLevelRoadmapCard(context, tokens, xpProfile),
                              const SizedBox(height: 16),
                              _buildLifetimeStatsCard(context, tokens, loaded),
                              const SizedBox(height: 16),
                              _buildDisciplineScoreCard(context, tokens, loaded),
                              const SizedBox(height: 16),
                              _buildAppSettingsCard(context, tokens, loaded),
                              const SizedBox(height: 16),
                              _buildDangerZoneCard(context, tokens),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 1. TOP NAV HEADER
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, ThemeData theme, AppThemeTokens tokens) {
    return Row(
      children: [
        InkWell(
          onTap: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed(AppRouter.homeRoute);
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.surfaceCard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.chevronLeft, size: 16, color: tokens.contentPrimary),
                const SizedBox(width: 4),
                Text(
                  'Back',
                  style: GoogleFonts.plusJakartaSans(
                    color: tokens.contentPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PROFILE & ACHIEVEMENTS',
                style: GoogleFonts.plusJakartaSans(
                  color: tokens.contentTertiary,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                'Commander Profile',
                style: GoogleFonts.plusJakartaSans(
                  color: tokens.contentPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            theme.brightness == Brightness.dark ? LucideIcons.sun : LucideIcons.moon,
            color: tokens.contentPrimary,
          ),
          onPressed: () => context.read<ThemeCubit>().toggleTheme(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 2. HERO PROFILE CARD
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeroCard(
    BuildContext context,
    AppThemeTokens tokens,
    XPProfile xpProfile,
    String displayName,
    String email,
  ) {
    final gamificationService = sl<GamificationService>();
    final levelProgress = gamificationService.calculateLevelProgress(xpProfile.totalXP);
    final avatarLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S';
    final rankTitles = {
      1: 'Recruit',
      2: 'Initiate',
      3: 'Apprentice',
      4: 'Practitioner',
      5: 'Specialist',
      6: 'Strategist',
      7: 'Master',
      8: 'Visionary',
      9: 'Architect',
      10: 'Grandmaster',
      11: 'Sovereign',
      12: 'Ascendant',
    };
    final rankTitle = rankTitles[levelProgress.currentLevel] ?? 'Commander';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    avatarLetter,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      email,
                      style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'Level ${levelProgress.currentLevel} — $rankTitle',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // XP Progress Bar
          Row(
            children: [
              Expanded(
                child: Text(
                  'TOTAL XP: ${xpProfile.totalXP}',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${levelProgress.xpNeededForNextLevel - levelProgress.xpInCurrentLevel} XP to Level ${levelProgress.currentLevel + 1}',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: levelProgress.progressRatio,
              minHeight: 8,
              backgroundColor: const Color(0xFF1E293B),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),

          // Earned Badges Mini Bar
          Text(
            'EARNED BADGES (${xpProfile.earnedBadges.length})',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w900,
              fontSize: 9,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          if (xpProfile.earnedBadges.isEmpty)
            Text(
              'No badges unlocked yet. Complete tasks & habits to earn badges!',
              style: TextStyle(color: const Color(0xFF64748B), fontSize: 11),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: xpProfile.earnedBadges.map((badgeId) {
                  final badgeDef = BadgesCatalog.allBadges.firstWhere(
                    (b) => b.id == badgeId,
                    orElse: () => BadgesCatalog.allBadges.first,
                  );
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.award, size: 12, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          badgeDef.title,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 3. IDENTITY BADGES & ACHIEVEMENTS SECTION
  // ─────────────────────────────────────────────────────────────
  Widget _buildIdentityBadgesSection(BuildContext context, AppThemeTokens tokens, ProfileLoaded? loaded) {
    final xpProfile = loaded?.xpProfile ?? const XPProfile(earnedBadges: [], xpHistory: {}, updatedAt: '');
    final selectedCategory = loaded?.selectedCategory;

    final categories = [
      null,
      BadgeCategory.consistency,
      BadgeCategory.learning,
      BadgeCategory.focus,
      BadgeCategory.accuracy,
      BadgeCategory.mastery,
    ];

    final filteredBadges = BadgesCatalog.allBadges.where((badge) {
      if (selectedCategory == null) return true;
      return badge.category == selectedCategory;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'IDENTITY BADGES & ACHIEVEMENTS',
                  style: GoogleFonts.plusJakartaSans(
                    color: tokens.contentTertiary,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                    letterSpacing: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ALL (${BadgesCatalog.allBadges.length})',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Filter Tabs Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = selectedCategory == cat;
                final count = BadgesCatalog.allBadges.where((b) => cat == null || b.category == cat).length;
                final unlockedCount = BadgesCatalog.allBadges
                    .where((b) => (cat == null || b.category == cat) && xpProfile.earnedBadges.contains(b.id))
                    .length;
                final label = cat == null
                    ? 'All ($unlockedCount/$count)'
                    : '${cat.name[0].toUpperCase()}${cat.name.substring(1)} ($unlockedCount/$count)';

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) {
                      context.read<ProfileBloc>().add(SelectBadgeCategoryTab(cat));
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      color: isSelected ? Colors.white : tokens.contentSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                    backgroundColor: tokens.surfaceElevated,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Badge Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisExtent: 110,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filteredBadges.length,
                itemBuilder: (context, index) {
                  final badge = filteredBadges[index];
                  final isUnlocked = xpProfile.earnedBadges.contains(badge.id);
                  final unlockedDate = xpProfile.unlockedBadgesMap[badge.id];

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : tokens.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isUnlocked ? AppColors.primary.withValues(alpha: 0.3) : tokens.borderDefault,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isUnlocked ? AppColors.primary : tokens.borderDefault,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isUnlocked ? LucideIcons.award : LucideIcons.lock,
                            color: isUnlocked ? Colors.white : tokens.iconSubtle,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                badge.title,
                                style: GoogleFonts.plusJakartaSans(
                                  color: isUnlocked ? tokens.contentPrimary : tokens.contentSecondary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                badge.description,
                                style: TextStyle(color: tokens.contentTertiary, fontSize: 10),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              if (isUnlocked)
                                Text(
                                  unlockedDate != null
                                      ? 'UNLOCKED ${unlockedDate.split("T").first}'
                                      : 'UNLOCKED',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9,
                                  ),
                                )
                              else
                                Text(
                                  'PROGRESS 0/${badge.targetValue}',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: tokens.iconSubtle,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 4. STORY MOMENT MEMORIES SECTION
  // ─────────────────────────────────────────────────────────────
  Widget _buildStoryMomentsSection(BuildContext context, AppThemeTokens tokens, XPProfile xpProfile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.bookOpen, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'STORY MOMENT MEMORIES',
                style: GoogleFonts.plusJakartaSans(
                  color: tokens.contentTertiary,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (xpProfile.storyMoments.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: tokens.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(LucideIcons.sparkles, size: 28, color: tokens.iconSubtle),
                  const SizedBox(height: 8),
                  Text(
                    'Your achievements book is empty',
                    style: GoogleFonts.plusJakartaSans(
                      color: tokens.contentPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete a goal to 100% to unlock your first story reflection moment!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: tokens.contentTertiary, fontSize: 11),
                  ),
                ],
              ),
            )
          else
            Column(
              children: xpProfile.storyMoments.map((moment) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tokens.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.bookmark, size: 18, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              moment.goalTitle,
                              style: GoogleFonts.plusJakartaSans(
                                color: tokens.contentPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              moment.reflectionText,
                              style: TextStyle(color: tokens.contentSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 5. RECENT XP GAINS FEED
  // ─────────────────────────────────────────────────────────────
  Widget _buildRecentXpGainsFeed(BuildContext context, AppThemeTokens tokens, XPProfile xpProfile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECENT XP GAINS ACTIVITY FEED',
            style: GoogleFonts.plusJakartaSans(
              color: tokens.contentTertiary,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),

          if (xpProfile.transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No XP activity recorded yet today.',
                style: TextStyle(color: tokens.contentSecondary, fontSize: 11),
              ),
            )
          else
            Column(
              children: xpProfile.transactions.take(10).map((tx) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tx.title,
                          style: TextStyle(color: tokens.contentPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '+${tx.amount} XP',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.green,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 6. RIGHT COLUMN: LEVEL ROADMAP
  // ─────────────────────────────────────────────────────────────
  Widget _buildLevelRoadmapCard(BuildContext context, AppThemeTokens tokens, XPProfile xpProfile) {
    final levels = [
      {'level': 1, 'title': 'Recruit', 'xp': 0},
      {'level': 2, 'title': 'Initiate', 'xp': 100},
      {'level': 3, 'title': 'Apprentice', 'xp': 250},
      {'level': 4, 'title': 'Practitioner', 'xp': 500},
      {'level': 5, 'title': 'Specialist', 'xp': 800},
      {'level': 6, 'title': 'Strategist', 'xp': 1200},
      {'level': 7, 'title': 'Master', 'xp': 1700},
      {'level': 8, 'title': 'Visionary', 'xp': 2400},
      {'level': 9, 'title': 'Architect', 'xp': 3300},
      {'level': 10, 'title': 'Grandmaster', 'xp': 4500},
      {'level': 11, 'title': 'Sovereign', 'xp': 6000},
      {'level': 12, 'title': 'Ascendant', 'xp': 8000},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LEVEL ROADMAP',
            style: GoogleFonts.plusJakartaSans(
              color: tokens.contentTertiary,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),

          SizedBox(
            height: 240,
            child: ListView.builder(
              itemCount: levels.length,
              itemBuilder: (context, index) {
                final lvl = levels[index];
                final levelNum = lvl['level'] as int;
                final isCurrent = xpProfile.level == levelNum;

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : tokens.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCurrent ? AppColors.primary : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Lvl $levelNum',
                        style: GoogleFonts.plusJakartaSans(
                          color: isCurrent ? AppColors.primary : tokens.contentSecondary,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          lvl['title'] as String,
                          style: TextStyle(
                            color: isCurrent ? tokens.contentPrimary : tokens.contentSecondary,
                            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '${lvl['xp']} XP',
                        style: GoogleFonts.plusJakartaSans(
                          color: tokens.contentTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 7. LIFETIME STATS CARD
  // ─────────────────────────────────────────────────────────────
  Widget _buildLifetimeStatsCard(BuildContext context, AppThemeTokens tokens, ProfileLoaded? loaded) {
    final totalXp = loaded?.xpProfile.totalXP ?? 0;
    final completions = loaded?.totalCompletions ?? 0;
    final focusMins = loaded?.totalFocusMinutes ?? 0;
    final badgesCount = loaded?.xpProfile.earnedBadges.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LIFETIME STATS',
            style: GoogleFonts.plusJakartaSans(
              color: tokens.contentTertiary,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),

          _buildStatRow(tokens, 'Total XP', '$totalXp'),
          _buildStatRow(tokens, 'Task Completions', '$completions'),
          _buildStatRow(tokens, 'Focus Time', '${focusMins ~/ 60}h ${focusMins % 60}m'),
          _buildStatRow(tokens, 'Badges Earned', '$badgesCount / 34'),
        ],
      ),
    );
  }

  Widget _buildStatRow(AppThemeTokens tokens, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: tokens.contentSecondary, fontSize: 12)),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(color: tokens.contentPrimary, fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 8. DISCIPLINE SCORE CARD
  // ─────────────────────────────────────────────────────────────
  Widget _buildDisciplineScoreCard(BuildContext context, AppThemeTokens tokens, ProfileLoaded? loaded) {
    final score = loaded?.disciplineScore ?? 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'TODAY\'S PERFORMANCE',
            style: GoogleFonts.plusJakartaSans(
              color: tokens.contentTertiary,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$score',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 36,
            ),
          ),
          Text(
            'Discipline Score',
            style: TextStyle(color: tokens.contentSecondary, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 9. APP SETTINGS CARD
  // ─────────────────────────────────────────────────────────────
  Widget _buildAppSettingsCard(BuildContext context, AppThemeTokens tokens, ProfileLoaded? loaded) {
    final isEnabled = loaded?.smartNotificationsEnabled ?? true;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'APP SETTINGS',
            style: GoogleFonts.plusJakartaSans(
              color: tokens.contentTertiary,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Notifications',
                      style: GoogleFonts.plusJakartaSans(
                        color: tokens.contentPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Daily reminders when falling behind on targets',
                      style: TextStyle(color: tokens.contentTertiary, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  context.read<ProfileBloc>().add(ToggleSmartNotificationsSetting(val));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 10. DANGER ZONE CARD
  // ─────────────────────────────────────────────────────────────
  Widget _buildDangerZoneCard(BuildContext context, AppThemeTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade700.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DANGER ZONE',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w900,
              fontSize: 9,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _showClearDataConfirmation(context, tokens),
              icon: const Icon(LucideIcons.trash2, size: 16),
              label: Text(
                'Clear Profile Data',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDataConfirmation(BuildContext context, AppThemeTokens tokens) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: tokens.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Clear Profile Data?',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          content: Text(
            'This action is irreversible. All your goals, habits, tasks, notes, focus logs, and XP achievements will be permanently deleted.',
            style: TextStyle(color: tokens.contentSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: TextStyle(color: tokens.contentSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<ProfileBloc>().add(const ClearAllProfileDataRequested());
              },
              child: const Text('Delete Everything'),
            ),
          ],
        );
      },
    );
  }
}
