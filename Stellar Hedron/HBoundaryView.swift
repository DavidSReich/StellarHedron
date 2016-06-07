//
//  HBoundaryView.swift
//  Stellar Hedron
//
//  Created by David S Reich on 30/09/2015.
//  Copyright © 2015 Stellar Software Pty Ltd. All rights reserved.
//

import UIKit

class HBoundaryView: UIView {

    var playerNumber = 0
    var completeColor = UIColor.clearColor()
    var path = UIBezierPath()
    static let lineWidth0: CGFloat = 4
    var lineWidth: CGFloat = 0

    static let markerColorWidth0: CGFloat = 4
    static let markerWidth0: CGFloat = HBoundaryView.markerColorWidth0 * 2
    var markerColorWidth: CGFloat = 0
    var markerWidth: CGFloat = 0
    var markerLength: CGFloat = 30

    var markerPath = UIBezierPath()
    var playState: PlayState = PlayState.Clear
    var boardView: HBoardView

    enum PlayState {
        case Clear  //unmarked
        case Tentative  //mark lightly
        case Committed  //permanent marker
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //p0 ... p1 are in coordinate space of the board ...
    //this is self-framing!  Hopefully not self-hoisting.
    init(theBoard: HBoardView, index: Int, p0: CGPoint, p1: CGPoint, markerLength: CGFloat) {
        self.boardView = theBoard

        //set lineWidths, etc.:
        lineWidth = floor(HBoundaryView.lineWidth0 * theBoard.bounds.width / 320)
        markerColorWidth = floor(HBoundaryView.markerColorWidth0 * theBoard.bounds.width / 320)
        markerWidth = floor(HBoundaryView.markerWidth0 * theBoard.bounds.width / 320)

        //first let's find the bounds
        let path0 = UIBezierPath()
        path0.removeAllPoints()
        path0.moveToPoint(p0)
        path0.addLineToPoint(p1)
        path0.closePath()
        path0.lineWidth = lineWidth

        path0.lineCapStyle = CGLineCap.Round
        path0.lineJoinStyle = CGLineJoin.Round

        super.init(frame: path0.bounds.insetBy(dx: -markerLength * 1.5, dy: -markerLength * 1.5))

        self.tag = index
        self.markerLength = markerLength

        func offSetPoint(p: CGPoint) -> CGPoint {
            return CGPointMake(p.x - self.frame.origin.x, p.y - self.frame.origin.y)
        }

        //now let's do it again with an offset so we can draw inside our own view.
        let offsetP0 = offSetPoint(p0)
        let offsetP1 = offSetPoint(p1)
        path.removeAllPoints()
        path.moveToPoint(offsetP0)
        path.addLineToPoint(offsetP1)
        path.closePath()
        path.lineWidth = lineWidth
        path.lineCapStyle = CGLineCap.Round
        path.lineJoinStyle = CGLineJoin.Round

        backgroundColor = UIColor.clearColor()
        completeColor = UIColor.blackColor()
        clipsToBounds = false

        userInteractionEnabled = false

        //let's make the marker the right way!
        let midpoint = CGPointMake((offsetP0.x + offsetP1.x) / 2, (offsetP0.y + offsetP1.y) / 2)

        markerPath.removeAllPoints()
        markerPath.moveToPoint(midpoint)
        markerPath.addLineToPoint(CGPointMake(midpoint.x + markerLength / 2, midpoint.y - markerLength / 2))
        markerPath.moveToPoint(midpoint)
        markerPath.addLineToPoint(CGPointMake(midpoint.x + markerLength / 2, midpoint.y + markerLength / 2))
        markerPath.moveToPoint(midpoint)
        markerPath.addLineToPoint(CGPointMake(midpoint.x - markerLength / 2, midpoint.y + markerLength / 2))
        markerPath.moveToPoint(midpoint)
        markerPath.addLineToPoint(CGPointMake(midpoint.x - markerLength / 2, midpoint.y - markerLength / 2))
        markerPath.lineCapStyle = CGLineCap.Round
        markerPath.lineJoinStyle = CGLineJoin.Round
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    */
    override func drawRect(rect: CGRect) {
        //the line
        UIColor.whiteColor().setStroke()
        path.stroke()

        if playState == PlayState.Clear {
            return
        }

        if playState == PlayState.Tentative {
            UIColor.lightGrayColor().setStroke()
        }

        markerPath.lineWidth = markerWidth
        markerPath.stroke()
        completeColor.setStroke()
        markerPath.lineWidth = markerColorWidth
        markerPath.stroke()
    }

    func setState(newState: PlayState, playerNum: Int, completeColor: UIColor) {
        if playState == newState {
            return
        }

        playState = newState
        self.completeColor = completeColor
        self.playerNumber = playerNum

        setNeedsDisplay()
    }

}
