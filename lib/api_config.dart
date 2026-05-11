class ApiConfig {
  // Use Vercel URL or Render URL for production, or 10.0.2.2 for Android Emulator testing
  // Currently skipping Render per user request, defaulting to Render URL but easily changeable.
  // Example for local emulator testing: 'http://10.0.2.2:8000/api'
  static const String baseUrl = 'https://livkit.onrender.com/api'; 
}
