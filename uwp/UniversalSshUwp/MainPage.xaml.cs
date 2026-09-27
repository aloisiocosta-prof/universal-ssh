using System;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;

namespace UniversalSshUwp
{
    public sealed partial class MainPage : Page
    {
        private readonly BridgeHostController _bridgeHost;

        public MainPage()
        {
            InitializeComponent();
            Application.Current.RequiresPointerMode = ApplicationRequiresPointerMode.WhenRequested;
            _bridgeHost = new BridgeHostController(
                new BridgeCommandDispatcher(OnBridgeCommand));
            FlutterView.Navigate(new Uri("ms-appx-web:///Web/index.html"));
        }

        private void OnScriptNotify(object sender, NotifyEventArgs e)
        {
            _bridgeHost.Receive(e.Value);
        }

        private static void OnBridgeCommand(BridgeCommand command)
        {
            _ = command;
        }
    }
}
