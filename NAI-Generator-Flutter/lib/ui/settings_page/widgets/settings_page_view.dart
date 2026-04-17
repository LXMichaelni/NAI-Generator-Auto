import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nai_casrand/core/constants/settings.dart';
import 'package:nai_casrand/ui/settings_page/view_models/settings_page_viewmodel.dart';
import 'package:nai_casrand/ui/core/widgets/editable_list_tile.dart';
import 'package:nai_casrand/ui/settings_page/widgets/config_selection_page_view.dart';
import 'package:nai_casrand/ui/core/utils/flushbar.dart';

import '../../../core/constants/defaults.dart';

class SettingsPageView extends StatefulWidget {
  const SettingsPageView({super.key});

  @override
  State<SettingsPageView> createState() => _SettingsPageViewState();
}

class _SettingsPageViewState extends State<SettingsPageView> {
  final SettingsPageViewmodel viewmodel = SettingsPageViewmodel();

  @override
  void dispose() {
    viewmodel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = ListenableBuilder(
      listenable: viewmodel,
      builder: (context, child) => Column(
        children: [
          _buildApiKeyTile(),
          _buildSentryProxyTile(context),
          _buildBatchTile(),
          _buildEraseMetadataTile(context),
          if (!kIsWeb && Platform.isWindows) _buildOutputSelectionTile(),
          _buildPrefixKeyTile(),
          if (!kIsWeb) _buildProxyTile(context),
          _buildBarkTokenTile(),
          _buildBarkAuthFailTile(),
          _buildBarkAuthFailCooldownTile(),
          const Divider(),
          _buildSavedConfigTile(context),
          _buildThemeModeTile(context),
          _buildLanguageTile(context),
        ],
      ),
    );

    final buttons = Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          onPressed: () => viewmodel.loadJsonConfig(context),
          tooltip: tr('import_settings_from_file'),
          heroTag: 'settings_import_fab',
          child: const Icon(Icons.file_open),
        ),
        const SizedBox(height: 20),
        FloatingActionButton(
          onPressed: () => viewmodel.saveJsonConfig(),
          tooltip: tr('export_settings_to_file'),
          heroTag: 'settings_export_fab',
          child: const Icon(Icons.save),
        ),
      ],
    );

    return Scaffold(
      body: SingleChildScrollView(
        child: content,
      ),
      floatingActionButton: buttons,
    );
  }

  Widget _buildApiKeyTile() {
    if (viewmodel.settings.sentryProxyEnabled) {
      return ListTile(
        leading: const Icon(Icons.token_outlined),
        title: Text(tr('NAI_API_key')),
        subtitle: Text(tr('sentry_proxy_api_key_hijacked')),
        enabled: false,
      );
    }
    return EditableListTile(
        leading: const Icon(Icons.token_outlined),
        title: tr('NAI_API_key'),
        notice: tr('NAI_API_key_hint'),
        currentValue: viewmodel.settings.apiKey,
        confirmOnSubmit: true,
        onEditComplete: (value) => viewmodel.setApiKey(value));
  }

  Widget _buildSentryProxyTile(BuildContext context) {
    final enabled = viewmodel.settings.sentryProxyEnabled;
    return ExpansionTile(
      leading: const Icon(Icons.vpn_lock_outlined),
      title: Text(tr('sentry_proxy_section')),
      subtitle: Text(enabled
          ? tr('sentry_proxy_enabled_subtitle')
          : tr('sentry_proxy_disabled_subtitle')),
      initiallyExpanded: enabled,
      children: [
        CheckboxListTile(
          secondary: const Icon(Icons.swap_horiz),
          title: Text(tr('sentry_proxy_toggle')),
          subtitle: Text(tr('sentry_proxy_toggle_hint')),
          value: enabled,
          onChanged: (value) => viewmodel.setSentryProxyEnabled(value),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: EditableListTile(
            leading: const Icon(Icons.link),
            title: tr('sentry_proxy_base_url'),
            notice: tr('sentry_proxy_base_url_hint'),
            currentValue: viewmodel.settings.sentryProxyBaseUrl,
            confirmOnSubmit: true,
            onEditComplete: (value) => viewmodel.setSentryProxyBaseUrl(value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.network_ping),
              label: Text(tr('sentry_proxy_test')),
              onPressed: () async {
                final result = await viewmodel.testSentryProxy();
                if (!context.mounted) return;
                if (result.ok) {
                  showInfoBar(context, result.message);
                } else {
                  showErrorBar(context, result.message);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchTile() {
    final displayedNumberOfRequests = viewmodel.settings.numberOfRequests == 0
        ? '∞'
        : viewmodel.settings.numberOfRequests.toString();
    return ExpansionTile(
      leading: const Icon(Icons.schedule),
      title: Text(tr('batch_settings')),
      subtitle: Text(tr('batch_settings_info', namedArgs: {
        'batch_count': viewmodel.settings.batchCount.toString(),
        'interval': viewmodel.settings.batchIntervalSec.toString(),
        'jitter': viewmodel.settings.batchIntervalJitterSec.toString(),
        'inner_interval': viewmodel.settings.batchInnerIntervalSec.toString(),
        'inner_jitter':
            viewmodel.settings.batchInnerIntervalJitterSec.toString(),
        'number_of_requests': displayedNumberOfRequests,
      })),
      children: [
        // Batch count
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: EditableListTile(
              leading: const Icon(Icons.checklist),
              title: tr('batch_count'),
              currentValue: viewmodel.settings.batchCount.toString(),
              keyboardType: TextInputType.number,
              confirmOnSubmit: true,
              onEditComplete: (value) => viewmodel.setBatchCount(value)),
        ),
        // Batch interval
        Padding(
            padding: const EdgeInsets.only(left: 20),
            child: EditableListTile(
                leading: const Icon(Icons.hourglass_empty),
                title: tr('batch_interval'),
                currentValue: viewmodel.settings.batchIntervalSec.toString(),
                keyboardType: TextInputType.number,
                confirmOnSubmit: true,
                onEditComplete: (value) =>
                    viewmodel.setBatchIntervalSet(value))),
        // Batch inner interval
        Padding(
            padding: const EdgeInsets.only(left: 20),
            child: EditableListTile(
                leading: const Icon(Icons.timelapse),
                title: tr('batch_inner_interval'),
                currentValue:
                    viewmodel.settings.batchInnerIntervalSec.toString(),
                keyboardType: TextInputType.number,
                confirmOnSubmit: true,
                onEditComplete: (value) =>
                    viewmodel.setBatchInnerIntervalSet(value))),
        // Batch interval jitter
        Padding(
            padding: const EdgeInsets.only(left: 20),
            child: EditableListTile(
                leading: const Icon(Icons.shuffle),
                title: tr('batch_interval_jitter'),
                currentValue:
                    viewmodel.settings.batchIntervalJitterSec.toString(),
                keyboardType: TextInputType.number,
                confirmOnSubmit: true,
                onEditComplete: (value) =>
                    viewmodel.setBatchIntervalJitterSet(value))),
        // Batch inner interval jitter
        Padding(
            padding: const EdgeInsets.only(left: 20),
            child: EditableListTile(
                leading: const Icon(Icons.shuffle_on),
                title: tr('batch_inner_interval_jitter'),
                currentValue:
                    viewmodel.settings.batchInnerIntervalJitterSec.toString(),
                keyboardType: TextInputType.number,
                confirmOnSubmit: true,
                onEditComplete: (value) =>
                    viewmodel.setBatchInnerIntervalJitterSet(value))),
        // Number of requests
        Padding(
            padding: const EdgeInsets.only(left: 20),
            child: EditableListTile(
              leading: const Icon(Icons.alarm),
              title: tr('image_number_to_generate'),
              currentValue: displayedNumberOfRequests,
              editValue: viewmodel.settings.numberOfRequests.toString(),
              notice: '0 → ∞',
              onEditComplete: (value) => viewmodel.setNumberOfRequests(value),
              keyboardType: TextInputType.number,
              confirmOnSubmit: true,
            )),
        // Max waterfall items
        Padding(
            padding: const EdgeInsets.only(left: 20),
            child: EditableListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: tr('generation_list_limit'),
              currentValue: viewmodel.settings.generationPageMaxItems.toString(),
              notice: tr('generation_list_limit_hint'),
              onEditComplete: (value) =>
                  viewmodel.setGenerationPageMaxItems(value),
              keyboardType: TextInputType.number,
              confirmOnSubmit: true,
            )),
        // API timeout
        Padding(
            padding: const EdgeInsets.only(left: 20),
            child: EditableListTile(
              leading: const Icon(Icons.timer),
              title: tr('api_timeout'),
              currentValue: viewmodel.settings.apiTimeoutSec == 0
                  ? '∞'
                  : viewmodel.settings.apiTimeoutSec.toString(),
              editValue: viewmodel.settings.apiTimeoutSec.toString(),
              notice: tr('api_timeout_hint'),
              onEditComplete: (value) => viewmodel.setApiTimeout(value),
              keyboardType: TextInputType.number,
              confirmOnSubmit: true,
            )),
      ],
    );
  }

  Widget _buildEraseMetadataTile(BuildContext context) {
    List<Widget> tiles = [
      CheckboxListTile(
          secondary: const Icon(Icons.delete_sweep),
          title: Text(tr('metadata_erase_enabled')),
          value: viewmodel.settings.metadataEraseEnabled,
          onChanged: (value) => viewmodel.setEraseMetadataEnabled(value))
    ];
    if (viewmodel.settings.metadataEraseEnabled) {
      tiles.add(Padding(
          padding: const EdgeInsets.only(left: 20),
          child: CheckboxListTile(
              secondary: const Icon(Icons.edit_note),
              title: Text(tr('custom_metadata_enabled')),
              value: viewmodel.settings.customMetadataEnabled,
              onChanged: (value) =>
                  viewmodel.setCustomMetadataEnabled(value))));
    }
    if (viewmodel.settings.metadataEraseEnabled &&
        viewmodel.settings.customMetadataEnabled) {
      tiles.add(Padding(
          padding: const EdgeInsets.only(left: 30),
          child: ListTile(
            title: Text(tr('custom_metadata_content')),
            subtitle: Text(
              viewmodel.settings.customMetadataContent,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _showEditCustomMetadataDialog(context),
          )));
    }
    return Column(
      children: tiles,
    );
  }

  Widget _buildOutputSelectionTile() {
    if (kIsWeb || Platform.isAndroid) return const SizedBox.shrink();
    final outputDirPath = viewmodel.settings.outputFolderPath == ''
        ? '<${tr('system_document_folder')}>\\nai_generated'
        : viewmodel.settings.outputFolderPath;
    return ListTile(
      leading: const Icon(Icons.folder_outlined),
      title: Text(tr('output_folder')),
      subtitle: Text(outputDirPath),
      onTap: () => viewmodel.pickOutputFolderPath(),
    );
  }

  Widget _buildProxyTile(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    final proxy = viewmodel.settings.proxy;
    if (viewmodel.settings.sentryProxyEnabled) {
      return ListTile(
        leading: const Icon(Icons.route),
        title: Text(tr('proxy_settings')),
        subtitle: Text(
            '${proxy == '' ? tr('proxy_settings_direct') : proxy} · ${tr('sentry_proxy_overrides_proxy')}'),
        enabled: false,
      );
    }
    return EditableListTile(
      leading: const Icon(Icons.route),
      title: tr('proxy_settings'),
      currentValue: proxy == '' ? tr('proxy_settings_direct') : proxy,
      editValue: proxy,
      notice: tr('proxy_settings_notice'),
      confirmOnSubmit: true,
      onEditComplete: (value) => viewmodel.setProxy(value),
    );
  }

  Widget _buildBarkTokenTile() {
    return EditableListTile(
      leading: const Icon(Icons.notifications_active_outlined),
      title: tr('bark_token'),
      notice: tr('bark_token_hint'),
      currentValue: viewmodel.settings.barkToken.isEmpty
          ? tr('bark_token_empty')
          : viewmodel.settings.barkToken,
      editValue: viewmodel.settings.barkToken,
      confirmOnSubmit: true,
      onEditComplete: (value) => viewmodel.setBarkToken(value),
    );
  }

  Widget _buildBarkAuthFailTile() {
    return CheckboxListTile(
      secondary: const Icon(Icons.lock_outline),
      title: Text(tr('bark_notify_auth_fail')),
      subtitle: Text(tr('bark_notify_auth_fail_hint')),
      value: viewmodel.settings.barkNotifyAuthFailEnabled,
      onChanged: (value) => viewmodel.setBarkAuthFailEnabled(value),
    );
  }

  Widget _buildBarkAuthFailCooldownTile() {
    return EditableListTile(
      leading: const Icon(Icons.timer_outlined),
      title: tr('bark_notify_auth_fail_cooldown'),
      notice: tr('bark_notify_auth_fail_cooldown_hint'),
      currentValue: viewmodel.settings.barkNotifyAuthFailCooldownSec.toString(),
      keyboardType: TextInputType.number,
      confirmOnSubmit: true,
      onEditComplete: (value) => viewmodel.setBarkAuthFailCooldown(value),
    );
  }

  void _showEditCustomMetadataDialog(context) {
    final controller =
        TextEditingController(text: viewmodel.settings.customMetadataContent);
    submit() {
      viewmodel.setCustomMetadataContent(controller.text);
      Navigator.of(context).pop();
    }

    showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                title: Text(
                    tr('edit') + tr('colon') + tr('custom_metadata_content')),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(tr('edit_custom_metadata_content_hint')),
                      TextField(
                        maxLines: null,
                        autofocus: true,
                        controller: controller,
                        onSubmitted: (_) => submit(),
                      )
                    ]),
                actions: [
                  Row(
                    children: [
                      TextButton(
                          onPressed: () => setState(
                              () => controller.text = defaultWatermarkContent),
                          child: const Text('👻')),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(tr('cancel')),
                      ),
                      TextButton(
                        onPressed: () => submit(),
                        child: Text(tr('confirm')),
                      )
                    ],
                  ),
                ],
              ),
            ));
  }

  Widget _buildPrefixKeyTile() {
    final shownPrefix = viewmodel.settings.fileNamePrefixKey.isNotEmpty
        ? viewmodel.settings.fileNamePrefixKey
        : 'nai-generated';
    return EditableListTile(
      leading: const Icon(Icons.description),
      title: tr('output_file_name_prefix'),
      notice: tr('output_file_name_prefix_hint'),
      editValue: viewmodel.settings.fileNamePrefixKey,
      currentValue: shownPrefix,
      confirmOnSubmit: true,
      onEditComplete: (value) => viewmodel.setFileNamePrefixKey(value),
    );
  }

  Widget _buildThemeModeTile(BuildContext context) {
    return SelectableListTile(
      title: tr('theme_mode'),
      leading: const Icon(Icons.dark_mode_outlined),
      currentValue: viewmodel.payloadConfig.settings.themeMode,
      options: themeModeStrings,
      onSelectComplete: (value) => viewmodel.setThemeMode(value, context),
    );
  }

  Widget _buildLanguageTile(BuildContext context) {
    return ListTile(
      title: const Text('Language'),
      leading: const Icon(Icons.translate),
      subtitle: Text(context.locale.toLanguageTag()),
      onTap: () => _showLanguageSelectionDialog(context),
    );
  }

  void _showLanguageSelectionDialog(BuildContext context) {
    final locales = context.supportedLocales;
    String getLocaleName(Locale locale) {
      if (locale.countryCode == null) {
        return locale.languageCode;
      } else {
        return '${locale.languageCode}-${locale.countryCode}';
      }
    }

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Select language...'),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: locales
                        .map((l) => ListTile(
                              title: Text(getLocaleName(l)),
                              onTap: () {
                                Navigator.of(context).pop();
                                context.setLocale(l);
                              },
                            ))
                        .toList()),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(context.tr('confirm')))
                ]));
  }

  Widget _buildSavedConfigTile(BuildContext context) {
    return ListTile(
      title: Text(tr('saved_config')),
      leading: const Icon(Icons.save_outlined),
      onTap: () {
        viewmodel.saveCurrentConfig();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ConfigSelectionPageView(
                      notificationCallback: () => viewmodel.notify(),
                    )));
      },
    );
  }
}
