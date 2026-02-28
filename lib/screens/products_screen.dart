// lib/screens/products_screen.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/app_providers.dart';
import '../utils/weather_condition_theme.dart';

// ── WMS config ────────────────────────────────────────────────────────────────
const String _wmsDate     = '2026-02-27-hr-00-00-00';
const String _wmsPressure = '850';
const String _wmsLayer    = 'dhurbi:road';
const String _wmsVersion  = '1.1.1';

// =============================================================================
// NCMRWF WMS TILE PROVIDER
// =============================================================================
class _NcmrwfWmsTileProvider extends TileProvider {
  final String endpoint;
  final String date;
  final String pressure;

  _NcmrwfWmsTileProvider({
    required this.endpoint,
    required this.date,
    required this.pressure,
  });

  String _tileToBbox(int z, int x, int y) {
    final n      = math.pow(2, z).toDouble();
    final minLon = x / n * 360.0 - 180.0;
    final maxLon = (x + 1) / n * 360.0 - 180.0;
    final maxLat = _tile2lat(y, z);
    final minLat = _tile2lat(y + 1, z);
    return '${minLon.toStringAsFixed(6)},${minLat.toStringAsFixed(6)}'
        ',${maxLon.toStringAsFixed(6)},${maxLat.toStringAsFixed(6)}';
  }

  double _tile2lat(int y, int z) {
    final n = math.pi - (2.0 * math.pi * y) / math.pow(2.0, z);
    return (180.0 / math.pi) * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final bbox = _tileToBbox(
      coordinates.z.toInt(),
      coordinates.x.toInt(),
      coordinates.y.toInt(),
    );
    final uri = Uri.parse(endpoint).replace(queryParameters: {
      'SERVICE':     'WMS',
      'VERSION':     _wmsVersion,
      'REQUEST':     'GetMap',
      'LAYERS':      _wmsLayer,
      'STYLES':      '',
      'FORMAT':      'image/png',
      'TRANSPARENT': 'true',
      'SRS':         'EPSG:4326',
      'WIDTH':       '256',
      'HEIGHT':      '256',
      'BBOX':        bbox,
      'date':        date,
      'pressure':    pressure,
    });
    debugPrint('[NCMRWF-WMS] ${coordinates.z}/${coordinates.x}/${coordinates.y}\n→ $uri');
    return NetworkImage(uri.toString());
  }
}

// ── Weather layer model ───────────────────────────────────────────────────────
class _WeatherLayer {
  final String id;
  final String label;
  final IconData icon;
  final String wmsEndpoint;
  final List<Color> legendColors;
  final List<String> legendLabels;
  final String unit;

  const _WeatherLayer({
    required this.id,
    required this.label,
    required this.icon,
    required this.wmsEndpoint,
    required this.legendColors,
    required this.legendLabels,
    required this.unit,
  });
}

const List<_WeatherLayer> _layers = [
  _WeatherLayer(
    id: 'temperature',
    label: 'Temperature',
    icon: Icons.thermostat_rounded,
    wmsEndpoint: 'https://api.ncmrwf.gov.in/temperature/',
    unit: '°C',
    legendColors: [
      Color(0xFF4575B4), Color(0xFF74ADD1), Color(0xFFABD9E9),
      Color(0xFFE0F3F8), Color(0xFFFEE090), Color(0xFFFDAE61),
      Color(0xFFF46D43), Color(0xFFD73027),
    ],
    legendLabels: ['-40', '-20', '-10', '0', '15', '25', '35', '50'],
  ),
  _WeatherLayer(
    id: 'humidity',
    label: 'Humidity',
    icon: Icons.water_drop_rounded,
    wmsEndpoint: 'https://api.ncmrwf.gov.in/humidity/',
    unit: '%',
    legendColors: [
      Color(0xFFFFF9C4), Color(0xFFFFF176), Color(0xFFFFEE58),
      Color(0xFF81D4FA), Color(0xFF29B6F6), Color(0xFF0288D1),
      Color(0xFF01579B), Color(0xFF003366),
    ],
    legendLabels: ['0', '10', '20', '40', '60', '70', '80', '100'],
  ),
  _WeatherLayer(
    id: 'rainfall',
    label: 'Rainfall',
    icon: Icons.grain_rounded,
    wmsEndpoint: 'https://api.ncmrwf.gov.in/rainfall/',
    unit: 'mm',
    legendColors: [
      Color(0xFFE8F5E9), Color(0xFFC8E6C9), Color(0xFFA5D6A7),
      Color(0xFF66BB6A), Color(0xFF2E7D32), Color(0xFF0D47A1),
      Color(0xFF4A148C),
    ],
    legendLabels: ['0', '0.5', '2', '5', '10', '50', '200'],
  ),
  _WeatherLayer(
    id: 'acurain',
    label: 'Acc. Rainfall',
    icon: Icons.water_rounded,
    wmsEndpoint: 'https://api.ncmrwf.gov.in/acurain/',
    unit: 'mm',
    legendColors: [
      Color(0xFFF3E5F5), Color(0xFFE1BEE7), Color(0xFFCE93D8),
      Color(0xFFAB47BC), Color(0xFF7B1FA2), Color(0xFF4A148C),
      Color(0xFF1A0030),
    ],
    legendLabels: ['0', '5', '10', '25', '50', '100', '200+'],
  ),
];

// =============================================================================
// MAIN SCREEN
// =============================================================================
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {

  int _selectedLayer = 0;
  final MapController _mapController = MapController();

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;
  bool _showLegend = true;

  LatLng? _tappedLatLng;
  Offset? _tappedScreen;
  bool    _showPopup = false;
  final GlobalKey _mapKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _switchLayer(int idx) {
    if (idx == _selectedLayer) return;
    _fadeCtrl.reset();
    setState(() => _selectedLayer = idx);
    _fadeCtrl.forward();
  }

  void _onMapTap(TapPosition tapPos, LatLng point) {
    final pt = _mapController.camera.latLngToScreenPoint(point);
    setState(() {
      _tappedLatLng = point;
      _tappedScreen = Offset(pt.x, pt.y);
      _showPopup    = true;
    });
  }

  void _closePopup() => setState(() => _showPopup = false);

  void _openMeteogram(LatLng pt) {
    _closePopup();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MeteogramSheet(point: pt),
    );
  }

  void _openVerticalProfile(LatLng pt) {
    _closePopup();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VerticalProfileSheet(point: pt),
    );
  }

  void _openEPSgram(LatLng pt) {
    _closePopup();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EPSgramSheet(point: pt),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();
    return Consumer<WeatherProvider>(builder: (ctx, wp, _) {
      final condition = wp.currentWeather?.condition ?? 'cloudy';
      final condTheme = WeatherConditionTheme.of(condition);
      final layer     = _layers[_selectedLayer];
      final centerLat = wp.latitude  != 0.0 ? wp.latitude  : 20.5937;
      final centerLon = wp.longitude != 0.0 ? wp.longitude : 78.9629;

      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: condTheme.skyGradient,
            ),
          ),
          child: SafeArea(
            child: Column(children: [
              _buildTopBar(wp),
              _buildLayerSelector(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      key: _mapKey,
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: LatLng(centerLat, centerLon),
                            initialZoom: 5.0,
                            minZoom: 2.0,
                            maxZoom: 12.0,
                            onTap: _onMapTap,
                            onPositionChanged: (pos, hasGesture) {
                              if (hasGesture && _showPopup) _closePopup();
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                              'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png',
                              subdomains: const ['a', 'b', 'c', 'd'],
                              userAgentPackageName: 'com.example.new_ncmrwf_app',
                              maxZoom: 19,
                            ),
                            FadeTransition(
                              opacity: _fadeAnim,
                              child: Opacity(
                                opacity: 0.85,
                                child: TileLayer(
                                  key: ValueKey(layer.id),
                                  urlTemplate: layer.wmsEndpoint,
                                  tileProvider: _NcmrwfWmsTileProvider(
                                    endpoint: layer.wmsEndpoint,
                                    date:     _wmsDate,
                                    pressure: _wmsPressure,
                                  ),
                                  userAgentPackageName: 'com.example.new_ncmrwf_app',
                                  maxZoom: 12,
                                  minZoom: 2,
                                ),
                              ),
                            ),
                            TileLayer(
                              urlTemplate:
                              'https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}.png',
                              subdomains: const ['a', 'b', 'c', 'd'],
                              userAgentPackageName: 'com.example.new_ncmrwf_app',
                              maxZoom: 19,
                            ),
                            if (wp.latitude != 0.0 && wp.longitude != 0.0)
                              MarkerLayer(markers: [
                                Marker(
                                  point: LatLng(wp.latitude, wp.longitude),
                                  width: 120,
                                  height: 64,
                                  child: _LocationMarker(wp: wp, layer: layer),
                                ),
                              ]),
                          ],
                        ),
                        Positioned(top: 12, left: 12, child: _buildZoomControls()),
                        Positioned(
                          top: 12, right: 12,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _showLegend = !_showLegend),
                            child: _glassBox(
                              child: Icon(
                                _showLegend
                                    ? Icons.layers_rounded
                                    : Icons.layers_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        if (_showLegend)
                          Positioned(
                            bottom: 12, left: 12, right: 12,
                            child: _buildLegend(layer),
                          ),
                        if (_showPopup &&
                            _tappedLatLng != null &&
                            _tappedScreen != null)
                          _buildFloatingPopup(layer),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
    });
  }

  Widget _buildFloatingPopup(_WeatherLayer layer) {
    const popupW = 215.0;
    const popupH = 210.0;
    const pinGap = 10.0;

    final RenderBox? box =
    _mapKey.currentContext?.findRenderObject() as RenderBox?;
    final mapW = box?.size.width  ?? 400.0;
    final mapH = box?.size.height ?? 600.0;

    double left = _tappedScreen!.dx - popupW / 2;
    double top  = _tappedScreen!.dy - popupH - pinGap;
    left = left.clamp(6.0, mapW - popupW - 6.0);
    top  = top.clamp(6.0, mapH - popupH - 6.0);

    return Positioned(
      left: left, top: top,
      child: _TapPopup(
        layer:             layer,
        point:             _tappedLatLng!,
        popupWidth:        popupW,
        onClose:           _closePopup,
        onMeteogram:       () => _openMeteogram(_tappedLatLng!),
        onVerticalProfile: () => _openVerticalProfile(_tappedLatLng!),
        onEPSgram:         () => _openEPSgram(_tappedLatLng!),
      ),
    );
  }

  Widget _buildTopBar(WeatherProvider wp) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(.2)),
          child: const Icon(Icons.map_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weather Map',
                    style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                if (wp.placeName.isNotEmpty)
                  Text(wp.placeName,
                      style: GoogleFonts.dmSans(
                          color: Colors.white60, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
              ]),
        ),
        if (wp.latitude != 0.0)
          GestureDetector(
            onTap: () =>
                _mapController.move(LatLng(wp.latitude, wp.longitude), 6),
            child: _glassBox(
                child: const Icon(Icons.my_location_rounded,
                    color: Colors.white, size: 18)),
          ),
      ]),
    );
  }

  Widget _buildLayerSelector() {
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        itemCount: _layers.length,
        itemBuilder: (ctx, i) {
          final sel = i == _selectedLayer;
          final l   = _layers[i];
          return GestureDetector(
            onTap: () => _switchLayer(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              margin: const EdgeInsets.only(right: 8),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: sel
                    ? Colors.white.withOpacity(0.30)
                    : Colors.white.withOpacity(0.12),
                border: Border.all(
                  color: sel
                      ? Colors.white.withOpacity(0.7)
                      : Colors.white.withOpacity(0.2),
                  width: sel ? 1.5 : 1.0,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(l.icon,
                    color: sel ? Colors.white : Colors.white54, size: 15),
                const SizedBox(width: 6),
                Text(l.label,
                    style: GoogleFonts.dmSans(
                      color: sel ? Colors.white : Colors.white60,
                      fontSize: 12,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    )),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend(_WeatherLayer layer) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(layer.icon, color: Colors.white70, size: 14),
                  const SizedBox(width: 6),
                  Text('${layer.label}  (${layer.unit})',
                      style: GoogleFonts.dmSans(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 12,
                    child: Row(
                      children: layer.legendColors
                          .map((c) => Expanded(child: ColoredBox(color: c)))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: layer.legendLabels
                      .map((l) => Text(l,
                      style: GoogleFonts.dmSans(
                          color: Colors.white54, fontSize: 9)))
                      .toList(),
                ),
              ]),
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Column(children: [
            _ZoomBtn(
              icon: Icons.add_rounded,
              onTap: () => _mapController.move(
                _mapController.camera.center,
                (_mapController.camera.zoom + 1).clamp(2.0, 12.0),
              ),
            ),
            Container(height: 1, width: 32, color: Colors.white12),
            _ZoomBtn(
              icon: Icons.remove_rounded,
              onTap: () => _mapController.move(
                _mapController.camera.center,
                (_mapController.camera.zoom - 1).clamp(2.0, 12.0),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _glassBox({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(.3)),
          ),
          child: child,
        ),
      ),
    );
  }
}

// =============================================================================
// TAP POPUP
// =============================================================================
class _TapPopup extends StatefulWidget {
  final _WeatherLayer layer;
  final LatLng        point;
  final double        popupWidth;
  final VoidCallback  onClose;
  final VoidCallback  onMeteogram;
  final VoidCallback  onVerticalProfile;
  final VoidCallback  onEPSgram;

  const _TapPopup({
    required this.layer,
    required this.point,
    required this.onClose,
    required this.onMeteogram,
    required this.onVerticalProfile,
    required this.onEPSgram,
    this.popupWidth = 215,
  });

  @override
  State<_TapPopup> createState() => _TapPopupState();
}

class _TapPopupState extends State<_TapPopup> {
  int _selectedOption = 0;

  String get _headerLabel {
    switch (widget.layer.id) {
      case 'temperature': return 'TEMPERATURE: -- °C';
      case 'humidity':    return 'HUMIDITY: -- %';
      case 'rainfall':    return 'RAINFALL: -- mm';
      case 'acurain':     return 'ACC. RAINFALL: -- mm';
      default:            return '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: widget.popupWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 14,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Row(children: [
                Expanded(
                  child: Text(_headerLabel,
                      style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87)),
                ),
                GestureDetector(
                  onTap: widget.onClose,
                  child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 15, color: Colors.black45)),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _RadioOption(
                    label: 'Meteogram',
                    value: 0,
                    groupValue: _selectedOption,
                    onChanged: (v) => setState(() => _selectedOption = v!)),
                _RadioOption(
                    label: 'Vertical Profile',
                    value: 1,
                    groupValue: _selectedOption,
                    onChanged: (v) => setState(() => _selectedOption = v!)),
                _RadioOption(
                    label: 'EPSgram',
                    value: 2,
                    groupValue: _selectedOption,
                    onChanged: (v) => setState(() => _selectedOption = v!)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () {
                      switch (_selectedOption) {
                        case 0: widget.onMeteogram();       break;
                        case 1: widget.onVerticalProfile(); break;
                        case 2: widget.onEPSgram();         break;
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7)),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text('View Details',
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String          label;
  final int             value;
  final int             groupValue;
  final ValueChanged<int?> onChanged;

  const _RadioOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(value),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(children: [
          Radio<int>(
            value: value,
            groupValue: groupValue,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            activeColor: const Color(0xFF1565C0),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

// =============================================================================
// BASE SHEET — overflow-safe
// =============================================================================
// Root cause of EPSgram overflow:
//   Old _BaseSheet used a Column → children: [header, Expanded(child)]
//   where `child` was another Column with 5 fixed-height charts (~670px total).
//   A Column inside SingleChildScrollView only scrolls if it's unconstrained,
//   but Expanded constrains it → overflow.
//
// Fix:
//   Replace the inner Column+SingleChildScrollView with a plain ListView whose
//   controller is the DraggableScrollableSheet's scrollCtrl. Charts are passed
//   as a flat list of items. ListView is always scrollable and never overflows.
// =============================================================================
class _BaseSheet extends StatelessWidget {
  final String       title;
  final String       subtitle;
  final List<Widget> chartWidgets;

  const _BaseSheet({
    required this.title,
    required this.subtitle,
    required this.chartWidgets,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize:     0.40,
      maxChildSize:     0.95,
      expand:           false, // never expands beyond maxChildSize
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ── Drag handle ──────────────────────────────────────────
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),

              // ── Header ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                child: Row(children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: GoogleFonts.dmSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87)),
                          const SizedBox(height: 2),
                          Text(subtitle,
                              style: GoogleFonts.dmSans(
                                  fontSize: 10, color: Colors.black45)),
                        ]),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8)),
                    child: IconButton(
                      icon: const Icon(Icons.picture_as_pdf_rounded,
                          size: 18, color: Colors.black54),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 20, color: Colors.black45),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ]),
              ),
              const Divider(height: 1),

              // ── Chart list — scrollable, no overflow ─────────────────
              // Expanded gives ListView all remaining vertical space.
              // ListView.separated scrolls when charts exceed that space.
              Expanded(
                child: ListView.separated(
                  controller:  scrollCtrl,
                  padding:     const EdgeInsets.fromLTRB(16, 14, 16, 32),
                  itemCount:   chartWidgets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => chartWidgets[i],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// SHEET IMPLEMENTATIONS
// =============================================================================

class _MeteogramSheet extends StatelessWidget {
  final LatLng point;
  const _MeteogramSheet({required this.point});

  @override
  Widget build(BuildContext context) {
    return _BaseSheet(
      title:    'Meteogram',
      subtitle: 'lat=${point.latitude.toStringAsFixed(4)}, '
          'lon=${point.longitude.toStringAsFixed(4)}',
      chartWidgets: [
        const _PlaceholderChart(
          title:  'Temperature (°C) & Relative Humidity (%)',
          height: 220,
          color:  Color(0xFFFFF3E0),
          icon:   Icons.show_chart_rounded,
        ),
        const _PlaceholderChart(
          title:  'Rainfall (mm/hr)',
          height: 130,
          color:  Color(0xFFE3F2FD),
          icon:   Icons.bar_chart_rounded,
        ),
        Wrap(spacing: 16, runSpacing: 6, children: const [
          _LegendDot(color: Colors.red,        label: 'Temperature'),
          _LegendDot(color: Colors.cyan,       label: 'Rainfall'),
          _LegendDot(color: Color(0xFF90CAF9), label: 'Rel. Humidity'),
          _LegendDot(color: Colors.black87,    label: 'Wind'),
        ]),
      ],
    );
  }
}

class _VerticalProfileSheet extends StatelessWidget {
  final LatLng point;
  const _VerticalProfileSheet({required this.point});

  @override
  Widget build(BuildContext context) {
    return _BaseSheet(
      title:    'Vertical Profile',
      subtitle: 'Skew-T  lat=${point.latitude.toStringAsFixed(4)}, '
          'lon=${point.longitude.toStringAsFixed(4)}',
      chartWidgets: [
        const _PlaceholderChart(
          title:  'Skew-T Log-P Diagram (Ensemble Mean ± Spread)',
          height: 360,
          color:  Color(0xFFE8F5E9),
          icon:   Icons.ssid_chart_rounded,
        ),
        Wrap(spacing: 16, children: const [
          _LegendDot(color: Color(0xFFB71C1C), label: 'Temperature'),
          _LegendDot(color: Color(0xFF1B5E20), label: 'Dewpoint'),
        ]),
      ],
    );
  }
}

/// EPSgram — 5 separate chart widgets passed as a flat list to _BaseSheet.
/// ListView handles scrolling automatically; no Column wrapping all charts.
class _EPSgramSheet extends StatelessWidget {
  final LatLng point;
  const _EPSgramSheet({required this.point});

  @override
  Widget build(BuildContext context) {
    return _BaseSheet(
      title:    'EPSgram',
      subtitle: 'Control Forecast & ENS Distribution\n'
          'lat=${point.latitude.toStringAsFixed(4)}, '
          'lon=${point.longitude.toStringAsFixed(4)}',
      chartWidgets: const [
        _PlaceholderChart(
          title:  'Temp 2m (°C)',
          height: 140,
          color:  Color(0xFFFFF3E0),
          icon:   Icons.thermostat_rounded,
        ),
        _PlaceholderChart(
          title:  'RH 2m (%)',
          height: 120,
          color:  Color(0xFFE3F2FD),
          icon:   Icons.water_drop_rounded,
        ),
        _PlaceholderChart(
          title:  '10m Wind (m/s)',
          height: 120,
          color:  Color(0xFFE0F2F1),
          icon:   Icons.air_rounded,
        ),
        _PlaceholderChart(
          title:  'Rain (mm/6h)',
          height: 110,
          color:  Color(0xFFE8F5E9),
          icon:   Icons.grain_rounded,
        ),
        _PlaceholderChart(
          title:  'MSLP (hPa)',
          height: 120,
          color:  Color(0xFFF3E5F5),
          icon:   Icons.speed_rounded,
        ),
      ],
    );
  }
}

// =============================================================================
// SHARED WIDGETS
// =============================================================================

class _PlaceholderChart extends StatelessWidget {
  final String   title;
  final double   height;
  final Color    color;
  final IconData icon;

  const _PlaceholderChart({
    required this.title,
    required this.height,
    required this.color,
    this.icon = Icons.bar_chart_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 34, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(title,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 4),
        Text('Connect API to render chart',
            style: GoogleFonts.dmSans(
                fontSize: 10, color: Colors.grey.shade400)),
      ]),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color  color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style: GoogleFonts.dmSans(fontSize: 11, color: Colors.black54)),
    ]);
  }
}

class _LocationMarker extends StatelessWidget {
  final WeatherProvider wp;
  final _WeatherLayer   layer;
  const _LocationMarker({required this.wp, required this.layer});

  String get _value {
    final cw = wp.currentWeather;
    if (cw == null) return '--';
    switch (layer.id) {
      case 'temperature': return '${cw.temperatureC.toStringAsFixed(0)}°C';
      case 'humidity':    return '${cw.humidityPercent.toStringAsFixed(0)}%';
      case 'rainfall':    return '0.0 mm';
      case 'acurain':     return '0 mm';
      default:            return '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(wp.placeName.split(',').first,
                  style: GoogleFonts.dmSans(
                      color: Colors.white, fontSize: 9,
                      fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis),
              Text(_value,
                  style: GoogleFonts.dmSans(
                      color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      ),
      Container(width: 2, height: 8, color: Colors.white.withOpacity(0.8)),
      Container(
          width: 8, height: 8,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Colors.white)),
    ]);
  }
}

class _ZoomBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  const _ZoomBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(
        width: 36, height: 36,
        child: Icon(icon, color: Colors.white, size: 20)),
  );
}