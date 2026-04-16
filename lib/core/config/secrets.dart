class Secrets {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const mapBoxKey = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
  static const localSaltKey = String.fromEnvironment('LOCAL_EMAIL_HASH_SALT');
}
