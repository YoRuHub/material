import 'package:flutter_highlighting/themes/dracula.dart';
import 'package:flutter_highlighting/themes/atom-one-dark-reasonable.dart';
import 'package:flutter_highlighting/themes/atom-one-dark.dart';
import 'package:flutter_highlighting/themes/atom-one-light.dart';
import 'package:flutter_highlighting/themes/github-dark-dimmed.dart';

enum EditorTheme {
  dracula,
  atomOneDarkReasonable,
  atomOneDark,
  atomOneLight,
  githubDarkDimmed
}

const themes = {
  EditorTheme.dracula: draculaTheme,
  EditorTheme.atomOneDarkReasonable: atomOneDarkReasonableTheme,
  EditorTheme.atomOneDark: atomOneDarkTheme,
  EditorTheme.atomOneLight: atomOneLightTheme,
  EditorTheme.githubDarkDimmed: githubDarkDimmedTheme
};
