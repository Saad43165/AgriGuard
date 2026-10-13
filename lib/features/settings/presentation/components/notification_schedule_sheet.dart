import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/app_themes.dart';

class NotificationScheduleSheet extends StatefulWidget {
  const NotificationScheduleSheet({super.key});

  @override
  State<NotificationScheduleSheet> createState() => _NotificationScheduleSheetState();
}

class _NotificationScheduleSheetState extends State<NotificationScheduleSheet> {
  bool _isLoading = true;
  bool _isSet = false;
  int _selectedWeekday = 1; // 1=Mon
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isSaving = false;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await NotificationService().getScanReminderStatus();
    if (mounted) {
      setState(() {
        _isSet = status['isSet'] as bool;
        _selectedWeekday = status['weekday'] as int;
        _selectedTime = TimeOfDay(
          hour: status['hour'] as int,
          minute: status['minute'] as int,
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _setReminder() async {
    setState(() => _isSaving = true);
    try {
      await NotificationService().scheduleWeeklyScanReminder(_selectedWeekday, _selectedTime);
      setState(() { _isSet = true; _isSaving = false; });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Reminder set for ${_days[_selectedWeekday - 1]} at ${_selectedTime.format(context)}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _removeReminder() async {
    setState(() => _isSaving = true);
    await NotificationService().cancelScanReminder();
    setState(() { _isSet = false; _isSaving = false; });
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Reminder removed'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: borderColor),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: borderColor, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.alarm_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scan Reminder', style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                          Text(_isSet ? 'Reminder is active' : 'No reminder set',
                              style: TextStyle(fontSize: 12, color: _isSet ? AppColors.success : captionColor)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Day picker
                  Text('Day of Week', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: captionColor)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: List.generate(7, (i) {
                      final day = i + 1;
                      final isSelected = _selectedWeekday == day;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedWeekday = day);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkSurface : AppColors.lightBg),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : borderColor,
                              width: 1.5,
                            ),
                          ),
                          child: Text(_days[i], style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : textColor,
                          )),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Time picker
                  Text('Time', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: captionColor)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 12),
                          Text(_selectedTime.format(context), style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
                          const Spacer(),
                          Icon(Icons.edit_rounded, size: 16, color: captionColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      if (_isSet)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSaving ? null : _removeReminder,
                            icon: const Icon(Icons.alarm_off_rounded, size: 16),
                            label: const Text('Remove'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      if (_isSet) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _setReminder,
                          icon: _isSaving
                              ? const SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.alarm_add_rounded, size: 16),
                          label: Text(_isSet ? 'Update Reminder' : 'Set Reminder'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
