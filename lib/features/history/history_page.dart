import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/history_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_header.dart';
import 'models/history_event.dart';

const _kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

enum _Period { today, days7, days30, custom }

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<HistoryEvent> _events = [];
  bool _isLoading = true;
  String? _errorMessage;
  RealtimeChannel? _channel;

  _Period _period = _Period.today;
  DateTimeRange? _customRange;
  String _category = 'semua';

  @override
  void initState() {
    super.initState();
    _load();
    _channel = HistoryService.subscribe(onChange: _load);
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) {
      HistoryService.unsubscribe(channel);
    }
    super.dispose();
  }

  DateTime _sinceForPeriod() {
    final now = DateTime.now();
    switch (_period) {
      case _Period.today:
        return DateTime(now.year, now.month, now.day);
      case _Period.days7:
        return now.subtract(const Duration(days: 7));
      case _Period.days30:
        return now.subtract(const Duration(days: 30));
      case _Period.custom:
        final start = _customRange?.start ?? DateTime(now.year, now.month, now.day);
        return DateTime(start.year, start.month, start.day);
    }
  }

  Future<void> _load() async {
    try {
      final events = await HistoryService.fetchHistory(since: _sinceForPeriod());
      if (!mounted) return;
      setState(() {
        _events = events;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat riwayat. Tarik untuk coba lagi.';
      });
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _customRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (picked == null) return;
    setState(() {
      _period = _Period.custom;
      _customRange = picked;
    });
    _load();
  }

  void _selectPeriod(_Period period) {
    if (period == _Period.custom) {
      _pickCustomRange();
      return;
    }
    setState(() {
      _period = period;
      _customRange = null;
    });
    _load();
  }

  List<HistoryEvent> get _filteredEvents {
    var list = _events;

    if (_period == _Period.custom && _customRange != null) {
      final endExclusive = DateTime(
        _customRange!.end.year,
        _customRange!.end.month,
        _customRange!.end.day,
      ).add(const Duration(days: 1));
      list = list.where((e) => e.occurredAt.isBefore(endExclusive)).toList();
    }

    if (_category != 'semua') {
      list = list.where((e) => e.category == _category).toList();
    }

    return list;
  }

  String _formatDateLabel(DateTime d) => '${d.day} ${_kMonths[d.month - 1]} ${d.year}';

  Map<String, List<HistoryEvent>> _groupByDay(List<HistoryEvent> events) {
    final map = <String, List<HistoryEvent>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final e in events) {
      final d = DateTime(e.occurredAt.year, e.occurredAt.month, e.occurredAt.day);
      final String label;
      if (d == today) {
        label = 'HARI INI';
      } else if (d == yesterday) {
        label = 'KEMARIN';
      } else {
        label = _formatDateLabel(d).toUpperCase();
      }
      map.putIfAbsent(label, () => []).add(e);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final grouped = _groupByDay(_filteredEvents);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(),
      body: SafeArea(
        child: Column(
          children: [
            // Screen Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Riwayat',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Aktivitas dan kejadian perangkat',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),

            // Filters
            _buildFilters(textTheme),
            const SizedBox(height: AppSpacing.md),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _buildErrorBanner(textTheme),
              ),

            // Timeline
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: grouped.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              children: [
                                const SizedBox(height: AppSpacing.xxl),
                                _buildEmptyState(textTheme),
                              ],
                            )
                          : ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              children: [
                                for (final entry in grouped.entries) ...[
                                  _buildTimelineGroup(
                                    textTheme,
                                    title: entry.key,
                                    items: [
                                      for (final e in entry.value) ...[
                                        _buildEventItem(textTheme, e),
                                        const SizedBox(height: AppSpacing.sm),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                ],
                                const SizedBox(height: 100), // padding for bottom nav
                              ],
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.destructive.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.destructive.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertTriangle, color: AppColors.destructive, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: textTheme.bodySmall?.copyWith(color: AppColors.destructive),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.calendar, size: 32, color: AppColors.mutedForeground),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Belum ada riwayat pada periode/filter ini',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Period Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              _buildFilterChip(
                textTheme,
                'Hari ini',
                isActive: _period == _Period.today,
                isPeriod: true,
                onTap: () => _selectPeriod(_Period.today),
              ),
              const SizedBox(width: AppSpacing.xs),
              _buildFilterChip(
                textTheme,
                '7 Hari',
                isActive: _period == _Period.days7,
                isPeriod: true,
                onTap: () => _selectPeriod(_Period.days7),
              ),
              const SizedBox(width: AppSpacing.xs),
              _buildFilterChip(
                textTheme,
                '30 Hari',
                isActive: _period == _Period.days30,
                isPeriod: true,
                onTap: () => _selectPeriod(_Period.days30),
              ),
              const SizedBox(width: AppSpacing.xs),
              _buildFilterChip(
                textTheme,
                _period == _Period.custom && _customRange != null
                    ? '${_customRange!.start.day}/${_customRange!.start.month} - ${_customRange!.end.day}/${_customRange!.end.month}'
                    : 'Custom',
                icon: LucideIcons.calendar,
                isActive: _period == _Period.custom,
                isPeriod: true,
                onTap: _pickCustomRange,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Category Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              _buildFilterChip(
                textTheme,
                'Semua',
                isActive: _category == 'semua',
                onTap: () => setState(() => _category = 'semua'),
              ),
              const SizedBox(width: AppSpacing.xs),
              _buildFilterChip(
                textTheme,
                'Peringatan',
                isActive: _category == 'peringatan',
                onTap: () => setState(() => _category = 'peringatan'),
              ),
              const SizedBox(width: AppSpacing.xs),
              _buildFilterChip(
                textTheme,
                'Kritis',
                isActive: _category == 'kritis',
                onTap: () => setState(() => _category = 'kritis'),
              ),
              const SizedBox(width: AppSpacing.xs),
              _buildFilterChip(
                textTheme,
                'Perangkat',
                isActive: _category == 'perangkat',
                onTap: () => setState(() => _category = 'perangkat'),
              ),
              const SizedBox(width: AppSpacing.xs),
              _buildFilterChip(
                textTheme,
                'Sistem',
                isActive: _category == 'sistem',
                onTap: () => setState(() => _category = 'sistem'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    TextTheme textTheme,
    String label, {
    bool isActive = false,
    bool isPeriod = false,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    Color bgColor;
    Color textColor;
    Border? border;

    if (isPeriod) {
      if (isActive) {
        bgColor = AppColors.primaryContainer;
        textColor = AppColors.primary;
      } else {
        bgColor = AppColors.muted;
        textColor = AppColors.foreground;
      }
    } else {
      if (isActive) {
        bgColor = AppColors.secondary;
        textColor = AppColors.foreground;
      } else {
        bgColor = AppColors.card;
        textColor = AppColors.foreground;
        border = Border.all(color: AppColors.border);
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isPeriod ? 24 : 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(isPeriod ? 24 : 8),
          border: border,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(color: textColor),
            ),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 14, color: textColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineGroup(
    TextTheme textTheme, {
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: AppSpacing.sm),
          child: Text(
            title,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.mutedForeground,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  (IconData, Color, Color) _iconFor(HistoryEvent e) {
    switch (e.category) {
      case 'kritis':
        return (LucideIcons.alertOctagon, AppColors.destructive, Colors.red.shade50);
      case 'peringatan':
        return (LucideIcons.alertTriangle, Colors.orange.shade800, Colors.orange.shade50);
      case 'sistem':
        return (LucideIcons.info, Colors.indigo.shade700, Colors.indigo.shade50);
      case 'perangkat':
      default:
        final isNegative = e.type.contains('disconnected');
        return isNegative
            ? (LucideIcons.alertOctagon, AppColors.destructive, Colors.red.shade50)
            : (LucideIcons.checkCircle2, Colors.green.shade800, Colors.green.shade50);
    }
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Widget _buildEventItem(TextTheme textTheme, HistoryEvent e) {
    final (icon, iconColor, iconBgColor) = _iconFor(e);
    final subtitle = e.deviceName != null
        ? '${e.deviceName}${e.deviceCode != null ? ' · ${e.deviceCode}' : ''}'
        : 'Sistem Pusat';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        e.title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _formatTime(e.occurredAt),
                      style: textTheme.labelSmall?.copyWith(color: AppColors.mutedForeground),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.labelSmall?.copyWith(color: Colors.indigo.shade300),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  e.description ?? '-',
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Icon(LucideIcons.chevronRight, color: AppColors.mutedForeground, size: 20),
          ),
        ],
      ),
    );
  }
}