import 'package:flutter/material.dart';
import 'package:virtualine/set_object.dart';
import '../../animation_page/components/left_bar_animation.dart';
import '../../sound_page/components/left_bar_sound.dart';
import '../../constructor_page/components/left_bar_constructor.dart';
import '../../animation_page/components/right_bar_animation.dart';
import '../../sound_page/components/right_bar_sound.dart';
import '../../constructor_page/components/right_bar_constructor.dart';
import '../../draw_page/draw_sheet.dart';
import '../../draw_page/components/left_bar_draw.dart';
import '../../draw_page/components/right_bar_draw.dart';
import '../../animation_page/animation_page.dart';
import '../../constructor_page/page_constructor.dart';
import '../../../set_stats.dart';
import 'header_bar.dart';
import 'btn_nav.dart';
import '../../sound_page/sound_page.dart';
//import 'sound_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  // ignore: library_private_types_in_public_api
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  int indexNav = 0;

  // Propriétés dynamiques
  ValueNotifier<List<ImageWidgetInfo>> imageWidgetsInfoNotifier =
      ValueNotifier([]);
  void Function(int)? onDelete;

  @override
  void initState() {
    super.initState();
    navIndex.addListener(_handleNavIndexChange);
    onDelete = _deleteImageWidget;
  }

  void _handleNavIndexChange() {
    if (mounted) {
      setState(() {
        indexNav = navIndex.value;
      });
    }
  }

  void _deleteImageWidget(int index) {
    setState(() {
      imageWidgetsInfoNotifier.value = List.from(imageWidgetsInfoNotifier.value)
        ..removeAt(index);
    });
  }

  @override
  void dispose() {
    navIndex.removeListener(_handleNavIndexChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        toolbarHeight: 50,
        title: const HeaderBar(),
      ),
      body: ValueListenableBuilder<List<ImageWidgetInfo>>(
        valueListenable: imageWidgetsInfoNotifier,
        builder: (context, imageWidgetsInfo, child) {
          return Row(
            children: [
              SizedBox(
                width: indexNav == 3 ? 250 : 50,
                child: IndexedStack(
                  index: indexNav,
                  children: [
                    const LeftDrawer(),
                    const LeftAnimation(),
                    const LeftSound(),
                    LeftConstructor(
                      imageWidgetsInfo: imageWidgetsInfoNotifier,
                      onDelete: onDelete!,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: indexNav,
                  children: [
                    const DrawSheet(),
                    const AnimationPage(),
                    const SoundPage(),
                  ConstructorPage(imageWidgetsInfoNotifier: imageWidgetsInfoNotifier),
                  ],
                ),
              ),
              IndexedStack(
                index: indexNav,
                children: const [
                  RightDrawer(),
                  RightAnimation(),
                  RightSound(),
                  RightConstructor(),
                ],
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const NavBttn(),
    );
  }
}
