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

import "chat.dart";
import "current.dart";
import "../util.dart";
import "../config.dart";
import "../gen/l10n.dart";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

class ChatSettings extends ConsumerStatefulWidget {
  const ChatSettings({super.key});

  @override
  ConsumerState<ChatSettings> createState() => _ChatSettingsState();
}

class _ChatSettingsState extends ConsumerState<ChatSettings> {
  String? _bot = Current.bot;
  String? _api = Current.api;
  String? _model = Current.model;
  final TextEditingController _titleCtrl =
      TextEditingController(text: Current.title);

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final botList = <DropdownMenuItem<String>>[];
    final apiList = <DropdownMenuItem<String>>[];
    final modelList = <DropdownMenuItem<String>>[];

    final bots = Config.bots.keys;
    final apis = Config.apis.keys;
    final models = Config.apis[_api]?.models ?? [];

    for (final bot in bots) {
      botList.add(DropdownMenuItem(
        value: bot,
        child: Text(bot, overflow: TextOverflow.ellipsis),
      ));
    }

    for (final api in apis) {
      apiList.add(DropdownMenuItem(
        value: api,
        child: Text(api, overflow: TextOverflow.ellipsis),
      ));
    }

    for (final model in models) {
      final config = Config.models[model];
      if (!(config?.chat ?? true)) continue;
      modelList.add(DropdownMenuItem(
        value: model,
        child: Text(model, overflow: TextOverflow.ellipsis),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).chat_settings),
      ),
      body: Container(
        padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 16),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: S.of(context).chat_title,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _bot,
                    items: botList,
                    isExpanded: true,
                    hint: Text(S.of(context).bot),
                    onChanged: (it) => setState(() => _bot = it),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _api,
                    items: apiList,
                    isExpanded: true,
                    hint: Text(S.of(context).api),
                    onChanged: (it) => setState(() {
                      _model = null;
                      _api = it;
                    }),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _model,
              items: modelList,
              isExpanded: true,
              menuMaxHeight: 480,
              hint: Text(S.of(context).model),
              onChanged: (it) => setState(() => _model = it),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    child: Text(S.of(context).reset),
                    onPressed: () => setState(() {
                      _model = null;
                      _api = null;
                      _bot = null;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(S.of(context).save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final title = _titleCtrl.text;
    final oldModel = Current.model;
    final oldTitle = Current.title;

    if (title.isEmpty && Current.hasChat) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).enter_a_title),
      );
      return;
    }

    if (Current.hasChat) {
      Current.chat!.title = title;
    } else if (title.isNotEmpty) {
      Current.initChat(title);
    }

    Current.core = CoreConfig(
      bot: _bot,
      api: _api,
      model: _model,
    );
    Current.save();

    if (title != oldTitle && Current.hasFile) {
      ref.read(chatsProvider.notifier).notify();
    }
    if (title != oldTitle || _model != oldModel) {
      ref.read(chatProvider.notifier).notify();
    }
    if (mounted) Navigator.of(context).pop();
  }
}
