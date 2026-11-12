/// Shared day label used by the itinerary pill strip and the move sheet so
/// both surfaces name a day the same way.
const _months = [
  'Ene',
  'Feb',
  'Mar',
  'Abr',
  'May',
  'Jun',
  'Jul',
  'Ago',
  'Sep',
  'Oct',
  'Nov',
  'Dic',
];

/// Zero-padded day number plus abbreviated Spanish month, e.g. `05 Nov`.
String dayLabel(DateTime day) =>
    '${day.day.toString().padLeft(2, '0')} ${_months[day.month - 1]}';
