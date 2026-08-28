enum ItinerarySlot {
  morning('morning', 'Mañana'),
  afternoon('afternoon', 'Tarde'),
  night('night', 'Noche');

  const ItinerarySlot(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static ItinerarySlot? fromWireValue(String? value) {
    for (final slot in values) {
      if (slot.wireValue == value) return slot;
    }
    return null;
  }
}