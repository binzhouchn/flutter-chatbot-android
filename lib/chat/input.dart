// This file is part of ChatBot.
//
// ChatBot is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ChatBot is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ChatBot. If not, see <https://www.gnu.org/licenses/>.

import "llm.dart";
import "chat.dart";
import "message.dart";
import "current.dart";
import "../util.dart";
import "../config.dart";
import "../gen/l10n.dart";

import "dart:convert";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:image_picker/image_picker.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_image_compress/flutter_image_compress.dart";

class InputWidget extends ConsumerStatefulWidget {
  static final FocusNode focusNode = FocusNode();

  const InputWidget({super.key});

  @override
  ConsumerState<InputWidget> createState() => _InputWidgetState();

  static void unFocus() => focusNode.unfocus();
}

typedef _Image = ({String name, MessageImage image});

class _InputWidgetState extends ConsumerState<InputWidget> {
  static final List<_Image> _images = [];
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _inputCtrl = TextEditingController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(llmProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height / 4,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            border: Border.all(
              width: 1,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: TextField(
                  maxLines: null,
                  autofocus: false,
                  controller: _inputCtrl,
                  focusNode: InputWidget.focusNode,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    constraints: const BoxConstraints(),
                    hintText: S.of(context).enter_message,
                    contentPadding: const EdgeInsets.only(
                        top: 16, left: 16, right: 16, bottom: 8),
                  ),
                ),
              ),
              Row(children: [
                const SizedBox(width: 5),
                IconButton(
                  icon: const Icon(Icons.upload_file),
                  onPressed: _addFile,
                ),
                IconButton(
                  icon: const Icon(Icons.language),
                  isSelected: LlmNotifier.googleSearch,
                  selectedIcon: const Icon(Icons.language),
                  onPressed: () => setState(() =>
                      LlmNotifier.googleSearch = !LlmNotifier.googleSearch),
                ),
                if (_images.isNotEmpty)
                  IconButton(
                    icon: Badge(
                      label: Text("${_images.length}"),
                      child: Icon(Icons.image),
                    ),
                    isSelected: true,
                    onPressed: _editImages,
                  ),
                const Expanded(child: SizedBox()),
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  isSelected: Current.chatStatus.isResponding,
                  selectedIcon: const Icon(Icons.pause),
                  onPressed: _sendMessage,
                ),
                const SizedBox(width: 5),
              ]),
              const SizedBox(height: 5),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addFile() async {
    InputWidget.unFocus();

    final result = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              minTileHeight: 48,
              shape: const StadiumBorder(),
              title: Text(S.of(context).camera),
              leading: const Icon(Icons.camera_outlined),
              onTap: () => Navigator.of(context).pop(1),
            ),
            ListTile(
              minTileHeight: 48,
              shape: const StadiumBorder(),
              title: Text(S.of(context).gallery),
              leading: const Icon(Icons.photo_library_outlined),
              onTap: () => Navigator.of(context).pop(2),
            ),
          ],
        ),
      ),
    );

    switch (result) {
      case 1:
        await _addImage(ImageSource.camera);
        break;

      case 2:
        await _addImage(ImageSource.gallery);
        break;
    }
  }

  Future<void> _addImage(ImageSource source) async {
    XFile? result;
    Uint8List? compressed;

    try {
      result = await _imagePicker.pickImage(source: source);
      if (result == null) return;
    } catch (e) {
      return;
    }

    if (Config.cic.enable ?? true) {
      try {
        compressed = await FlutterImageCompress.compressWithFile(
          result.path,
          quality: Config.cic.quality ?? 95,
          minWidth: Config.cic.minWidth ?? 1920,
          minHeight: Config.cic.minHeight ?? 1080,
        );
        if (compressed == null) throw false;
      } catch (e) {
        if (mounted) {
          Util.showSnackBar(
            context: context,
            content: Text(S.of(context).image_compress_failed),
          );
        }
      }
    }

    final bytes = compressed ?? await result.readAsBytes();
    final image = (
      name: result.name,
      image: (bytes: bytes, base64: base64Encode(bytes)),
    );
    setState(() => _images.add(image));
  }

  void _editImages() async {
    InputWidget.unFocus();

    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState2) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  top: 16, left: 24, right: 12, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    S.of(context).images,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: Navigator.of(context).pop,
                  ),
                ],
              ),
            ),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _images.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(_images[index].name),
                  contentPadding: const EdgeInsets.only(left: 24, right: 12),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() => _images.removeAt(index));
                      if (_images.isEmpty) {
                        Navigator.of(context).pop();
                      } else {
                        setState2(() {});
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (!Current.chatStatus.isNothing) {
      ref.read(llmProvider.notifier).stopChat();
      return;
    }

    final text = _inputCtrl.text;
    if (text.isEmpty) return;

    if (!Current.isOkToChat) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).setup_api_model_first),
      );
      return;
    }

    final messages = Current.messages;

    final user = MessageItem(
      text: text,
      role: MessageRole.user,
    );
    for (final image in _images) {
      user.images.add(image.image);
    }
    messages.add(Message.fromItem(user));

    final assistant = Message.fromItem(MessageItem(
      text: "",
      model: Current.model,
      role: MessageRole.assistant,
      time: Util.formatDateTime(DateTime.now()),
    ));
    messages.add(assistant);
    ref.read(messagesProvider.notifier).notify();

    _images.clear();
    _inputCtrl.clear();
    final error = await ref.read(llmProvider.notifier).chat(assistant);

    if (error != null && mounted) {
      _inputCtrl.text = text;
      Dialogs.error(context: context, error: error);
    }
  }
}
