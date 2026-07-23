import '../models/note.dart';
import '../models/quick_thought.dart';

abstract class NotesRepository {
  /// Stream notes list.
  Stream<List<Note>> watchNotes();

  /// Get cached notes.
  List<Note> getNotes();

  /// Create or update a note.
  Future<void> upsertNote(Note note);

  /// Delete a note.
  Future<void> deleteNote(String noteId);

  /// Stream quick thoughts list.
  Stream<List<QuickThought>> watchQuickThoughts();

  /// Get cached quick thoughts.
  List<QuickThought> getQuickThoughts();

  /// Create or update a quick thought.
  Future<void> upsertQuickThought(QuickThought thought);

  /// Delete a quick thought.
  Future<void> deleteQuickThought(String thoughtId);

  /// Force fetch from Firestore and refresh local cache.
  Future<void> fetchRemoteNotesAndThoughts();
}
