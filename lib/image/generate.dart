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

import "../util.dart";
import "../config.dart";
import "../gen/l10n.dart";

import "dart:io";
import "dart:convert";
import "package:http/http.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

enum _Status {
  nothing,
  loading,
  generating;

  bool get isNothing => this == _Status.nothing;
  bool get isLoading => this == _Status.loading;
  bool get isGenerating => this == _Status.generating;
}

class GenerateTab extends ConsumerStatefulWidget {
  const GenerateTab({super.key});

  @override
  ConsumerState<GenerateTab> createState() => _GenerateTabState();
}

class _GenerateTabState extends ConsumerState<GenerateTab>
    with AutomaticKeepAliveClientMixin<GenerateTab> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _node = FocusNode();
  _Status _status = _Status.nothing;
  final List<String> _images = [];
  Client? _client;

  @override
  void dispose() {
    _node.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final decoration = BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: decoration,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: TextField(
            maxLines: 4,
            focusNode: _node,
            controller: _ctrl,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: S.of(context).enter_prompts,
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          icon: Icon(_status.isNothing ? Icons.add : Icons.close),
          label: Text(
            _status.isNothing ? S.of(context).generate : S.of(context).cancel,
          ),
          onPressed: _generate,
        ),
        const SizedBox(height: 12),
        if (!_status.isNothing) LinearProgressIndicator(),
        if (_images.isNotEmpty)
          InkWell(
            onTap: () => Dialogs.handleImage(
              context: context,
              path: _images[0],
            ),
            child: Image.file(File(_images[0])),
          ),
      ],
    );
  }

  Future<void> _generate() async {
    if (_status.isGenerating) {
      _status = _Status.nothing;
      _client?.close();
      _client = null;
      return;
    }

    final prompt = _ctrl.text;
    if (prompt.isEmpty) return;

    final image = Config.image;
    final model = image.model;
    final api = Config.apis[image.api];

    if (model == null || api == null) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).setup_api_model_first),
      );
      return;
    }

    final apiUrl = api.url;
    final apiKey = api.key;
    final endPoint = "$apiUrl/images/generations";

    setState(() {
      _images.clear();
      _status = _Status.generating;
    });

    final size = image.size;
    final style = image.style;
    final quality = image.quality;
    final optional = <String, String>{};

    if (size != null) optional["size"] = size;
    if (style != null) optional["style"] = style;
    if (quality != null) optional["quality"] = quality;

    try {
      _client ??= Client();
      final genRes = await _client!.post(
        Uri.parse(endPoint),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          ...optional,
          "model": model,
          "prompt": prompt,
        }),
      );
      if (genRes.statusCode != 200) {
        throw "${genRes.statusCode} ${genRes.body}";
      }

      _status = _Status.loading;

      final json = jsonDecode(genRes.body);
      final url = json["data"][0]["url"];

      final loadRes = await _client!.get(Uri.parse(url));
      if (loadRes.statusCode != 200) {
        throw "${genRes.statusCode} ${genRes.body}";
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final path = Config.imageFilePath("$timestamp.png");

      final file = File(path);
      await file.writeAsBytes(loadRes.bodyBytes);

      if (!mounted) return;
      setState(() => _images.add(path));
    } catch (e) {
      if (!mounted) return;
      if (_status.isGenerating) {
        Dialogs.error(context: context, error: e);
      }
    }

    if (!mounted) return;
    setState(() => _status = _Status.nothing);
  }
}
