// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:vm_service/vm_service.dart';

import 'analytics/constants.dart' as gac;
import 'common_widgets.dart';
import 'globals.dart';
import 'primitives/utils.dart';
import 'routing.dart';
import 'theme.dart';
import 'ui/utils.dart';
import 'utils.dart';

class ConnectedAppSummary extends StatelessWidget {
  const ConnectedAppSummary({super.key, this.narrowView = true});

  final bool narrowView;

  @override
  Widget build(BuildContext context) {
    final VM? vm = serviceManager.vm;
    final connectedApp = serviceManager.connectedApp;
    if (vm == null ||
        connectedApp == null ||
        !serviceManager.connectedAppInitialized) return const SizedBox();

    final connectionDescriptionEntries =
        generateDeviceDescription(vm, connectedApp);

    // Ensure the screen is large enough to render two columns, even if
    // [narrowView] is false.
    final forceNarrowView = ScreenSize(context).width < MediaSize.m;
    if (narrowView || forceNarrowView) {
      return _ConnectionDescriptionColumn(
        entries: connectionDescriptionEntries,
      );
    }

    final midPoint = connectionDescriptionEntries.length ~/ 2;
    final h1 = connectionDescriptionEntries.sublist(0, midPoint);
    final h2 = connectionDescriptionEntries.sublist(midPoint);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ConnectionDescriptionColumn(entries: h1),
        const SizedBox(width: defaultSpacing),
        _ConnectionDescriptionColumn(entries: h2),
      ],
    );
  }
}

class _ConnectionDescriptionColumn extends StatelessWidget {
  const _ConnectionDescriptionColumn({required this.entries});

  final List<ConnectionDescription> entries;

  @override
  Widget build(BuildContext context) {
    const boldText = TextStyle(fontWeight: FontWeight.bold);
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var entry in entries)
          Padding(
            padding: EdgeInsets.only(
              bottom: entry == entries.last ? 0.0 : denseRowSpacing,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${entry.title}: ', style: boldText),
                SelectableText(
                  entry.description,
                  style: theme.subtleTextStyle,
                ),
                if (entry.actions.isNotEmpty) ...entry.actions,
              ],
            ),
          ),
      ],
    );
  }
}

class ConnectToNewAppButton extends StatelessWidget {
  const ConnectToNewAppButton({
    super.key,
    required this.gaScreen,
    this.elevated = false,
    this.minScreenWidthForTextBeforeScaling,
  });

  final String gaScreen;

  final bool elevated;

  final double? minScreenWidthForTextBeforeScaling;

  @override
  Widget build(BuildContext context) {
    return DevToolsButton(
      elevatedButton: elevated,
      label: connectToNewAppText,
      icon: Icons.device_hub_rounded,
      gaScreen: gaScreen,
      gaSelection: gac.HomeScreenEvents.connectToNewApp.name,
      minScreenWidthForTextBeforeScaling: minScreenWidthForTextBeforeScaling,
      onPressed: () {
        DevToolsRouterDelegate.of(context).navigateHome(
          clearUriParam: true,
          clearScreenParam: true,
        );
        Navigator.of(context, rootNavigator: true).pop('dialog');
      },
    );
  }
}
