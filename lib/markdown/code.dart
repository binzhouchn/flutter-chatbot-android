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

import "util.dart";
import "../util.dart";
import "../gen/l10n.dart";

import "package:flutter/material.dart";
import "package:markdown/markdown.dart" as md;
import "package:flutter_markdown/flutter_markdown.dart";
import "package:flutter_highlighter/flutter_highlighter.dart";

class CodeBlockBuilder extends MarkdownElementBuilder {
  var language = "";
  final BuildContext context;

  CodeBlockBuilder({required this.context});

  @override
  void visitElementBefore(md.Element element) {
    final code = element.children?.first;
    if (code is md.Element) {
      final lang = code.attributes["class"];
      if (lang != null) language = lang.substring(9);
    }
    super.visitElementBefore(element);
  }

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = switch (colorScheme.brightness) {
      Brightness.light => codeLightTheme,
      Brightness.dark => codeDarkTheme,
    };
    final content = text.textContent.trim();

    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme == codeDarkTheme
                  ? Colors.black.withOpacity(0.3)
                  : Colors.blueGrey.withOpacity(0.3),
            ),
            padding: EdgeInsets.only(left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(language),
                InkWell(
                  onTap: () => Util.copyText(
                    context: context,
                    text: content,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      S.of(context).copy,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: HighlightView(
              content,
              tabSize: 2,
              theme: theme,
              language: language,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }
}

class CodeBlockBuilder2 extends MarkdownElementBuilder {
  var language = "";
  final BuildContext context;

  CodeBlockBuilder2({required this.context});

  @override
  void visitElementBefore(md.Element element) {
    final code = element.children?.first;
    if (code is md.Element) {
      final lang = code.attributes["class"];
      if (lang != null) language = lang.substring(9);
    }
    super.visitElementBefore(element);
  }

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = switch (colorScheme.brightness) {
      Brightness.light => codeLightTheme,
      Brightness.dark => codeDarkTheme,
    };
    final content = text.textContent.trim();

    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme == codeDarkTheme
                  ? Colors.black.withOpacity(0.3)
                  : Colors.blueGrey.withOpacity(0.3),
            ),
            padding: EdgeInsets.only(left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(language),
                InkWell(
                  onTap: () => Util.copyText(
                    context: context,
                    text: content,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      S.current.copy,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
          HighlightView(
            content,
            tabSize: 2,
            theme: theme,
            language: language,
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }
}
