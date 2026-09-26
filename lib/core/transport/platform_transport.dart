import '../ssh/ssh_contracts.dart';

enum SshRuntimePlatform { web, android, uwp }

SshTransportCapabilities transportCapabilitiesFor(SshRuntimePlatform platform) =>
    switch (platform) {
      SshRuntimePlatform.web => const SshTransportCapabilities(
          rawTcp: false,
          requiresBridge: true,
        ),
      SshRuntimePlatform.android || SshRuntimePlatform.uwp =>
        const SshTransportCapabilities(
          rawTcp: true,
          requiresBridge: false,
        ),
    };
