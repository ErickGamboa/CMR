// Genera los assets de marca a partir del PNG original con transparencia.
//
//   dart run tool/build_brand_assets.dart <ruta_al_png_original>
//
// Produce:
//   assets/images/logo_cmr.png            logo completo (monograma + tagline)
//   assets/images/logo_cmr_marca.png      solo el monograma, sin el tagline
//   assets/icon/app_icon.png              1024x1024 opaco, para iOS y Android legacy
//   assets/icon/app_icon_foreground.png   1024x1024 transparente, capa adaptativa
//   assets/splash/logo_splash.png         logo completo para el splash nativo
//   assets/splash/logo_splash_a12.png     1152x1152 para el splash de Android 12+
import 'dart:io';

import 'package:image/image.dart';

/// Fila donde termina el monograma y empieza el tagline. Medida sobre el
/// original: la cola de la hélice muere en y=844 y el texto arranca en y=855.
const _filaCorte = 850;

/// Alfa mínimo para considerar que un píxel es contenido y no borde suave.
const _alphaMin = 12;

/// El monograma ocupa este porcentaje del ancho en el ícono opaco.
const _escalaIcono = 0.86;

/// En un ícono adaptativo de Android el sistema recorta a un círculo/squircle;
/// solo el 66% central está garantizado. Nos quedamos por dentro de eso.
const _escalaAdaptativo = 0.62;

/// Ancho del logo en el splash, en píxeles a 4x.
///
/// 608 px a 4x son 152 dp en pantalla. El número sale de la restricción más
/// dura: Android 12+ recorta el splash a un círculo de 768 px sobre un lienzo
/// de 1152, y el rectángulo más grande con la proporción del logo que entra en
/// ese círculo mide 624 px de ancho. Se usa 608 para dejar aire.
///
/// El mismo ancho lo usa la pantalla de carga de Flutter, así que el salto del
/// splash nativo a la app es invisible.
const _anchoSplash = 608;
const _lienzoAndroid12 = 1152;

final _fondo = ColorRgba8(0xFF, 0xFF, 0xFF, 0xFF);

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Falta la ruta al PNG original.');
    exit(64);
  }

  final src = decodePng(File(args.single).readAsBytesSync());
  if (src == null) {
    stderr.writeln('No se pudo decodificar el PNG.');
    exit(65);
  }

  final completo = _recortarAlContenido(src, hasta: src.height);
  final marca = _recortarAlContenido(src, hasta: _filaCorte);

  _escribir('assets/images/logo_cmr.png', completo);
  _escribir('assets/images/logo_cmr_marca.png', marca);
  _escribir('assets/icon/app_icon.png', _componer(marca, _escalaIcono, _fondo));
  _escribir(
    'assets/icon/app_icon_foreground.png',
    _componer(marca, _escalaAdaptativo, null),
  );

  final splash = copyResize(
    completo,
    width: _anchoSplash,
    interpolation: Interpolation.cubic,
  );
  _escribir('assets/splash/logo_splash.png', splash);
  _escribir(
    'assets/splash/logo_splash_a12.png',
    _centrarEnLienzo(splash, _lienzoAndroid12),
  );
}

/// Centra [img] en un lienzo cuadrado transparente de [lado] píxeles.
Image _centrarEnLienzo(Image img, int lado) {
  final lienzo = Image(width: lado, height: lado, numChannels: 4);
  fill(lienzo, color: ColorRgba8(0, 0, 0, 0));

  return compositeImage(
    lienzo,
    img,
    dstX: (lado - img.width) ~/ 2,
    dstY: (lado - img.height) ~/ 2,
  );
}

/// Recorta la imagen al bounding box del contenido no transparente,
/// ignorando todo lo que esté por debajo de [hasta].
Image _recortarAlContenido(Image src, {required int hasta}) {
  var x0 = src.width, x1 = -1, y0 = src.height, y1 = -1;
  final limite = hasta.clamp(0, src.height);

  for (var y = 0; y < limite; y++) {
    for (var x = 0; x < src.width; x++) {
      if (src.getPixel(x, y).a <= _alphaMin) continue;
      if (x < x0) x0 = x;
      if (x > x1) x1 = x;
      if (y < y0) y0 = y;
      if (y > y1) y1 = y;
    }
  }

  if (x1 < x0 || y1 < y0) throw StateError('No se encontró contenido opaco.');

  return copyCrop(
    src,
    x: x0,
    y: y0,
    width: x1 - x0 + 1,
    height: y1 - y0 + 1,
  );
}

/// Centra [marca] en un lienzo cuadrado de 1024, ocupando [escala] del ancho.
/// Con [fondo] nulo el lienzo queda transparente.
Image _componer(Image marca, double escala, Color? fondo) {
  const lado = 1024;
  final lienzo = Image(width: lado, height: lado, numChannels: 4);
  if (fondo != null) {
    fill(lienzo, color: fondo);
  } else {
    fill(lienzo, color: ColorRgba8(0, 0, 0, 0));
  }

  // El monograma es apaisado: el ancho es siempre el lado que manda.
  final ancho = (lado * escala).round();
  final alto = (ancho * marca.height / marca.width).round();
  final redimensionada = copyResize(
    marca,
    width: ancho,
    height: alto,
    interpolation: Interpolation.cubic,
  );

  return compositeImage(
    lienzo,
    redimensionada,
    dstX: (lado - ancho) ~/ 2,
    dstY: (lado - alto) ~/ 2,
  );
}

void _escribir(String ruta, Image img) {
  File(ruta)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(encodePng(img));
  stdout.writeln('${img.width}x${img.height}  $ruta');
}
