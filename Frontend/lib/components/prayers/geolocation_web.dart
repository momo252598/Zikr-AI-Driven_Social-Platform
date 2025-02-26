import 'dart:html' as html;
import 'dart:async';
import 'package:adhan_dart/adhan_dart.dart';

Future<Coordinates> getCurrentCoordinates() async {
  final completer = Completer<Coordinates>();
  html.window.navigator.geolocation.getCurrentPosition().then((position) {
    final coords = position.coords;
    if (coords == null) {
      completer.completeError(Exception("Location coordinates are null"));
    } else {
      completer.complete(Coordinates(
          coords.latitude!.toDouble(), coords.longitude!.toDouble()));
    }
  }).catchError((error) {
    completer.completeError(Exception("Failed to retrieve location on web"));
  });
  return completer.future;
}
