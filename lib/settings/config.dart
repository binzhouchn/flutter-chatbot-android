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

import "bot.dart";
import "api.dart";
import "../util.dart";
import "../config.dart";
import "../gen/l10n.dart";
import "../chat/chat.dart";

import "dart:io";
import "package:flutter/services.dart";
import "package:flutter/material.dart";
import "package:file_picker/file_picker.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

class ConfigTab extends ConsumerStatefulWidget {
  const ConfigTab({super.key});

  @override
  ConsumerState<ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends ConsumerState<ConfigTab> {
  @override
  Widget build(BuildContext context) {
    ref.watch(botsProvider);
    ref.watch(apisProvider);

    final s = S.of(context);
    const padding = EdgeInsets.only(left: 24, right: 24);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ListView(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: padding,
          child: Text(
            s.default_config,
            style: TextStyle(color: primaryColor),
          ),
        ),
        ListTile(
          title: Text(s.bot),
          contentPadding: padding,
          subtitle: Text(Config.core.bot ?? s.empty),
          onTap: () async {
            if (Config.bots.isEmpty) return;

            final bot = await Dialogs.select(
              context: context,
              list: Config.bots.keys.toList(),
              selected: Config.core.bot,
              title: s.choose_bot,
            );
            if (bot == null) return;

            setState(() => Config.core.bot = bot);
            Config.save();
          },
        ),
        const Divider(height: 1),
        ListTile(
          title: Text(s.api),
          contentPadding: padding,
          subtitle: Text(Config.core.api ?? s.empty),
          onTap: () async {
            if (Config.apis.isEmpty) return;

            final api = await Dialogs.select(
              context: context,
              list: Config.apis.keys.toList(),
              selected: Config.core.api,
              title: s.choose_api,
            );
            if (api == null) return;

            setState(() => Config.core.api = api);
            ref.read(chatProvider.notifier).notify();
            Config.save();
          },
        ),
        const Divider(height: 1),
        ListTile(
          title: Text(s.model),
          contentPadding: padding,
          subtitle: Text(Config.core.model ?? s.empty),
          onTap: () async {
            final models = Config.apis[Config.core.api]?.models;
            if (models == null) return;

            final model = await Dialogs.select(
              context: context,
              selected: Config.core.model,
              title: s.choose_model,
              list: models,
            );
            if (model == null) return;

            setState(() => Config.core.model = model);
            ref.read(chatProvider.notifier).notify();
            Config.save();
          },
        ),
        const SizedBox(height: 8),
        Padding(
          padding: padding,
          child: Text(
            s.text_to_speech,
            style: TextStyle(color: primaryColor),
          ),
        ),
        ListTile(
          title: Text(s.api),
          contentPadding: padding,
          subtitle: Text(Config.tts.api ?? s.empty),
          onTap: () async {
            if (Config.apis.isEmpty) return;

            final api = await Dialogs.select(
              context: context,
              list: Config.apis.keys.toList(),
              selected: Config.tts.api,
              title: s.choose_api,
            );
            if (api == null) return;

            setState(() => Config.tts.api = api);
            Config.save();
          },
        ),
        const Divider(height: 1),
        ListTile(
          title: Text(s.model),
          contentPadding: padding,
          subtitle: Text(Config.tts.model ?? s.empty),
          onTap: () async {
            final models = Config.apis[Config.tts.api]?.models;
            if (models == null) return;

            final model = await Dialogs.select(
              context: context,
              selected: Config.tts.model,
              title: s.choose_model,
              list: models,
            );
            if (model == null) return;

            setState(() => Config.tts.model = model);
            Config.save();
          },
        ),
        const Divider(height: 1),
        ListTile(
          title: Text(s.voice),
          contentPadding: padding,
          subtitle: Text(Config.tts.voice ?? s.empty),
          onTap: () async {
            final texts = await Dialogs.input(
              context: context,
              title: s.voice,
              fields: <InputDialogField>[
                (hint: s.please_input, text: Config.tts.voice)
              ],
            );
            if (texts == null) return;

            String? voice;
            final text = texts[0].trim();
            if (text.isNotEmpty) voice = text;

            setState(() => Config.tts.voice = voice);
            Config.save();
          },
        ),
        const SizedBox(height: 8),
        Padding(
          padding: padding,
          child: Text(
            s.chat_image_compress,
            style: TextStyle(color: primaryColor),
          ),
        ),
        CheckboxListTile(
          title: Text(s.enable),
          contentPadding: const EdgeInsets.only(left: 24, right: 16),
          value: Config.cic.enable ?? true,
          subtitle: Text(s.image_enable_hint),
          onChanged: (value) async {
            setState(() => Config.cic.enable = value);
            Config.save();
          },
        ),
        const Divider(height: 1),
        ListTile(
          title: Text(s.quality),
          contentPadding: padding,
          subtitle: Text(Config.cic.quality?.toString() ?? s.empty),
          onTap: () async {
            final texts = await Dialogs.input(
              context: context,
              title: s.quality,
              fields: <InputDialogField>[
                (hint: s.please_input, text: Config.cic.quality?.toString()),
              ],
            );
            if (texts == null) return;

            int? quality;
            final text = texts[0].trim();
            if (text.isNotEmpty) {
              quality = int.tryParse(text);
              if (quality == null) return;
            }

            setState(() => Config.cic.quality = quality);
            Config.save();
          },
        ),
        const Divider(height: 1),
        ListTile(
          title: Text(s.min_width_height),
          contentPadding: padding,
          subtitle: Text(
            "${Config.cic.minWidth ?? s.empty} x "
            "${Config.cic.minHeight ?? s.empty}",
          ),
          onTap: () async {
            final texts = await Dialogs.input(
              context: context,
              title: s.min_width_height,
              fields: <InputDialogField>[
                (hint: s.min_width, text: Config.cic.minWidth?.toString()),
                (hint: s.min_height, text: Config.cic.minHeight?.toString()),
              ],
            );
            if (texts == null) return;

            int? minWidth;
            int? minHeight;
            final text1 = texts[0].trim();
            final text2 = texts[1].trim();
            if (text1.isNotEmpty) {
              minWidth = int.tryParse(text1);
              if (minWidth == null) return;
            }
            if (text2.isNotEmpty) {
              minHeight = int.tryParse(text2);
              if (minHeight == null) return;
            }

            setState(() {
              Config.cic.minWidth = minWidth;
              Config.cic.minHeight = minHeight;
            });
            Config.save();
          },
        ),
        Card.outlined(
          margin: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 8),
          child: Padding(
            padding:
                const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.info_outlined,
                  color: primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.image_hint,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: padding,
          child: Text(
            s.config_import_export,
            style: TextStyle(color: primaryColor),
          ),
        ),
        ListTile(
          title: Text(s.import_config),
          contentPadding: padding,
          onTap: () async {
            try {
              final result = await FilePicker.platform.pickFiles();
              if (result == null || !context.mounted) return;

              Dialogs.loading(context: context, hint: s.importing);
              final from = result.files.single.path!;
              await Backup.importConfig(from);

              if (!context.mounted) return;
              Navigator.of(context).pop();
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(s.imported_successfully),
                  content: Text(s.restart_app),
                  actions: [
                    TextButton(
                      onPressed: Navigator.of(context).pop,
                      child: Text(s.ok),
                    )
                  ],
                ),
              );

              SystemNavigator.pop();
            } catch (e) {
              if (!context.mounted) return;
              Navigator.of(context).pop();
              Dialogs.error(context: context, error: e);
            }
          },
        ),
        const Divider(height: 1),
        ListTile(
          title: Text(s.export_config),
          contentPadding: padding,
          onTap: () async {
            try {
              final to = await FilePicker.platform.getDirectoryPath();
              if (to == null || !context.mounted) return;

              Dialogs.loading(context: context, hint: s.exporting);
              await Backup.exportConfig(to);

              if (!context.mounted) return;
              Navigator.of(context).pop();
              Util.showSnackBar(
                context: context,
                content: Text(s.exported_successfully),
              );
            } on PathAccessException {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(s.error),
                  content: Text(s.failed_to_export),
                  actions: [
                    TextButton(
                      child: Text(s.ok),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            } catch (e) {
              Navigator.of(context).pop();
              Dialogs.error(context: context, error: e);
            }
          },
        ),
        Card.outlined(
          margin:
              const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 16),
          child: Padding(
            padding:
                const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.info_outlined,
                  color: primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.config_hint,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: padding,
          child: Text(
            S.of(context).other,
            style: TextStyle(color: primaryColor),
          ),
        ),
        ListTile(
          title: Text(S.of(context).check_for_updates),
          onTap: () => Util.checkUpdate(
            context: context,
            notify: true,
          ),
          contentPadding: padding,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
