import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.accentColor,
    required this.textColor,
    required this.heroImageUrl,
    required this.order,
    this.selectedAccentColor,
    this.selectedTextColor,
  });

  final String id;
  final String name;
  final String slug;
  final String accentColor;
  final String textColor;
  final String heroImageUrl;
  final int order;
  final String? selectedAccentColor;
  final String? selectedTextColor;

  factory Category.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return Category(
      id: doc.id,
      name: (data['name'] as String?)?.trim() ?? 'Category',
      slug: (data['slug'] as String?)?.trim() ?? doc.id,
      accentColor: (data['accentColor'] as String?)?.trim() ?? '0xFFFFE0E0',
      textColor: (data['textColor'] as String?)?.trim() ?? '0xFFE23E3E',
      heroImageUrl: (data['heroImageUrl'] as String?)?.trim() ?? '',
      order: (data['order'] as num?)?.round() ?? 0,
      selectedAccentColor:
          (data['selectedAccentColor'] as String?)?.trim(),
      selectedTextColor: (data['selectedTextColor'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'slug': slug,
        'accentColor': accentColor,
        'textColor': textColor,
        'heroImageUrl': heroImageUrl,
        'order': order,
        if (selectedAccentColor != null)
          'selectedAccentColor': selectedAccentColor,
        if (selectedTextColor != null)
          'selectedTextColor': selectedTextColor,
      };
}
