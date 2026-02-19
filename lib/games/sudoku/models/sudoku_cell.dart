class SudokuCell {
  final int row;
  final int col;
  int value;
  final int solutionValue;
  final bool isInitial;
  Set<int> notes;
  bool isError;

  SudokuCell({
    required this.row,
    required this.col,
    required this.value,
    required this.solutionValue,
    required this.isInitial,
    Set<int>? notes,
    this.isError = false,
  }) : notes = notes ?? {};

  SudokuCell copyWith({int? value, Set<int>? notes, bool? isError}) {
    return SudokuCell(
      row: row,
      col: col,
      value: value ?? this.value,
      solutionValue: solutionValue,
      isInitial: isInitial,
      notes: notes ?? Set.from(this.notes),
      isError: isError ?? this.isError,
    );
  }
}
