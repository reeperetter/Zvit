class DefectItem {
  final String id;
  final int number;
  final String room;
  final String category;
  final String subCategoryCode;
  final String contractor;
  final String description;
  final String priority;
  final String status;
  final String defectType;
  final String normReference;
  final String deviationValue;
  final List<String> photoPaths;
  final double? planX;
  final double? planY;
  final DateTime createdAt;

  DefectItem({
    required this.id,
    required this.number,
    required this.room,
    required this.category,
    required this.subCategoryCode,
    required this.contractor,
    required this.description,
    this.priority = 'Normalny',
    this.status = 'W trakcie realizacji',
    this.defectType = 'Budowlana',
    this.normReference = '',
    this.deviationValue = '',
    this.photoPaths = const [],
    this.planX,
    this.planY,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'room': room,
        'category': category,
        'subCategoryCode': subCategoryCode,
        'contractor': contractor,
        'description': description,
        'priority': priority,
        'status': status,
        'defectType': defectType,
        'normReference': normReference,
        'deviationValue': deviationValue,
        'photoPaths': photoPaths,
        'planX': planX,
        'planY': planY,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DefectItem.fromJson(Map<String, dynamic> json) => DefectItem(
        id: json['id'],
        number: json['number'],
        room: json['room'] ?? 'Ogólne',
        category: json['category'] ?? '',
        subCategoryCode: json['subCategoryCode'] ?? '',
        contractor: json['contractor'] ?? '',
        description: json['description'] ?? '',
        priority: json['priority'] ?? 'Normalny',
        status: json['status'] ?? 'W trakcie realizacji',
        defectType: json['defectType'] ?? 'Budowlana',
        normReference: json['normReference'] ?? '',
        deviationValue: json['deviationValue'] ?? '',
        photoPaths: List<String>.from(json['photoPaths'] ?? []),
        planX: json['planX']?.toDouble(),
        planY: json['planY']?.toDouble(),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class InspectionProject {
  final String id;
  final String protocolNumber;
  final String productCode;
  final String protocolType;
  final String address;
  final String inspectorName;
  final String clientName;
  final String developerName;
  final String? floorPlanPath;
  final String weatherAndMeter;
  final DateTime date;
  final List<DefectItem> defects;

  InspectionProject({
    required this.id,
    required this.protocolNumber,
    required this.productCode,
    required this.protocolType,
    required this.address,
    required this.inspectorName,
    this.clientName = '',
    this.developerName = '',
    this.floorPlanPath,
    this.weatherAndMeter = '',
    required this.date,
    this.defects = const [],
  });

  InspectionProject copyWith({
    String? floorPlanPath,
    List<DefectItem>? defects,
    String? weatherAndMeter,
  }) {
    return InspectionProject(
      id: id,
      protocolNumber: protocolNumber,
      productCode: productCode,
      protocolType: protocolType,
      address: address,
      inspectorName: inspectorName,
      clientName: clientName,
      developerName: developerName,
      floorPlanPath: floorPlanPath ?? this.floorPlanPath,
      weatherAndMeter: weatherAndMeter ?? this.weatherAndMeter,
      date: date,
      defects: defects ?? this.defects,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'protocolNumber': protocolNumber,
        'productCode': productCode,
        'protocolType': protocolType,
        'address': address,
        'inspectorName': inspectorName,
        'clientName': clientName,
        'developerName': developerName,
        'floorPlanPath': floorPlanPath,
        'weatherAndMeter': weatherAndMeter,
        'date': date.toIso8601String(),
        'defects': defects.map((e) => e.toJson()).toList(),
      };

  factory InspectionProject.fromJson(Map<String, dynamic> json) =>
      InspectionProject(
        id: json['id'],
        protocolNumber: json['protocolNumber'] ?? '#101',
        productCode: json['productCode'] ?? '',
        protocolType: json['protocolType'] ?? 'Przedodbiór wewnętrzny',
        address: json['address'] ?? '',
        inspectorName: json['inspectorName'] ?? '',
        clientName: json['clientName'] ?? '',
        developerName: json['developerName'] ?? '',
        floorPlanPath: json['floorPlanPath'],
        weatherAndMeter: json['weatherAndMeter'] ?? '',
        date: DateTime.parse(json['date']),
        defects: (json['defects'] as List<dynamic>? ?? [])
            .map((e) => DefectItem.fromJson(e))
            .toList(),
      );
}

class AppDictionaries {
  List<String> rooms;
  List<String> categories;
  List<String> subCodes;
  List<String> contractors;
  List<String> protocolTypes;

  AppDictionaries({
    required this.rooms,
    required this.categories,
    required this.subCodes,
    required this.contractors,
    required this.protocolTypes,
  });

  factory AppDictionaries.defaultPolish() {
    return AppDictionaries(
      rooms: [
        'Przedpokój / Korytarz',
        'Salon z aneksem kuchennym',
        'Kuchnia',
        'Sypialnia 1',
        'Sypialnia 2',
        'Łazienka główna',
        'WC / Toaleta',
        'Balkon / Loggia / Taras',
        'Komórka lokatorska / Garaż',
      ],
      categories: [
        'Instalacja elektryczna',
        'Instalacja sanitarna i CO',
        'Wentylacja i klimatyzacja',
        'Tynki i gładzie',
        'Posadzki / Szlichta',
        'Stolarka okienna i parapety',
        'Drzwi wejściowe',
        'Balkon / Elewacja / Balustrady',
      ],
      subCodes: [
        '(E00) UWAGI OGÓLNE - ELEKTRYKA',
        '(E15) BRAK OPISU BEZPIECZNIKÓW',
        '(E16) BRAK / BAŁAGAN W ROZDZIELNI TT',
        '(E26) USZKODZONA TM/TT',
        '(E30) BRAK NAPIĘCIA / ZŁE PODŁĄCZENIE GNIAZDA',
        '(T01) ODCHYLENIE PŁASZCZYZNY ŚCIANY > 3mm (PN-B-10110)',
        '(T02) BRAK PIONU ŚCIANY / NAROŻNIKA',
        '(T05) PĘKNIĘCIA / RYSY SKURCZOWE TYNKU',
        '(P01) BRAK POZIOMU POSADZKI (PN-EN 13813)',
        '(P04) ZBYT WYSOKA WILGOTNOŚĆ PODŁOŻA (>2% CM)',
        '(O01) RYSY NA SZYBIE ZESPOLONEJ (PN-EN 1279)',
        '(O03) USZKODZENIE PROFILU OKIENNEGO / USZCZELKI',
        '(O07) REGULACJA OKNA / ZŁY DOCISK SKRZYDŁA',
        '(S02) NIESZCZELNOŚĆ / BRAK SPADKU KANALIZACJI',
        '(W01) BRAK CIĄGU WENTYLACYJNEGO / COFKA',
      ],
      contractors: [
        'GENERALNY WYKONAWCA',
        'VOLTIMA SP. Z O.O.',
        'INSTAL-BUD SANIT',
        'OKNO-PLAST SYSTEM',
        'TYNK-MIX BUDOWNICTWO',
        'WENT-TECH POLSKA',
      ],
      protocolTypes: [
        'Przedodbiór wewnętrzny',
        'Odbiór techniczny lokalu',
        'Odbiór po usunięciu usterek',
        'Przekazanie kluczy',
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'rooms': rooms,
        'categories': categories,
        'subCodes': subCodes,
        'contractors': contractors,
        'protocolTypes': protocolTypes,
      };

  factory AppDictionaries.fromJson(Map<String, dynamic> json) =>
      AppDictionaries(
        rooms: List<String>.from(json['rooms'] ?? []),
        categories: List<String>.from(json['categories'] ?? []),
        subCodes: List<String>.from(json['subCodes'] ?? []),
        contractors: List<String>.from(json['contractors'] ?? []),
        protocolTypes: List<String>.from(json['protocolTypes'] ?? []),
      );
}
