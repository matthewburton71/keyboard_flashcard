import 'dart:math';

class Notes {
  static Set<int> A = {21, 33, 45, 57, 69, 81, 93, 104};
  static List<String> notes = [
    "C",
    "C#",
    "D",
    "D#",
    "E",
    "F",
    "F#",
    "G",
    "G#",
    "A",
    "A#",
    "B",
  ];

  static List<String> naturalNotes = ["C", "D", "E", "F", "G", "A", "B"];

  static String getNoteLetter(int note) {
    int i = note % 12;
    return notes[i];
  }

  static int getOctave(int note) {
    return (note ~/ 12) - 1;
  }

  static getRandomNaturalNote() {
    return naturalNotes[Random().nextInt(naturalNotes.length)];
  }

  static getRandomNote() {
    return naturalNotes[Random().nextInt(notes.length)];
  }
}
