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

import "../config.dart";
import "../chat/chat.dart";
import "../chat/current.dart";
import "../chat/message.dart";
import "../markdown/util.dart";

import "dart:io";
import "dart:convert";
import "package:http/http.dart";
import "package:langchain/langchain.dart";
import "package:audioplayers/audioplayers.dart";
import "package:langchain_openai/langchain_openai.dart";
import "package:langchain_google/langchain_google.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

final llmProvider =
    AutoDisposeNotifierProvider<LlmNotifier, void>(LlmNotifier.new);

class LlmNotifier extends AutoDisposeNotifier<void> {
  Client? _ttsClient;
  _Client? _chatClient;
  AudioPlayer? _player;
  static bool googleSearch = false;

  @override
  void build() {}
  void notify() => ref.notifyListeners();

  void updateMessage(Message message) =>
      ref.read(messageProvider(message).notifier).notify();

  Future<dynamic> tts(Message message) async {
    dynamic error;

    final tts = Config.tts;
    final model = tts.model!;
    final voice = tts.voice!;
    final api = Config.apis[tts.api]!;

    final apiUrl = api.url;
    final apiKey = api.key;
    final endPoint = "$apiUrl/audio/speech";

    Current.ttsStatus = TtsStatus.loading;
    updateMessage(message);

    try {
      _ttsClient ??= Client();
      _player ??= AudioPlayer();
      final response = await _ttsClient!.post(
        Uri.parse(endPoint),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": model,
          "voice": voice,
          "stream": false,
          "input": markdownToText(message.item.text),
        }),
      );

      if (response.statusCode != 200) {
        throw "${response.statusCode} ${response.body}";
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final path = Config.audioFilePath("$timestamp.mp3");

      final file = File(path);
      await file.writeAsBytes(response.bodyBytes);

      Current.ttsStatus = TtsStatus.playing;
      updateMessage(message);

      await _player!.play(DeviceFileSource(path));
      await _player!.onPlayerStateChanged.first;
    } catch (e) {
      if (!Current.ttsStatus.isNothing) error = e;
    }

    Current.ttsStatus = TtsStatus.nothing;
    updateMessage(message);
    return error;
  }

  void stopTts() {
    Current.ttsStatus = TtsStatus.nothing;
    _ttsClient?.close();
    _ttsClient = null;
    _player?.stop();
  }

  Future<dynamic> chat(Message message) async {
    dynamic error;

    final model = Current.model!;
    final apiUrl = Current.apiUrl!;
    final apiKey = Current.apiKey!;
    final apiType = Current.apiType;
    final messages = Current.messages;

    final item = message.item;
    final chatContext = _buildContext(messages);

    Current.chatStatus = ChatStatus.responding;
    updateMessage(message);
    notify();

    try {
      _chatClient ??= _Client();
      BaseChatModel llm = switch (apiType) {
        "google" => ChatGoogleGenerativeAI(
            apiKey: apiKey,
            baseUrl: apiUrl,
            client: _chatClient,
            defaultOptions: ChatGoogleGenerativeAIOptions(
              model: model,
              temperature: Current.temperature,
              maxOutputTokens: Current.maxTokens,
            ),
          ),
        _ => ChatOpenAI(
            apiKey: apiKey,
            baseUrl: apiUrl,
            client: _chatClient,
            defaultOptions: ChatOpenAIOptions(
              model: model,
              maxTokens: Current.maxTokens,
              temperature: Current.temperature,
            ),
          ),
      };

      if (Current.stream ?? true) {
        final stream = llm.stream(PromptValue.chat(chatContext));
        await for (final chunk in stream) {
          item.text += chunk.output.content;
          updateMessage(message);
        }
      } else {
        final result = await llm.invoke(PromptValue.chat(chatContext));
        item.text += result.output.content;
        updateMessage(message);
      }
    } catch (e) {
      if (!Current.chatStatus.isNothing) error = e;
      if (item.text.isEmpty) {
        if (message.list.length == 1) {
          messages.length -= 2;
          ref.read(messagesProvider.notifier).notify();
        } else {
          message.list.removeAt(message.index--);
          updateMessage(message);
        }
      }
    }

    Current.chatStatus = ChatStatus.nothing;
    updateMessage(message);
    notify();

    final isNewChat = !Current.hasFile;
    Current.save();

    if (isNewChat) {
      ref.read(chatsProvider.notifier).notify();
      ref.read(chatProvider.notifier).notify();
    }

    return error;
  }

  void stopChat() {
    Current.chatStatus = ChatStatus.nothing;
    _chatClient?.close();
    _chatClient = null;
  }
}

List<ChatMessage> _buildContext(List<Message> list) {
  final context = <ChatMessage>[];
  final items = [
    for (final message in list) message.item,
  ];
  if (items.last.role.isAssistant) items.removeLast();

  if (Current.systemPrompts != null) {
    context.add(ChatMessage.system(Current.systemPrompts!));
  }

  for (final item in items) {
    switch (item.role) {
      case MessageRole.assistant:
        context.add(ChatMessage.ai(item.text));
        break;

      case MessageRole.user:
        if (item.images.isEmpty) {
          context.add(ChatMessage.humanText(item.text));
        } else {
          context.add(ChatMessage.human(ChatMessageContent.multiModal([
            ChatMessageContent.text(item.text),
            for (final image in item.images)
              ChatMessageContent.image(
                mimeType: "image/jpeg",
                data: image.base64,
              ),
          ])));
        }
        break;
    }
  }

  return context;
}

class _Client extends BaseClient {
  final Client _inner = Client();

  void _handleBody(Request request) {
    final json = jsonDecode(request.body);
    if (LlmNotifier.googleSearch) {
      json["tools"] = [
        {"google_search": {}},
      ];
    }
    request.body = jsonEncode(json);
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    if (request is Request) _handleBody(request);
    return _inner.send(request);
  }

  @override
  void close() {
    super.close();
    _inner.close();
  }
}
