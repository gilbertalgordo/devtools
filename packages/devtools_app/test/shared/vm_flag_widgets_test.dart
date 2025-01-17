// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:devtools_app/devtools_app.dart';
import 'package:devtools_app/src/service/service_registrations.dart'
    as registrations;
import 'package:devtools_app/src/service/vm_flags.dart' as vm_flags;
import 'package:devtools_app/src/shared/ui/drop_down_button.dart';
import 'package:devtools_app/src/shared/ui/vm_flag_widgets.dart';
import 'package:devtools_test/devtools_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:vm_service/vm_service.dart';

void main() {
  group('Profile Granularity Dropdown', () {
    late FakeServiceManager fakeServiceManager;
    late CpuSamplingRateDropdown dropdown;

    setUp(() async {
      fakeServiceManager = FakeServiceManager();
      setGlobal(
        DevToolsEnvironmentParameters,
        ExternalDevToolsEnvironmentParameters(),
      );
      setGlobal(ServiceConnectionManager, fakeServiceManager);
      setGlobal(IdeTheme, IdeTheme());
      setGlobal(NotificationService, NotificationService());
      setGlobal(BannerMessagesController, BannerMessagesController());
      await fakeServiceManager.flagsInitialized.future;
      dropdown = CpuSamplingRateDropdown(
        screenId: ProfilerScreen.id,
        profilePeriodFlagNotifier:
            fakeServiceManager.vmFlagManager.flag(vm_flags.profilePeriod)!,
      );
    });

    Future<void> pumpDropdown(WidgetTester tester) async {
      await tester.pumpWidget(wrap(dropdown));
    }

    testWidgets('displays with default content', (WidgetTester tester) async {
      await pumpDropdown(tester);
      expect(find.byWidget(dropdown), findsOneWidget);
      expect(
        find.byKey(CpuSamplingRateDropdown.dropdownKey),
        findsOneWidget,
      );
      expect(
        find.text(CpuSamplingRate.low.display, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text(CpuSamplingRate.medium.display, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text(CpuSamplingRate.high.display, skipOffstage: false),
        findsOneWidget,
      );
      final AnalyticsDropDownButton<String> dropdownButton =
          tester.widget(find.byKey(CpuSamplingRateDropdown.dropdownKey));
      expect(dropdownButton.value, equals(CpuSamplingRate.medium.value));
    });

    testWidgets('selection', (WidgetTester tester) async {
      await pumpDropdown(tester);
      expect(find.byWidget(dropdown), findsOneWidget);
      expect(
        find.text(CpuSamplingRate.low.display, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text(CpuSamplingRate.medium.display, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text(CpuSamplingRate.high.display, skipOffstage: false),
        findsOneWidget,
      );
      AnalyticsDropDownButton<String> dropdownButton =
          tester.widget(find.byKey(CpuSamplingRateDropdown.dropdownKey));
      expect(dropdownButton.value, equals(CpuSamplingRate.medium.value));

      var profilePeriodFlag =
          (await getProfileGranularityFlag(fakeServiceManager))!;
      expect(
        profilePeriodFlag.valueAsString,
        equals(CpuSamplingRate.medium.value),
      );

      // Switch to high granularity.
      await tester.tap(find.byKey(CpuSamplingRateDropdown.dropdownKey));
      await tester.pumpAndSettle(); // finish the menu animation
      await tester.tap(find.text(CpuSamplingRate.high.display).last);
      await tester.pumpAndSettle(); // finish the menu animation
      dropdownButton =
          tester.widget(find.byKey(CpuSamplingRateDropdown.dropdownKey));
      expect(dropdownButton.value, equals(CpuSamplingRate.high.value));

      profilePeriodFlag =
          (await getProfileGranularityFlag(fakeServiceManager))!;
      expect(profilePeriodFlag.name, equals(vm_flags.profilePeriod));
      expect(
        profilePeriodFlag.valueAsString,
        equals(CpuSamplingRate.high.value),
      );
      // Verify we are showing the high profile granularity warning.
      expect(
        bannerMessages.messagesForScreen(ProfilerScreen.id).value.length,
        equals(1),
      );

      // Switch to low granularity.
      await tester.tap(find.byKey(CpuSamplingRateDropdown.dropdownKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text(CpuSamplingRate.low.display).last);
      await tester.pumpAndSettle();
      dropdownButton =
          tester.widget(find.byKey(CpuSamplingRateDropdown.dropdownKey));
      expect(dropdownButton.value, equals(CpuSamplingRate.low.value));

      profilePeriodFlag =
          (await getProfileGranularityFlag(fakeServiceManager))!;
      expect(profilePeriodFlag.name, equals(vm_flags.profilePeriod));
      expect(
        profilePeriodFlag.valueAsString,
        equals(CpuSamplingRate.low.value),
      );
      // Verify we are not showing the high profile granularity warning.
      expect(
        bannerMessages.messagesForScreen(ProfilerScreen.id).value,
        isEmpty,
      );
    });

    void testUpdatesForFlagChange(
      WidgetTester tester, {
      required String newFlagValue,
      required String expectedFlagValue,
    }) async {
      await pumpDropdown(tester);
      expect(find.byWidget(dropdown), findsOneWidget);
      final dropdownButtonFinder =
          find.byKey(CpuSamplingRateDropdown.dropdownKey);
      AnalyticsDropDownButton<String> dropdownButton =
          tester.widget(dropdownButtonFinder);
      expect(dropdownButton.value, equals(CpuSamplingRate.medium.value));

      await serviceManager.service!.setFlag(
        vm_flags.profilePeriod,
        newFlagValue,
      );
      await tester.pumpAndSettle();
      dropdownButton = tester.widget(dropdownButtonFinder);
      expect(dropdownButton.value, equals(expectedFlagValue));
    }

    testWidgets(
      'updates value for safe flag change',
      (WidgetTester tester) async {
        testUpdatesForFlagChange(
          tester,
          newFlagValue: CpuSamplingRate.high.value,
          expectedFlagValue: CpuSamplingRate.high.value,
        );
      },
    );

    testWidgets(
      'updates value for unsafe flag change',
      (WidgetTester tester) async {
        // 999 is not a value in the dropdown list.
        testUpdatesForFlagChange(
          tester,
          newFlagValue: '999',
          expectedFlagValue: CpuSamplingRate.medium.value,
        );
      },
    );
  });

  group('VMFlagsDialog', () {
    late FakeServiceManager fakeServiceManager;

    void initServiceManager({
      bool flutterVersionServiceAvailable = true,
    }) {
      final availableServices = [
        if (flutterVersionServiceAvailable)
          registrations.flutterVersion.service,
      ];
      fakeServiceManager = FakeServiceManager(
        availableServices: availableServices,
      );
      when(fakeServiceManager.vm.version).thenReturn('1.9.1');
      final app = fakeServiceManager.connectedApp!;
      when(app.isDartWebAppNow).thenReturn(false);
      when(app.isRunningOnDartVM).thenReturn(true);
      setGlobal(ServiceConnectionManager, fakeServiceManager);
    }

    setUp(() {
      initServiceManager();
    });

    testWidgets('builds dialog', (WidgetTester tester) async {
      mockConnectedApp(
        fakeServiceManager.connectedApp!,
        isFlutterApp: true,
        isProfileBuild: false,
        isWebApp: false,
      );

      await tester.pumpWidget(wrap(const VMFlagsDialog()));
      expect(find.richText('VM Flags'), findsOneWidget);
      expect(find.richText('flag 1 name'), findsOneWidget);
      final RichText commentText = tester.firstWidget<RichText>(
        findSubstring('flag 1 comment'),
      );
      expect(commentText, isNotNull);
    });
  });
}

BannerMessagesController bannerMessagesController(BuildContext context) {
  return Provider.of<BannerMessagesController>(context, listen: false);
}

Future<Flag?> getProfileGranularityFlag(
  FakeServiceManager serviceManager,
) async {
  final flagList = (await serviceManager.service!.getFlagList()).flags!;
  return flagList.firstWhereOrNull(
    (flag) => flag.name == vm_flags.profilePeriod,
  );
}
