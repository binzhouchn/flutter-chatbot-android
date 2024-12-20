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

import "config.dart";
import "../gen/l10n.dart";

import "dart:io";
import "package:flutter/services.dart";
import "package:flutter/material.dart";
import "package:share_plus/share_plus.dart";
import "package:url_launcher/url_launcher.dart";
import "package:image_gallery_saver_plus/image_gallery_saver_plus.dart";

class Util {
  static Future<void> copyText({
    required BuildContext context,
    required String text,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    Util.showSnackBar(
      context: context,
      content: Text(S.of(context).copied_successfully),
    );
  }

  static Future<void> checkUpdate({
    required BuildContext context,
    required bool notify,
  }) async {
    try {
      final info = await Updater.check();
      if (!context.mounted) return;

      if (info == null) {
        if (notify) {
          showSnackBar(
            context: context,
            content: Text(S.of(context).up_to_date),
          );
        }
        return;
      }

      String changeLog = info["body"];
      String newVersion = info["tag_name"];
      String apkUrl = info["assets"][0]["browser_download_url"];
      final url = Platform.isAndroid ? apkUrl : Updater.latestUrl;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(newVersion),
          content: Text(changeLog),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              child: Text(S.of(context).download),
              onPressed: () {
                launchUrl(Uri.parse(url));
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    } catch (e) {
      if (notify) Dialogs.error(context: context, error: e);
    }
  }

  static void showSnackBar({
    required Text content,
    required BuildContext context,
    Duration duration = const Duration(milliseconds: 800),
    SnackBarBehavior behavior = SnackBarBehavior.floating,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: content,
        duration: duration,
        behavior: behavior,
        dismissDirection: DismissDirection.down,
      ),
    );
  }

  static String formatDateTime(DateTime time) {
    return "${_keepTwo(time.month)}-${_keepTwo(time.day)} "
        "${_keepTwo(time.hour)}:${_keepTwo(time.minute)}";
  }

  static String _keepTwo(int n) => n.toString().padLeft(2, '0');
}

class Widgets {
  static Widget modelAvatar(String? id) {
    final config = Config.models[id];
    final path = config?.avatar;

    Icon? child;
    Color? color;
    FileImage? image;

    if (path != null) {
      color = Colors.transparent;
      image = FileImage(
        File(Config.avatarFilePath(path)),
      );
    } else {
      child = const Icon(Icons.smart_toy);
    }

    return CircleAvatar(
      key: ValueKey<String?>(path),
      backgroundColor: color,
      backgroundImage: image,
      child: child,
    );
  }
}

class Dialogs {
  static Future<List<String>?> input({
    required BuildContext context,
    required String title,
    required List<InputDialogField> fields,
  }) async {
    return await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: InputDialog(
            title: title,
            fields: fields,
          ),
        ),
      ),
    );
  }

  static void error({
    required BuildContext context,
    required dynamic error,
  }) {
    final info = error.toString();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).error),
        content: Text(info),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              Util.copyText(context: context, text: info);
              Navigator.of(context).pop();
            },
            child: Text(S.of(context).copy),
          ),
        ],
      ),
    );
  }

  static Future<String?> select({
    required BuildContext context,
    required List<String> list,
    required String title,
    String? selected,
  }) async {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  top: 16, left: 24, right: 12, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: Navigator.of(context).pop,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: list.length,
                itemBuilder: (context, index) => RadioListTile(
                  value: list[index],
                  groupValue: selected,
                  title: Text(list[index]),
                  contentPadding: const EdgeInsets.only(left: 16, right: 24),
                  onChanged: (value) => setState(() => selected = value),
                ),
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: Navigator.of(context).pop,
                  child: Text(S.of(context).cancel),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(selected),
                  child: Text(S.of(context).ok),
                ),
                const SizedBox(width: 24),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static void loading({
    required BuildContext context,
    required String hint,
    bool canPop = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: canPop,
      builder: (context) => PopScope(
        canPop: canPop,
        child: Dialog(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 24),
                Text(hint),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> openLink({
    required BuildContext context,
    required String? link,
  }) async {
    if (link == null) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).empty_link),
      );
      return;
    }

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).link),
        content: Text(link),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(1),
            child: Text(S.of(context).copy),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(2),
            child: Text(S.of(context).open),
          ),
        ],
      ),
    );

    switch (result) {
      case 1:
        if (!context.mounted) return;
        Util.copyText(context: context, text: link);
        break;

      case 2:
        final uri = Uri.parse(link);
        if (await canLaunchUrl(uri)) {
          launchUrl(uri, mode: LaunchMode.platformDefault);
        } else {
          if (!context.mounted) return;
          Util.showSnackBar(
            context: context,
            content: Text(S.of(context).cannot_open),
          );
        }
        break;
    }
  }

  static Future<void> handleImage({
    required BuildContext context,
    required String path,
  }) async {
    final action = await showModalBottomSheet<int>(
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
              shape: StadiumBorder(),
              title: Text(S.of(context).share),
              onTap: () => Navigator.pop(context, 1),
              leading: const Icon(Icons.share_outlined),
            ),
            ListTile(
              minTileHeight: 48,
              shape: StadiumBorder(),
              title: Text(S.of(context).save),
              onTap: () => Navigator.pop(context, 2),
              leading: const Icon(Icons.save_outlined),
            ),
          ],
        ),
      ),
    );
    if (action == null) return;

    if (!Platform.isAndroid) {
      final uri = Uri.file(path);
      launchUrl(uri);
      return;
    }

    switch (action) {
      case 1:
        Share.shareXFiles([XFile(path)]);
        break;

      case 2:
        final result = await ImageGallerySaverPlus.saveFile(path);
        if (!context.mounted) return;
        if (result is Map && result["isSuccess"] == true) {
          Util.showSnackBar(
            context: context,
            content: Text(S.of(context).saved_successfully),
          );
        }
        break;
    }
  }
}

typedef InputDialogField = ({String? hint, String? text});

class InputDialog extends StatefulWidget {
  final String title;
  final List<InputDialogField> fields;

  const InputDialog({
    required this.title,
    required this.fields,
    super.key,
  });

  @override
  State<InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  late final List<TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = [
      for (final field in widget.fields)
        TextEditingController(text: field.text),
    ];
  }

  @override
  void dispose() {
    for (final ctrl in _ctrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(top: 16, left: 24, right: 12, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: Navigator.of(context).pop,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < _ctrls.length; i++) ...[
                SizedBox(height: i == 0 ? 0 : 8),
                TextField(
                  controller: _ctrls[i],
                  decoration: InputDecoration(
                    labelText: widget.fields[i].hint,
                    border: const UnderlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: Text(S.of(context).cancel),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(<String>[
                for (final ctrl in _ctrls) ctrl.text,
              ]),
              child: Text(S.of(context).ok),
            ),
            const SizedBox(width: 24),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
