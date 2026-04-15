import 'package:flutter/foundation.dart';

import '../../../data/models/vibe_config_v4.dart';

class VibeConfigV4Viewmodel extends ChangeNotifier {
  VibeConfigV4 config;

  VibeConfigV4Viewmodel({required this.config});

  String get fileName => config.fileName;
  Uint8List? get imageBytes => config.imageBytes;
  double get referenceStrength => config.referenceStrength;
  List<double> get availableInformationExtractedValues =>
      config.availableInformationExtractedValues;
  double get selectedInformationExtracted => config.selectedInformationExtracted;

  setReferenceStrength(double value) {
    config.referenceStrength = value;
    notifyListeners();
  }

  void setSelectedInformationExtracted(double value) {
    config.selectedInformationExtracted = value;
    final key = VibeConfigV4.normalizeInformationExtracted(value);
    final matchedEncoding = config.encodingByInformationExtracted[key];
    if (matchedEncoding != null) {
      config.vibeB64 = matchedEncoding;
    }
    notifyListeners();
  }

  void setSelectedInformationExtractedByIndex(int index) {
    if (index < 0 || index >= availableInformationExtractedValues.length) {
      return;
    }
    setSelectedInformationExtracted(availableInformationExtractedValues[index]);
  }
}
