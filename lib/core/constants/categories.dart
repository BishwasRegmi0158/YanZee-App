// lib/core/constants/categories.dart

/// Backend enum values (source of truth).
const List<String> categoryEnums = [
  'FASHION',
  'SPORTS',
  'KIDS',
  'BEAUTY',
  'OUTLET',
  'PREMIUM',
  'HOME_DECOR',
];

const List<String> audienceEnums = [
  'MEN',
  'WOMEN',
  'UNISEX',
  'BOY',
  'GIRL',
  'KIDS_UNISEX',
];

/// Display labels shown in category pills / grid.
const List<String> categoryLabels = [
  'Fashion',
  'Sports',
  'Kids',
  'Beauty',
  'Outlet',
  'Premium',
  'Home Decor',
];

/// Label -> backend enum. The enum is what goes in the route
/// (/home/category/FASHION) and in the ?category= query.
const Map<String, String> categorySlugMap = {
  'Fashion': 'FASHION',
  'Sports': 'SPORTS',
  'Kids': 'KIDS',
  'Beauty': 'BEAUTY',
  'Outlet': 'OUTLET',
  'Premium': 'PREMIUM',
  'Home Decor': 'HOME_DECOR',
};

const Map<String, String> audienceLabels = {
  'MEN': 'Men',
  'WOMEN': 'Women',
  'UNISEX': 'Unisex',
  'BOY': 'Boys',
  'GIRL': 'Girls',
  'KIDS_UNISEX': 'Kids (Unisex)',
};

/// 'HOME_DECOR' -> 'Home Decor'. Falls back to the raw value.
String categoryLabelFor(String enumValue) {
  for (final entry in categorySlugMap.entries) {
    if (entry.value == enumValue.toUpperCase()) return entry.key;
  }
  return enumValue;
}

String audienceLabelFor(String enumValue) =>
    audienceLabels[enumValue.toUpperCase()] ?? enumValue;