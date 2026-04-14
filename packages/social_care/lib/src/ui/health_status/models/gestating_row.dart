/// Mutable UI model for a gestating member row.
class GestatingRow {
  String? memberId;
  int monthsGestation;
  bool startedPrenatalCare;

  GestatingRow({
    this.memberId,
    this.monthsGestation = 1,
    this.startedPrenatalCare = false,
  });

  GestatingRow copy() => GestatingRow(
    memberId: memberId,
    monthsGestation: monthsGestation,
    startedPrenatalCare: startedPrenatalCare,
  );
}
