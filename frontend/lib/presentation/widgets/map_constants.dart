import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

const kDefaultCenter = LatLng(42.0414, -3.0428);

const kDefaultZoom = 13.0;

const kMinZoom = 3.0;

const kMaxZoom = 18.0;

/// CartoDB Positron light tiles (subdomains a–d). Attribution to OSM + CARTO
/// is rendered on the map via `RichAttributionWidget`.
const kCartoTileUrlTemplate =
    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';

// TEMP: legacy marker colors, removed once teardrop pins land (step 4.2).
const kNewMarkerColor = Colors.red;
const kSavedMarkerColor = Colors.blue;