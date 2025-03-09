class Surah {
  int id;
  String revelationPlace;
  int revelationOrder;
  String name;
  String arabicName;
  int versesCount;
  Surah({
    required this.id,
    required this.revelationPlace,
    required this.revelationOrder,
    required this.name,
    required this.arabicName,
    required this.versesCount,
  });

  factory Surah.fromMap(Map<String, dynamic> Json) => Surah(
        arabicName: Json['arabicName'],
        id: Json['id'],
        name: Json['name'],
        revelationOrder: Json['revelationOrder'],
        revelationPlace: Json['revelationPlace'],
        versesCount: Json['versesCount'],
      );
}
