//
//  DispatchMain.swift
//  SurfingGoWatchApp Extension
//
//  Created by 野澤 通弘 on 2017/09/27.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import Foundation
func dispatch_sync_main(block: () -> Void) {
    if Thread.isMainThread {
        block()
    }
    else {
        DispatchQueue.main.sync {() -> Void in
            block()
        }
    }
}
func dispatch_async_main(block: @escaping () -> Void) {
    DispatchQueue.main.async {() -> Void in
        block()
    }
}
