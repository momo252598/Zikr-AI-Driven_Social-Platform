import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/utils/sura.dart';
import 'package:quran/quran.dart';
import 'package:easy_container/easy_container.dart';
import 'package:software_graduation_project/screens/quran/quran_page.dart';
import 'package:string_validator/string_validator.dart';
import '../../base/res/styles/app_styles.dart';

class QuranPage2 extends StatefulWidget {
  var suraJsonData;
  final bool isWeb;
  final Function(int)? onPageSelected;

  QuranPage2({
    super.key,
    required this.suraJsonData,
    this.isWeb = false,
    this.onPageSelected,
  });

  @override
  State<QuranPage2> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage2> {
  TextEditingController textEditingController = TextEditingController();

  bool isLoading = true;

  var searchQuery = "";
  var filteredData;
  List<Surah> surahList = [];
  var ayatFiltered;

  List pageNumbers = [];

  addFilteredData() async {
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      filteredData = widget.suraJsonData;
      isLoading = false;
    });
  }

  @override
  void initState() {
    addFilteredData();
    super.initState();
  }

  void _navigateToPage(int pageNumber) {
    if (widget.isWeb && widget.onPageSelected != null) {
      // Call the callback to update the page in the parent widget
      widget.onPageSelected!(pageNumber);
      // No navigation needed in web mode - just update the right panel
    } else {
      // For mobile, navigate to a new page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuranViewPage(
            shouldHighlightText: false,
            highlightVerse: "",
            jsonData: widget.suraJsonData,
            pageNumber: pageNumber,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // Ensure RTL for this component
      child: Scaffold(
        backgroundColor: AppStyles.bgColor,
        // appBar: AppBar(
        //   title: const Text("Quran Page"),
        // ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      textDirection: TextDirection.rtl,
                      controller: textEditingController,
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });

                        if (value == "") {
                          filteredData = widget.suraJsonData;

                          pageNumbers = [];

                          setState(() {});
                        }

                        if (searchQuery.isNotEmpty &&
                            isInt(searchQuery) &&
                            toInt(searchQuery) < 605 &&
                            toInt(searchQuery) > 0) {
                          pageNumbers.add(toInt(searchQuery));
                        }

                        if (searchQuery.length > 3 ||
                            searchQuery.toString().contains(" ")) {
                          setState(() {
                            ayatFiltered = [];

                            ayatFiltered = searchWords(searchQuery);
                            filteredData = widget.suraJsonData.where((sura) {
                              final suraName = sura['name'].toLowerCase();
                              // final suraNameTranslated =
                              //     sura['name']
                              //         .toString()
                              //         .toLowerCase();
                              final suraNameTranslated =
                                  getSurahNameArabic(sura["number"]);

                              return suraName
                                      .contains(searchQuery.toLowerCase()) ||
                                  suraNameTranslated
                                      .contains(searchQuery.toLowerCase());
                            }).toList();
                          });
                        }
                      },
                      style:
                          const TextStyle(color: Color.fromARGB(190, 0, 0, 0)),
                      decoration: const InputDecoration(
                        hintText: 'البحث',
                        hintStyle: TextStyle(),
                        // border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (pageNumbers.isNotEmpty)
                    Container(
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("page"),
                      ),
                    ),
                  ListView.separated(
                      reverse: true,
                      itemBuilder: (ctx, index) {
                        return Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: AppStyles.lightPurple, width: 1),
                            ),
                            elevation: 3,
                            child: InkWell(
                              onTap: () {
                                _navigateToPage(pageNumbers[index]);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      pageNumbers[index].toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    Text(
                                      getSurahNameArabic(
                                          getPageData(pageNumbers[index])[0]
                                              ["surah"]),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (context, index) => Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Divider(
                              color: AppStyles.bgColor,
                            ),
                          ),
                      itemCount: pageNumbers.length),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 4),
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      int suraNumber = index + 1;
                      String suraName = filteredData[index]["name"];
                      String suraNameEnglishTranslated =
                          filteredData[index]["englishName"];
                      int suraNumberInQuran = filteredData[index]["number"];
                      String suraNameTranslated =
                          filteredData[index]["name"].toString();
                      int ayahCount = getVerseCount(suraNumber);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color: AppStyles.lightPurple, width: 1),
                          ),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppStyles.lightPurple.withOpacity(0.2),
                              ),
                              child: Center(
                                child: Text(
                                  suraNumber.toString(),
                                  style: TextStyle(
                                    color: AppStyles.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              suraName,
                              style: TextStyle(
                                color: AppStyles.txtFieldColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              "$suraNameEnglishTranslated ($ayahCount)",
                              style: TextStyle(
                                  fontSize: 14, color: AppStyles.surahName),
                            ),
                            trailing: searchQuery.isEmpty
                                ? RichText(
                                    text: TextSpan(
                                      text: suraNumber.toString(),
                                      style: TextStyle(
                                        fontFamily: "arsura",
                                        fontSize: 22,
                                        color: AppStyles.black,
                                      ),
                                    ),
                                  )
                                : null,
                            onTap: () async {
                              _navigateToPage(
                                  getPageNumber(suraNumberInQuran, 1));
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  if (ayatFiltered != null)
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: ayatFiltered["occurences"] > 10
                          ? 10
                          : ayatFiltered["occurences"],
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: AppStyles.lightPurple, width: 1),
                            ),
                            elevation: 3,
                            child: InkWell(
                              onTap: () {
                                _navigateToPage(getPageNumber(
                                  ayatFiltered["result"][index]["surah"],
                                  ayatFiltered["result"][index]["verse"],
                                ));
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Text(
                                  "سورة ${getSurahNameArabic(ayatFiltered["result"][index]["surah"])} - ${getVerse(ayatFiltered["result"][index]["surah"], ayatFiltered["result"][index]["verse"], verseEndSymbol: true)}",
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                      color: AppStyles.black, fontSize: 17),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
      ),
    );
  }
}
