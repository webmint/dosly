/// Meds feature — reactive medication-list screen for the dosly MVP.
///
/// This library hosts [MedsScreen], the screen displayed when the user
/// selects the "Meds" destination in the bottom navigation bar. The screen
/// watches [medicationsListProvider], applies search and filter state held
/// locally in the widget, builds the view model via [buildMedsListView], and
/// renders two grouped [MedicationSection]s (continuous and course). A
/// [FloatingActionButton] opens [AddMedicationModal] as a full-screen modal.
library;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/l10n_extensions.dart';
import '../../domain/entities/medication.dart';
import '../providers/medication_providers.dart';
import '../view_models/meds_list_view_model.dart';
import '../widgets/add_medication_modal.dart';
import '../widgets/medication_section.dart';

/// Medication-list screen shown at the meds route.
///
/// Displays a Material 3 [AppBar] with an animated slide-in search bar that
/// overlays the app-bar region from the trailing edge. The title fades out as
/// the search bar animates in. Below the app bar a filter-chip row lets the
/// user switch between [MedsFilter.all] and [MedsFilter.active]. The body
/// renders the result of [buildMedsListView] applied to the live stream from
/// [medicationsListProvider]: loading → [CircularProgressIndicator]; error → a
/// muted error message; data with zero total medications → an empty-state card;
/// data with medications → two [MedicationSection]s (continuous then course).
///
/// All UI state (search open flag, query string, active filter) is ephemeral
/// [State] — no Riverpod providers are created for it.
///
/// The [FloatingActionButton] (`key: ValueKey('medsAddFab')`) opens
/// [AddMedicationModal] via [_openAddMedicationModal].
class MedsScreen extends ConsumerStatefulWidget {
  /// Creates the meds list screen.
  const MedsScreen({super.key});

  @override
  ConsumerState<MedsScreen> createState() => _MedsScreenState();
}

class _MedsScreenState extends ConsumerState<MedsScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final AnimationController _searchAnim;
  late final CurvedAnimation _searchCurve;
  late final Animation<Offset> _slideAnim;
  late final FocusNode _searchFocus;

  String _query = '';
  MedsFilter _filter = MedsFilter.all;
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocus = FocusNode();
    _searchAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _searchCurve = CurvedAnimation(parent: _searchAnim, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(_searchCurve);
  }

  @override
  void dispose() {
    _searchCurve.dispose();
    _searchAnim.dispose();
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openSearch() {
    if (_searchAnim.isAnimating) return;
    setState(() {
      _searchOpen = true;
    });
    _searchAnim.forward().then((_) {
      if (!mounted) return;
      _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    _searchAnim.reverse();
    _searchController.clear();
    setState(() {
      _query = '';
      _searchOpen = false;
    });
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value;
    });
  }

  void _onFilterSelected(MedsFilter filter) {
    setState(() {
      _filter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncValue<List<Medication>> medicationsAsync =
        ref.watch(medicationsListProvider);

    final bool queryActive = _query.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: FadeTransition(
          opacity: ReverseAnimation(_searchAnim),
          child: Text(l10n.medsListTitle),
        ),
        actions: [
          FadeTransition(
            opacity: ReverseAnimation(_searchAnim),
            child: IgnorePointer(
              ignoring: _searchOpen,
              child: IconButton(
                icon: const Icon(LucideIcons.search),
                tooltip: l10n.medsListSearchTooltip,
                onPressed: _openSearch,
              ),
            ),
          ),
        ],
        flexibleSpace: SlideTransition(
          position: _slideAnim,
          child: IgnorePointer(
            ignoring: !_searchOpen,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Material(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(LucideIcons.search, size: 20),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          onChanged: _onQueryChanged,
                          decoration: InputDecoration(
                            hintText: l10n.medsListSearchHint,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: _closeSearch,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _FilterChipRow(
            selected: _filter,
            onSelected: _onFilterSelected,
          ),
          Expanded(
            child: medicationsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace st) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
              data: (meds) {
                final DateTime now = clock.now();
                final MedsListView view = buildMedsListView(
                  meds: meds,
                  now: now,
                  filter: _filter,
                  query: _query,
                );

                if (view.totalCount == 0) {
                  return _EmptyState(
                    title: l10n.medsListEmptyTitle,
                    body: l10n.medsListEmptyBody,
                  );
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 88),
                  children: <Widget>[
                    MedicationSection(
                      title: l10n.medsListSectionContinuous,
                      items: view.continuous,
                      queryActive: queryActive,
                      onTapItem: (med) =>
                          _openEditMedicationModal(context, med),
                    ),
                    const SizedBox(height: 8),
                    MedicationSection(
                      title: l10n.medsListSectionCourse,
                      items: view.course,
                      queryActive: queryActive,
                      onTapItem: (med) =>
                          _openEditMedicationModal(context, med),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('medsAddFab'),
        onPressed: () => _openAddMedicationModal(context),
        tooltip: l10n.medsAddFabTooltip,
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}

/// Row of [FilterChip]s for switching between [MedsFilter] values.
///
/// Renders two chips — "All" and "Active" — aligned to the leading edge of the
/// screen with horizontal padding and a minimum 48 dp tap target.
class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.selected,
    required this.onSelected,
  });

  final MedsFilter selected;
  final void Function(MedsFilter) onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 8,
        children: <Widget>[
          _buildChip(
            context: context,
            cs: cs,
            label: l10n.medsListFilterAll,
            isSelected: selected == MedsFilter.all,
            onTap: () => onSelected(MedsFilter.all),
          ),
          _buildChip(
            context: context,
            cs: cs,
            label: l10n.medsListFilterActive,
            isSelected: selected == MedsFilter.active,
            onTap: () => onSelected(MedsFilter.active),
          ),
        ],
      ),
    );
  }

  /// Builds a stadium pill [FilterChip] matching the `.f-chip` design spec.
  ///
  /// Selected state: solid [ColorScheme.primary] background, white
  /// ([ColorScheme.onPrimary]) label at weight 500. Unselected state:
  /// [ColorScheme.secondaryContainer] background, [ColorScheme.onSecondaryContainer]
  /// label at weight 400. No border, no checkmark.
  FilterChip _buildChip({
    required BuildContext context,
    required ColorScheme cs,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          color: isSelected ? cs.onPrimary : cs.onSecondaryContainer,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      shape: const StadiumBorder(),
      showCheckmark: false,
      backgroundColor: cs.secondaryContainer,
      selectedColor: cs.primary,
      side: BorderSide.none,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

/// Centered empty-state widget shown when no medications have been added.
///
/// Displays a [title] in [TextTheme.titleMedium] and a [body] subtitle in
/// [TextTheme.bodyMedium], both muted with [ColorScheme.onSurfaceVariant].
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              textAlign: TextAlign.center,
              style: (tt.titleMedium ?? const TextStyle()).copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: (tt.bodyMedium ?? const TextStyle()).copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the Add-medication modal as a full-screen route.
///
/// Uses `rootNavigator: true` so the modal is pushed onto the top-level
/// navigator (above the [StatefulShellRoute] in `app_router.dart`),
/// covering the [AppShell]'s [AppBottomNav]. The push uses
/// `MaterialPageRoute(fullscreenDialog: true, ...)` which gives a
/// modal slide-up transition.
void _openAddMedicationModal(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const AddMedicationModal(),
    ),
  );
}

/// Opens the Edit-medication modal pre-filled with [medication].
///
/// Mirrors [_openAddMedicationModal] exactly — same root navigator, same
/// full-screen dialog transition — but passes [medication] as the [initial]
/// argument to [AddMedicationModal] so the form fields are pre-populated for
/// editing.
void _openEditMedicationModal(BuildContext context, Medication medication) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => AddMedicationModal(initial: medication),
    ),
  );
}
