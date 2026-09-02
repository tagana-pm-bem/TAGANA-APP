import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/map_device_model.dart';

final mapDevicesProvider = FutureProvider.autoDispose<List<MapDeviceModel>>((ref) async {
  final supabase = SupabaseClientService.client;
  
  try {
    final response = await supabase
        .from('devices')
        .select('''
          id, 
          device_code, 
          device_name, 
          device_status(status), 
          device_locations(latitude, longitude, recorded_at)
        ''')
        .order('recorded_at', referencedTable: 'device_locations', ascending: false)
        .limit(1, referencedTable: 'device_locations');

    final List<dynamic> data = response;
    
    final devices = data
        .map((json) => MapDeviceModel.fromJson(json as Map<String, dynamic>))
        .toList();
        
    final validDevices = devices.where((device) {
      return device.latitude != 0.0 && device.longitude != 0.0;
    }).toList();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_map_devices', jsonEncode(validDevices.map((d) => d.toJson()).toList()));
    } catch (_) {}

    return validDevices;
  } catch (e) {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('cached_map_devices');
      if (str != null) {
        final List<dynamic> data = jsonDecode(str);
        return data.map((json) => MapDeviceModel.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    rethrow;
  }
});
