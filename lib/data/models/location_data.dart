class CountryInfo {
  final String name;
  final Map<String, List<String>> provinces;
  final Map<String, Map<String, List<String>>>? districts;

  const CountryInfo({required this.name, required this.provinces, this.districts});
}

const allowedCountries = ['NP', 'US', 'IN'];

final Map<String, CountryInfo> locationData = {
  'NP': const CountryInfo(
    name: 'Nepal',
    provinces: {},
    districts: {
      'Bagmati Province': {
        'Kathmandu': ['Kathmandu', 'Kirtipur'],
        'Lalitpur': ['Lalitpur', 'Godawari'],
        'Makwanpur': ['Hetauda'],
      },
      'Gandaki Province': {
        'Kaski': ['Pokhara'],
      },
    },
  ),
  'US': const CountryInfo(
    name: 'United States',
    provinces: {
      'California': ['Los Angeles', 'San Francisco', 'San Diego'],
      'New York': ['New York City', 'Buffalo'],
    },
  ),
  'IN': const CountryInfo(
    name: 'India',
    provinces: {
      'Maharashtra': ['Mumbai', 'Pune'],
      'Delhi': ['New Delhi'],
    },
  ),
};

bool countryHasDistricts(String countryCode) {
  final info = locationData[countryCode];
  return info?.districts != null && info!.districts!.isNotEmpty;
}

List<String> getProvincesForCountry(String? countryCode) {
  if (countryCode == null) return [];
  final info = locationData[countryCode]!;
  return countryHasDistricts(countryCode)
      ? info.districts!.keys.toList()
      : info.provinces.keys.toList();
}

List<String> getDistrictsForProvince(String? countryCode, String? province) {
  if (countryCode == null || province == null) return [];
  final info = locationData[countryCode]!;
  return info.districts?[province]?.keys.toList() ?? [];
}

List<String> getCitiesForDistrict(String? countryCode, String? province, String? district) {
  if (countryCode == null || province == null || district == null) return [];
  return locationData[countryCode]!.districts?[province]?[district] ?? [];
}

List<String> getCitiesForProvince(String? countryCode, String? province) {
  if (countryCode == null || province == null) return [];
  return locationData[countryCode]!.provinces[province] ?? [];
}