using System;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
namespace UniversalSshUwp {
 public sealed partial class MainPage : Page {
  public MainPage() {
   InitializeComponent();
   Application.Current.RequiresPointerMode = ApplicationRequiresPointerMode.WhenRequested;
   FlutterView.Navigate(new Uri("ms-appx-web:///Web/index.html"));
  }
  private async void OnScriptNotify(object sender, NotifyEventArgs e) {
   var escaped = e.Value.Replace("\\", "\\\\").Replace("'", "\\'");
   await FlutterView.InvokeScriptAsync("eval", new[] { $"window.universalSshNativeReceive?.('{escaped}')" });
  }
 }
}
