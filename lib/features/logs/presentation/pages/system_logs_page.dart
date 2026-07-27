import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/domain/models/note.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../../core/widgets/custom_card.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';

enum NoteViewMode {
  list,
  create,
  detail,
}

class SystemLogsPage extends StatefulWidget {
  const SystemLogsPage({super.key});

  @override
  State<SystemLogsPage> createState() => _SystemLogsPageState();
}

class _SystemLogsPageState extends State<SystemLogsPage> {
  final TextEditingController _searchController = TextEditingController();
  
  // View state management
  NoteViewMode _viewMode = NoteViewMode.list;
  Note? _activeNote;

  // New Note Form controllers & state
  final TextEditingController _newTitleController = TextEditingController();
  final TextEditingController _newFolderController = TextEditingController();
  String _selectedStructure = 'text'; // 'text' or 'checklist'
  String _selectedFolder = '';

  // Active Note Editor controllers
  final TextEditingController _editorTitleController = TextEditingController();
  final TextEditingController _editorContentController = TextEditingController();
  final TextEditingController _newSubtaskController = TextEditingController();

  NotesLoaded? _latestState;

  @override
  void dispose() {
    _searchController.dispose();
    _newTitleController.dispose();
    _newFolderController.dispose();
    _editorTitleController.dispose();
    _editorContentController.dispose();
    _newSubtaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<NotesBloc, NotesState>(
      builder: (context, state) {
        if (state is NotesLoaded) {
          _latestState = state;
          // Keep activeNote synced if editing
          if (_activeNote != null) {
            final updated = state.notes.where((n) => n.id == _activeNote!.id).firstOrNull;
            if (updated != null) {
              _activeNote = updated;
            }
          }
        }

        final isWide = !ResponsiveLayout.isMobile(context);

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: isWide ? 1100.0 : 600.0),
                  child: _buildCurrentView(theme, context),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentView(ThemeData theme, BuildContext context) {
    switch (_viewMode) {
      case NoteViewMode.create:
        return _buildNewNoteView(theme, context);
      case NoteViewMode.detail:
        return _buildNoteDetailView(theme, context);
      case NoteViewMode.list:
      default:
        return _buildNotesListView(theme, context);
    }
  }

  // ==========================================
  // VIEW 1: MAIN NOTES LIST & OVERVIEW
  // ==========================================
  Widget _buildNotesListView(ThemeData theme, BuildContext context) {
    final totalRecords = _latestState?.totalStoredCount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notes',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: AppThemeTokens.of(context).contentSecondary,
                    fontSize: 26.0,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  '$totalRecords STORED RECORDS',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppThemeTokens.of(context).contentTertiary,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.0,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _newTitleController.clear();
                  _newFolderController.clear();
                  _selectedFolder = '';
                  _selectedStructure = 'text';
                  _viewMode = NoteViewMode.create;
                });
              },
              icon: const Icon(LucideIcons.plus, size: 18.0),
              label: Text(
                'New Note',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14.0),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20.0),

        // Search Bar
        _buildSearchBar(theme, context),
        const SizedBox(height: 16.0),

        // Category Filter Chips
        _buildFolderFilterChips(theme, context),
        const SizedBox(height: 24.0),

        // Pinned Section
        _buildPinnedSection(theme, context),
        const SizedBox(height: 24.0),

        // All Notes Section
        _buildAllNotesSection(theme, context),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme, BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: tokens.borderDefault),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 10.0, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Icon(LucideIcons.search, color: tokens.iconSubtle, size: 20.0),
          const SizedBox(width: 10.0),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                context.read<NotesBloc>().add(FilterNotesEvent(query: query));
              },
              style: GoogleFonts.plusJakartaSans(color: tokens.contentSecondary, fontSize: 14.0),
              decoration: InputDecoration(
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Search through records...',
                hintStyle: GoogleFonts.plusJakartaSans(color: tokens.iconSubtle, fontSize: 14.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderFilterChips(ThemeData theme, BuildContext context) {
    final notes = _latestState?.notes ?? [];
    final userFolders = notes
        .map((n) => n.folder)
        .where((f) => f.trim().isNotEmpty)
        .toSet()
        .toList();
    userFolders.sort();

    final categories = ['ALL LOGS', ...userFolders];
    final selectedCat = _latestState?.selectedCategory ?? 'ALL LOGS';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = cat == selectedCat;
          final isFolder = cat != 'ALL LOGS';

          final tokens = AppThemeTokens.of(context);
          return Container(
            margin: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                context.read<NotesBloc>().add(FilterNotesEvent(category: cat));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : tokens.filterChipBg,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : tokens.filterChipBorder,
                  ),
                ),
                child: Row(
                  children: [
                    if (isFolder) ...[
                      Icon(
                        LucideIcons.folder,
                        size: 14.0,
                        color: isSelected ? Colors.white : tokens.iconSubtle,
                      ),
                      const SizedBox(width: 6.0),
                    ],
                    Text(
                      cat,
                      style: GoogleFonts.plusJakartaSans(
                        color: isSelected ? Colors.white : tokens.filterChipText,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPinnedSection(ThemeData theme, BuildContext context) {
    final pinned = _latestState?.pinnedNotes ?? [];
    if (pinned.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.pin, color: AppColors.primary, size: 14.0),
            const SizedBox(width: 6.0),
            Text(
              'PINNED LOGS',
              style: GoogleFonts.plusJakartaSans(
                color: AppThemeTokens.of(context).iconSubtle,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                fontSize: 9.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        Column(
          children: pinned.map((note) => _buildNoteCardItem(theme, context, note)).toList(),
        ),
      ],
    );
  }

  Widget _buildAllNotesSection(ThemeData theme, BuildContext context) {
    final notes = _latestState?.notes ?? [];
    if (notes.isEmpty) {
      return CustomCard(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              const Icon(LucideIcons.fileText, size: 48.0, color: Color(0xFF8C97AB)),
              const SizedBox(height: 12.0),
              Text(
                'No Records Found',
                style: GoogleFonts.plusJakartaSans(fontSize: 16.0, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Tap "New Note" to forge your first note or checklist.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF8C97AB), fontSize: 13.0),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ALL LOGS',
          style: GoogleFonts.plusJakartaSans(
            color: AppThemeTokens.of(context).iconSubtle,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            fontSize: 9.0,
          ),
        ),
        const SizedBox(height: 12.0),
        Column(
          children: notes.map((note) => _buildNoteCardItem(theme, context, note)).toList(),
        ),
      ],
    );
  }

  Widget _buildNoteCardItem(ThemeData theme, BuildContext context, Note note) {
    final isChecklist = note.type == 'checklist' || note.checklist.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _activeNote = note;
            _editorTitleController.text = note.title;
            _editorContentController.text = note.content;
            _viewMode = NoteViewMode.detail;
          });
        },
        borderRadius: BorderRadius.circular(16.0),
        child: CustomCard(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42.0,
                height: 42.0,
                decoration: BoxDecoration(
                  color: isChecklist ? AppColors.primary.withValues(alpha: 0.1) : AppThemeTokens.of(context).surfaceChip,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  isChecklist ? LucideIcons.checkSquare : LucideIcons.fileText,
                  color: isChecklist ? AppColors.primary : AppThemeTokens.of(context).iconSubtle,
                  size: 20.0,
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          note.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w800,
                            color: AppThemeTokens.of(context).contentSecondary,
                          ),
                        ),
                        if (note.pinned) ...[
                          const SizedBox(width: 6.0),
                          const Icon(LucideIcons.pin, color: AppColors.primary, size: 14.0),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      isChecklist
                          ? '${note.checklist.where((i) => i.completed).length}/${note.checklist.length} sub-tasks completed'
                          : (note.content.isEmpty ? 'Empty note...' : note.content),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppThemeTokens.of(context).iconSubtle,
                        fontSize: 13.0,
                      ),
                    ),
                    if (note.folder.isNotEmpty) ...[
                      const SizedBox(height: 8.0),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                        decoration: BoxDecoration(
                          color: AppThemeTokens.of(context).surfaceChip,
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          note.folder.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            color: AppThemeTokens.of(context).contentSecondary,
                            fontSize: 9.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      note.pinned ? LucideIcons.pin : LucideIcons.pin,
                      color: note.pinned ? AppColors.primary : const Color(0xFFCBD5E1),
                      size: 18.0,
                    ),
                    onPressed: () {
                      context.read<NotesBloc>().add(TogglePinNoteEvent(note.id));
                    },
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, color: Color(0xFFCBD5E1), size: 18.0),
                    onPressed: () {
                      context.read<NotesBloc>().add(DeleteNoteEvent(note.id));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // VIEW 2: NEW NOTE FORM OVERLAY (Screenshot 1)
  // ==========================================
  Widget _buildNewNoteView(ThemeData theme, BuildContext context) {
    final existingFolders = (_latestState?.notes ?? [])
        .map((n) => n.folder)
        .where((f) => f.isNotEmpty)
        .toSet()
        .toList();
    if (!existingFolders.contains('Trading')) existingFolders.add('Trading');
    if (!existingFolders.contains('Collage')) existingFolders.add('Collage');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row: Back button + New Note title
        Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _viewMode = NoteViewMode.list;
                });
              },
              child: Container(
                width: 36.0,
                height: 36.0,
                decoration: BoxDecoration(
                  color: AppThemeTokens.of(context).surfaceCard,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: AppThemeTokens.of(context).borderDefault),
                ),
                child: Icon(LucideIcons.arrowLeft, color: AppThemeTokens.of(context).iconDefault, size: 18.0),
              ),
            ),
            const SizedBox(width: 14.0),
            Text(
              'New Note',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: AppThemeTokens.of(context).contentSecondary,
                fontSize: 24.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24.0),

        // Main White Form Container (Screenshot 1)
        Container(
          padding: const EdgeInsets.all(28.0),
          decoration: BoxDecoration(
            color: AppThemeTokens.of(context).surfaceCard,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: AppThemeTokens.of(context).borderDefault),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 16.0, offset: Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TITLE
              _buildEyebrowLabel('TITLE'),
              const SizedBox(height: 6.0),
              TextField(
                controller: _newTitleController,
                style: GoogleFonts.plusJakartaSans(fontSize: 14.0, color: AppThemeTokens.of(context).contentSecondary),
                decoration: InputDecoration(
                  hintText: 'Give your note a title...',
                  hintStyle: GoogleFonts.plusJakartaSans(color: AppThemeTokens.of(context).iconSubtle, fontSize: 14.0),
                  filled: false,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: AppThemeTokens.of(context).borderDefault),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: AppThemeTokens.of(context).borderDefault),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),

              // STRUCTURE
              _buildEyebrowLabel('STRUCTURE'),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    child: _buildStructureCard(
                      title: 'Free Text',
                      icon: LucideIcons.fileText,
                      typeKey: 'text',
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: _buildStructureCard(
                      title: 'Checklist',
                      icon: LucideIcons.checkSquare,
                      typeKey: 'checklist',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),

              // SECTION / FOLDER (OPTIONAL)
              _buildEyebrowLabel('SECTION / FOLDER (OPTIONAL)'),
              const SizedBox(height: 8.0),
              TextField(
                controller: _newFolderController,
                style: GoogleFonts.plusJakartaSans(fontSize: 14.0, color: AppThemeTokens.of(context).contentSecondary),
                decoration: InputDecoration(
                  hintText: 'Or type a new folder name...',
                  hintStyle: GoogleFonts.plusJakartaSans(color: AppThemeTokens.of(context).iconSubtle, fontSize: 13.0),
                  suffixIcon: Icon(LucideIcons.folderPlus, size: 18.0, color: AppThemeTokens.of(context).iconSubtle),
                  filled: false,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: AppThemeTokens.of(context).borderDefault),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: AppThemeTokens.of(context).borderDefault),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 28.0),

              // Create Note Button
              SizedBox(
                width: double.infinity,
                height: 52.0,
                child: ElevatedButton(
                  onPressed: () => _createNote(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Create Note',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStructureCard({
    required String title,
    required IconData icon,
    required String typeKey,
  }) {
    final isActive = _selectedStructure == typeKey;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStructure = typeKey;
        });
      },
      child: Builder(
        builder: (ctx) {
          final tokens = AppThemeTokens.of(ctx);
          return Container(
            height: 76.0,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withValues(alpha: 0.1) : tokens.surfaceChip,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: isActive ? AppColors.primary : Colors.transparent,
                width: isActive ? 2.0 : 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 22.0,
                  color: isActive ? AppColors.primary : tokens.iconSubtle,
                ),
                const SizedBox(height: 4.0),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: isActive ? AppColors.primary : tokens.contentSecondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // VIEW 3: NOTE DETAIL & EDITOR (Screenshots 2 & 3)
  // ==========================================
  Widget _buildNoteDetailView(ThemeData theme, BuildContext context) {
    final note = _activeNote;
    if (note == null) return const SizedBox.shrink();

    final isChecklist = note.type == 'checklist' || note.checklist.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    _saveActiveNote(context);
                    setState(() {
                      _viewMode = NoteViewMode.list;
                    });
                  },
                  child: Builder(
                    builder: (ctx) {
                      final tk = AppThemeTokens.of(ctx);
                      return Container(
                        width: 36.0,
                        height: 36.0,
                        decoration: BoxDecoration(
                          color: tk.surfaceCard,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(color: tk.borderDefault),
                        ),
                        child: Icon(LucideIcons.arrowLeft, color: tk.iconDefault, size: 18.0),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 300.0,
                      child: TextField(
                        controller: _editorTitleController,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          color: AppThemeTokens.of(context).contentSecondary,
                          fontSize: 22.0,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Row(
                      children: [
                        Icon(LucideIcons.clock, size: 12.0, color: AppThemeTokens.of(context).iconSubtle),
                        const SizedBox(width: 4.0),
                        Text(
                          'JUST NOW',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppThemeTokens.of(context).iconSubtle,
                            fontWeight: FontWeight.w800,
                            fontSize: 9.0,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Row(
                          children: [
                            Icon(LucideIcons.folder, size: 12.0, color: AppThemeTokens.of(context).iconSubtle),
                            const SizedBox(width: 4.0),
                            Text(
                              note.folder.isEmpty ? 'ADD TO FOLDER ∨' : '${note.folder.toUpperCase()} ∨',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppThemeTokens.of(context).iconSubtle,
                                fontWeight: FontWeight.w800,
                                fontSize: 9.0,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // Top Right Pin & Delete Buttons
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    context.read<NotesBloc>().add(TogglePinNoteEvent(note.id));
                  },
                  child: Container(
                    width: 36.0,
                    height: 36.0,
                    decoration: BoxDecoration(
                      color: note.pinned ? AppColors.primary.withValues(alpha: 0.1) : AppThemeTokens.of(context).surfaceCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppThemeTokens.of(context).borderDefault),
                    ),
                    child: Icon(
                      LucideIcons.pin,
                      color: note.pinned ? AppColors.primary : AppThemeTokens.of(context).iconSubtle,
                      size: 16.0,
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                GestureDetector(
                  onTap: () {
                    context.read<NotesBloc>().add(DeleteNoteEvent(note.id));
                    setState(() {
                      _viewMode = NoteViewMode.list;
                    });
                  },
                  child: Container(
                    width: 36.0,
                    height: 36.0,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.trash2, color: Color(0xFFEF4444), size: 16.0),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20.0),

        if (!isChecklist) ...[
          // Free Text Rich Format Toolbar (Screenshot 2)
          _buildRichFormatToolbar(),
          const SizedBox(height: 16.0),

          // Rich Text Body Card
          Container(
            constraints: const BoxConstraints(minHeight: 360.0),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: AppThemeTokens.of(context).surfaceCard,
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: AppThemeTokens.of(context).borderDefault),
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 16.0, offset: Offset(0, 6)),
              ],
            ),
            child: TextField(
              controller: _editorContentController,
              maxLines: null,
              onChanged: (newVal) {
                _saveEditorContent(newVal);
              },
              style: GoogleFonts.plusJakartaSans(
                color: AppThemeTokens.of(context).contentSecondary,
                fontSize: 14.0,
                height: 1.6,
              ),
              decoration: InputDecoration(
                filled: false,
                fillColor: Colors.transparent,
                hintText: 'Start forging your thoughts with rich formats...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: AppThemeTokens.of(context).borderStrong,
                  fontSize: 14.0,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 20.0),

          // Footer Link: Convert to Checklist
          GestureDetector(
            onTap: () {
              final updated = note.copyWith(type: 'checklist');
              context.read<NotesBloc>().add(UpdateNoteEvent(updated));
              setState(() {
                _activeNote = updated;
              });
            },
            child: Row(
              children: [
                Icon(LucideIcons.checkSquare, size: 14.0, color: AppThemeTokens.of(context).iconSubtle),
                const SizedBox(width: 6.0),
                Text(
                  'CONVERT TO OPERATIONAL CHECKLIST',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppThemeTokens.of(context).iconSubtle,
                    fontWeight: FontWeight.w800,
                    fontSize: 9.0,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Checklist Mode View (Screenshot 4 design)
          Builder(
            builder: (ctx) {
              final tokens = AppThemeTokens.of(ctx);
              final checklist = List<ChecklistItem>.from(note.checklist);

              // Sort checklist: incomplete items first, completed items moved to last
              checklist.sort((a, b) {
                if (a.completed == b.completed) return 0;
                return a.completed ? 1 : -1;
              });

              final activeCount = checklist.where((i) => !i.completed).length;
              final totalCount = checklist.length;
              final progress = totalCount > 0 ? ((totalCount - activeCount) / totalCount) : 0.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SYNCHRONIZATION Header & Progress Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildEyebrowLabel('SYNCHRONIZATION'),
                      Text(
                        '$activeCount/$totalCount Units Active',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6.0),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6.0,
                      backgroundColor: tokens.surfaceInput,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Sub-tasks List (Sorted: Active first, Completed moved to last)
                  ...checklist.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10.0),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      decoration: BoxDecoration(
                        color: tokens.surfaceCard,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: tokens.borderDefault),
                        boxShadow: const [
                          BoxShadow(color: Color(0x05000000), blurRadius: 8.0, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              final updatedChecklist = note.checklist.map((i) {
                                if (i.id == item.id) {
                                  return i.copyWith(completed: !i.completed);
                                }
                                return i;
                              }).toList();
                              final updatedNote = note.copyWith(checklist: updatedChecklist);
                              context.read<NotesBloc>().add(UpdateNoteEvent(updatedNote));
                              setState(() {
                                _activeNote = updatedNote;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 26.0,
                              height: 26.0,
                              decoration: BoxDecoration(
                                color: item.completed ? AppColors.primary : tokens.surfaceInput,
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(
                                  color: item.completed ? AppColors.primary : tokens.borderDefault,
                                  width: 1.5,
                                ),
                              ),
                              child: item.completed
                                  ? const Icon(LucideIcons.check, size: 16.0, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 14.0),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey(item.id),
                              initialValue: item.text,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.0,
                                fontWeight: item.completed ? FontWeight.w500 : FontWeight.w700,
                                color: item.completed ? tokens.iconSubtle : tokens.contentSecondary,
                                decoration: item.completed ? TextDecoration.lineThrough : null,
                              ),
                              decoration: const InputDecoration(
                                filled: false,
                                fillColor: Colors.transparent,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (newVal) {
                                final updatedChecklist = note.checklist.map((i) {
                                  if (i.id == item.id) {
                                    return i.copyWith(text: newVal);
                                  }
                                  return i;
                                }).toList();
                                final updatedNote = note.copyWith(checklist: updatedChecklist);
                                context.read<NotesBloc>().add(UpdateNoteEvent(updatedNote));
                                _activeNote = updatedNote;
                              },
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              final updatedChecklist = note.checklist.where((i) => i.id != item.id).toList();
                              final updatedNote = note.copyWith(checklist: updatedChecklist);
                              context.read<NotesBloc>().add(UpdateNoteEvent(updatedNote));
                              setState(() {
                                _activeNote = updatedNote;
                              });
                            },
                            child: Icon(LucideIcons.x, size: 18.0, color: tokens.iconSubtle.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12.0),

                  // Bottom Add Sub-task Input Container (Screenshot 4 style)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    decoration: BoxDecoration(
                      color: tokens.surfaceCard,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: tokens.borderDefault,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _addSubtask(context),
                          child: Container(
                            width: 26.0,
                            height: 26.0,
                            decoration: BoxDecoration(
                              color: tokens.surfaceInput,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: tokens.borderDefault),
                            ),
                            child: Icon(LucideIcons.plus, size: 16.0, color: tokens.iconSubtle),
                          ),
                        ),
                        const SizedBox(width: 14.0),
                        Expanded(
                          child: TextField(
                            controller: _newSubtaskController,
                            onSubmitted: (_) => _addSubtask(context),
                            style: GoogleFonts.plusJakartaSans(fontSize: 14.0, color: tokens.contentSecondary),
                            decoration: InputDecoration(
                              filled: false,
                              fillColor: Colors.transparent,
                              hintText: 'Add sub-task...',
                              hintStyle: GoogleFonts.plusJakartaSans(color: tokens.iconSubtle, fontSize: 14.0),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Footer Link: Convert to Free Text
                  GestureDetector(
                    onTap: () {
                      final updated = note.copyWith(type: 'text');
                      context.read<NotesBloc>().add(UpdateNoteEvent(updated));
                      setState(() {
                        _activeNote = updated;
                      });
                    },
                    child: Row(
                      children: [
                        Icon(LucideIcons.fileText, size: 14.0, color: AppThemeTokens.of(context).iconSubtle),
                        const SizedBox(width: 6.0),
                        Text(
                          'CONVERT TO FREE TEXT NOTE',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppThemeTokens.of(context).iconSubtle,
                            fontWeight: FontWeight.w800,
                            fontSize: 9.0,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  // Formatting Helper Methods
  void _saveEditorContent(String newText) {
    if (_activeNote != null) {
      final updated = _activeNote!.copyWith(content: newText);
      _activeNote = updated;
      context.read<NotesBloc>().add(UpdateNoteEvent(updated));
    }
  }

  void _insertFormatting(String prefix, [String suffix = '']) {
    final text = _editorContentController.text;
    final selection = _editorContentController.selection;
    String newText;
    int newCursor;

    if (!selection.isValid || selection.isCollapsed || selection.baseOffset < 0) {
      final cursor = (selection.isValid && selection.baseOffset >= 0) ? selection.baseOffset : text.length;
      final safeCursor = cursor > text.length ? text.length : cursor;
      newText = text.replaceRange(safeCursor, safeCursor, '$prefix$suffix');
      newCursor = safeCursor + prefix.length;
    } else {
      final start = selection.start;
      final end = selection.end;
      final selectedText = text.substring(start, end);
      final replacement = '$prefix$selectedText$suffix';
      newText = text.replaceRange(start, end, replacement);
      newCursor = start + prefix.length + selectedText.length + suffix.length;
    }

    _editorContentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    _saveEditorContent(newText);
    if (mounted) setState(() {});
  }

  void _insertLinePrefix(String linePrefix) {
    final text = _editorContentController.text;
    final selection = _editorContentController.selection;
    final cursor = (selection.isValid && selection.baseOffset >= 0) ? selection.baseOffset : text.length;
    final safeCursor = cursor > text.length ? text.length : cursor;
    final newText = text.replaceRange(safeCursor, safeCursor, '\n$linePrefix');
    final newCursor = safeCursor + 1 + linePrefix.length;

    _editorContentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    _saveEditorContent(newText);
    if (mounted) setState(() {});
  }

  // Formatting Toolbar Widget (Screenshot 2)
  Widget _buildRichFormatToolbar() {
    return Builder(
      builder: (ctx) {
        final tokens = AppThemeTokens.of(ctx);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: tokens.surfaceCard,
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: tokens.borderDefault),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildToolbarIcon(LucideIcons.undo2, onTap: () {
                  if (_editorContentController.text.isNotEmpty) {
                    _editorContentController.clear();
                  }
                }),
                _buildToolbarIcon(LucideIcons.redo2, onTap: () {}),
                _buildToolbarDivider(),
                _buildToolbarTextBtn('H1', onTap: () => _insertLinePrefix('# ')),
                _buildToolbarTextBtn('H2', onTap: () => _insertLinePrefix('## ')),
                _buildToolbarTextBtn('H3', onTap: () => _insertLinePrefix('### ')),
                _buildToolbarTextBtn('P', onTap: () => _insertLinePrefix('')),
                _buildToolbarDivider(),
                _buildToolbarTextBtn('B', bold: true, onTap: () => _insertFormatting('**', '**')),
                _buildToolbarTextBtn('I', italic: true, onTap: () => _insertFormatting('*', '*')),
                _buildToolbarTextBtn('U', underline: true, onTap: () => _insertFormatting('<u>', '</u>')),
                _buildToolbarTextBtn('S', strikethrough: true, onTap: () => _insertFormatting('~~', '~~')),
                _buildToolbarDivider(),
                _buildToolbarIcon(LucideIcons.alignLeft, onTap: () {}),
                _buildToolbarIcon(LucideIcons.alignCenter, onTap: () {}),
                _buildToolbarIcon(LucideIcons.alignRight, onTap: () {}),
                _buildToolbarDivider(),
                _buildToolbarIcon(LucideIcons.list, onTap: () => _insertLinePrefix('• ')),
                _buildToolbarIcon(LucideIcons.listOrdered, onTap: () => _insertLinePrefix('1. ')),
                _buildToolbarIcon(LucideIcons.checkSquare, onTap: () => _insertLinePrefix('[ ] ')),
                _buildToolbarDivider(),
                _buildToolbarIcon(LucideIcons.quote, onTap: () => _insertLinePrefix('> ')),
                _buildToolbarIcon(LucideIcons.code, onTap: () => _insertFormatting('`', '`')),
                _buildToolbarDivider(),
                _buildToolbarIcon(LucideIcons.palette, onTap: () => _insertFormatting('<color>', '</color>')),
                _buildToolbarIcon(LucideIcons.link, onTap: () => _insertFormatting('[', '](url)')),
                _buildToolbarIcon(LucideIcons.type, onTap: () {}),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolbarIcon(IconData icon, {VoidCallback? onTap}) {
    return Builder(
      builder: (ctx) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
          child: Icon(icon, size: 16.0, color: AppThemeTokens.of(ctx).iconSubtle),
        ),
      ),
    );
  }

  Widget _buildToolbarTextBtn(String label, {bool bold = false, bool italic = false, bool underline = false, bool strikethrough = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.0,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            decoration: underline
                ? TextDecoration.underline
                : (strikethrough ? TextDecoration.lineThrough : TextDecoration.none),
            color: AppThemeTokens.of(context).contentSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarDivider() {
    return Builder(
      builder: (ctx) => Container(
        height: 14.0,
        width: 1.0,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        color: AppThemeTokens.of(ctx).borderDefault,
      ),
    );
  }

  Widget _buildEyebrowLabel(String text) {
    return Builder(
      builder: (ctx) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          color: AppThemeTokens.of(ctx).iconSubtle,
          fontWeight: FontWeight.w800,
          fontSize: 8.5,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  void _createNote(BuildContext context) {
    final title = _newTitleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a note title.')),
      );
      return;
    }

    final folder = _newFolderController.text.trim().isEmpty
        ? (_selectedFolder.isEmpty ? 'General' : _selectedFolder)
        : _newFolderController.text.trim();

    final newNote = Note(
      id: UuidGenerator.generate(),
      title: title,
      content: '',
      type: _selectedStructure,
      checklist: const [],
      tags: [folder.toUpperCase()],
      folder: folder,
      createdAt: DateTime.now().toIso8601String(),
    );

    context.read<NotesBloc>().add(CreateNoteEvent(newNote));

    setState(() {
      _activeNote = newNote;
      _editorTitleController.text = newNote.title;
      _editorContentController.text = newNote.content;
      _viewMode = NoteViewMode.detail;
    });
  }

  void _saveActiveNote(BuildContext context) {
    final note = _activeNote;
    if (note == null) return;

    final updated = note.copyWith(
      title: _editorTitleController.text.trim().isEmpty ? 'Untitled Note' : _editorTitleController.text.trim(),
      content: _editorContentController.text,
    );

    context.read<NotesBloc>().add(UpdateNoteEvent(updated));
  }

  void _addSubtask(BuildContext context) {
    final text = _newSubtaskController.text.trim();
    if (text.isEmpty || _activeNote == null) return;

    final newItem = ChecklistItem(
      id: UuidGenerator.generate(),
      text: text,
      completed: false,
    );

    final updatedChecklist = [..._activeNote!.checklist, newItem];
    final updatedNote = _activeNote!.copyWith(checklist: updatedChecklist);

    context.read<NotesBloc>().add(UpdateNoteEvent(updatedNote));
    _newSubtaskController.clear();
    setState(() {
      _activeNote = updatedNote;
    });
  }
}
