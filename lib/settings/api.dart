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

import "dart:convert";
import "package:http/http.dart";
import "package:flutter/material.dart";
import "package:animate_do/animate_do.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

final apisProvider =
    NotifierProvider.autoDispose<ApisNotifier, void>(ApisNotifier.new);

class ApisNotifier extends AutoDisposeNotifier<void> {
  @override
  void build() {}
  void notify() => ref.notifyListeners();
}

class ApisTab extends ConsumerWidget {
  const ApisTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(apisProvider);
    final apis = Config.apis.entries.toList();

    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.all(16),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemCount: apis.length,
          itemBuilder: (context, index) => Card.filled(
            margin: EdgeInsets.zero,
            child: ListTile(
              title: Text(
                apis[index].key,
                overflow: TextOverflow.ellipsis,
              ),
              leading: const Icon(Icons.api),
              contentPadding: const EdgeInsets.only(left: 16, right: 8),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ApiSettings(apiPair: apis[index]),
              )),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: "api",
            icon: const Icon(Icons.api),
            label: Text(S.of(context).new_api),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ApiSettings(),
            )),
          ),
        ),
      ],
    );
  }
}

class ApiSettings extends ConsumerStatefulWidget {
  final MapEntry<String, ApiConfig>? apiPair;

  const ApiSettings({
    super.key,
    this.apiPair,
  });

  @override
  ConsumerState<ApiSettings> createState() => _ApiSettingsState();
}

class _ApiSettingsState extends ConsumerState<ApiSettings> {
  String? _type;
  Client? _client;
  bool _isFetching = false;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _modelsCtrl;
  late final TextEditingController _apiUrlCtrl;
  late final TextEditingController _apiKeyCtrl;

  @override
  void initState() {
    super.initState();

    final apiPair = widget.apiPair;
    final api = apiPair?.value;
    final name = apiPair?.key;

    _type = api?.type;
    _nameCtrl = TextEditingController(text: name);
    _apiUrlCtrl = TextEditingController(text: api?.url);
    _apiKeyCtrl = TextEditingController(text: api?.key);
    _modelsCtrl = TextEditingController(text: api?.models.join(", "));
  }

  @override
  void dispose() {
    _modelsCtrl.dispose();
    _apiKeyCtrl.dispose();
    _apiUrlCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiPair = widget.apiPair;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).api),
      ),
      body: Container(
        padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 16),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _type,
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem(
                        value: "openai",
                        child: const Text("OpenAI"),
                      ),
                      DropdownMenuItem(
                        value: "google",
                        child: const Text("Google"),
                      ),
                    ],
                    isExpanded: true,
                    hint: Text(S.of(context).api_type),
                    onChanged: (it) => setState(() => _type = it),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: S.of(context).name,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiUrlCtrl,
              decoration: InputDecoration(
                labelText: S.of(context).api_url,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyCtrl,
              decoration: InputDecoration(
                labelText: S.of(context).api_key,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    maxLines: 4,
                    controller: _modelsCtrl,
                    decoration: InputDecoration(
                      labelText: S.of(context).model_list,
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Spin(
                      infinite: true,
                      animate: _isFetching,
                      duration: Duration(seconds: 1),
                      child: IconButton.outlined(
                        icon: const Icon(Icons.sync),
                        onPressed: _fetchModels,
                      ),
                    ),
                    const SizedBox(height: 16),
                    IconButton.outlined(
                      icon: const Icon(Icons.edit),
                      onPressed: _editModels,
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: FilledButton.tonal(
                    onPressed: Navigator.of(context).pop,
                    child: Text(S.of(context).cancel),
                  ),
                ),
                const SizedBox(width: 6),
                if (apiPair != null) ...[
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 1,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                      child: Text(S.of(context).delete),
                      onPressed: () {
                        Config.apis.remove(apiPair.key);
                        Config.save();

                        ref.read(apisProvider.notifier).notify();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                const SizedBox(width: 6),
                Expanded(
                  flex: 1,
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

  Future<void> _fetchModels() async {
    if (_isFetching) {
      _isFetching = false;
      _client?.close();
      _client = null;
      return;
    }

    final url = _apiUrlCtrl.text;
    final key = _apiKeyCtrl.text;
    final endPoint = switch (_type) {
      "google" => "$url/models?key=$key",
      _ => "$url/models",
    };

    if (url.isEmpty || key.isEmpty) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).complete_all_fields),
      );
      return;
    }

    setState(() => _isFetching = true);

    try {
      _client ??= Client();
      final response = await _client!.get(
        Uri.parse(endPoint),
        headers: switch (_type) {
          "google" => null,
          _ => {"Authorization": "Bearer $key"},
        },
      );

      if (response.statusCode != 200) {
        throw "${response.statusCode} ${response.body}";
      }

      final json = jsonDecode(response.body);
      List<String> models = switch (_type) {
        "google" => [
            for (final cell in json["models"]) cell["name"].substring(7),
          ],
        _ => [for (final cell in json["data"]) cell["id"]],
      };

      _modelsCtrl.text = models.join(", ");
    } catch (e) {
      if (_isFetching && mounted) {
        Dialogs.error(context: context, error: e);
      }
    }

    setState(() => _isFetching = false);
  }

  Future<void> _editModels() async {
    final text = _modelsCtrl.text;
    if (text.isEmpty) return;

    final models = text.split(',').map((it) => it.trim()).toList();
    final chosen = {for (final model in models) model: true};
    if (chosen.isEmpty) return;

    final result = await showModalBottomSheet<bool>(
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
                    S.of(context).select_models,
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
                itemCount: chosen.length,
                itemBuilder: (context, index) => CheckboxListTile(
                  title: Text(models[index]),
                  value: chosen[models[index]],
                  contentPadding: const EdgeInsets.only(left: 24, right: 16),
                  onChanged: (value) =>
                      setState(() => chosen[models[index]] = value ?? false),
                ),
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 24),
                    TextButton(
                      child: Text(S.of(context).clear),
                      onPressed: () => setState(
                          () => chosen.forEach((it, _) => chosen[it] = false)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: Navigator.of(context).pop,
                      child: Text(S.of(context).cancel),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      child: Text(S.of(context).ok),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (!(result ?? false)) return;

    _modelsCtrl.text = [
      for (final pair in chosen.entries)
        if (pair.value) pair.key
    ].join(", ");
  }

  void _save() {
    final name = _nameCtrl.text;
    final models = _modelsCtrl.text;
    final apiUrl = _apiUrlCtrl.text;
    final apiKey = _apiKeyCtrl.text;

    if (name.isEmpty || models.isEmpty || apiUrl.isEmpty || apiKey.isEmpty) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).complete_all_fields),
      );
      return;
    }

    final apiPair = widget.apiPair;
    if (Config.apis.containsKey(name) &&
        (apiPair == null || name != apiPair.key)) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).duplicate_api_name),
      );
      return;
    }

    if (apiPair != null) Config.apis.remove(apiPair.key);
    final modelList = models.split(',').map((e) => e.trim()).toList();

    Config.apis[name] = ApiConfig(
      url: apiUrl,
      key: apiKey,
      type: _type,
      models: modelList,
    );
    Config.save();

    ref.read(apisProvider.notifier).notify();
    Navigator.of(context).pop();
  }
}
