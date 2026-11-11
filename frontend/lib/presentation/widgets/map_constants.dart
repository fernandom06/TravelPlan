import 'package:latlong2/latlong.dart';

const kDefaultCenter = LatLng(42.0414, -3.0428);

const kDefaultZoom = 13.0;

const kMinZoom = 3.0;

const kMaxZoom = 18.0;

/// OpenStreetMap standard raster tiles. Attribution to OSM contributors is
/// rendered on the map via `RichAttributionWidget`.
const kOsmTileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
