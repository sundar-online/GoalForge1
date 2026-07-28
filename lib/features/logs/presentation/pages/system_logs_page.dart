import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final GlobalKey<_NoteEditorState> _noteEditorKey = GlobalKey<_NoteEditorState>();

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
          // Free Text Rich Format Toolbar
          _buildRichFormatToolbar(),
          const SizedBox(height: 16.0),

          // Rich Note Editor
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
            child: Builder(
              builder: (ctx) {
                final tokens = AppThemeTokens.of(ctx);
                return _NoteEditor(
                  key: _noteEditorKey,
                  masterController: _editorContentController,
                  hintText: 'Start typing your note...',
                  contentColor: tokens.contentPrimary,
                  hintColor: tokens.borderStrong,
                  onChanged: _saveEditorContent,
                );
              },
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

  // Formatting Toolbar
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
                _buildToolbarIcon(LucideIcons.undo2, onTap: () => _noteEditorKey.currentState?.undo()),
                _buildToolbarIcon(LucideIcons.redo2, onTap: () {}),
                _buildToolbarDivider(),
                _buildToolbarTextBtn('H1', onTap: () => _noteEditorKey.currentState?.applyLineType('h1')),
                _buildToolbarTextBtn('H2', onTap: () => _noteEditorKey.currentState?.applyLineType('h2')),
                _buildToolbarTextBtn('H3', onTap: () => _noteEditorKey.currentState?.applyLineType('h3')),
                _buildToolbarTextBtn('P',  onTap: () => _noteEditorKey.currentState?.applyLineType('p')),
                _buildToolbarDivider(),
                _buildToolbarTextBtn('B', bold: true,          onTap: () => _noteEditorKey.currentState?.applyInlineFormat('**', '**')),
                _buildToolbarTextBtn('I', italic: true,        onTap: () => _noteEditorKey.currentState?.applyInlineFormat('*', '*')),
                _buildToolbarTextBtn('U', underline: true,     onTap: () => _noteEditorKey.currentState?.applyInlineFormat('<u>', '</u>')),
                _buildToolbarTextBtn('S', strikethrough: true, onTap: () => _noteEditorKey.currentState?.applyInlineFormat('~~', '~~')),
                _buildToolbarDivider(),
                _buildToolbarIcon(LucideIcons.alignLeft,    onTap: () {}),
                _buildToolbarIcon(LucideIcons.alignCenter,  onTap: () {}),
                _buildToolbarIcon(LucideIcons.alignRight,   onTap: () {}),
                _buildToolbarDivider(),
                _buildToolbarIcon(LucideIcons.list,         onTap: () => _noteEditorKey.currentState?.applyLineType('bullet')),
                _buildToolbarIcon(LucideIcons.listOrdered,  onTap: () => _noteEditorKey.currentState?.applyLineType('ordered')),
                _buildToolbarIcon(LucideIcons.checkSquare,  onTap: () => _noteEditorKey.currentState?.applyLineType('checkbox')),
                _buildToolbarDivider(),
                _buildToolbarIcon(LucideIcons.quote, onTap: () => _noteEditorKey.currentState?.applyLineType('quote')),
                _buildToolbarIcon(LucideIcons.code,  onTap: () => _noteEditorKey.currentState?.applyInlineFormat('`', '`')),
                _buildToolbarDivider(),
                _buildToolbarIcon(LucideIcons.link, onTap: () => _noteEditorKey.currentState?.applyInlineFormat('[', '](url)')),
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

// ═══════════════════════════════════════════════════════════════
//  Data model: one logical line in the note editor
// ═══════════════════════════════════════════════════════════════
class _EditorLine {
  String type; // 'h1' | 'h2' | 'h3' | 'p' | 'bullet' | 'ordered' | 'quote' | 'checkbox'
  String content;
  bool checked;

  _EditorLine({this.type = 'p', this.content = '', this.checked = false});

  factory _EditorLine.fromMarkdown(String raw) {
    if (raw.startsWith('### ')) return _EditorLine(type: 'h3', content: raw.substring(4));
    if (raw.startsWith('## '))  return _EditorLine(type: 'h2', content: raw.substring(3));
    if (raw.startsWith('# '))   return _EditorLine(type: 'h1', content: raw.substring(2));
    if (raw.startsWith('> '))   return _EditorLine(type: 'quote', content: raw.substring(2));
    if (raw.startsWith('[x] ')) return _EditorLine(type: 'checkbox', content: raw.substring(4), checked: true);
    if (raw.startsWith('[ ] ')) return _EditorLine(type: 'checkbox', content: raw.substring(4), checked: false);
    if (raw.startsWith('• '))   return _EditorLine(type: 'bullet', content: raw.substring(2));
    if (raw.startsWith('- '))   return _EditorLine(type: 'bullet', content: raw.substring(2));
    if (RegExp(r'^\d+\.\s').hasMatch(raw)) {
      return _EditorLine(type: 'ordered', content: raw.replaceFirst(RegExp(r'^\d+\.\s'), ''));
    }
    return _EditorLine(type: 'p', content: raw);
  }

  String toMarkdown({int orderedIndex = 1}) {
    switch (type) {
      case 'h1':      return '# $content';
      case 'h2':      return '## $content';
      case 'h3':      return '### $content';
      case 'quote':   return '> $content';
      case 'checkbox':return checked ? '[x] $content' : '[ ] $content';
      case 'bullet':  return '• $content';
      case 'ordered': return '$orderedIndex. $content';
      default:        return content;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  Line-based rich note editor
//  — Each logical line is a separate TextField with correct style
//  — Enter  → new paragraph line below cursor
//  — Backspace at start → merge with previous line
//  — Toolbar calls applyLineType / applyInlineFormat / undo
// ═══════════════════════════════════════════════════════════════
class _NoteEditor extends StatefulWidget {
  final TextEditingController masterController;
  final String hintText;
  final Color contentColor;
  final Color hintColor;
  final ValueChanged<String>? onChanged;

  const _NoteEditor({
    super.key,
    required this.masterController,
    required this.hintText,
    required this.contentColor,
    required this.hintColor,
    this.onChanged,
  });

  @override
  _NoteEditorState createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late List<_EditorLine> _lines;
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  int _focusedIndex = 0;
  String _lastMasterText = '';

  // Undo stack — stores markdown snapshots
  final List<String> _history = [];
  int _historyIndex = -1;

  @override
  void initState() {
    super.initState();
    _initFromMarkdown(widget.masterController.text);
    widget.masterController.addListener(_onMasterChanged);
  }

  @override
  void dispose() {
    widget.masterController.removeListener(_onMasterChanged);
    _disposeAll();
    super.dispose();
  }

  void _disposeAll() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
  }

  // ── Parse markdown into lines ──────────────────────────────
  void _initFromMarkdown(String markdown) {
    _lastMasterText = markdown;
    final rawLines = markdown.isEmpty ? [''] : markdown.split('\n');
    _lines = rawLines.map(_EditorLine.fromMarkdown).toList();
    if (_lines.isEmpty) _lines = [_EditorLine()];

    _controllers = _lines
        .map((l) => TextEditingController(text: l.content))
        .toList();
    _focusNodes = List.generate(_lines.length, _makeFocusNode);
  }

  FocusNode _makeFocusNode(int i) {
    final fn = FocusNode();
    fn.addListener(() {
      if (fn.hasFocus && mounted) setState(() => _focusedIndex = i);
    });
    return fn;
  }

  // ── External note switch ───────────────────────────────────
  void _onMasterChanged() {
    final newText = widget.masterController.text;
    if (newText != _lastMasterText) {
      setState(() {
        _disposeAll();
        _initFromMarkdown(newText);
      });
    }
  }

  // ── Save to masterController ───────────────────────────────
  void _save({bool recordHistory = true}) {
    // Sync content from controllers → lines
    for (int i = 0; i < _lines.length && i < _controllers.length; i++) {
      _lines[i].content = _controllers[i].text;
    }

    int ordNum = 1;
    final markdown = _lines.map((l) {
      if (l.type == 'ordered') {
        final s = l.toMarkdown(orderedIndex: ordNum++);
        return s;
      }
      ordNum = 1;
      return l.toMarkdown();
    }).join('\n');

    _lastMasterText = markdown;
    widget.masterController.removeListener(_onMasterChanged);
    widget.masterController.text = markdown;
    widget.masterController.addListener(_onMasterChanged);
    widget.onChanged?.call(markdown);

    if (recordHistory) {
      if (_history.isEmpty || _history.last != markdown) {
        if (_historyIndex < _history.length - 1) {
          _history.removeRange(_historyIndex + 1, _history.length);
        }
        _history.add(markdown);
        if (_history.length > 50) _history.removeAt(0);
        _historyIndex = _history.length - 1;
      }
    }
  }

  // ── Public API called by toolbar ───────────────────────────
  void applyLineType(String type) {
    if (_focusedIndex >= _lines.length) return;
    setState(() => _lines[_focusedIndex].type = type);
    _save();
    // Re-focus the line so the user can keep typing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusedIndex < _focusNodes.length) {
        _focusNodes[_focusedIndex].requestFocus();
      }
    });
  }

  void applyInlineFormat(String prefix, String suffix) {
    if (_focusedIndex >= _controllers.length) return;
    final ctrl = _controllers[_focusedIndex];
    final sel = ctrl.selection;
    if (!sel.isValid) return;
    final text = ctrl.text;
    if (sel.isCollapsed) {
      final newText = text.replaceRange(sel.start, sel.end, '$prefix$suffix');
      ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: sel.start + prefix.length),
      );
    } else {
      final selected = text.substring(sel.start, sel.end);
      final newText = text.replaceRange(sel.start, sel.end, '$prefix$selected$suffix');
      ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
            offset: sel.start + prefix.length + selected.length + suffix.length),
      );
    }
    _lines[_focusedIndex].content = ctrl.text;
    _save();
  }

  void undo() {
    if (_historyIndex <= 0) return;
    _historyIndex--;
    final prev = _history[_historyIndex];
    setState(() {
      _disposeAll();
      _initFromMarkdown(prev);
    });
    _lastMasterText = prev;
    widget.masterController.removeListener(_onMasterChanged);
    widget.masterController.text = prev;
    widget.masterController.addListener(_onMasterChanged);
    widget.onChanged?.call(prev);
  }

  // ── Line editing logic ─────────────────────────────────────
  void _onLineChanged(int index, String value) {
    // Detect Enter (newline inserted by hardware keyboard on some platforms)
    if (value.contains('\n')) {
      final parts = value.split('\n');
      _controllers[index].text = parts[0];
      _controllers[index].selection =
          TextSelection.collapsed(offset: parts[0].length);
      _lines[index].content = parts[0];

      for (int j = 1; j < parts.length; j++) {
        _insertLineAfter(index + j - 1, initialContent: parts[j]);
      }

      final targetIdx = (index + parts.length - 1).clamp(0, _lines.length - 1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (targetIdx < _focusNodes.length) {
          _focusNodes[targetIdx].requestFocus();
          final c = _controllers[targetIdx];
          c.selection = TextSelection.collapsed(offset: c.text.length);
        }
      });
      return;
    }
    _lines[index].content = value;
    _save();
  }

  void _insertLineAfter(int afterIndex, {String initialContent = ''}) {
    setState(() {
      final newLine = _EditorLine(content: initialContent);
      _lines.insert(afterIndex + 1, newLine);

      final newCtrl = TextEditingController(text: initialContent);
      _controllers.insert(afterIndex + 1, newCtrl);

      final idx = afterIndex + 1;
      final newFn = FocusNode();
      newFn.addListener(() {
        if (newFn.hasFocus && mounted) setState(() => _focusedIndex = idx);
      });
      _focusNodes.insert(afterIndex + 1, newFn);
      _focusedIndex = afterIndex + 1;
    });
    _save();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (afterIndex + 1 < _focusNodes.length) {
        _focusNodes[afterIndex + 1].requestFocus();
      }
    });
  }

  void _mergeWithPrevious(int index) {
    if (index <= 0) return;
    setState(() {
      final prevCtrl = _controllers[index - 1];
      final currCtrl = _controllers[index];
      final joinOffset = prevCtrl.text.length;
      final merged = prevCtrl.text + currCtrl.text;
      prevCtrl.value = TextEditingValue(
        text: merged,
        selection: TextSelection.collapsed(offset: joinOffset),
      );
      _lines[index - 1].content = merged;

      _controllers[index].dispose();
      _focusNodes[index].dispose();
      _controllers.removeAt(index);
      _focusNodes.removeAt(index);
      _lines.removeAt(index);
      _focusedIndex = index - 1;
    });
    _save();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (index - 1 < _focusNodes.length) {
        _focusNodes[index - 1].requestFocus();
      }
    });
  }

  // ── Styling ────────────────────────────────────────────────
  TextStyle _styleFor(String type, {bool checkedThrough = false}) {
    final c = widget.contentColor;
    TextStyle base;
    switch (type) {
      case 'h1':
        base = GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w900, color: c, height: 1.25);
        break;
      case 'h2':
        base = GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: c, height: 1.3);
        break;
      case 'h3':
        base = GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: c, height: 1.35);
        break;
      case 'quote':
        base = GoogleFonts.plusJakartaSans(fontSize: 14, fontStyle: FontStyle.italic, color: c.withValues(alpha: 0.6), height: 1.6);
        break;
      default:
        base = GoogleFonts.plusJakartaSans(fontSize: 14, color: c, height: 1.6);
    }
    if (checkedThrough) {
      return base.copyWith(decoration: TextDecoration.lineThrough, color: c.withValues(alpha: 0.4));
    }
    return base;
  }

  EdgeInsets _paddingFor(String type) {
    switch (type) {
      case 'h1': return const EdgeInsets.only(top: 16, bottom: 6);
      case 'h2': return const EdgeInsets.only(top: 12, bottom: 4);
      case 'h3': return const EdgeInsets.only(top: 8, bottom: 2);
      default:   return const EdgeInsets.symmetric(vertical: 1);
    }
  }

  // ── Build one line ─────────────────────────────────────────
  Widget _buildLine(int index) {
    final line = _lines[index];
    final style = _styleFor(line.type, checkedThrough: line.type == 'checkbox' && line.checked);

    Widget field = Focus(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace) {
          final ctrl = _controllers[index];
          if (ctrl.text.isEmpty ||
              (ctrl.selection.isCollapsed && ctrl.selection.baseOffset == 0)) {
            if (index > 0) {
              _mergeWithPrevious(index);
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        maxLines: null,
        style: style,
        cursorColor: widget.contentColor,
        onChanged: (v) => _onLineChanged(index, v),
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 2),
          hintText: index == 0 ? widget.hintText : null,
          hintStyle: index == 0
              ? GoogleFonts.plusJakartaSans(color: widget.hintColor, fontSize: 14, height: 1.6)
              : null,
        ),
      ),
    );

    // Line leader (bullet dot, checkbox, quote bar, ordered number)
    Widget leader = const SizedBox.shrink();
    switch (line.type) {
      case 'bullet':
        leader = Padding(
          padding: const EdgeInsets.only(right: 8, top: 3),
          child: Text('•', style: style),
        );
        break;
      case 'ordered':
        final num = _lines.sublist(0, index + 1).where((l) => l.type == 'ordered').length;
        leader = Padding(
          padding: const EdgeInsets.only(right: 6, top: 3),
          child: SizedBox(width: 22, child: Text('$num.', style: style)),
        );
        break;
      case 'quote':
        leader = Container(
          width: 3,
          margin: const EdgeInsets.only(right: 10, top: 2, bottom: 2),
          decoration: BoxDecoration(
            color: widget.contentColor.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(2),
          ),
        );
        break;
      case 'checkbox':
        leader = GestureDetector(
          onTap: () {
            setState(() => _lines[index].checked = !_lines[index].checked);
            _save();
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 8, top: 1),
            child: Icon(
              line.checked
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 18,
              color: line.checked
                  ? AppColors.primary
                  : widget.contentColor.withValues(alpha: 0.4),
            ),
          ),
        );
        break;
    }

    return Padding(
      padding: _paddingFor(line.type),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [leader, Expanded(child: field)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (int i = 0; i < _lines.length; i++) _buildLine(i)],
    );
  }
}

