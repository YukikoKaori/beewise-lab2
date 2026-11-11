import 'package:flutter/material.dart';

abstract final class BeeWiseColors {
  static const canvas = Color(0xFFF0F4FF);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF162CD4);
  static const primaryPressed = Color(0xFF280F91);
  static const accent = Color(0xFFFFC500);
  static const accentSoft = Color(0xFFFFF8E0);
  static const highlight = Color(0xFFFADC76);
  static const ink = Color(0xFF0C0C0B);
  static const muted = Color(0xFF435580);
  static const border = Color(0xFFDCE8FB);
  static const borderStrong = Color(0xFFC9D1E3);
  static const success = Color(0xFF1F7A1F);
  static const successSoft = Color(0xFFECFBEC);
  static const warning = Color(0xFF905B0F);
  static const error = Color(0xFFDC2626);
  static const errorSoft = Color(0xFFFEF7F6);
  static const disabled = Color(0xFFDCE8FB);
}

abstract final class BeeWiseSpace {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x8 = 32.0;
  static const x10 = 40.0;
  static const x12 = 48.0;
}

abstract final class BeeWiseRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const field = 16.0;
  static const card = 24.0;
  static const panel = 32.0;
  static const full = 999.0;
}

abstract final class BeeWiseElevation {
  static const soft = <BoxShadow>[
    BoxShadow(color: Color(0x14280F91), blurRadius: 8, offset: Offset(0, 3)),
  ];
  static const pop = <BoxShadow>[
    BoxShadow(color: Color(0x29280F91), blurRadius: 8, offset: Offset(0, 4)),
  ];
}
