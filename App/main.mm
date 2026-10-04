#import <UIKit/UIKit.h>
#import <MapLibreWithPlugins/MapLibreWithPlugins.h>
#include "ngon_layer.hpp"

@interface NgonViewController : UIViewController <MLNMapViewDelegate>
@property(nonatomic, strong) UILabel *registrationLabel;
@property(nonatomic, strong) UILabel *renderLabel;
@end

@implementation NgonViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    UILabel *title = [[UILabel alloc] init];
    title.text = @"MapLibre · ngon plugin";
    title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    self.registrationLabel = [[UILabel alloc] init];
    self.registrationLabel.accessibilityIdentifier = @"registration-status";
    self.renderLabel = [[UILabel alloc] init];
    self.renderLabel.accessibilityIdentifier = @"render-status";
    self.renderLabel.text = @"Waiting for map";
    self.renderLabel.numberOfLines = 0;
    UIStackView *heading = [[UIStackView alloc] initWithArrangedSubviews:@[
        title, self.registrationLabel, self.renderLabel
    ]];
    heading.axis = UILayoutConstraintAxisVertical;
    heading.spacing = 6;
    heading.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:heading];
    [NSLayoutConstraint activateConstraints:@[
        [heading.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16],
        [heading.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [heading.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
    ]];

    // Registration must happen before the first map/style is constructed.
    char error[1024] = {};
    mln_plugin_status status = mln_ngon_layer_register(&mln_plugin_register_v1, error, sizeof(error));
    if (status != MLN_PLUGIN_STATUS_OK) {
        self.registrationLabel.text = [NSString stringWithFormat:@"Registration failed (%d): %s", status, error];
        NSLog(@"%@", self.registrationLabel.text);
        return;
    }
    self.registrationLabel.text = @"Plugin registered";
    NSLog(@"ngon registered through MapLibreWithPlugins XCFramework");

    NSURL *styleURL = [NSBundle.mainBundle URLForResource:@"ngon" withExtension:@"json"];
    NSAssert(styleURL != nil, @"Missing bundled ngon style");
    MLNMapView *map = [[MLNMapView alloc] initWithFrame:self.view.bounds styleURL:styleURL];
    map.delegate = self;
    map.translatesAutoresizingMaskIntoConstraints = NO;
    [map setCenterCoordinate:CLLocationCoordinate2DMake(0, 0) zoomLevel:11 animated:NO];
    [self.view addSubview:map];
    [NSLayoutConstraint activateConstraints:@[
        [map.topAnchor constraintEqualToAnchor:heading.bottomAnchor constant:16],
        [map.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [map.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [map.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)mapViewDidFinishRenderingMap:(MLNMapView *)mapView fullyRendered:(BOOL)fullyRendered {
    if (fullyRendered) {
        self.renderLabel.text = @"Map rendered";
    }
}

- (void)mapViewDidFailLoadingMap:(MLNMapView *)mapView withError:(NSError *)error {
    self.renderLabel.text = [@"Map failed: " stringByAppendingString:error.localizedDescription];
    NSLog(@"%@", self.renderLabel.text);
}
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow *window;
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [[NgonViewController alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass(AppDelegate.class));
    }
}
