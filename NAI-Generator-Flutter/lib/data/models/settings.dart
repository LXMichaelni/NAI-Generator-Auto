import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:nai_casrand/core/constants/settings.dart';

import '../../core/constants/defaults.dart';

class Settings {
  // Don't show again
  String welcomeMessageVersion;

  // Display settings
  int generationPageColumnCount;
  int generationPageMaxItems;
  String themeMode;

  // API key
  String apiKey;

  // Output dir, for windows only
  String outputFolderPath;

  // Proxy settings
  String proxy;

  // Debug API path
  String debugApiPath;
  bool debugApiEnabled;

  // Sentry 反向代理（反代劫持）
  bool sentryProxyEnabled;
  String sentryProxyBaseUrl;

  // Image metadata erase
  bool metadataEraseEnabled;
  bool customMetadataEnabled;
  String customMetadataContent;

  // Batch settings
  int batchCount;
  int batchIntervalSec;
  int batchIntervalJitterSec;
  int batchInnerIntervalSec;
  int batchInnerIntervalJitterSec;
  // Number of requests
  int numberOfRequests;

  // API timeout
  int apiTimeoutSec;

  // File name prefix key
  String fileNamePrefixKey;

  // Bark token
  String barkToken;
  bool barkNotifyAuthFailEnabled;
  int barkNotifyAuthFailCooldownSec;

  Settings({
    required this.welcomeMessageVersion,
    required this.apiKey,
    required this.outputFolderPath,
    required this.proxy,
    required this.debugApiEnabled,
    required this.debugApiPath,
    required this.sentryProxyEnabled,
    required this.sentryProxyBaseUrl,
    required this.metadataEraseEnabled,
    required this.customMetadataEnabled,
    required this.customMetadataContent,
    required this.batchCount,
    required this.batchIntervalSec,
    required this.batchIntervalJitterSec,
    required this.batchInnerIntervalSec,
    required this.batchInnerIntervalJitterSec,
    required this.numberOfRequests,
    required this.apiTimeoutSec,
    required this.fileNamePrefixKey,
    required this.barkToken,
    required this.barkNotifyAuthFailEnabled,
    required this.barkNotifyAuthFailCooldownSec,
    required this.generationPageColumnCount,
    required this.generationPageMaxItems,
    required this.themeMode,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      welcomeMessageVersion: json['welcome_message_version'] ?? '',
      apiKey: json['api_key'] ?? '',
      outputFolderPath: json['output_folder'] ?? '',
      proxy: json['proxy'] ?? '',
      debugApiEnabled: false,
      debugApiPath: 'http://localhost:5000/ai/generate-image',
      sentryProxyEnabled: json['sentry_proxy_enabled'] ?? false,
      sentryProxyBaseUrl:
          json['sentry_proxy_base_url'] ?? 'http://localhost:7899',
      metadataEraseEnabled: json['metadata_erase_enabled'] ?? false,
      customMetadataEnabled: json['custom_metadata_enabled'] ?? false,
      customMetadataContent:
          json['custom_metadata_content'] ?? defaultWatermarkContent,
      batchCount: json['batch_count'] ?? 10,
      batchIntervalSec: json['batch_interval'] ?? 10,
      batchIntervalJitterSec: json['batch_interval_jitter'] ?? 0,
      batchInnerIntervalSec: json['batch_inner_interval'] ?? 0,
      batchInnerIntervalJitterSec: json['batch_inner_interval_jitter'] ?? 0,
      numberOfRequests: json['number_of_requests'] ?? 0,
      apiTimeoutSec: json['api_timeout'] ?? 60,
      fileNamePrefixKey: json['file_name_prefix_key'] ?? '',
      barkToken: json['bark_token'] ?? '',
      barkNotifyAuthFailEnabled: json['bark_notify_auth_fail'] ?? false,
      barkNotifyAuthFailCooldownSec:
          json['bark_notify_auth_fail_cooldown'] ?? 60,
      generationPageColumnCount: json['generation_page_column_count'] ?? 2,
      generationPageMaxItems: json['generation_page_max_items'] ?? 200,
      themeMode: json['theme_mode'] ?? 'system',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'welcome_message_version': welcomeMessageVersion,
      'api_key': apiKey,
      'output_folder': outputFolderPath,
      'proxy': proxy,
      'metadata_erase_enabled': metadataEraseEnabled,
      'custom_metadata_enabled': customMetadataEnabled,
      'custom_metadata_content': customMetadataContent,
      'batch_count': batchCount,
      'batch_interval': batchIntervalSec,
      'batch_interval_jitter': batchIntervalJitterSec,
      'batch_inner_interval': batchInnerIntervalSec,
      'batch_inner_interval_jitter': batchInnerIntervalJitterSec,
      'file_name_prefix_key': fileNamePrefixKey,
      'bark_token': barkToken,
      'bark_notify_auth_fail': barkNotifyAuthFailEnabled,
      'bark_notify_auth_fail_cooldown': barkNotifyAuthFailCooldownSec,
      'number_of_requests': numberOfRequests,
      'api_timeout': apiTimeoutSec,
      'generation_page_column_count': generationPageColumnCount,
      'generation_page_max_items': generationPageMaxItems,
      'theme_mode': themeMode,
      'sentry_proxy_enabled': sentryProxyEnabled,
      'sentry_proxy_base_url': sentryProxyBaseUrl,
    };
  }

  AdaptiveThemeMode get theme =>
      stringToThemeMode[themeMode] ?? AdaptiveThemeMode.system;
}
