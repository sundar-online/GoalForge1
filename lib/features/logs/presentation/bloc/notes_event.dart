import 'package:equatable/equatable.dart';
import '../../../../core/domain/models/note.dart';
import '../../../../core/domain/models/quick_thought.dart';

abstract class NotesEvent extends Equatable {
  const NotesEvent();

  @override
  List<Object?> get props => [];
}

class SubscribeToNotes extends NotesEvent {}

class CreateNoteEvent extends NotesEvent {
  final Note note;

  const CreateNoteEvent(this.note);

  @override
  List<Object?> get props => [note];
}

class UpdateNoteEvent extends NotesEvent {
  final Note note;

  const UpdateNoteEvent(this.note);

  @override
  List<Object?> get props => [note];
}

class DeleteNoteEvent extends NotesEvent {
  final String noteId;

  const DeleteNoteEvent(this.noteId);

  @override
  List<Object?> get props => [noteId];
}

class TogglePinNoteEvent extends NotesEvent {
  final String noteId;

  const TogglePinNoteEvent(this.noteId);

  @override
  List<Object?> get props => [noteId];
}

class CreateQuickThoughtEvent extends NotesEvent {
  final QuickThought thought;

  const CreateQuickThoughtEvent(this.thought);

  @override
  List<Object?> get props => [thought];
}

class DeleteQuickThoughtEvent extends NotesEvent {
  final String thoughtId;

  const DeleteQuickThoughtEvent(this.thoughtId);

  @override
  List<Object?> get props => [thoughtId];
}

class FilterNotesEvent extends NotesEvent {
  final String? query;
  final String? category;

  const FilterNotesEvent({this.query, this.category});

  @override
  List<Object?> get props => [query, category];
}
