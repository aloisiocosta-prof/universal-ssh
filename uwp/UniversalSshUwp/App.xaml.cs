using Windows.ApplicationModel.Activation;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
namespace UniversalSshUwp {
 sealed partial class App : Application {
  public App() => InitializeComponent();
  protected override void OnLaunched(LaunchActivatedEventArgs e) {
   var frame = Window.Current.Content as Frame ?? new Frame();
   Window.Current.Content = frame;
   if (frame.Content == null) frame.Navigate(typeof(MainPage));
   Window.Current.Activate();
  }
 }
}
