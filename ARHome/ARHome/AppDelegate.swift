//
//  AppDelegate.swift
//  ARHome
//
//  Created by MrZhou on 2017/11/15.
//  Copyright © 2017年 vipme. All rights reserved.
//

import UIKit
import ARKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
//        guard ARWorldTrackingConfiguration.isSupported else {
//            fatalError("""
//                ARKit is not available on this device. For apps that require ARKit
//                for core functionality, use the `arkit` key in the key in the
//                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
//                the app from installing. (If the app can't be installed, this error
//                can't be triggered in a production scenario.)
//                In apps where AR is an additive feature, use `isSupported` to
//                determine whether to show UI for launching AR experiences.
//            """) // For details, see https://developer.apple.com/documentation/arkit
//        }
        
//        NetworkingHelper.get(url: "https://app-api-global.vip.com/home/getactivityspeciallist?type=upcomingevents&currentPage=1&pageSize=10", parameters: nil) { (data:AnyObject?, error:AnyObject?) in
//            if error == nil {
//                let dic = data as? NSDictionary
//                let items = dic?.object(forKey: "items") as? NSArray
//                for item in items! {
//                    let pLet = item as? NSDictionary
//                    let imgUrl = pLet?.object(forKey: "imgUrl")
//                    print(imgUrl)
//                }
//            }
//        }
        NetworkingHelper.download(url: "https://a.vpimg3.com/upload/merchandise/pdcvis/115713/2017/0824/71/a84f22ed-0881-4513-beae-de4f4a6103f8.jpg", parameters: nil) { (resp, nil) in
            //
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

