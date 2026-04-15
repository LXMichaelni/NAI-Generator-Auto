import 'package:flutter/material.dart';

import '../viewmodels/vibe_config_v4_viewmodel.dart';

class VibeConfigV4View extends StatelessWidget {
  final VibeConfigV4Viewmodel viewmodel;
  final VoidCallback? onDelete; // Callback for delete action

  const VibeConfigV4View({
    super.key,
    required this.viewmodel,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnail = viewmodel.imageBytes != null
        ? Image.memory(viewmodel.imageBytes!, fit: BoxFit.cover)
        : const Icon(Icons.broken_image_outlined, size: 50);

    final widgetImage = SizedBox(
      height: 120.0,
      width: 120.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: thumbnail,
      ),
    );

    return ListenableBuilder(
      listenable: viewmodel,
      builder: (context, child) {
        final infoValues = viewmodel.availableInformationExtractedValues;
        final selectedInfoIndex = _findSelectedIndex(
          infoValues,
          viewmodel.selectedInformationExtracted,
        );

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widgetImage,
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        viewmodel.fileName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                          'Strength: ${viewmodel.referenceStrength.toStringAsFixed(2)}'),
                      Row(children: [
                        Expanded(
                          child: Slider(
                            value: viewmodel.referenceStrength.clamp(0.0, 1.0),
                            min: 0.0,
                            max: 1.0,
                            divisions: 100,
                            label:
                                viewmodel.referenceStrength.toStringAsFixed(2),
                            onChanged: (value) =>
                                viewmodel.setReferenceStrength(value),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_note),
                          tooltip: "Edit Strength Value",
                          onPressed: () => _showEditReferenceStrengthDialog(
                              context, viewmodel),
                        )
                      ]),
                      const SizedBox(height: 6),
                      Text(
                        'Information Extracted: ${_formatDecimal(viewmodel.selectedInformationExtracted)}',
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: selectedInfoIndex.toDouble(),
                              min: 0.0,
                              max: (infoValues.length - 1).toDouble(),
                              divisions:
                                  infoValues.length > 1 ? infoValues.length - 1 : 1,
                              label: _formatDecimal(infoValues[selectedInfoIndex]),
                              onChanged: infoValues.length <= 1
                                  ? null
                                  : (value) => viewmodel
                                      .setSelectedInformationExtractedByIndex(
                                          value.round()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                    tooltip: "Delete Vibe Config",
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _findSelectedIndex(List<double> values, double selected) {
    final selectedIndex = values.indexWhere((value) {
      return (value - selected).abs() < 1e-9;
    });
    if (selectedIndex >= 0) {
      return selectedIndex;
    }
    return values.isEmpty ? 0 : values.length - 1;
  }

  String _formatDecimal(double value) {
    final fixed = value.toStringAsFixed(6);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  void _showEditReferenceStrengthDialog(
      BuildContext context, VibeConfigV4Viewmodel vm) {
    final TextEditingController controller =
        TextEditingController(text: vm.referenceStrength.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit Reference Strength'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Value (0.0 to 1.0)'),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                final double? newValue = double.tryParse(controller.text);
                if (newValue != null && newValue >= 0.0 && newValue <= 1.0) {
                  vm.setReferenceStrength(newValue);
                  Navigator.of(dialogContext).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Invalid value. Please enter a number between 0.0 and 1.0.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
