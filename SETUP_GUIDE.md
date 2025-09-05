# S25007 MQTT Controller Setup Guide

## Supabase Configuration

### 1. Create a Supabase Project

1. Go to [Supabase](https://supabase.com) and create a new project
2. Note down your project URL and anon key from the project settings

### 2. Set up Database Tables

1. Go to the SQL Editor in your Supabase dashboard
2. Copy and paste the contents of `supabase_setup.sql`
3. Run the SQL script to create the necessary tables

### 3. Configure the Application

1. Open `lib/config/environment.dart`
2. Replace the placeholder values:
   ```dart
   static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
   static const String supabaseAnonKey = 'YOUR_ANON_KEY';
   ```

### 4. Install Dependencies

```bash
cd s25007_mqtt_controller
flutter pub get
```

### 5. Run the Application

For web:
```bash
flutter run -d chrome
```

For mobile:
```bash
flutter run
```

## Features

### MQTT Data Logging
- Automatically logs MQTT data to Supabase every 10 seconds
- Stores topic, payload, and timestamp

### History View
- View data from the last 1 hour
- View data from the last 24 hours
- Custom date range selection
- Interactive chart visualization
- List view of all data points

### Real-time Dashboard
- Live MQTT status updates
- Send commands to devices
- Connection status indicator

## Building for Production

### Web Deployment (GitHub Pages)

```bash
flutter build web --base-href /cube_automation/
```

Then copy the build output to the docs folder for GitHub Pages deployment.

## Troubleshooting

### MQTT Connection Issues
- Ensure you have the correct broker URL and credentials
- Check that port 8884 is not blocked
- Verify WebSocket support is enabled

### Supabase Connection Issues
- Verify your Supabase URL and anon key are correct
- Check that the tables are created properly
- Ensure Row Level Security policies are configured

### Data Not Showing in History
- Verify MQTT data is being received
- Check Supabase table for data entries
- Ensure time zone settings are correct