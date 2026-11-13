class LanguageItem {
  final String code;
  final String name;
  final String nativeName;
  final String flagEmoji;
  final bool isRtl;

  const LanguageItem({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flagEmoji,
    this.isRtl = false,
  });
}
