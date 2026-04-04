import 'package:flutter/material.dart';
import 'package:kalig_onan_evac_system/core/widgets/app_list_item_card.dart';
import 'package:kalig_onan_evac_system/features/staff/evacuees/domain/evacuee.dart';

class InlineRenameCard extends StatefulWidget {
  final Evacuee evacuee;
  final int index;
  final Function(String name) onSave;
  final VoidCallback onCancel;

  const InlineRenameCard({
    super.key,
    required this.evacuee,
    required this.index,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<InlineRenameCard> createState() => _InlineRenameCardState();
}

class _InlineRenameCardState extends State<InlineRenameCard> {
  late final TextEditingController controller;
  late final FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    focusNode = FocusNode();
    // Auto-focus the input field
    Future.microtask(() {
      FocusScope.of(context).requestFocus(focusNode);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppListItemCard(
      margin: const EdgeInsets.only(bottom: 8),
      title: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: const InputDecoration(
          hintText: 'Enter evacuee name',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () {
              focusNode.unfocus();
              widget.onCancel();
            },
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              focusNode.unfocus();
              widget.onSave(controller.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
