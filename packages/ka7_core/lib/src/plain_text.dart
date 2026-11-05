/// [text] as plain lowercase letters, for comparing what people type with
/// what YouTube titles show: styled letters (𝐁𝐨𝐥𝐝, 𝘐𝘵𝘢𝘭𝘪𝘤, ＦＵＬＬ…) become
/// the letters they stand for, accents go (é → e, Ë → e).
String plainText(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    // Combining accent marks (an Ë written as E + ¨): dropped.
    if (rune >= 0x0300 && rune <= 0x036F) continue;
    out.write(_plain(rune));
  }
  return out.toString().toLowerCase();
}

String _plain(int rune) {
  // Mathematical letters: 13 styles of A–Z then a–z, one after the other.
  if (rune >= 0x1D400 && rune <= 0x1D6A3) {
    final i = (rune - 0x1D400) % 52;
    return String.fromCharCode(i < 26 ? 0x41 + i : 0x61 + i - 26);
  }
  // Mathematical digits: 5 styles of 0–9.
  if (rune >= 0x1D7CE && rune <= 0x1D7FF) {
    return String.fromCharCode(0x30 + (rune - 0x1D7CE) % 10);
  }
  // Fullwidth letters and digits.
  if ((rune >= 0xFF21 && rune <= 0xFF3A) ||
      (rune >= 0xFF41 && rune <= 0xFF5A) ||
      (rune >= 0xFF10 && rune <= 0xFF19)) {
    return String.fromCharCode(rune - 0xFEE0);
  }
  final char = String.fromCharCode(rune);
  return _accents[char] ?? char;
}

/// Accented Latin letters met in French and Malagasy titles.
const _accents = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', //
  'À': 'A', 'Á': 'A', 'Â': 'A', 'Ä': 'A', 'Ã': 'A', 'Å': 'A', //
  'ç': 'c', 'Ç': 'C', //
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', //
  'È': 'E', 'É': 'E', 'Ê': 'E', 'Ë': 'E', //
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', //
  'Ì': 'I', 'Í': 'I', 'Î': 'I', 'Ï': 'I', //
  'ñ': 'n', 'Ñ': 'N', //
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', //
  'Ò': 'O', 'Ó': 'O', 'Ô': 'O', 'Ö': 'O', 'Õ': 'O', //
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', //
  'Ù': 'U', 'Ú': 'U', 'Û': 'U', 'Ü': 'U', //
  'ÿ': 'y', 'Ÿ': 'Y', 'ỳ': 'y', 'Ỳ': 'Y', //
};
