// Central configuration for environment URLs.
//
// - `apiBaseUrl` is the Node.js backend base URL. Change this when
//   the backend IP or port changes (do NOT use localhost when testing
//   QR scans from mobile — use your PC LAN IP).
// - `webAppBaseUrl` is the Flutter Web app base URL used to generate
//   QR codes. Scanning a QR on a phone must point to the PC's LAN IP
//   (e.g. http://192.168.1.33:64146) so the phone can reach the web app.

class AppConfig {
  // Change this when backend IP or port changes
  // This must point to your Node.js backend (use LAN IP when testing from mobile)
  static const String apiBaseUrl = 'http://localhost:5000';

  // Change this when Flutter Web IP or port changes
  // This is used to build QR links. Do NOT use 'localhost' here when
  // you plan to scan the QR from a mobile device — use your PC LAN IP.
  static const String webAppBaseUrl = 'http://192.168.1.33:64146';
  
}
