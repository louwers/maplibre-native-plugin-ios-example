#import <UIKit/UIKit.h>
#import <MapLibreWithPlugins/MapLibreWithPlugins.h>
#include "ngon_layer.hpp"

@interface NgonViewController : UIViewController <MLNMapViewDelegate>
@end

@implementation NgonViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    // Registration must happen before the first map/style is constructed.
    char error[1024] = {};
    mln_plugin_status status = mln_ngon_layer_register(&mln_plugin_register_v1, error, sizeof(error));
    if (status != MLN_PLUGIN_STATUS_OK) {
        NSLog(@"ngon registration failed (%d): %s", status, error);
        return;
    }
    NSLog(@"ngon registered through MapLibreWithPlugins XCFramework");

    NSURL *styleURL = [NSBundle.mainBundle URLForResource:@"ngon" withExtension:@"json"];
    NSAssert(styleURL != nil, @"Missing bundled ngon style");
    MLNMapView *map = [[MLNMapView alloc] initWithFrame:self.view.bounds styleURL:styleURL];
    map.delegate = self;
    map.translatesAutoresizingMaskIntoConstraints = NO;
    [map setCenterCoordinate:CLLocationCoordinate2DMake(0, 0) zoomLevel:11.3 animated:NO];
    [self.view addSubview:map];
    [NSLayoutConstraint activateConstraints:@[
        [map.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [map.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [map.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [map.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)mapViewDidFailLoadingMap:(MLNMapView *)mapView withError:(NSError *)error {
    NSLog(@"Map failed: %@", error.localizedDescription);
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
