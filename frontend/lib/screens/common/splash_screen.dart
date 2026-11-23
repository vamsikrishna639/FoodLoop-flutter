// Shown for a moment at start-up while the saved session is checked.
import 'package:material_ui/material_ui.dart';

import '../../core/theme/tokens.dart';
import '../../widgets/brand_mark.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fl.board,
      body: const Center(child: BrandMark(onDark: true, size: 44)),
    );
  }
}
