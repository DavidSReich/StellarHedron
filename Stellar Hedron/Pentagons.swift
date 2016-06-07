//
//  Pentagons.swift
//  Stellar Hedron
//
//  Created by David S Reich on 30/09/2015.
//  Copyright © 2015 Stellar Software Pty Ltd. All rights reserved.
//

import UIKit

class Pentagons {

    let aspectRatio: CGFloat = CGFloat(1 / cos(2 * M_PI * 18 / 360))
    let P3P2percent: CGFloat = 1.47
    static let cos36deg: CGFloat = CGFloat(cos(2 * M_PI * 36 / 360))
    let cos54deg: CGFloat = CGFloat(cos(2 * M_PI * 54 / 360))
    static let radians72deg: CGFloat = CGFloat(2 * M_PI / 5)
    static let radians36deg: CGFloat = Pentagons.radians72deg / 2

    var pentagon4Size = CGSizeZero

    var bounds = CGRect()
    var boardCenter = CGPointZero
    static var keyLength: CGFloat = 0

    class Pentagon {
        var up = true
        var radius: CGFloat = 0
        var points = [CGPoint](count: 5, repeatedValue: CGPointZero)
    }

    var pentagons = [Pentagon]()

    //frame has already been inset
    //origin of board is controlled by parent (or parent's parent)
    func calculatePentagons(bounds: CGRect, boardCenter: CGPoint) {
        //we are ALWAYS in portrait orientation
        //therefore the limiting dimension is always width.
        self.bounds = bounds
        self.boardCenter = boardCenter

        pentagon4Size = CGSizeMake(bounds.width - 40, (bounds.width - 40) / aspectRatio)
        //just in case we have landscape ...
        if bounds.width > bounds.height {
            pentagon4Size = CGSizeMake((bounds.height - 40) * aspectRatio, bounds.height - 40)
        }

        //sanity check
        if (pentagon4Size.height > bounds.height) || (pentagon4Size.width > bounds.width) {
            //uh oh!!
        }

        Pentagons.keyLength = (pentagon4Size.height / (1 + Pentagons.cos36deg)) / ((((1 / (2 * cos54deg)) + 1) * P3P2percent) + 1)

//        print("calcbounds: \(bounds)")
//        print("aspectRation= \(aspectRatio)")
//        pentagon4Size = CGSizeMake(bounds.width, bounds.width / aspectRatio)
//        print("keyLength = \(keyLength)")
//        keyLength = (pentagon4Size.width / (1 + cos36deg)) / ((((1 / (2 * cos54deg)) + 1) * P3P2percent) + 1)
//        print("keyLength = \(keyLength)")
        for i in 0...3 {
            var radius: CGFloat
            var startRadians: CGFloat = 0
            switch i {
            case 0:
                radius = Pentagons.keyLength / (2 * cos54deg)
            case 1:
                radius = pentagons[0].radius + Pentagons.keyLength
            case 2:
                radius = pentagons[1].radius * P3P2percent
                startRadians = CGFloat(M_PI)
            case 3:
                radius = pentagons[2].radius + Pentagons.keyLength
                //should be the same as
//                let radius2 = pentagon4Size.height / (1 + cos36deg)
//                print("r == r2: \(radius) ==? \(radius2)")
                startRadians = CGFloat(M_PI)
            default:
                radius = 1  //never get here
            }

//            print("radius = \(radius)")
            pentagons.append(Pentagon())
            pentagons[i].radius = radius
            calculatePentagonPoints(pentagons[i], startRadians: startRadians)
        }

    }

    func calculatePentagonPoints(p: Pentagon, startRadians: CGFloat) {
        let cx = bounds.width / 2
        let cy = (bounds.height / 2) - UIApplication.sharedApplication().statusBarFrame.size.height
        let r  = p.radius
        p.points.removeAll()

        for i in 0...4 {
            let x = cx + r * sin(startRadians + Pentagons.radians72deg * CGFloat(i))
            let y = cy - r * cos(startRadians + Pentagons.radians72deg * CGFloat(i))
            print("x:y = \(x) \(y)")
            p.points.append(CGPoint(x: x, y: y))
        }
    }
}
