const String nepalCountry = 'Nepal';

/// Province -> District -> Cities / Municipalities
const Map<String, Map<String, List<String>>> nepalLocations = {
  'Koshi': {
    'Bhojpur': ['Bhojpur', 'Shadananda'],
    'Dhankuta': ['Dhankuta', 'Pakhribas', 'Mahalaxmi'],
    'Ilam': ['Ilam', 'Deumai', 'Mai', 'Suryodaya'],
    'Jhapa': [
      'Bhadrapur', 'Birtamod', 'Damak', 'Mechinagar', 'Kankai',
      'Arjundhara', 'Shivasatakshi', 'Gauradaha',
    ],
    'Khotang': ['Diktel Rupakot Majhuwagadhi', 'Halesi Tuwachung'],
    'Morang': [
      'Biratnagar', 'Belbari', 'Pathari Shanishchare', 'Urlabari',
      'Sundarharaicha', 'Letang', 'Rangeli', 'Ratuwamai', 'Sunawarshi',
    ],
    'Okhaldhunga': ['Siddhicharan'],
    'Panchthar': ['Phidim'],
    'Sankhuwasabha': ['Khandbari', 'Chainpur', 'Dharmadevi', 'Panchkhapan', 'Madi'],
    'Solukhumbu': ['Solududhkunda'],
    'Sunsari': ['Itahari', 'Dharan', 'Inaruwa', 'Duhabi', 'Barahachhetra', 'Ramdhuni'],
    'Taplejung': ['Phungling'],
    'Terhathum': ['Myanglung', 'Laligurans'],
    'Udayapur': ['Triyuga', 'Katari', 'Chaudandigadhi', 'Belaka'],
  },
  'Madhesh': {
    'Parsa': ['Birgunj', 'Pokhariya', 'Bahudarmai', 'Parsagadhi'],
    'Bara': [
      'Kalaiya', 'Jitpur Simara', 'Kolhabi', 'Nijgadh', 'Mahagadhimai',
      'Simraungadh', 'Pacharauta',
    ],
    'Rautahat': [
      'Chandrapur', 'Gaur', 'Baudhimai', 'Brindaban', 'Garuda', 'Gujara',
      'Katahariya', 'Ishanath', 'Paroha', 'Rajdevi', 'Rajpur',
    ],
    'Sarlahi': [
      'Malangwa', 'Hariwan', 'Barahathwa', 'Ishworpur', 'Lalbandi',
      'Haripur', 'Haripurwa', 'Bagmati', 'Balara', 'Godaita', 'Kabilasi',
    ],
    'Dhanusha': [
      'Janakpurdham', 'Chhireshwarnath', 'Ganeshman Charnath', 'Dhanushadham',
      'Nagarain', 'Bideha', 'Mithila', 'Sabaila', 'Sahidnagar',
      'Mithila Bihari', 'Hansapur', 'Kamala',
    ],
    'Mahottari': [
      'Jaleshwar', 'Bardibas', 'Gaushala', 'Balwa', 'Bhangaha', 'Loharpatti',
      'Manra Siswa', 'Matihani', 'Aurahi', 'Ramgopalpur',
    ],
    'Siraha': [
      'Siraha', 'Lahan', 'Dhangadhimai', 'Golbazar', 'Mirchaiya',
      'Kalyanpur', 'Karjanha', 'Sukhipur',
    ],
    'Saptari': [
      'Rajbiraj', 'Kanchanrup', 'Dakneshwori', 'Bodebarsain', 'Shambhunath',
      'Surunga', 'Hanumannagar Kankalini', 'Khadak', 'Saptakoshi',
    ],
  },
  'Bagmati': {
    'Sindhuli': ['Kamalamai', 'Dudhauli'],
    'Ramechhap': ['Manthali', 'Ramechhap'],
    'Dolakha': ['Bhimeshwar', 'Jiri'],
    'Bhaktapur': ['Bhaktapur', 'Madhyapur Thimi', 'Changunarayan', 'Suryabinayak'],
    'Dhading': ['Dhunibesi', 'Nilkantha'],
    'Kathmandu': [
      'Kathmandu', 'Kirtipur', 'Budhanilkantha', 'Tokha', 'Chandragiri',
      'Gokarneshwar', 'Kageshwari Manohara', 'Nagarjun', 'Shankharapur',
      'Tarakeshwar', 'Dakshinkali',
    ],
    'Kavrepalanchok': ['Dhulikhel', 'Banepa', 'Panauti', 'Panchkhal', 'Namobuddha', 'Mandandeupur'],
    'Lalitpur': ['Lalitpur', 'Godawari', 'Mahalaxmi'],
    'Nuwakot': ['Bidur', 'Belkotgadhi'],
    'Rasuwa': ['Dhunche', 'Uttargaya'],
    'Sindhupalchok': ['Chautara Sangachokgadhi', 'Melamchi', 'Bahrabise'],
    'Chitwan': ['Bharatpur', 'Ratnanagar', 'Rapti', 'Khairahani', 'Kalika', 'Madi', 'Ichchhakamana'],
    'Makwanpur': ['Hetauda', 'Thaha'],
  },
  'Gandaki': {
    'Baglung': ['Baglung', 'Dhorpatan', 'Galkot', 'Jaimini'],
    'Gorkha': ['Gorkha', 'Palungtar'],
    'Kaski': ['Pokhara'],
    'Lamjung': ['Besisahar', 'Sundarbazar', 'Madhya Nepal', 'Rainas'],
    'Manang': ['Chame'],
    'Mustang': ['Jomsom'],
    'Myagdi': ['Beni'],
    'Nawalpur': ['Kawasoti', 'Gaindakot', 'Devchuli', 'Madhyabindu'],
    'Parbat': ['Kushma', 'Phalebas'],
    'Syangja': ['Putalibazar', 'Waling', 'Galyang', 'Chapakot', 'Bhirkot'],
    'Tanahun': ['Byas', 'Bhanu', 'Bhimad', 'Shuklagandaki'],
  },
  'Lumbini': {
    'Kapilvastu': ['Kapilvastu', 'Buddhabhumi', 'Shivaraj', 'Krishnanagar', 'Banganga', 'Maharajgunj', 'Yashodhara'],
    'Parasi': ['Bardaghat', 'Ramgram', 'Sunwal'],
    'Rupandehi': [
      'Butwal', 'Siddharthanagar', 'Tilottama', 'Devdaha',
      'Lumbini Sanskritik', 'Sainamaina', 'Suddhodhan',
    ],
    'Arghakhanchi': ['Sandhikharka', 'Sitganga', 'Bhumikasthan'],
    'Gulmi': ['Resunga', 'Musikot'],
    'Palpa': ['Tansen', 'Rampur'],
    'Dang': ['Ghorahi', 'Tulsipur', 'Lamahi'],
    'Pyuthan': ['Pyuthan', 'Sworgadwary'],
    'Rolpa': ['Rolpa'],
    'Eastern Rukum': ['Bhume'],
    'Banke': ['Nepalgunj', 'Kohalpur'],
    'Bardiya': ['Gulariya', 'Rajapur', 'Madhuwan', 'Thakurbaba', 'Basgadhi', 'Barbardiya'],
  },
  'Karnali': {
    'Western Rukum': ['Musikot', 'Chaurjahari', 'Aathbiskot'],
    'Salyan': ['Sharada', 'Bagchaur', 'Bangad Kupinde'],
    'Dolpa': ['Thuli Bheri', 'Tripurasundari'],
    'Humla': ['Simikot'],
    'Jumla': ['Chandannath'],
    'Kalikot': ['Khandachakra', 'Raskot', 'Tilagufa'],
    'Mugu': ['Chhayanath Rara'],
    'Surkhet': ['Birendranagar', 'Bheriganga', 'Gurbhakot', 'Panchapuri', 'Lekbeshi'],
    'Dailekh': ['Narayan', 'Dullu', 'Chamunda Bindrasaini', 'Aathabis', 'Bhagawatimai'],
    'Jajarkot': ['Bheri', 'Chhedagad', 'Nalgad'],
  },
  'Sudurpashchim': {
    'Kailali': ['Dhangadhi', 'Tikapur', 'Lamki Chuha', 'Godawari', 'Ghodaghodi', 'Bhajani', 'Gauriganga'],
    'Achham': ['Mangalsen', 'Kamalbazar', 'Sanphebagar', 'Panchadewal Binayak'],
    'Doti': ['Dipayal Silgadhi', 'Shikhar'],
    'Bajhang': ['Jaya Prithvi', 'Bungal'],
    'Bajura': ['Badimalika', 'Triveni', 'Budhiganga', 'Budhinanda'],
    'Kanchanpur': ['Bhimdatta', 'Belauri', 'Krishnapur', 'Shuklaphanta', 'Punarbas', 'Bedkot'],
    'Dadeldhura': ['Amargadhi', 'Parashuram'],
    'Baitadi': ['Dasharathchand', 'Patan', 'Melauli', 'Purchaudi'],
    'Darchula': ['Mahakali', 'Shailyashikhar'],
  },
};

List<String> nepalProvinces() => nepalLocations.keys.toList();

List<String> nepalDistricts(String? province) {
  if (province == null) return const [];
  return nepalLocations[province]?.keys.toList() ?? const [];
}

List<String> nepalCities(String? province, String? district) {
  if (province == null || district == null) return const [];
  return nepalLocations[province]?[district] ?? const [];
}