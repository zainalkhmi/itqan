import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import 'models/language_item.dart';
import 'services/translation_service.dart';

class LanguageSelectorDialog extends StatefulWidget {
  final String currentCode;
  final ValueChanged<LanguageItem> onSelected;

  const LanguageSelectorDialog({
    super.key,
    required this.currentCode,
    required this.onSelected,
  });

  @override
  State<LanguageSelectorDialog> createState() => _LanguageSelectorDialogState();
}

class _LanguageSelectorDialogState extends State<LanguageSelectorDialog> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final all = TranslationService.supportedLanguages;
    final filtered = _search.isEmpty
        ? all
        : all.where((l) =>
            l.name.toLowerCase().contains(_search.toLowerCase()) ||
            l.nativeName.toLowerCase().contains(_search.toLowerCase()) ||
            l.code.toLowerCase().contains(_search.toLowerCase())).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(ItqanSpacing.lg),
      decoration: const BoxDecoration(
        color: ItqanColors.onyx,
        borderRadius: BorderRadius.vertical(top: Radius.circular(ItqanRadius.xl)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Language (20+ Languages)', style: ItqanTypography.heading2),
                  Text('${all.length} international languages supported', style: ItqanTypography.caption),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: ItqanColors.mist),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: ItqanSpacing.md),
          TextField(
            style: ItqanTypography.body,
            decoration: InputDecoration(
              hintText: 'Search language / cari bahasa...',
              hintStyle: const TextStyle(color: ItqanColors.mist),
              prefixIcon: const Icon(Icons.search, color: ItqanColors.gold),
              fillColor: ItqanColors.charcoal,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(ItqanRadius.md)),
            ),
            onChanged: (v) => setState(() => _search = v.trim()),
          ),
          const SizedBox(height: ItqanSpacing.md),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(color: ItqanColors.charcoal, height: 1),
              itemBuilder: (ctx, i) {
                final lang = filtered[i];
                final isSelected = lang.code.toLowerCase() == widget.currentCode.toLowerCase() ||
                    lang.name.toLowerCase() == widget.currentCode.toLowerCase();

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: Text(lang.flagEmoji, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    lang.nativeName,
                    style: TextStyle(
                      color: isSelected ? ItqanColors.gold : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontFamily: lang.isRtl ? 'NotoNaskhArabic' : null,
                    ),
                  ),
                  subtitle: Text(
                    '${lang.name} (${lang.code.toUpperCase()})${lang.isRtl ? " • RTL" : ""}',
                    style: ItqanTypography.caption,
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: ItqanColors.gold)
                      : null,
                  onTap: () {
                    widget.onSelected(lang);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
