import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/models/note.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/domain/models/quick_thought.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../../core/widgets/custom_card.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';

class SystemLogsPage extends StatefulWidget {
  const SystemLogsPage({super.key});

  @override
  State<SystemLogsPage> createState() => _SystemLogsPageState();
}

class _SystemLogsPageState extends State<SystemLogsPage> {
  final TextEditingController _searchController = TextEditingController();
  NotesLoaded? _latestState;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<NotesBloc, NotesState>(
      builder: (context, state) {
          if (state is NotesLoaded) {
            _latestState = state;
          }

          final totalRecords = _latestState?.totalStoredCount ?? 0;

          final isWide = !ResponsiveLayout.isMobile(context);

          return Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showAddNoteDialog(context),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.0),
              ),
              child: const Icon(Icons.add, size: 28.0),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: isWide ? 1200.0 : 600.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text(
                          'System Logs',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.onBackground,
                            fontSize: 26.0,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          '$totalRecords STORED RECORDS',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.outline,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                            fontSize: 10.0,
                          ),
                        ),
                        const SizedBox(height: 20.0),

                        // Search Bar
                        _buildSearchBar(theme, context),
                        const SizedBox(height: 16.0),

                        // Category Filter Chips
                        _buildCategoryFilterChips(theme, context),
                        const SizedBox(height: 24.0),

                        // Pinned Logs Section
                        _buildPinnedSection(theme, context),
                        const SizedBox(height: 24.0),

                        // All Logs Section
                        _buildAllLogsSection(theme, context),
                        const SizedBox(height: 32.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
  }

  // --- Search Bar ---
  Widget _buildSearchBar(ThemeData theme, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.02),
            blurRadius: 10.0,
            offset: const Offset(0, 4.0),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant, size: 20.0),
          const SizedBox(width: 10.0),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                context.read<NotesBloc>().add(FilterNotesEvent(query: query));
              },
              style: TextStyle(color: theme.colorScheme.onBackground),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Search through records...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Category Filter Chips ---
  Widget _buildCategoryFilterChips(ThemeData theme, BuildContext context) {
    final notes = _latestState?.notes ?? [];
    final userCategories = notes
        .map((n) => n.folder)
        .where((f) => f.trim().isNotEmpty)
        .map((f) => f.trim().toUpperCase())
        .toSet()
        .toList();
    userCategories.sort();

    final categories = ['ALL LOGS', ...userCategories];
    final selectedCat = _latestState?.selectedCategory ?? 'ALL LOGS';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = cat == selectedCat;
          final isFolder = cat != 'ALL LOGS';

          return Container(
            margin: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                context.read<NotesBloc>().add(FilterNotesEvent(category: cat));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : theme.colorScheme.outline,
                  ),
                ),
                child: Row(
                  children: [
                    if (isFolder) ...[
                      Icon(
                        Icons.folder_outlined,
                        size: 14.0,
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6.0),
                    ],
                    Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                        letterSpacing: 0.5,
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

  // --- Pinned Logs Section ---
  Widget _buildPinnedSection(ThemeData theme, BuildContext context) {
    final pinned = _latestState?.pinnedNotes ?? [];

    if (pinned.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.push_pin, color: AppColors.primary, size: 14.0),
            const SizedBox(width: 6.0),
            Text(
              'PINNED LOGS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.outline,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                fontSize: 10.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        Column(
          children: pinned.map((note) {
            return Column(
              children: [
                _buildNoteCard(theme, context, note),
                const SizedBox(height: 12.0),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- All Logs Section ---
  Widget _buildAllLogsSection(ThemeData theme, BuildContext context) {
    final regular = _latestState?.notes ?? [];
    final quickThoughts = _latestState?.quickThoughts ?? [];

    if (regular.isEmpty && quickThoughts.isEmpty) {
      return CustomCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(Icons.description_outlined, size: 48.0, color: AppColors.outlineVariant),
                const SizedBox(height: 12.0),
                Text(
                  'No Records Found',
                  style: theme.textTheme.headlineSmall?.copyWith(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Tap the "+" button below to log thoughts, notes, and records.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.outline),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ALL LOGS',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.outline,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            fontSize: 10.0,
          ),
        ),
        const SizedBox(height: 12.0),
        Column(
          children: [
            ...quickThoughts.map((thought) {
              return Column(
                children: [
                  _buildQuickThoughtCard(theme, context, thought),
                  const SizedBox(height: 12.0),
                ],
              );
            }),
            ...regular.map((note) {
              return Column(
                children: [
                  _buildNoteCard(theme, context, note),
                  const SizedBox(height: 12.0),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildNoteCard(ThemeData theme, BuildContext context, Note note) {
    final isPinned = note.pinned;
    return CustomCard(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.0,
            height: 44.0,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: AppColors.primary,
              size: 22.0,
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
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (isPinned) ...[
                      const SizedBox(width: 6.0),
                      const Icon(Icons.push_pin, color: AppColors.primary, size: 14.0),
                    ],
                  ],
                ),
                const SizedBox(height: 6.0),
                Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.outline,
                    fontSize: 12.5,
                  ),
                ),
                if (note.folder.isNotEmpty) ...[
                  const SizedBox(height: 8.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      note.folder.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 9.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(
                  isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: isPinned ? AppColors.primary : AppColors.outlineVariant,
                  size: 18.0,
                ),
                onPressed: () {
                  context.read<NotesBloc>().add(TogglePinNoteEvent(note.id));
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.outlineVariant, size: 18.0),
                onPressed: () {
                  context.read<NotesBloc>().add(DeleteNoteEvent(note.id));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickThoughtCard(ThemeData theme, BuildContext context, QuickThought thought) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF2E6FF),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology_alt_outlined, color: Color(0xFFBF5AF2), size: 20.0),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              thought.content,
              style: const TextStyle(
                color: Color(0xFF5A1A8A),
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFBF5AF2), size: 18.0),
            onPressed: () {
              context.read<NotesBloc>().add(DeleteQuickThoughtEvent(thought.id));
            },
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog(BuildContext parentContext) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final folderController = TextEditingController(text: 'GENERAL');
    bool isQuickThought = false;

    showDialog(
      context: parentContext,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
              title: Text(
                isQuickThought ? 'Capture Quick Thought' : 'Add System Log',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        FilterChip(
                          label: const Text('Full Log'),
                          selected: !isQuickThought,
                          onSelected: (selected) {
                            setDialogState(() {
                              isQuickThought = false;
                            });
                          },
                        ),
                        const SizedBox(width: 8.0),
                        FilterChip(
                          label: const Text('Quick Thought'),
                          selected: isQuickThought,
                          onSelected: (selected) {
                            setDialogState(() {
                              isQuickThought = true;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    if (!isQuickThought) ...[
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      TextField(
                        controller: folderController,
                        decoration: const InputDecoration(
                          labelText: 'Folder / Tag (e.g. TRADING)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12.0),
                    ],
                    TextField(
                      controller: contentController,
                      maxLines: isQuickThought ? 2 : 4,
                      decoration: InputDecoration(
                        labelText: isQuickThought ? 'What\'s on your mind?' : 'Content',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final content = contentController.text.trim();
                    if (content.isEmpty) return;

                    final nowStr = DateTime.now().toIso8601String();

                    if (isQuickThought) {
                      final thought = QuickThought(
                        id: UuidGenerator.generate(),
                        content: content,
                        createdAt: nowStr,
                      );
                      parentContext.read<NotesBloc>().add(CreateQuickThoughtEvent(thought));
                    } else {
                      final note = Note(
                        id: UuidGenerator.generate(),
                        title: titleController.text.trim().isEmpty ? 'Untitled Log' : titleController.text.trim(),
                        content: content,
                        checklist: const [],
                        tags: [folderController.text.trim().toUpperCase()],
                        folder: folderController.text.trim().toUpperCase(),
                        createdAt: nowStr,
                      );
                      parentContext.read<NotesBloc>().add(CreateNoteEvent(note));
                    }

                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
