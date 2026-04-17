import 'dart:io';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:nai_casrand/data/models/command_status.dart';
import 'package:nai_casrand/data/models/info_card_content.dart';
import 'package:nai_casrand/data/models/payload_config.dart';
import 'package:nai_casrand/data/models/settings.dart';
import 'package:nai_casrand/ui/core/utils/flushbar.dart';
import 'package:flutter_command/flutter_command.dart';

class InfoCard extends StatelessWidget {
  final Command<void, InfoCardContent> command;

  CommandStatus get commandStatus => GetIt.I();
  Settings get settings => GetIt.I<PayloadConfig>().settings;

  const InfoCard({super.key, required this.command});

  @override
  Widget build(BuildContext context) {
    final cardBody = ListenableBuilder(
      listenable: command.isExecuting,
      builder: (context, child) {
        if (command.isExecuting.value) {
          final current = commandStatus.currentTotalCount.toString();
          final total = settings.numberOfRequests != 0
              ? settings.numberOfRequests.toString()
              : '∞';
          // Loading
          return ListTile(
            leading: const CircularProgressIndicator(),
            title: Text(tr('requesting_progress', namedArgs: {'current': current, 'total': total})),
          );
        } else {
          // Result
          return _buildCardContentBody(context, command.value);
        }
      },
    );

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => _showDetailedInfoDialog(context),
        child: cardBody,
      ),
    );
  }

  void _showDetailedInfoDialog(BuildContext context) {
    if (command.isExecuting.value) return;
    final content = command.value;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InfoDetailPage(content: content),
      ),
    );
  }

  Widget _buildCardContentBody(BuildContext context, InfoCardContent content) {
    final previewBytes = content.thumbnailBytes ?? content.detailImageBytesFallback;
    return previewBytes == null
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(content.title),
              ),
              ListTile(
                subtitle: Text(
                  content.info,
                  maxLines: 20,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_outlined),
                title: Text(
                  content.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Image.memory(
                fit: BoxFit.contain,
                previewBytes,
                filterQuality: FilterQuality.medium,
              ),
            ],
          );
  }
}

class InfoDetailPage extends StatefulWidget {
  final InfoCardContent content;

  const InfoDetailPage({super.key, required this.content});

  @override
  State<InfoDetailPage> createState() => _InfoDetailPageState();
}

class _InfoDetailPageState extends State<InfoDetailPage> {
  late final Future<Uint8List?> _detailImageFuture;

  @override
  void initState() {
    super.initState();
    _detailImageFuture = _loadDetailImageBytes();
  }

  Future<Uint8List?> _loadDetailImageBytes() async {
    final path = widget.content.originalImagePath;
    if (!kIsWeb && path != null && path.isNotEmpty) {
      try {
        final file = File(path);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      } catch (_) {
        // Fallback below.
      }
    }
    return widget.content.detailImageBytesFallback ?? widget.content.thumbnailBytes;
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.content;
    final hasImageSource =
        (content.originalImagePath?.isNotEmpty ?? false) ||
            content.detailImageBytesFallback != null ||
            content.thumbnailBytes != null;

    final detailRows = <Widget>[
      _buildInfoTile(tr('title'), content.title, context),
      _buildInfoTile(tr('info'), content.info, context),
      for (final item in content.additionalInfo.entries)
        _buildInfoTile(item.key, item.value.toString(), context),
    ];

    final body = Scaffold(
      appBar: AppBar(title: Text(content.title)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (hasImageSource)
              FutureBuilder<Uint8List?>(
                future: _detailImageFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return ListTile(
                      leading: const Icon(Icons.broken_image_outlined),
                      title: Text(tr('failed')),
                    );
                  }
                  return Image.memory(snapshot.data!, fit: BoxFit.contain);
                },
              ),
            ...detailRows,
          ],
        ),
      ),
    );

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: body,
    );
  }

  Widget _buildInfoTile(String title, String content, BuildContext context) {
    return Column(
      children: [
        ListTile(
          titleAlignment: ListTileTitleAlignment.top,
          title: Text(title),
          subtitle: SelectableText(content),
          trailing: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
              _copyContent(content, context);
            },
            tooltip: tr('copy_to_clipboard'),
            icon: const Icon(Icons.copy),
          ),
        ),
        const Divider(),
      ],
    );
  }

  void _copyContent(String content, BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (!context.mounted) return;
    showInfoBar(context, '${tr('info_export_to_clipboard')}${tr('succeed')}');
  }
}
