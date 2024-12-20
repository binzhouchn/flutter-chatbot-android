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

import "latex.dart";

import "package:markdown/markdown.dart";
import "package:flutter/material.dart" hide Text, Element;
import "package:flutter_highlighter/themes/atom-one-dark.dart";
import "package:flutter_highlighter/themes/atom-one-light.dart";

final mdExtensionSet = ExtensionSet(
  <BlockSyntax>[
    LatexBlockSyntax(),
    const TableSyntax(),
    const FootnoteDefSyntax(),
    const FencedCodeBlockSyntax(),
    const OrderedListWithCheckboxSyntax(),
    const UnorderedListWithCheckboxSyntax(),
  ],
  <InlineSyntax>[
    InlineHtmlSyntax(),
    LatexInlineSyntax(),
    StrikethroughSyntax(),
    AutolinkExtensionSyntax()
  ],
);

final codeDarkTheme = Map.of(atomOneDarkTheme)
  ..["root"] = TextStyle(
      color: Colors.white.withOpacity(0.7),
      backgroundColor: Colors.transparent);

final codeLightTheme = Map.of(atomOneLightTheme)
  ..["root"] = TextStyle(
      color: Colors.black.withOpacity(0.7),
      backgroundColor: Colors.transparent);

String markdownToText(String markdown) {
  final doc = Document(
    extensionSet: mdExtensionSet,
  );
  final buff = StringBuffer();
  final nodes = doc.parse(markdown);

  for (final node in nodes) {
    if (node is Element) {
      buff.write(_elementToText(node));
    }
  }

  return buff.toString().trim();
}

String _elementToText(Element element) {
  final buff = StringBuffer();
  final nodes = element.children ?? [];

  if (element.tag == "ul") {
    for (final node in nodes) {
      if (node is Element && node.tag == "li") {
        buff.write(_elementToText(node));
      }
    }
  } else if (element.tag == "ol") {
    int index = 1;
    for (final node in nodes) {
      if (node is Element && node.tag == "li") {
        buff.write("${index++}. ${_elementToText(node)}");
      }
    }
  } else {
    for (final node in nodes) {
      if (node is Text) {
        buff.write(node.text);
      } else if (node is Element) {
        final tag = node.tag;
        if (tag == "code") continue;
        if (tag == "latex") continue;
        if (tag == "th" || tag == "td") continue;
        buff.write(_elementToText(node));
      }
      buff.write("\n");
    }
  }

  return buff.toString();
}
