import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://nxfnrkzzkegmbduktnph.supabase.co',
      anonKey: 'sb_publishable_QluQm_Nt7tYi443GB0irIg_C4omQMl1',
    );
  }
}
