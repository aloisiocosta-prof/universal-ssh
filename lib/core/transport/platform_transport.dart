import '../ssh/ssh_contracts.dart';

enum SshRuntimePlatform { web, android, uwpWebView }

SshTransportCapabilities transportCapabilitiesFor(
        SshRuntimePlatform platform) =>
    switch (platform) {
      SshRuntimePlatform.web ||
      SshRuntimePlatform.uwpWebView =>
        const SshTransportCapabilities(
          rawTcp: false,
          requiresBridge: true,
        ),
      SshRuntimePlatform.android => const SshTransportCapabilities(
          rawTcp: true,
          requiresBridge: false,
        ),
    };
