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

import "message.dart";
import "../util.dart";
import "../config.dart";

import "dart:io";
import "dart:isolate";
import "dart:convert";

class Current {
  static File? file;
  static ChatConfig? chat;

  static CoreConfig core = Config.core;
  static final List<Message> messages = [];
  static TtsStatus ttsStatus = TtsStatus.nothing;
  static ChatStatus chatStatus = ChatStatus.nothing;

  static void clear() {
    chat = null;
    file = null;
    messages.clear();
    core = Config.core;
  }

  static Future<void> load(ChatConfig chat) async {
    file = File(Config.chatFilePath(chat.fileName));
    final from = file;

    final json = await Isolate.run(() async {
      return jsonDecode(await from!.readAsString());
    });

    final messagesJson = json["messages"] ?? [];
    final coreJson = json["core"];

    messages.clear();
    for (final message in messagesJson) {
      messages.add(Message.fromJson(message));
    }

    core = coreJson != null ? CoreConfig.fromJson(coreJson) : Config.core;
  }

  static Future<void> save() async {
    if (chat == null) {
      if (messages.isEmpty) return;
      initChat(messages.first.item.text);
    }

    if (file == null) {
      Config.chats.insert(0, chat!);
      Config.save();
      initFile();
    }

    await file!.writeAsString(jsonEncode({
      "core": core,
      "messages": messages,
    }));
  }

  static void initChat(String title) {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString();

    final time = Util.formatDateTime(now);
    final fileName = "$timestamp.json";

    chat = ChatConfig(
      time: time,
      title: title,
      fileName: fileName,
    );
  }

  static void initFile() {
    file = File(Config.chatFilePath(chat!.fileName));
  }

  static bool get hasChat => chat != null;
  static bool get hasFile => file != null;

  static String? get bot => core.bot;
  static String? get api => core.api;
  static String? get model => core.model;

  static String? get apiUrl => Config.apis[api]?.url;
  static String? get apiKey => Config.apis[api]?.key;
  static String? get apiType => Config.apis[api]?.type;
  static BotConfig? get _bot => Config.bots[core.bot];

  static String? get title => chat?.title;
  static bool? get stream => _bot?.stream;
  static int? get maxTokens => _bot?.maxTokens;
  static double? get temperature => _bot?.temperature;
  static String? get systemPrompts => _bot?.systemPrompts;

  static bool get isOkToChat => api != null && model != null;
}

enum TtsStatus {
  nothing,
  loading,
  playing;

  bool get isNothing => this == TtsStatus.nothing;
  bool get isLoading => this == TtsStatus.loading;
  bool get isPlaying => this == TtsStatus.playing;
}

enum ChatStatus {
  nothing,
  responding;

  bool get isNothing => this == ChatStatus.nothing;
  bool get isResponding => this == ChatStatus.responding;
}
