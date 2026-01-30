import 'dart:math';
import 'dictionary.dart';

enum WordDifficulty { easy, normal, hard }

class WordBattleLogic {
  static const int gridSize = 4;
  List<String> grid = [];
  Set<String> foundWords = {};
  int score = 0;
  String currentWord = "";
  List<int> selectedPositions = [];
  WordDifficulty difficulty = WordDifficulty.normal;

  WordBattleLogic({this.difficulty = WordDifficulty.normal}) {
    generateGrid();
  }

  // Scrabble-like letter values
  static const Map<String, int> letterValues = {
    'A': 1,
    'B': 3,
    'C': 3,
    'D': 2,
    'E': 1,
    'F': 4,
    'G': 2,
    'H': 4,
    'I': 1,
    'J': 8,
    'K': 5,
    'L': 1,
    'M': 3,
    'N': 1,
    'O': 1,
    'P': 3,
    'Q': 10,
    'R': 1,
    'S': 1,
    'T': 1,
    'U': 1,
    'V': 4,
    'W': 4,
    'X': 8,
    'Y': 4,
    'Z': 10,
  };

  // Letter frequencies based on difficulty
  static String _getLettersForDifficulty(WordDifficulty diff) {
    switch (diff) {
      case WordDifficulty.easy:
        // Heavily weighted towards vowels and common consonants
        return "AAAAAAAAAEEEEEEEEEOOOOOOOOIIIIIIIUUUURRRRRRSSSSSSTTTTTTLLLLNNNNDDDD";
      case WordDifficulty.hard:
        // Fewer vowels, more rare letters
        return "AAAAAEEEEEOOOIIUUUUKKKJJJQQQZZZXXXVVVWWWBBBPYRRRSSSTTT";
      case WordDifficulty.normal:
        return "AAAAAAAAABBCCDDDDEEEEEEEEEEEEFFGGGHHIIIIIIIIIJKLLLLMMNNNNNNOOOOOOOOPPQRRRRRRSSSSSTTTTTTUUUUVVWWXYYZ";
    }
  }

  void generateGrid() {
    final random = Random();
    final lettersSource = _getLettersForDifficulty(difficulty);
    grid = List.generate(
      gridSize * gridSize,
      (index) => lettersSource[random.nextInt(lettersSource.length)],
    );
    foundWords.clear();
    score = 0;
    currentWord = "";
    selectedPositions.clear();
  }

  bool selectLetter(int index) {
    if (selectedPositions.contains(index)) {
      if (selectedPositions.last == index) {
        selectedPositions.removeLast();
        currentWord = currentWord.substring(0, currentWord.length - 1);
        return true;
      }
      return false;
    }

    if (selectedPositions.isNotEmpty) {
      int lastPos = selectedPositions.last;
      int lastRow = lastPos ~/ gridSize;
      int lastCol = lastPos % gridSize;
      int currentRow = index ~/ gridSize;
      int currentCol = index % gridSize;

      if ((lastRow - currentRow).abs() > 1 ||
          (lastCol - currentCol).abs() > 1) {
        return false;
      }
    }

    selectedPositions.add(index);
    currentWord += grid[index];
    return true;
  }

  Map<String, dynamic>? submitWord() {
    String word = currentWord.toLowerCase();

    if (word.length < 3) {
      clearSelection();
      return {'valid': false, 'message': 'Too short!'};
    }

    if (foundWords.contains(word)) {
      clearSelection();
      return {'valid': false, 'message': 'Already found!'};
    }

    if (englishDictionary.contains(word)) {
      int wordScore = calculateScore(word);
      score += wordScore;
      foundWords.add(word);
      String resultWord = currentWord;
      clearSelection();
      return {'valid': true, 'word': resultWord, 'score': wordScore};
    }

    clearSelection();
    return {'valid': false, 'message': 'Not in dictionary!'};
  }

  void clearSelection() {
    currentWord = "";
    selectedPositions.clear();
  }

  int calculateScore(String word) {
    int baseScore = 0;
    for (int i = 0; i < word.length; i++) {
      baseScore += letterValues[word[i].toUpperCase()] ?? 1;
    }

    int bonus = 0;
    if (word.length >= 7) {
      bonus = 25;
    } else if (word.length >= 5) {
      bonus = 10;
    }

    bool hasRare = word.toUpperCase().contains(RegExp(r'[QZXJ]'));
    if (hasRare) {
      bonus += 5;
    }

    return baseScore + bonus;
  }

  String? findAiWord() {
    for (int i = 0; i < grid.length; i++) {
      String? word = _dfsFindWord(i, grid[i].toLowerCase(), {i});
      if (word != null) return word;
    }
    return null;
  }

  String? _dfsFindWord(int pos, String current, Set<int> visited) {
    if (current.length >= 3 &&
        englishDictionary.contains(current) &&
        !foundWords.contains(current)) {
      return current;
    }

    if (current.length >= 8) return null;

    int row = pos ~/ gridSize;
    int col = pos % gridSize;

    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        int nr = row + dr;
        int nc = col + dc;
        if (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
          int nextPos = nr * gridSize + nc;
          if (!visited.contains(nextPos)) {
            String? found = _dfsFindWord(
              nextPos,
              current + grid[nextPos].toLowerCase(),
              {...visited, nextPos},
            );
            if (found != null) return found;
          }
        }
      }
    }
    return null;
  }
}
