import 'dart:typed_data';

class InfoCardContent {
  final String title;
  final String info;
  final Map<String, dynamic> additionalInfo;

  // Lightweight preview image used in waterfall cards.
  final Uint8List? thumbnailBytes;

  // Absolute path to the original image on disk, loaded lazily in detail page.
  final String? originalImagePath;

  // Fallback only for platforms where path loading is unavailable.
  final Uint8List? detailImageBytesFallback;

  const InfoCardContent({
    required this.title,
    required this.info,
    required this.additionalInfo,
    this.thumbnailBytes,
    this.originalImagePath,
    this.detailImageBytesFallback,
  });

  factory InfoCardContent.fromEmpty() => const InfoCardContent(
        title: '',
        info: '',
        additionalInfo: {},
      );
}
