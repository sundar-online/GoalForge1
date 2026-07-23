import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/repositories/notes_repository.dart';
import 'notes_event.dart';
import 'notes_state.dart';

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final NotesRepository _notesRepository;

  StreamSubscription? _notesSubscription;
  StreamSubscription? _thoughtsSubscription;

  NotesBloc({
    required NotesRepository notesRepository,
  })  : _notesRepository = notesRepository,
        super(NotesInitial()) {
    on<SubscribeToNotes>(_onSubscribeToNotes);
    on<CreateNoteEvent>(_onCreateNote);
    on<UpdateNoteEvent>(_onUpdateNote);
    on<DeleteNoteEvent>(_onDeleteNote);
    on<TogglePinNoteEvent>(_onTogglePinNote);
    on<CreateQuickThoughtEvent>(_onCreateQuickThought);
    on<DeleteQuickThoughtEvent>(_onDeleteQuickThought);
    on<FilterNotesEvent>(_onFilterNotes);
  }

  Future<void> _onSubscribeToNotes(SubscribeToNotes event, Emitter<NotesState> emit) async {
    emit(NotesLoading());
    await _notesSubscription?.cancel();
    await _thoughtsSubscription?.cancel();

    _notesSubscription = _notesRepository.watchNotes().listen((_) {
      if (!isClosed) {
        add(SubscribeToNotes());
      }
    });

    _thoughtsSubscription = _notesRepository.watchQuickThoughts().listen((_) {
      if (!isClosed) {
        add(SubscribeToNotes());
      }
    });

    _recalculateAndEmit(emit);
  }

  void _recalculateAndEmit(Emitter<NotesState> emit) {
    try {
      final allNotes = _notesRepository.getNotes();
      final quickThoughts = _notesRepository.getQuickThoughts();

      final query = (state is NotesLoaded) ? (state as NotesLoaded).searchQuery.toLowerCase() : '';
      final category = (state is NotesLoaded) ? (state as NotesLoaded).selectedCategory : 'ALL LOGS';

      final filteredNotes = allNotes.where((note) {
        final matchesQuery = query.isEmpty ||
            note.title.toLowerCase().contains(query) ||
            note.content.toLowerCase().contains(query);
        final matchesCategory = category == 'ALL LOGS' ||
            note.folder.toLowerCase() == category.toLowerCase() ||
            note.tags.any((tag) => tag.toLowerCase() == category.toLowerCase());
        return matchesQuery && matchesCategory;
      }).toList();

      final pinned = filteredNotes.where((n) => n.pinned).toList();
      final regular = filteredNotes.where((n) => !n.pinned).toList();
      final totalCount = allNotes.length + quickThoughts.length;

      emit(NotesLoaded(
        notes: regular,
        pinnedNotes: pinned,
        quickThoughts: quickThoughts,
        totalStoredCount: totalCount,
        searchQuery: query,
        selectedCategory: category,
      ));
    } catch (e) {
      emit(NotesError(e.toString()));
    }
  }

  Future<void> _onCreateNote(CreateNoteEvent event, Emitter<NotesState> emit) async {
    try {
      await _notesRepository.upsertNote(event.note);
    } catch (e) {
      emit(NotesError('Failed to create note: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateNote(UpdateNoteEvent event, Emitter<NotesState> emit) async {
    try {
      await _notesRepository.upsertNote(event.note);
    } catch (e) {
      emit(NotesError('Failed to update note: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteNote(DeleteNoteEvent event, Emitter<NotesState> emit) async {
    try {
      await _notesRepository.deleteNote(event.noteId);
    } catch (e) {
      emit(NotesError('Failed to delete note: ${e.toString()}'));
    }
  }

  Future<void> _onTogglePinNote(TogglePinNoteEvent event, Emitter<NotesState> emit) async {
    try {
      final allNotes = _notesRepository.getNotes();
      final target = allNotes.firstWhere((n) => n.id == event.noteId);
      final updatedNote = target.copyWith(pinned: !target.pinned);
      await _notesRepository.upsertNote(updatedNote);
    } catch (e) {
      emit(NotesError('Failed to toggle pin: ${e.toString()}'));
    }
  }

  Future<void> _onCreateQuickThought(CreateQuickThoughtEvent event, Emitter<NotesState> emit) async {
    try {
      await _notesRepository.upsertQuickThought(event.thought);
    } catch (e) {
      emit(NotesError('Failed to create quick thought: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteQuickThought(DeleteQuickThoughtEvent event, Emitter<NotesState> emit) async {
    try {
      await _notesRepository.deleteQuickThought(event.thoughtId);
    } catch (e) {
      emit(NotesError('Failed to delete quick thought: ${e.toString()}'));
    }
  }

  void _onFilterNotes(FilterNotesEvent event, Emitter<NotesState> emit) {
    if (state is NotesLoaded) {
      final current = state as NotesLoaded;
      emit(current.copyWith(
        searchQuery: event.query ?? current.searchQuery,
        selectedCategory: event.category ?? current.selectedCategory,
      ));
      _recalculateAndEmit(emit);
    }
  }

  @override
  Future<void> close() {
    _notesSubscription?.cancel();
    _thoughtsSubscription?.cancel();
    return super.close();
  }
}
