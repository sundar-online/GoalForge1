import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/domain/models/scheduled_event.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../../core/widgets/custom_card.dart';
import '../bloc/events_bloc.dart';
import '../bloc/events_event.dart';
import '../bloc/events_state.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  EventsLoaded? _latestState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (context) => sl<EventsBloc>()..add(SubscribeToEvents()),
      child: BlocBuilder<EventsBloc, EventsState>(
        builder: (context, state) {
          if (state is EventsLoaded) {
            _latestState = state;
          }

          final selectedDate = _latestState?.selectedDateStr ?? AppDateUtils.getTodayString();
          final totalCount = _latestState?.totalEventCount ?? 0;

          return Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showAddEventDialog(context, selectedDate),
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
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Event Schedule',
                                  style: theme.textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onBackground,
                                    fontSize: 26.0,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  '$totalCount TOTAL SCHEDULED EVENTS',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: AppColors.outline,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20.0),

                        // Date Strip Selector
                        _buildDateStripSelector(theme, context, selectedDate),
                        const SizedBox(height: 24.0),

                        // Events for Selected Date
                        _buildSelectedDateEventsSection(theme, context),
                        const SizedBox(height: 32.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Date Strip Selector ---
  Widget _buildDateStripSelector(ThemeData theme, BuildContext context, String selectedDate) {
    final now = DateTime.now();
    final dates = List.generate(7, (i) => now.add(Duration(days: i - 3)));

    const dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: dates.map((date) {
          final dateStr = AppDateUtils.toLocalYYYYMMDD(date);
          final isSelected = dateStr == selectedDate;
          final dayName = dayNames[date.weekday - 1];
          final dayNum = date.day;

          return Container(
            margin: const EdgeInsets.only(right: 10.0),
            child: GestureDetector(
              onTap: () {
                context.read<EventsBloc>().add(SelectEventDate(dateStr));
              },
              child: Container(
                width: 60.0,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.outlineVariant.withValues(alpha: 0.4),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10.0,
                            offset: const Offset(0, 4.0),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        color: isSelected ? Colors.white70 : AppColors.outline,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.0,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '$dayNum',
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.onBackground,
                        fontWeight: FontWeight.w800,
                        fontSize: 18.0,
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

  // --- Selected Date Events Section ---
  Widget _buildSelectedDateEventsSection(ThemeData theme, BuildContext context) {
    final events = _latestState?.selectedDateEvents ?? [];
    final selectedDateStr = _latestState?.selectedDateStr ?? AppDateUtils.getTodayString();

    if (events.isEmpty) {
      return CustomCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              children: [
                const Icon(Icons.event_available, size: 48.0, color: AppColors.outlineVariant),
                const SizedBox(height: 12.0),
                Text(
                  'No Events for $selectedDateStr',
                  style: theme.textTheme.headlineSmall?.copyWith(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Tap the "+" button to schedule an event for this date.',
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
          'EVENTS FOR $selectedDateStr',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.outline,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            fontSize: 10.0,
          ),
        ),
        const SizedBox(height: 12.0),
        Column(
          children: events.map((event) {
            return Column(
              children: [
                _buildEventCard(theme, context, event),
                const SizedBox(height: 12.0),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEventCard(ThemeData theme, BuildContext context, ScheduledEvent event) {
    final isCompleted = event.completed;

    return CustomCard(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              context.read<EventsBloc>().add(ToggleEventCompletion(event.id));
            },
            child: Container(
              width: 32.0,
              height: 32.0,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFF00D9A5) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? const Color(0xFF00D9A5) : AppColors.outlineVariant,
                  width: 2.0,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 20.0)
                  : null,
            ),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (event.eventTime != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 10.0, color: AppColors.primary),
                            const SizedBox(width: 4.0),
                            Text(
                              event.eventTime!,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8.0),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        'REMIND ${event.reminderMinutes}M PRIOR',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6.0),
                Text(
                  event.title,
                  style: TextStyle(
                    color: isCompleted ? AppColors.outline : AppColors.onBackground,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.0,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (event.description != null && event.description!.isNotEmpty) ...[
                  const SizedBox(height: 2.0),
                  Text(
                    event.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.outline,
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.outlineVariant, size: 20.0),
            onPressed: () {
              context.read<EventsBloc>().add(DeleteEvent(event.id));
            },
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog(BuildContext parentContext, String selectedDate) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: parentContext,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
              title: const Text('Schedule New Event', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Event Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Time: ${selectedTime.format(context)}'),
                        TextButton(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (time != null) {
                              setDialogState(() {
                                selectedTime = time;
                              });
                            }
                          },
                          child: const Text('Select Time'),
                        ),
                      ],
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
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    final timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                    final event = ScheduledEvent(
                      id: UuidGenerator.generate(),
                      title: title,
                      description: descController.text.trim(),
                      eventDate: selectedDate,
                      eventTime: timeStr,
                      reminderMinutes: 15,
                      createdAt: DateTime.now().toIso8601String(),
                    );

                    parentContext.read<EventsBloc>().add(CreateEvent(event));
                    Navigator.pop(context);
                  },
                  child: const Text('Schedule'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
