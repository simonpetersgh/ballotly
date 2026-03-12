import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:myapp/core/theme/app_theme.dart';

// class AppLogoSvg extends StatelessWidget {
//   const AppLogoSvg({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return IconButton(
//       icon: SvgPicture.asset(
//         'assets/icons/ballotly.svg',
//         width: 24,
//         height: 24,
//         colorFilter: const ColorFilter.mode(
//           AppTheme.textPrimary,
//           BlendMode.srcIn,
//         ),
//       ),
//       onPressed: () {},
//     );
//   }
// }

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Image.asset(
        'assets/images/ballotly.jpg',
        width: 24,
        height: 24,
        color: AppTheme.textPrimary, // tints the image if it's monochrome
      ),
      onPressed: () {},
    );
  }
}
