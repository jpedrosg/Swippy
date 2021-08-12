//
//  SwippyApp.swift
//  swippy
//
//  Created by João Pedro Giarrante on 22/07/21.
//

import SwiftUI

@main
struct SwippyApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            let viewModel = MultiImagesView.ViewModel(
                leftNavigationButtonText: "Done",
                rightNavigationButtonText: "Share Product",
                rightNavigationButtonImage: "square.and.arrow.up",
                topNavigationText: "%@ of %@",
                images:  [#imageLiteral(resourceName: "Image1"), #imageLiteral(resourceName: "Image2"), #imageLiteral(resourceName: "Image1"), #imageLiteral(resourceName: "Image2"), #imageLiteral(resourceName: "Image1")],
                squareSide: 220)
            
            MultiImagesView(with: viewModel)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.all
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}
