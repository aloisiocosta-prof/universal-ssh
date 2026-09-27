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
            _bridgeHost = BridgeHostController.ForSocket(new WinRtBridgeSocket());
            FlutterView.Navigate(new Uri("ms-appx-web:///Web/index.html"));
        }

        private async void OnScriptNotify(object sender, NotifyEventArgs e)
        {
            await _bridgeHost.ReceiveAsync(e.Value);
        }

    }
}
