using System;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;

namespace UniversalSshUwp
{
    public sealed partial class MainPage : Page
    {
        private readonly BridgeHostController _bridgeHost;
        private readonly BridgeEventEmitter _bridgeEvents;

        public MainPage()
        {
            InitializeComponent();
            Application.Current.RequiresPointerMode = ApplicationRequiresPointerMode.WhenRequested;
            _bridgeHost = BridgeHostController.ForSocket(new WinRtBridgeSocket());
            _bridgeEvents = new BridgeEventEmitter(EmitBridgeEventJsonAsync);
            FlutterView.Navigate(new Uri("ms-appx-web:///Web/index.html"));
        }

        private async System.Threading.Tasks.Task EmitBridgeEventJsonAsync(string json)
        {
            await FlutterView.InvokeScriptAsync("universalSshBridgeEvent", new[] { json });
        }

        private async void OnScriptNotify(object sender, NotifyEventArgs e)
        {
            await _bridgeHost.ReceiveAsync(e.Value);
        }

    }
}
