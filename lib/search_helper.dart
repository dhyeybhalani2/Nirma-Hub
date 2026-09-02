String generateShortForm(String name) {
  final ignoreWords = ['for', 'and', 'in', 'to', 'of', '&', 'the', 'introduction', 'or', 'a', 'an'];
  final words = name.split(RegExp(r'\s+'));
  String shortForm = '';
  
  for (var word in words) {
    final cleanWord = word.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (cleanWord.isEmpty) continue;
    
    if (ignoreWords.contains(cleanWord.toLowerCase())) continue;
    
    // If word is already fully uppercase (like AI, ML), keep it as is.
    if (cleanWord == cleanWord.toUpperCase() && cleanWord.length > 1) {
      shortForm += cleanWord;
    } else {
      // Otherwise just take the first letter
      shortForm += cleanWord[0].toUpperCase();
    }
  }
  return shortForm.toLowerCase();
}
