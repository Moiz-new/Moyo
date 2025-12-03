
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ImageSlider extends StatefulWidget {
  const ImageSlider({super.key, this.imageLinks = const []});
  final List<dynamic?> imageLinks;

  @override
  State<ImageSlider> createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  List imageList = [];
  bool networkImage = false;
  List dummyList = [
    // {'id': 1, 'image_path': 'assets/slider/1.png'},
    // {'id': 2, 'image_path': 'assets/slider/2.png'},
    // {'id': 3, 'image_path': 'assets/slider/3.png'},
    {
      'id': 1,
      'image_path':
      'https://raw.githubusercontent.com/aarifhusainwork/aaspas-storage-assets/refs/heads/main/AppWizard/AltImages/propertyDummyImages/1.png',
    },
    // {
    //   'id': 2,
    //   'image_path':
    //       'https://raw.githubusercontent.com/aarifhusainwork/aaspas-storage-assets/refs/heads/main/AppWizard/AltImages/propertyDummyImages/2.png',
    // },
    // {
    //   'id': 3,
    //   'image_path':
    //       'https://raw.githubusercontent.com/aarifhusainwork/aaspas-storage-assets/refs/heads/main/AppWizard/AltImages/propertyDummyImages/3.png',
    // },
  ];

  bool containsMap(List list) {
    return list.any((element) => element is Map);
  }

  @override
  initState() {
    print("/////////////////widget.imageLinks");
    print(widget.imageLinks);
    print(containsMap(widget.imageLinks));
    if (widget.imageLinks.isEmpty) {
      imageList = [...dummyList];

      print("/////////////////////////////////// First is running");
      // print(imageList);
    } else if (containsMap(widget.imageLinks)) {
      imageList = [...dummyList];
      print("/////////////////////////////////// 2 is running");
    } else {
      print("/////////////////////////////////// 3 is running");
      networkImage = true;
      imageList = List.generate(
        widget.imageLinks.length,
            (index) => {'id': index + 1, 'image_path': widget.imageLinks[index]},
      );
    }

    super.initState();
  }

  final CarouselController carouselController = CarouselController();
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    print("/////// Image Slider Build");
    print(imageList);
    return SizedBox(
      child: InkWell(
        onTap: () {},
        child: CarouselSlider(
          items:
          imageList
              .map(
                (item) => Container(
              clipBehavior: Clip.hardEdge,
              width: double.infinity,
              height: 10,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/image_slider.png"),
                  fit: BoxFit.cover, // covers entire container
                ),
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey,
              ),
              child:
              networkImage
                  ? CachedNetworkImage(
                imageUrl: item['image_path'],
                fit: BoxFit.cover,
                errorWidget:
                    (context, url, error) => Image.asset(
                  fit: BoxFit.cover,
                      "assets/images/image_slider.png",
                ),
              )
                  : CachedNetworkImage(
                imageUrl: item['image_path'],
                fit: BoxFit.cover,
                errorWidget:
                    (context, url, error) => Image.asset(
                  fit: BoxFit.cover,
                      "assets/images/image_slider.png",
                ),
              ),

            ),
          )
              .toList(),
          options: CarouselOptions(
            scrollPhysics: BouncingScrollPhysics(),
            autoPlay: (imageList.length == 1) ? false : true,
            aspectRatio: 2,

            viewportFraction: 1,
            onPageChanged: (index, reason) {
              setState(() {
                currentIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}
