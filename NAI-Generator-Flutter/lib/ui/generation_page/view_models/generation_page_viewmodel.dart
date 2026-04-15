import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:get_it/get_it.dart';
import 'package:nai_casrand/data/models/api_request.dart';
import 'package:nai_casrand/data/models/command_status.dart';
import 'package:nai_casrand/data/models/info_card_content.dart';
import 'package:nai_casrand/data/models/payload_config.dart';
import 'package:lorem_ipsum/lorem_ipsum.dart';
import 'package:nai_casrand/data/services/api_service.dart';
import 'package:nai_casrand/data/services/bark_service.dart';
import 'package:nai_casrand/data/services/file_service.dart';
import 'package:nai_casrand/data/services/image_service.dart';
import 'package:nai_casrand/data/services/log_service.dart';
import 'package:nai_casrand/data/use_cases/generate_payload_use_case.dart';

const defaultMaxInfoCardContentListLength = 200;

class GenerationPageViewmodel extends ChangeNotifier {
  PayloadConfig get payloadConfig => GetIt.I<PayloadConfig>();
  CommandStatus get commandStatus => GetIt.I<CommandStatus>();
  List<Command<void, InfoCardContent>> get commandList =>
      commandStatus.commandList;
  int get colNum => payloadConfig.settings.generationPageColumnCount;
  int get maxInfoCardCount =>
      max(1, payloadConfig.settings.generationPageMaxItems);

  final ValueNotifier<int?> cooldownDelaySec = ValueNotifier(null);
  final ValueNotifier<int?> innerDelaySec = ValueNotifier(null);

  Command<void, InfoCardContent>? currentCommand;
  Timer? _cooldownTimer;
  Timer? _innerDelayTimer;

  PayloadGenerationResult? _cachedPayloadResult;
  int _cacheRetriesCount = 0;
  DateTime? _lastBarkAuthFailAt;

  void setCardsPerCol(int value) {
    payloadConfig.settings.generationPageColumnCount = value;
    notifyListeners();
  }

  void addAndRunCommand(Command<void, InfoCardContent> command) {
    // Make sure list is not longer than expected
    while (commandList.length >= maxInfoCardCount) {
      commandList.removeAt(0);
    }
    // Push command into list and run command
    commandList.add(command);
    command();
  }

  void addLoremInfoCardContent() async {
    // Async command as image requires loading
    commandFunc() async {
      await Future.delayed(const Duration(milliseconds: 500));
      final random = Random();
      final bytes =
          Uint8List.sublistView(await rootBundle.load('assets/appicon.png'));
      return InfoCardContent(
        title: '#${commandList.length}: ${loremIpsum(
          words: random.nextInt(3) + 3,
          initWithLorem: true,
        )}',
        info: loremIpsum(
          words: random.nextInt(300),
          initWithLorem: true,
        ),
        additionalInfo: {"Random Seed": random.nextInt(1 << 31)},
        thumbnailBytes: bytes,
        detailImageBytesFallback: bytes,
      );
    }

    // Skip if active command exists
    if (currentCommand != null && currentCommand!.isExecuting.value) return;
    final command = Command.createAsyncNoParam(
      commandFunc,
      initialValue: InfoCardContent.fromEmpty(),
    );
    currentCommand = command;
    addAndRunCommand(command);
  }

  void addTestPromptInfoCardContent() {
    // Sync command but wrapped as async
    commandFunc() async {
      final payloadResult =
          GeneratePayloadUseCase(payloadConfig: payloadConfig)();
      final additionalInfo = digestPayloadResult(payloadResult);
      return InfoCardContent(
          title: tr('test_prompt'),
          info: payloadResult.comment,
          additionalInfo: additionalInfo);
    }

    // Skip the check of active command (because command is sync)
    final command = Command.createAsyncNoParam(
      commandFunc,
      initialValue: InfoCardContent.fromEmpty(),
    );
    command.isExecuting.addListener(() {
      if (command.isExecuting.value) return;
      notifyListeners();
    });
    addAndRunCommand(command);
  }

  void nextCommand() {
    // Stop if batch is inactive or cooling down
    if (!commandStatus.isBatchActive.value) return;
    if (commandStatus.isCoolingDown.value) return;

    // Skip if active command exists
    if (currentCommand != null && currentCommand!.isExecuting.value) return;

    // Generate, postprocess and save image
    commandFunc() async {
      final endpoint = payloadConfig.settings.debugApiEnabled
          ? payloadConfig.settings.debugApiPath
          : 'https://image.novelai.net/ai/generate-image';

      // Check whether cached payload exists, use cache if exists
      PayloadGenerationResult payloadResult;
      if (_cachedPayloadResult != null && _cacheRetriesCount < 3) {
        // Use cached payload, increment counter
        payloadResult = _cachedPayloadResult!;
        _cacheRetriesCount++;
      } else {
        // Generate new payload
        payloadResult = GeneratePayloadUseCase(payloadConfig: payloadConfig)();
        _cachedPayloadResult = payloadResult; // Cache generated payload
        _cacheRetriesCount = 0;
      }

      final timeoutSec = payloadConfig.settings.apiTimeoutSec;
      final request = ApiRequest(
        endpoint: endpoint,
        proxy: payloadConfig.settings.proxy,
        headers: payloadConfig.getHeaders(),
        payload: payloadResult.payload,
        timeout: timeoutSec > 0 ? Duration(seconds: timeoutSec) : null,
      );
      bool rateLimitLogged = false;
      try {
        final response = await ApiService().fetchData(request);
        if (response.status == '401') {
          await _notifyAuthFailed();
          throw Exception(tr('bark_auth_fail_body'));
        }
        if (response.status == '429') {
          await LogService().logRateLimit429();
          rateLimitLogged = true;
          throw Exception(tr('rate_limit_429'));
        }
        // Even if response status is not 2xx, postprocess could throw correct exception.
        var imageBytes = ImageService().processResponse(response.data);
        // Add custom metadata
        if (payloadConfig.settings.metadataEraseEnabled) {
          final metadataString = payloadConfig.settings.customMetadataEnabled
              ? payloadConfig.settings.customMetadataContent
              : '';
          imageBytes =
              await ImageService().embedMetadata(imageBytes, metadataString);
        }
        final thumbnailBytes = ImageService().createThumbnail(imageBytes);

        // Save original image and keep only lightweight data in list cards.
        final filePrefix = payloadResult.suggestedFileName.isNotEmpty
            ? _getSafeFileName(payloadResult.suggestedFileName)
            : '';
        final fileName = [
          FileService().generateTimestampString(commandStatus.batchTimestamp),
          commandStatus.currentTotalCount.toString().padLeft(6, '0'),
          filePrefix,
          '${FileService().generateRandomString()}.png',
        ].join('-');

        String? originalImagePath;
        Uint8List? detailImageBytesFallback = imageBytes;
        try {
          originalImagePath = await FileService().savePictureToFile(
            imageBytes,
            fileName,
            payloadConfig.settings.outputFolderPath,
          );
          if (originalImagePath != null && originalImagePath.isNotEmpty) {
            detailImageBytesFallback = null;
          }
        } catch (_) {
          // Keep rendering flow alive; detail page will fallback to memory bytes.
        }
        // Reset cache after successful generation
        _cachedPayloadResult = null;
        // Only increment total count after successful generation
        commandStatus.currentTotalCount++;
        return InfoCardContent(
          title: fileName,
          info: payloadResult.comment,
          additionalInfo: digestPayloadResult(payloadResult),
          thumbnailBytes: thumbnailBytes,
          originalImagePath: originalImagePath,
          detailImageBytesFallback: detailImageBytesFallback,
        );
      } catch (e) {
        await _logIfRateLimitError(e, alreadyLogged: rateLimitLogged);
        await _logIfHandshakeError(e);
        return InfoCardContent(
          title: 'Error occurred in generation process.',
          info: e.toString(),
          additionalInfo: digestPayloadResult(payloadResult),
        );
      }
    }

    // Create command and attach post-command operations
    final command = Command.createAsyncNoParam(
      commandFunc,
      initialValue: InfoCardContent.fromEmpty(),
    );
    command.isExecuting.addListener(() {
      notifyListeners();
      // Only update after execution
      if (command.isExecuting.value) return;

      if (!commandStatus.isBatchActive.value) return;

      commandStatus.currentBatchCount++;
      if (commandStatus.currentTotalCount >=
              payloadConfig.settings.numberOfRequests &&
          payloadConfig.settings.numberOfRequests != 0) {
        stopBatch();
        return;
      } else if (commandStatus.currentBatchCount >=
          payloadConfig.settings.batchCount) {
        setCooldown();
        return;
      } else {
        setInnerDelay();
      }
    });

    // Execute command
    currentCommand = command;
    addAndRunCommand(command);
  }

  void startBatch() {
    _cancelDelayTimers();
    cooldownDelaySec.value = null;
    innerDelaySec.value = null;
    commandStatus.isCoolingDown.value = false;
    commandStatus.currentBatchCount = 0;
    commandStatus.currentTotalCount = 0;
    commandStatus.isBatchActive.value = true;
    commandStatus.batchTimestamp = DateTime.now();
    nextCommand();
  }

  void stopBatch() {
    commandStatus.isBatchActive.value = false;
    commandStatus.isCoolingDown.value = false;
    _cancelDelayTimers();
  }

  void _cancelDelayTimers() {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _innerDelayTimer?.cancel();
    _innerDelayTimer = null;
  }

  void setCooldown() {
    if (!commandStatus.isBatchActive.value) return;

    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _innerDelayTimer?.cancel();
    _innerDelayTimer = null;

    commandStatus.isCoolingDown.value = true;
    final baseSec = payloadConfig.settings.batchIntervalSec;
    final jitterSec = payloadConfig.settings.batchIntervalJitterSec;
    final safeBaseSec = max(0, baseSec);
    final safeJitterSec = max(0, jitterSec);
    final minSec = max(0, safeBaseSec - safeJitterSec);
    final maxSec = max(0, safeBaseSec + safeJitterSec);
    final delaySec = safeJitterSec == 0
        ? safeBaseSec
        : minSec + Random().nextInt(maxSec - minSec + 1);
    cooldownDelaySec.value = delaySec;
    _cooldownTimer = Timer(
      Duration(seconds: delaySec),
      () {
        _cooldownTimer = null;
        if (!commandStatus.isBatchActive.value) return;
        commandStatus.isCoolingDown.value = false;
        commandStatus.currentBatchCount = 0;
        nextCommand();
      },
    );
  }

  void setInnerDelay() {
    if (!commandStatus.isBatchActive.value) return;

    _innerDelayTimer?.cancel();
    _innerDelayTimer = null;

    final baseSec = payloadConfig.settings.batchInnerIntervalSec;
    final jitterSec = payloadConfig.settings.batchInnerIntervalJitterSec;
    final safeBaseSec = max(0, baseSec);
    final safeJitterSec = max(0, jitterSec);
    final minSec = max(0, safeBaseSec - safeJitterSec);
    final maxSec = max(0, safeBaseSec + safeJitterSec);
    final delaySec = safeJitterSec == 0
        ? safeBaseSec
        : minSec + Random().nextInt(maxSec - minSec + 1);
    if (delaySec <= 0) {
      nextCommand();
      return;
    }
    innerDelaySec.value = delaySec;
    _innerDelayTimer = Timer(
      Duration(seconds: delaySec),
      () {
        _innerDelayTimer = null;
        if (!commandStatus.isBatchActive.value) return;
        nextCommand();
      },
    );
  }

  void clearCooldownDelayNotice() {
    cooldownDelaySec.value = null;
  }

  void clearInnerDelayNotice() {
    innerDelaySec.value = null;
  }

  Future<void> _notifyAuthFailed() async {
    final settings = payloadConfig.settings;
    if (!settings.barkNotifyAuthFailEnabled) return;
    if (settings.barkToken.trim().isEmpty) return;
    final now = DateTime.now();
    final cooldownSec = settings.barkNotifyAuthFailCooldownSec;
    if (cooldownSec > 0 && _lastBarkAuthFailAt != null) {
      final diff = now.difference(_lastBarkAuthFailAt!);
      if (diff.inSeconds < cooldownSec) return;
    }
    _lastBarkAuthFailAt = now;
    try {
      await BarkService().sendAuthFailNotification(
        token: settings.barkToken,
        title: tr('bark_auth_fail_title'),
        body: tr('bark_auth_fail_body'),
        proxy: settings.proxy,
      );
    } catch (_) {
      // Ignore Bark failures to avoid breaking generation flow.
    }
  }

  Future<void> _logIfHandshakeError(Object e) async {
    if (e is HandshakeException || e.toString().contains('HandshakeException')) {
      await LogService().logHandshakeException(e.toString());
    }
  }

  Future<void> _logIfRateLimitError(
    Object e, {
    required bool alreadyLogged,
  }) async {
    if (alreadyLogged) return;
    final message = e.toString();
    if (message.contains('"statusCode":429') ||
        message.contains('statusCode":429') ||
        message.contains('Concurrent generation is locked')) {
      await LogService().logRateLimit429();
    }
  }

  void toggleBatch() {
    if (commandStatus.isBatchActive.value) {
      stopBatch();
    } else {
      startBatch();
    }
  }

  /// Make PayloadResult into readable Map<String, dynamic> for better visualization
  Map<String, dynamic> digestPayloadResult(
      PayloadGenerationResult payloadResult) {
    // 明确将 payload 转换为可空动态类型
    final additionalInfo = Map<String, dynamic>.from(payloadResult.payload);

    // 使用 Map.from 确保 parameters 的类型为 Map<String, dynamic>
    final additionalInfoParam = Map<String, dynamic>.from(
      additionalInfo['parameters']! as Map,
    );

    // 移除不需要的键
    for (final key in [
      'reference_image_multiple',
      'reference_information_extracted_multiple',
      'reference_strength_multiple'
    ]) {
      additionalInfoParam.remove(key);
    }

    additionalInfo.remove('parameters');

    // 合并时使用显式类型转换
    additionalInfo.addAll(additionalInfoParam.cast<String, dynamic>());

    return additionalInfo;
  }

  void clearCommandList() {
    // Remove finished commands in list
    commandList.removeWhere((command) => !command.isExecuting.value);
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelDelayTimers();
    super.dispose();
  }

  String _getSafeFileName(String fileName) {
    String safeName = fileName.replaceAll(RegExp(r'[<>"/\\|?*{}\[\]]'), '');
    safeName = safeName.replaceAll(RegExp(r'[:]'), '_');
    return safeName.substring(0, min(200, safeName.length));
  }

  void setOverride(bool? value) {
    if (value == null) return;
    payloadConfig.useOverridePrompt = value;
    notifyListeners();
  }

  void setCharacterOverride(bool? value) {
    if (value == null) return;
    payloadConfig.useCharacterPromptWithOverride = value;
    notifyListeners();
  }

  void setOverridePrompt(String value) {
    payloadConfig.overridePrompt = value;
    notifyListeners();
  }

  void setUC(String value) {
    payloadConfig.paramConfig.negativePrompt = value;
    notifyListeners();
  }
}
