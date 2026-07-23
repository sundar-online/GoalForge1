import 'package:equatable/equatable.dart';
import '../../../../core/domain/models/note.dart';
import '../../../../core/domain/models/quick_thought.dart';

abstract class NotesState extends Equatable {
  const NotesState();

  @override
  List<Object?> get props => [];
}

class NotesInitial extends NotesState {}

class NotesLoading extends NotesState {}

class NotesLoaded extends NotesState {
  final List<Note> notes;
  final List<Note> pinnedNotes;
  final List<QuickThought> quickThoughts;
  final int totalStoredCount;
  final String searchQuery;
  final String selectedCategory; // 'ALL LOGS', 'TRADING', 'COLLAGE', etc.

  const NotesLoaded({
    required this.notes,
    required this.pinnedNotes,
    required this.quickThoughts,
    this.totalStoredCount = 0,
    this.searchQuery = '',
    this.selectedCategory = 'ALL LOGS',
  });

  NotesLoaded copyWith({
    List<Note>? notes,
    List<Note>? pinnedNotes,
    List<QuickThought>? quickThoughts,
    int? totalStoredCount,
    String? searchQuery,
    String? selectedCategory,
  }) {
    return NotesLoaded(
      notes: notes ?? this.notes,
      pinnedNotes: pinnedNotes ?? this.pinnedNotes,
      quickThoughts: quickThoughts ?? this.quickThoughts,
      totalStoredCount: totalStoredCount ?? this.totalStoredCount,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }

  @override
  List<Object?> get props => [
        notes,
        pinnedNotes,
        quickThoughts,
        totalStoredCount,
        searchQuery,
        selectedCategory,
      ];
}

class NotesError extends NotesState {
  final String message;
  const NotesError(this.message);

  @override
  List<Object?> get props => [message];
}
