//
//  HCellView.swift
//  Stellar Hedron
//
//  Created by David S Reich on 29/09/2015.
//  Copyright © 2015 Stellar Software Pty Ltd. All rights reserved.
//

import UIKit

class HCellView: UIView {

    let p4Size: CGSize
    var complete = false
    var playerNumber = 0
    var completeColor = UIColor.clearColor()
    var path = UIBezierPath()
    var pointValue: Int
    var valueLabel: UILabel
    var outsideCell = false

    var middlePoint = CGPointZero

    //for user interaction:
    struct HotSpot {
        let path = UIBezierPath()
        var enabled = true
    }

    var hotSpots = Array<HotSpot>()
    var boardView: HBoardView
    var previousPointInsidePoint: CGPoint?
    var previousPointInsideResponse: Bool?
    var tapRecognizer: UITapGestureRecognizer?
    var doubleTapRecognizer: UITapGestureRecognizer?


    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //p0 ... p4 are in coordinate space of the board ...
    //this is self-framing!  Hopefully not self-hoisting.
    init(theBoard: HBoardView, index: Int, p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, p4: CGPoint, p4Size: CGSize, pointValue: Int, outsideCell: Bool) {
        self.boardView = theBoard
        self.p4Size = p4Size
        self.pointValue = pointValue

        self.outsideCell = outsideCell
        //first let's find the bounds
        let path0 = UIBezierPath()
        path0.removeAllPoints()
        path0.moveToPoint(p0)
        path0.addLineToPoint(p1)
        path0.addLineToPoint(p2)
        path0.addLineToPoint(p3)
        path0.addLineToPoint(p4)
        path0.closePath()

        let tH = p4Size.height / 6
        valueLabel = UILabel(frame: CGRectMake(0, 0, tH, tH))

        var path0Bounds = path0.bounds
        if outsideCell {
            path0Bounds = path0Bounds.insetBy(dx: -12, dy: -12)
        }

        super.init(frame: path0Bounds)

        self.tag = index
        self.addSubview(valueLabel)

        func offSetPoint(p: CGPoint) -> CGPoint {
            return CGPointMake(p.x - self.frame.origin.x, p.y - self.frame.origin.y)
        }

        //now let's do it again with an offset so we can draw inside our own view.
        let offSetP0 = offSetPoint(p0)
        let offSetP1 = offSetPoint(p1)
        let offSetP2 = offSetPoint(p2)
        let offSetP3 = offSetPoint(p3)
        let offSetP4 = offSetPoint(p4)

        path.removeAllPoints()
        path.moveToPoint(offSetP0)
        path.addLineToPoint(offSetP1)
        path.addLineToPoint(offSetP2)
        path.addLineToPoint(offSetP3)
        path.addLineToPoint(offSetP4)
        path.closePath()

        backgroundColor = UIColor.clearColor()
        completeColor = UIColor.clearColor()
        opaque = false

        valueLabel.textAlignment = NSTextAlignment.Center
        valueLabel.textColor = UIColor.whiteColor()
        valueLabel.opaque = true
        valueLabel.text = String(pointValue)
        valueLabel.numberOfLines = 1
        valueLabel.baselineAdjustment = UIBaselineAdjustment.AlignCenters

        let fontSize = floor(18 * theBoard.bounds.width / 320)
        valueLabel.font = UIFont(name: "Verdana-Bold", size: fontSize) //adjust font sizes for different screens?

        if outsideCell {
            let outsidePath = UIBezierPath(rect: CGRectInfinite)
            outsidePath.appendPath(path)
            outsidePath.usesEvenOddFillRule = true
            path = outsidePath
            self.clipsToBounds = false
            self.layer.borderWidth = 2
            self.layer.borderColor = UIColor.whiteColor().CGColor

            middlePoint = CGPointMake(bounds.width * 0.825, bounds.height * 0.825)
        } else {
            let offsetP0 = offSetPoint(p0)
            let offsetP2 = offSetPoint(p2)
            let offsetP3 = offSetPoint(p3)
            let midPointP2P3 = CGPointMake((offsetP2.x + offsetP3.x) / 2, (offsetP2.y + offsetP3.y) / 2)

            middlePoint = CGPointMake((offsetP0.x + midPointP2P3.x) / 2, (offsetP0.y + midPointP2P3.y) / 2)
        }

        valueLabel.center = middlePoint

        if !outsideCell {
            //it would be nice to be able to interate this.
            hotSpots.append(makeHotSpot(offSetP0, p1: offSetP1))
            hotSpots.append(makeHotSpot(offSetP1, p1: offSetP2))
            hotSpots.append(makeHotSpot(offSetP2, p1: offSetP3))
            hotSpots.append(makeHotSpot(offSetP3, p1: offSetP4))
            hotSpots.append(makeHotSpot(offSetP4, p1: offSetP0))
            
        } else {
            let savedMiddlePoint = middlePoint

            middlePoint = CGPointMake(0, bounds.height)
            hotSpots.append(makeHotSpot(offSetP0, p1: offSetP1))

            middlePoint = CGPointMake(0, 0)
            hotSpots.append(makeHotSpot(offSetP1, p1: offSetP2))

            middlePoint = CGPointMake(bounds.width / 2, 0)
            hotSpots.append(makeHotSpot(offSetP2, p1: offSetP3))

            middlePoint = CGPointMake(bounds.width, 0)
            hotSpots.append(makeHotSpot(offSetP3, p1: offSetP4))

            middlePoint = CGPointMake(bounds.width, bounds.height)
            hotSpots.append(makeHotSpot(offSetP4, p1: offSetP0))

            middlePoint = savedMiddlePoint

            self.backgroundColor = UIColor(red: 40.0 / 256.0, green: 40.0 / 256.0, blue: 40.0 / 256.0, alpha: 1.0)
        }

        tapRecognizer = UITapGestureRecognizer(target: self, action:#selector(HCellView.hotspotTapped(_:)))
        tapRecognizer?.enabled = true
        addGestureRecognizer(tapRecognizer!);
        doubleTapRecognizer = UITapGestureRecognizer(target: self, action:#selector(HCellView.hotspotDoubleTapped(_:)))
        doubleTapRecognizer?.numberOfTapsRequired = 2
        doubleTapRecognizer?.enabled = true
        addGestureRecognizer(doubleTapRecognizer!);

        userInteractionEnabled = true
    }

    func makeHotSpot(p0: CGPoint, p1: CGPoint) -> HotSpot {
        let hs = HotSpot()

        hs.path.moveToPoint(p0)
        hs.path.addLineToPoint(p1)
        hs.path.addLineToPoint(middlePoint)
        hs.path.closePath()

        return hs
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    override func drawRect(rect: CGRect) {
        if complete {
            completeColor.setFill()
            path.fill()
        }
    }

    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        let superResult = super.pointInside(point, withEvent: event)
        if (!superResult) {
            return superResult;
        }

        if let thePoint = previousPointInsidePoint {
            if (CGPointEqualToPoint(point, thePoint)) {
                return previousPointInsideResponse!;
            }
        }

        var response = false
        var boundaryIndex = 0

        for hs in hotSpots {
            if hs.enabled && hs.path.containsPoint(point) {
                response = true
                break
            }
            boundaryIndex += 1
        }

        previousPointInsidePoint = point;
        previousPointInsideResponse = response;
        if (response) {
//            print("Clicked inside \(tag) Boundary (0-4) \(boundaryIndex)")
        }
        return response;

    }

    func hotspotTapped(recognizer: UITapGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Ended {
            print("Tapped in Cell")

            let tapPoint = recognizer.locationInView(recognizer.view)
            var boundaryIndex = 0
            for hs in hotSpots {
                if hs.enabled && hs.path.containsPoint(tapPoint) {
                    boardView.playerTapped(self.tag, pentagonNumber: boundaryIndex)
                    return
                }

                boundaryIndex += 1
            }
        }
    }

    func hotspotDoubleTapped(recognizer: UITapGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Ended {
            print("Doubletapped in Cell")

            let tapPoint = recognizer.locationInView(recognizer.view)
            var boundaryIndex = 0
            for hs in hotSpots {
                if hs.enabled && hs.path.containsPoint(tapPoint) {
                    boardView.playerCommitted(self.tag, pentagonNumber: boundaryIndex)
                    return
                }

                boundaryIndex += 1
            }
        }
    }

    func setComplete(complete: Bool, playerNum: Int, completeColor: UIColor) {
        self.complete = complete

        if complete {
            self.playerNumber = playerNum
            self.completeColor = completeColor
        }

        setNeedsDisplay()
    }

    func setCellPointValue(pointValue: Int) {
        self.pointValue = pointValue
        valueLabel.text = String(pointValue)
    }
}
