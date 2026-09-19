import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ai/core/theme/app_theme.dart';
import 'package:ai/widgets/theme_toggle_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the real icon fonts so the captured image shows glyphs rather than
/// tofu boxes. Resolves cupertino_icons from package_config.json and the
/// Material icon font from the Flutter SDK that is running this test.
Future<void> _loadIconFonts() async {
  // An IconData with a fontPackage resolves to 'packages/<pkg>/<family>',
  // so the loader has to register that exact family name too.
  final fonts = <String, String?>{
    'CupertinoIcons': _cupertinoFont(),
    'packages/cupertino_icons/CupertinoIcons': _cupertinoFont(),
    'MaterialIcons': _materialFont(),
  };

  for (final entry in fonts.entries) {
    final path = entry.value;
    if (path == null) continue;
    final bytes = File(path).readAsBytesSync();
    await (FontLoader(entry.key)
          ..addFont(Future.value(ByteData.view(bytes.buffer))))
        .load();
  }
}

String? _cupertinoFont() {
  final config = File('.dart_tool/package_config.json');
  if (!config.existsSync()) return null;
  final match = RegExp(r'"name"\s*:\s*"cupertino_icons"\s*,\s*"rootUri"\s*:\s*"([^"]+)"')
      .firstMatch(config.readAsStringSync());
  if (match == null) return null;
  final file = File(
    '${Uri.parse(match.group(1)!).toFilePath()}${Platform.pathSeparator}assets'
    '${Platform.pathSeparator}CupertinoIcons.ttf',
  );
  return file.existsSync() ? file.path : null;
}

String? _materialFont() {
  // .../bin/cache/dart-sdk/bin/dart.exe -> walk up to the Flutter root
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 6 && dir.path != dir.parent.path; i++) {
    final candidate = Directory(
      '${dir.path}${Platform.pathSeparator}artifacts'
      '${Platform.pathSeparator}material_fonts',
    );
    if (candidate.existsSync()) {
      for (final f in candidate.listSync()) {
        if (f.path.toLowerCase().endsWith('.otf')) return f.path;
      }
    }
    dir = dir.parent;
  }
  return null;
}

void main() {
  testWidgets('theme toggle renders beside the bell in both themes', (tester) async {
    await tester.runAsync(_loadIconFonts);
    tester.view.physicalSize = const Size(900, 200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final key = GlobalKey();

    Future<void> pumpBar(ThemeData theme) async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            theme: theme,
            debugShowCheckedModeBanner: false,
            home: Builder(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: Text(
                    'Nirma Hub',
                    style: TextStyle(fontWeight: FontWeight.w900, color: context.c.text),
                  ),
                  actions: [
                    const ThemeToggleButton(),
                    // The real bell, copied from home_screen for comparison
                    IconButton(
                      onPressed: () {},
                      icon: Icon(CupertinoIcons.bell, color: context.c.text, size: 24),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(CupertinoIcons.person_crop_circle, color: context.c.text, size: 24),
                    ),
                  ],
                ),
                body: const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // ---- structure: the button exists, is tappable and occupies a real box ----
    await pumpBar(AppTheme.light);

    expect(find.byType(ThemeToggleButton), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.moon), findsOneWidget);

    final toggleSize = tester.getSize(find.byType(ThemeToggleButton));
    final bellSize = tester.getSize(
      find.ancestor(of: find.byIcon(CupertinoIcons.bell), matching: find.byType(IconButton)),
    );
    expect(toggleSize.width, greaterThan(24));
    expect(toggleSize.height, greaterThan(24));
    // Same footprint as the bell, so the app bar spacing stays even
    expect(toggleSize, bellSize);

    // The toggle sits to the LEFT of the bell
    expect(
      tester.getCenter(find.byType(ThemeToggleButton)).dx,
      lessThan(tester.getCenter(find.byIcon(CupertinoIcons.bell)).dx),
    );

    await _capture(tester, key, 'build/toggle_light.png');

    // ---- dark ----
    await pumpBar(AppTheme.dark);
    expect(find.byIcon(CupertinoIcons.sun_max), findsOneWidget);
    await _capture(tester, key, 'build/toggle_dark.png');
  });
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String path) async {
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
