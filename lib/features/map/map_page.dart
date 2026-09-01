import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'models/map_device_model.dart';
import 'providers/map_provider.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final MapController _mapController = MapController();
  MapDeviceModel? _selectedDevice;
  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  String? _savedDeviceCode;

  @override
  void initState() {
    super.initState();
    _loadSavedDevice();
  }

  Future<void> _loadSavedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedDeviceCode = prefs.getString('last_selected_map_device');
    });
  }

  Future<void> _saveDeviceCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_selected_map_device', code);
  }

  void _onMarkerTapped(MapDeviceModel device) {
    setState(() {
      _selectedDevice = device;
    });
    // Center map on selected device
    _mapController.move(LatLng(device.latitude, device.longitude), 16.0);
  }

  void _closePreview() {
    setState(() {
      _selectedDevice = null;
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'online':
        return Colors.green.shade500;
      case 'warning':
        return Colors.yellow.shade600;
      case 'critical':
        return Colors.red.shade600;
      case 'offline':
      default:
        return AppColors.mutedForeground;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mapDevicesAsync = ref.watch(mapDevicesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildFlutterMap(mapDevicesAsync),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderCard(textTheme),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSearchBar(textTheme),
                  const SizedBox(height: AppSpacing.sm),
                  _buildStatusFilters(textTheme),
                  const SizedBox(height: AppSpacing.sm),
                  mapDevicesAsync.when(
                    data: (devices) => _buildDeviceShortcuts(devices, textTheme),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            right: AppSpacing.md,
            bottom: _selectedDevice != null ? 220 : 120, // Adjust based on preview card visibility
            child: _buildMapControls(),
          ),

          Positioned(
            left: AppSpacing.md,
            bottom: _selectedDevice != null ? 220 : 120,
            child: _buildLegend(textTheme),
          ),

          if (_selectedDevice != null)
            Positioned(
              bottom: 80, 
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: _buildDevicePreviewCard(context, textTheme),
            ),
        ],
      ),
    );
  }

  Widget _buildFlutterMap(AsyncValue<List<MapDeviceModel>> asyncDevices) {
    return asyncDevices.when(
      data: (devices) {
        final filteredDevices = devices.where((d) {
          final matchesSearch = d.deviceName.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                d.deviceCode.toLowerCase().contains(_searchQuery.toLowerCase());
          
          bool matchesFilter = true;
          if (_selectedFilter == 'Normal') matchesFilter = d.status == 'online';
          if (_selectedFilter == 'Peringatan') matchesFilter = d.status == 'warning';
          if (_selectedFilter == 'Kritis') matchesFilter = d.status == 'critical';
          if (_selectedFilter == 'Tidak Terhubung') matchesFilter = d.status == 'offline';

          return matchesSearch && matchesFilter;
        }).toList();

        LatLng initialCenter = const LatLng(-6.200000, 106.816666); // Default Jakarta
        double initialZoom = 10.0;
        
        if (filteredDevices.isNotEmpty) {
           initialCenter = LatLng(filteredDevices.first.latitude, filteredDevices.first.longitude);
           
           if (_savedDeviceCode != null) {
              try {
                final savedDevice = filteredDevices.firstWhere((d) => d.deviceCode == _savedDeviceCode);
                initialCenter = LatLng(savedDevice.latitude, savedDevice.longitude);
                initialZoom = 16.0;
              } catch (_) {
                // If saved device not found in current filters, fallback to first
              }
           }
        }

        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: initialZoom,
            onTap: (_, __) => _closePreview(),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.tagana.app',
            ),
            MarkerLayer(
              markers: () {
                final groupedDevices = <String, List<MapDeviceModel>>{};
                for (final d in filteredDevices) {
                  // Mengelompokkan perangkat yang memiliki titik persis sama
                  final key = '${d.latitude.toStringAsFixed(5)}_${d.longitude.toStringAsFixed(5)}';
                  groupedDevices.putIfAbsent(key, () => []).add(d);
                }

                final markers = <Marker>[];
                for (final group in groupedDevices.values) {
                  if (group.isEmpty) continue;
                  
                  // Posisi titik tetap diam/asli (tidak digeser)
                  final lat = group.first.latitude;
                  final lng = group.first.longitude;
                  
                  // Menentukan warna titik gabungan (prioritaskan yang kritis/warning)
                  Color dotColor = AppColors.mutedForeground;
                  if (group.any((d) => d.status == 'critical')) {
                    dotColor = Colors.red.shade600;
                  } else if (group.any((d) => d.status == 'warning')) {
                    dotColor = Colors.yellow.shade600;
                  } else if (group.any((d) => d.status == 'online')) {
                    dotColor = Colors.green.shade500;
                  }

                  final bool anySelected = group.any((d) => _selectedDevice?.id == d.id);

                  markers.add(
                    Marker(
                      point: LatLng(lat, lng),
                      width: 140,
                      height: 30.0 + (group.length * 35.0), 
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tumpuk semua label device di satu titik
                          ...group.map((device) {
                            final isSelected = _selectedDevice?.id == device.id;
                            return GestureDetector(
                              onTap: () => _onMarkerTapped(device),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.border,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  device.deviceCode,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: AppColors.foreground,
                                      ),
                                ),
                              ),
                            );
                          }),
                          
                          // Satu titik (dot) merepresentasikan lokasi fisiknya
                          Container(
                            width: anySelected ? 20 : 16,
                            height: anySelected ? 20 : 16,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.card, width: 2),
                              boxShadow: [
                                BoxShadow(color: dotColor.withOpacity(0.5), blurRadius: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  );
                }
                return markers;
              }(),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildHeaderCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Peta TAGANA',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          Text(
            'Pantau lokasi perangkat TAGANA',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.search, color: AppColors.mutedForeground, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
                final currentDevicesAsync = ref.read(mapDevicesProvider);
                if (value.isNotEmpty && currentDevicesAsync.hasValue) {
                  final devices = currentDevicesAsync.value!;
                  final matches = devices.where((d) => 
                    d.deviceName.toLowerCase().contains(value.toLowerCase()) || 
                    d.deviceCode.toLowerCase().contains(value.toLowerCase())
                  ).toList();
                  
                  if (matches.isNotEmpty) {
                    _mapController.move(LatLng(matches.first.latitude, matches.first.longitude), 14.0);
                  }
                }
              },
              decoration: InputDecoration(
                hintText: 'Cari perangkat atau lokasi...',
                hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: textTheme.bodyMedium?.copyWith(color: AppColors.foreground),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilters(TextTheme textTheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(textTheme, 'Semua'),
          const SizedBox(width: AppSpacing.xs),
          _buildFilterChip(textTheme, 'Normal'),
          const SizedBox(width: AppSpacing.xs),
          _buildFilterChip(textTheme, 'Kritis'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(TextTheme textTheme, String label) {
    final isActive = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedFilter = label;
        _selectedDevice = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryContainer : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? null : Border.all(color: AppColors.border),
          boxShadow: [
            if (!isActive)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: isActive ? AppColors.primaryForeground : AppColors.foreground,
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceShortcuts(List<MapDeviceModel> devices, TextTheme textTheme) {
    if (devices.isEmpty) return const SizedBox.shrink();
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: devices.map((device) {
          final isSelected = (_selectedDevice != null && _selectedDevice?.id == device.id) || 
                             (_selectedDevice == null && _savedDeviceCode == device.deviceCode);
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: GestureDetector(
              onTap: () {
                _onMarkerTapped(device);
                _saveDeviceCode(device.deviceCode);
                setState(() => _savedDeviceCode = device.deviceCode);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected ? null : Border.all(color: AppColors.border),
                  boxShadow: [
                    if (!isSelected)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.mapPin,
                      size: 14,
                      color: isSelected ? AppColors.primaryForeground : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      device.deviceCode,
                      style: textTheme.labelSmall?.copyWith(
                        color: isSelected ? AppColors.primaryForeground : AppColors.foreground,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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

  Widget _buildMapControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(LucideIcons.crosshair),
            color: AppColors.foreground,
            onPressed: () {
               ref.invalidate(mapDevicesProvider);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.plus),
                color: AppColors.foreground,
                onPressed: () {
                  final zoom = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, zoom + 1);
                },
              ),
              Container(height: 1, width: 40, color: AppColors.border),
              IconButton(
                icon: const Icon(LucideIcons.minus),
                color: AppColors.foreground,
                onPressed: () {
                  final zoom = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, zoom - 1);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLegendItem(textTheme, 'Normal', Colors.green.shade500),
          const SizedBox(height: 4),
          _buildLegendItem(textTheme, 'Kritis', Colors.red.shade600),
        ],
      ),
    );
  }

  Widget _buildLegendItem(TextTheme textTheme, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: AppColors.foreground),
        ),
      ],
    );
  }

  Widget _buildDevicePreviewCard(BuildContext context, TextTheme textTheme) {
    if (_selectedDevice == null) return const SizedBox();
    
    final device = _selectedDevice!;
    final statusColor = _getStatusColor(device.status);
    
    String statusText;
    switch(device.status) {
       case 'online': statusText = 'Normal / Terhubung'; break;
       case 'warning': statusText = 'Peringatan'; break;
       case 'critical': statusText = 'Kritis'; break;
       case 'offline': default: statusText = 'Tidak Terhubung'; break;
    }

    // Time difference
    final diff = DateTime.now().difference(device.recordedAt);
    String timeStr = 'Baru saja';
    if (diff.inDays > 0) timeStr = '${diff.inDays} hari lalu';
    else if (diff.inHours > 0) timeStr = '${diff.inHours} jam lalu';
    else if (diff.inMinutes > 0) timeStr = '${diff.inMinutes} menit lalu';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 32,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.deviceCode,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.foreground,
                      ),
                    ),
                    Text(
                      device.deviceName,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(LucideIcons.x),
                color: AppColors.mutedForeground,
                onPressed: _closePreview,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: textTheme.labelSmall?.copyWith(color: AppColors.mutedForeground),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: textTheme.bodyMedium?.copyWith(color: AppColors.foreground),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pembaruan Terakhir',
                      style: textTheme.labelSmall?.copyWith(color: AppColors.mutedForeground),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeStr,
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.foreground),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: () => context.push('/device/${device.id}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.primaryForeground,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Tampilkan Detail'),
          ),
        ],
      ),
    );
  }
}