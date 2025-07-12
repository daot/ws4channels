# Known Bugs

None at this time. Latest update(6-7-2025) should fix past issues of errors when running the container on a port different then default, incorrect cpu/ram stats in logs, and a rare memory leak.

# ws4channels

A Dockerized Node.js application that combines **WS4KP (WeatherStar 4000 KP)** and **ws4channels** into a single container, providing a complete weather streaming solution for Channels DVR.

## What's Included

- **WS4KP**: WeatherStar 4000+ web interface providing nostalgic weather displays
- **ws4channels**: Streaming service that captures WS4KP screens and creates HLS video streams
- **Nginx**: Reverse proxy that routes traffic to both services
- **Background Music**: 7 included MP3 tracks for the streaming channel

## Prerequisites

- 850MB available RAM
- Docker installed
- Docker Compose (optional, for easier management)

## Quick Start

### Using Docker Compose (Recommended)

1. **Set your ZIP code** (optional):

   ```bash
   export ZIP_CODE="90210"
   ```

2. **Build and run**:

   ```bash
   docker-compose up -d
   ```

3. **Access the services**:
   - **Main Interface**: http://localhost/
   - **WS4KP Direct**: http://localhost:8080/
   - **Stream Playlist**: http://localhost/playlist.m3u
   - **Guide Data**: http://localhost/guide.xml
   - **Health Check**: http://localhost/health

### Using Docker Directly

1. **Pull the Docker Image**:

   ```bash
   docker pull ghcr.io/rice9797/ws4channels:latest
   ```

2. **Run the Container**:
   ```bash
   docker run -d \
     --name ws4channels \
     --restart unless-stopped \
     -p 80:80 \
     -p 8080:8080 \
     -p 9798:9798 \
     -e ZIP_CODE=your_zip_code \
     ghcr.io/rice9797/ws4channels:latest
   ```

## Services Overview

### Ports

- **80**: Main web interface (nginx proxy)
- **8080**: WS4KP direct access
- **9798**: ws4channels direct access

### Environment Variables

#### WS4KP Configuration

- `ZIP_CODE`: Your ZIP code (default: 90210)
- `WSQS_latLonQuery`: Location query string
- `WSQS_hazards_checkbox`: Show weather hazards
- `WSQS_current_weather_checkbox`: Show current weather
- `WSQS_hourly_checkbox`: Show hourly forecast
- `WSQS_hourly_graph_checkbox`: Show hourly graphs
- `WSQS_travel_checkbox`: Show travel forecast
- `WSQS_regional_forecast_checkbox`: Show regional forecast
- `WSQS_local_forecast_checkbox`: Show local forecast
- `WSQS_extended_forecast_checkbox`: Show extended forecast
- `WSQS_almanac_checkbox`: Show almanac data
- `WSQS_spc_outlook_checkbox`: Show SPC outlook
- `WSQS_radar_checkbox`: Show radar
- `WSQS_settings_wide_checkbox`: Wide screen mode
- `WSQS_settings_kiosk_checkbox`: Kiosk mode
- `WSQS_settings_scanLines_checkbox`: Scan lines effect
- `WSQS_settings_speed_select`: Animation speed
- `WSQS_settings_units_select`: Units (us/metric)

#### ws4channels Configuration

- `ZIP_CODE`: ZIP code for weather data
- `WS4KP_HOST`: WS4KP host (default: localhost)
- `WS4KP_PORT`: WS4KP port (default: 8080)
- `STREAM_PORT`: Streaming port (default: 9798)
- `FRAME_RATE`: Video frame rate (default: 10)

## Adding to Channels DVR

1. **Get the playlist URL**: `http://your-server-ip/playlist.m3u`
2. **Add to Channels DVR**:
   - Open Channels DVR
   - Go to Settings → DVR → M3U Tuner
   - Add new M3U tuner
   - Enter the playlist URL
   - Set guide data URL: `http://your-server-ip/guide.xml`

## Customization

### Custom Music

Place your MP3 files in the `music/` directory. The container will use these instead of the default tracks.

### Custom Logo

Replace `logo/ws4000.png` with your own logo file.

### Environment Variables

You can customize the behavior by setting environment variables:

```bash
# Example with custom settings
docker-compose up -d \
  -e ZIP_CODE="10001" \
  -e WSQS_settings_units_select=metric \
  -e FRAME_RATE=15
```

## Troubleshooting

### Check Service Status

```bash
# Check container logs
docker-compose logs -f

# Check individual service health
curl http://localhost/health
curl http://localhost:8080/
curl http://localhost:9798/health
```

### Common Issues

1. **Stream not working**: Check if WS4KP is running on port 8080
2. **No video**: Ensure FFmpeg is working and frame rate is reasonable
3. **Audio issues**: Check if music files are accessible
4. **High CPU usage**: Reduce frame rate or increase CPU limits

### Resource Requirements

- **Memory**: Minimum 1GB, recommended 2GB
- **CPU**: 1 core minimum, 2 cores recommended
- **Storage**: ~500MB for the container

## Architecture

```
┌─────────────────┐
│   Nginx (80)    │ ← Main proxy
├─────────────────┤
│  WS4KP (8080)   │ ← Weather data
├─────────────────┤
│ws4channels(9798)│ ← Video streaming
└─────────────────┘
```

The nginx proxy routes requests to the appropriate service:

- `/` → WS4KP web interface
- `/stream/*`, `/playlist.m3u`, `/guide.xml` → ws4channels
- `/health` → ws4channels health check

## Development

To modify the setup:

1. **Edit Dockerfile**: Change the base image or add dependencies
2. **Edit docker-compose.yml**: Modify ports, environment variables, or volumes
3. **Edit nginx config**: Modify the proxy configuration in the Dockerfile

## Credits

- **WS4KP**: [netbymatt/ws4kp](https://github.com/netbymatt/ws4kp)
- **ws4channels**: [rice9797/ws4channels](https://github.com/rice9797/ws4channels)

This combined setup provides a complete solution for creating a nostalgic weather streaming channel that can be integrated with Channels DVR.
