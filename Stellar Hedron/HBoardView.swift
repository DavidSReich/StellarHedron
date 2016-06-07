//
//  HBoardView.swift
//  Stellar Hedron
//
//  Created by David S Reich on 1/10/2015.
//  Copyright © 2015 Stellar Software Pty Ltd. All rights reserved.
//

import UIKit

class HBoardView: UIView {

    let pentagons = Pentagons()
    var cells = Array<HCellView>()
    var boundaries = Array<HBoundaryView>()
    var boardCenter = CGPointZero
    var markerLength = CGFloat()

    var currentPlay: HBoundaryView?
    var mainViewController: HMainViewController!
    var currentPlayer = 0
    var players = Array<HPlayer>()
    var gameType = LocationType.Local
    var insideGame = false
    var gameOver = false
    var aiStrength = 2  //0 - easy, 1 - medium, 2 - hard ... or "very easy", "easy" and "normal"
    //for remote synchronization
    var randomSeedForRemoteHandshake = 0
    var haveRandomSeed = false
    var remoteCellPoints = Array<Int>()
    var remoteSeed = 0
    var haveRemoteSeed = false


    enum LocationType {
        case Local  //game is on this system - two local players
        case Remote //game is through GC - each player is local, each opponent is remote
        case AI     //game is on this system - one player is local, other player is AI
    }

/*
    maps:
    cell2boundaryMap[cellIndex][<boundaryIndex * 5>]
    boundary2CellMap[boundaryIndex][<cellIndex * 2>]
*/
    //cell boundaries are in order, first one is between v0/v1, next v1/v2, etc.
    //where v0 is the top point, and other points are clockwise.
    //so ... tap in hotspot B2.2 ... is cell3.boundary4
    //looking up boundary4 gives cell0 and cell3 as a pair.  Since we are cell3 the other cell is cell0
    var cell2BoundaryDict: [Int: [Int]] = [
        //A
        0: [0, 1, 2, 3, 4],
        //B0 - B4
        1: [16, 8, 2, 7, 15],
        2: [18, 9, 3, 8, 17],
        3: [10, 5, 4, 9, 19],
        4: [12, 6, 0, 5, 11],
        5: [14, 7, 1, 6, 13],
        //C0 - C4
        6: [10, 22, 27, 23, 11],
        7: [12, 23, 28, 24, 13],
        8: [14, 24, 29, 20, 15],
        9: [16, 20, 25, 21, 17],
        10: [18, 21, 26, 22, 19],
        //D
        11: [25, 26, 27, 28, 29]
    ]

    var boundary2CellDict: [Int: [Int]] = [
        //AB
        0: [0, 4],
        1: [0, 5],
        2: [0, 1],
        3: [0, 2],
        4: [0, 3],
        //BB
        5: [3, 4],
        6: [4, 5],
        7: [5, 1],
        8: [1, 2],
        9: [2, 3],
        //BC
        10: [3, 6],
        11: [4, 6],
        12: [4, 7],
        13: [5, 7],
        14: [5, 8],
        15: [1, 8],
        16: [1, 9],
        17: [2, 9],
        18: [2, 10],
        19: [3, 10],
        //CC
        20: [8, 9],
        21: [9, 10],
        22: [10, 6],
        23: [6, 7],
        24: [7, 8],
        //CD
        25: [9, 11],
        26: [10, 11],
        27: [6, 11],
        28: [7, 11],
        29: [8, 11]
    ]

    var cellPoints = Array<Int>(count: 21, repeatedValue: 0)
    var scores = [Int](count: 2, repeatedValue: 0)

    func createBoard(boardCenter: CGPoint) {
//        self.backgroundColor = UIColor.yellowColor()
//        self.layer.borderColor = UIColor.redColor().CGColor
//        self.layer.borderWidth = 1
        print("bounds: \(bounds)")
        print("frame: \(frame)")
        self.boardCenter = boardCenter
    }

    func setupBoard(viewController: HMainViewController) {
        mainViewController = viewController

        pentagons.calculatePentagons(self.bounds, boardCenter: boardCenter)
        markerLength = Pentagons.keyLength * 0.15
        makeCells()
        makeBoundaries()

        rematch()
    }

    // MARK: Build the board!

    func makeCells() {
        //make A cell
        let points0 = pentagons.pentagons[0].points
        let colorA = UIColor.clearColor()
//        var colorA = UIColor.clearColor()
//        colorA = UIColor.magentaColor()
        addCellView(points0[0], p1: points0[1], p2: points0[2], p3: points0[3], p4: points0[4]).completeColor = colorA

        //make B cells
        let points1 = pentagons.pentagons[1].points
        let points2 = pentagons.pentagons[2].points
        let colorB = UIColor.clearColor()
//        var colorB = UIColor.clearColor()
//        colorB = UIColor.blueColor()
        var hCV: HCellView
        var startRadians: CGFloat

        //let's make 5 the same and then rotate and position all -
        //the first one isn't rotated and it's already in the correct position

        startRadians = CGFloat(M_PI)

        let cx = pentagons.bounds.width / 2
        let cy = (pentagons.bounds.height / 2) - UIApplication.sharedApplication().statusBarFrame.size.height

        for i in 0...4 {
            hCV = addCellView(points2[0], p1: points1[3], p2: points0[3], p3: points0[2], p4: points1[2])
            hCV.completeColor = colorB

            let r = hCV.center.y - cy
            let rotateRadians = Pentagons.radians72deg * CGFloat(i)

            let x = cx + r * sin(startRadians + rotateRadians)
            let y = cy - r * cos(startRadians + rotateRadians)
            hCV.center = CGPointMake(x, y)

            hCV.transform = CGAffineTransformMakeRotation(rotateRadians)
            hCV.valueLabel.transform = CGAffineTransformMakeRotation(-rotateRadians)
            hCV.valueLabel.center = CGPointMake(hCV.valueLabel.center.x, hCV.valueLabel.center.y - hCV.bounds.height * 0.1)
        }

        //make C cells
        let points3 = pentagons.pentagons[3].points
        let colorC = UIColor.clearColor()
//        var colorC = UIColor.clearColor()
//        colorC = UIColor.orangeColor()
        startRadians = CGFloat(M_PI)

        for i in 0...4 {
            hCV = addCellView(points1[0], p1: points2[2], p2: points3[2], p3: points3[3], p4: points2[3])
            hCV.completeColor = colorC

            let r = hCV.center.y - cy
            let rotateRadians = Pentagons.radians72deg * CGFloat(i)

            let x = cx + r * sin(startRadians + rotateRadians)
            let y = cy - r * cos(startRadians + rotateRadians)
            hCV.center = CGPointMake(x, y)

            hCV.transform = CGAffineTransformMakeRotation(rotateRadians)
            hCV.valueLabel.transform = CGAffineTransformMakeRotation(-rotateRadians)
        }

        //make D cell
        let colorD = UIColor.clearColor()
//        var colorD = UIColor.clearColor()
//        colorD = UIColor.lightGrayColor()
        let cellD = addCellView(points3[0], p1: points3[1], p2: points3[2], p3: points3[3], p4: points3[4], outsideCell: true)
        cellD.completeColor = colorD
        sendSubviewToBack(cellD)
    }

    func addCellView(p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, p4: CGPoint) -> HCellView {
        return addCellView(p0, p1: p1, p2: p2, p3: p3, p4: p4, outsideCell: false)
    }

    func addCellView(p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, p4: CGPoint, outsideCell: Bool) -> HCellView {
        var pointValue = 0
        repeat {
            pointValue = Int(arc4random_uniform(21))
        } while cellPoints[pointValue] != 0

        cellPoints[pointValue] = 1
        let hCV = HCellView(theBoard: self, index: cells.count, p0: p0, p1: p1, p2: p2, p3: p3, p4: p4, p4Size: pentagons.pentagon4Size, pointValue: pointValue + 1, outsideCell: outsideCell)
        self.addSubview(hCV)
        cells.append(hCV)
        return hCV
    }

    func resetPointValues() {
        print("resetPointValues()!")
        var cellPoints = Array<Int>(count: 21, repeatedValue: 0)

        for cell in cells {
            var pointValue = 0
            repeat {
                pointValue = Int(arc4random_uniform(21))
            } while cellPoints[pointValue] != 0

            cell.setCellPointValue(pointValue + 1)
            cellPoints[pointValue] = 1
        }
    }

    func makeBoundaries() {

        //make AB boundaries
        let points0 = pentagons.pentagons[0].points

        //let's make 5 the same and then rotate and position all -
        //the first one isn't rotated and it's already in the correct position

        var hBV: HBoundaryView
        var startRadians: CGFloat
        startRadians = CGFloat(M_PI)

        let cx = pentagons.bounds.width / 2
        let cy = (pentagons.bounds.height / 2) - UIApplication.sharedApplication().statusBarFrame.size.height
        
        let colorB = UIColor.clearColor()
//        var colorB = UIColor.clearColor()
//        colorB = UIColor.yellowColor()

        for i in 0...4 {
            //use the horizontal one -- boundary 2
            hBV = addBoundaryView(points0[2], p1: points0[3])
            hBV.completeColor = colorB
//            colorB = UIColor.redColor()

            let r = hBV.center.y - cy

            var numRotations: CGFloat = 0
            if i > 1 {
                numRotations = CGFloat(i - 2)
            } else {
                numRotations = CGFloat(i - 2 + 5)
            }

            let rotateRadians = Pentagons.radians72deg * numRotations

            let x = cx + r * sin(startRadians + rotateRadians)
            let y = cy - r * cos(startRadians + rotateRadians)
            hBV.center = CGPointMake(x, y)

            hBV.transform = CGAffineTransformMakeRotation(rotateRadians)
        }

        //make inter B boundaries
        let points1 = pentagons.pentagons[1].points

//        colorB = UIColor.yellowColor()

        //start with a horizontal one, then rotate it an extra 90degrees
        //use this just to get the radius and distance
        hBV = HBoundaryView(theBoard: self, index: 0, p0: points0[0], p1: points1[0], markerLength: markerLength)
        var r = hBV.center.y - cy
        var distance = CGFloat(hypotf(Float(points1[0].x - points0[0].x), Float(points1[0].y - points0[0].y)))

        for i in 0...4 {
            //use horizontal start
            let p0 = CGPointMake(0, 0)
            let p1 = CGPointMake(distance, 0)
            hBV = addBoundaryView(p0, p1: p1)
            hBV.completeColor = colorB
//            colorB = UIColor.redColor()

            let numRotations: CGFloat = CGFloat(i)
            var rotateRadians = Pentagons.radians72deg * numRotations

            let x = cx + r * sin(startRadians + rotateRadians)
            let y = cy - r * cos(startRadians + rotateRadians)
            hBV.center = CGPointMake(x, y)

            rotateRadians += CGFloat(M_PI_2)
            hBV.transform = CGAffineTransformMakeRotation(rotateRadians)
        }

        //make BC boundaries
        let points2 = pentagons.pentagons[2].points

//        colorB = UIColor.yellowColor()

        //start with a horizontal one, then rotate it an extra 90degrees
        //use this just to get the radius and distance
        let p0 = points1[0]
        let p1 = points2[3]

        distance = CGFloat(hypotf(Float(p1.x - p0.x), Float(p1.y - p0.y)))

        let p0p1Center = CGPointMake((p0.x + p1.x) / 2, (p0.y + p1.y) / 2)
        r = CGFloat(hypotf(Float(p0p1Center.x - cx), Float(p0p1Center.y - cy)))

        let placementAngleOffset = abs(atan2(p0p1Center.x - cx, p0p1Center.y - cy))
        let boundaryAngleRadians = atan2(p1.x - p0.x, p1.y - p0.y)  //for rotation of boundary

        for i in 0...4 {
            //use horizontal start
            let p0 = CGPointMake(0, 0)
            let p1 = CGPointMake(distance, 0)
            hBV = addBoundaryView(p0, p1: p1)
            hBV.completeColor = colorB
//            colorB = UIColor.redColor()

            let numRotations: CGFloat = CGFloat(i)
            let rotateRadians = Pentagons.radians72deg * numRotations
            let spinRadians = CGFloat(M_PI_2) + rotateRadians

            var rotateRadiansOffset =  rotateRadians + placementAngleOffset

            let x = cx + r * sin(startRadians + rotateRadiansOffset)
            let y = cy - r * cos(startRadians + rotateRadiansOffset)
            hBV.center = CGPointMake(x, y)
            hBV.transform = CGAffineTransformMakeRotation(spinRadians + boundaryAngleRadians)

            //other one
            hBV = addBoundaryView(p0, p1: p1)
            hBV.completeColor = colorB
//            colorB = UIColor.yellowColor()

            rotateRadiansOffset =  rotateRadians - placementAngleOffset

            let x2 = cx + r * sin(startRadians + rotateRadiansOffset)
            let y2 = cy - r * cos(startRadians + rotateRadiansOffset)
            hBV.center = CGPointMake(x2, y2)
            hBV.transform = CGAffineTransformMakeRotation(spinRadians - boundaryAngleRadians)
        }

        //make inter C boundaries
        let points3 = pentagons.pentagons[3].points

//        colorB = UIColor.yellowColor()

        //start with a horizontal one, then rotate it an extra 90degrees
        //use this just to get the radius and distance
        hBV = HBoundaryView(theBoard: self, index: 0, p0: points2[0], p1: points3[0], markerLength: markerLength)
        r = hBV.center.y - cy
        distance = CGFloat(hypotf(Float(points3[0].x - points2[0].x), Float(points3[0].y - points2[0].y)))

        for i in 0...4 {
            //use horizontal start
            let p0 = CGPointMake(0, 0)
            let p1 = CGPointMake(distance, 0)
            hBV = addBoundaryView(p0, p1: p1)
            hBV.completeColor = colorB
//            colorB = UIColor.redColor()

            let numRotations: CGFloat = CGFloat(i)
            var rotateRadians = Pentagons.radians72deg * numRotations

            let x = cx + r * sin(startRadians + rotateRadians)
            let y = cy - r * cos(startRadians + rotateRadians)
            hBV.center = CGPointMake(x, y)

            rotateRadians += CGFloat(M_PI_2)
            hBV.transform = CGAffineTransformMakeRotation(rotateRadians)
        }

        //make CD boundaries
//        colorB = UIColor.yellowColor()

        for i in 0...4 {
            //use the horizontal one -- boundary 2
            hBV = addBoundaryView(points3[2], p1: points3[3])
            hBV.completeColor = colorB
//            colorB = UIColor.redColor()

            let r = hBV.center.y - cy

            var numRotations: CGFloat = 0
            if i > 1 {
                numRotations = CGFloat(i - 2)
            } else {
                numRotations = CGFloat(i - 2 + 5)
            }

            let rotateRadians = Pentagons.radians72deg * numRotations

            let x = cx + r * sin(startRadians + rotateRadians)
            let y = cy - r * cos(startRadians + rotateRadians)
            hBV.center = CGPointMake(x, y)

            hBV.transform = CGAffineTransformMakeRotation(rotateRadians)
        }
    }
    
    func addBoundaryView(p0: CGPoint, p1: CGPoint) -> HBoundaryView {
        let hBV = HBoundaryView(theBoard: self, index: boundaries.count, p0: p0, p1: p1, markerLength: markerLength)
        self.addSubview(hBV)
        boundaries.append(hBV)
        return hBV
    }

    func setupPlayers(type: HBoardView.LocationType, otherPlayerName: String?) {
        while players.count < 2 {
            players.append(HPlayer())
        }

        gameType = type
        if gameType == HBoardView.LocationType.Local {
            players[0].playerName = "Player 1"
            players[0].playerOwnsName = "Player 1's"
            players[0].playerType = HBoardView.LocationType.Local
            players[1].playerName = "Player 2"
            players[1].playerOwnsName = "Player 2's"
            players[1].playerType = HBoardView.LocationType.Local
        } else if gameType == HBoardView.LocationType.AI {
            players[0].playerName = "You"
            players[0].playerOwnsName = "Your"
            players[0].playerType = HBoardView.LocationType.Local
            players[1].playerName = "The AI"
            players[1].playerOwnsName = "The AI's"
            players[1].playerType = HBoardView.LocationType.AI
        } else { //if gameType == HBoardView.LocationType.Remote {
            players[0].playerName = "You"
            players[0].playerOwnsName = "Your"
            players[0].playerType = HBoardView.LocationType.Local
            players[1].playerName = otherPlayerName!
            players[1].playerOwnsName = otherPlayerName! + "'s"
            players[1].playerType = HBoardView.LocationType.Remote
        }

        players[0].playerColor = UIColor(red: 252.0 / 256.0, green: 32.0 / 256.0, blue: 37.0 / 256.0, alpha: 0.75)
        players[1].playerColor = UIColor(red: 77.0 / 256.0, green: 187.0 / 256.0, blue: 248.0 / 256.0, alpha: 0.75)
    }
    
    // MARK: player interactions

    func startLocalGame() {
        if gameType == HBoardView.LocationType.Remote {
            mainViewController.gameCenterManager.disconnectMatch()
        }
        gameType = HBoardView.LocationType.Local
        setupPlayers(HBoardView.LocationType.Local, otherPlayerName: nil)
        rematch()
    }

    func startAIGame() {
        if gameType == HBoardView.LocationType.Remote {
            mainViewController.gameCenterManager.disconnectMatch()
        }
        gameType = HBoardView.LocationType.AI
        setupPlayers(HBoardView.LocationType.AI, otherPlayerName: nil)
        rematch()
    }

    func initRemoteGame() {
        haveRandomSeed = false
        remoteCellPoints.removeAll()
        haveRemoteSeed = false
    }

    func setPlayerAndPoints() {
        if haveRandomSeed && haveRemoteSeed {
            print("Them:Us == \(remoteSeed) :: \(randomSeedForRemoteHandshake)")
            if remoteSeed >= randomSeedForRemoteHandshake {
                var index = 0
                for cell in cells {
                    cell.setCellPointValue(remoteCellPoints[index])
                    cell.setNeedsDisplay()
                    index += 1
                }

                currentPlayer = 0
            } else {
                currentPlayer = 1
            }
            
            nextTurn()
        }
    }

    func startRemoteGame(otherPlayerName: String) {
        gameType = HBoardView.LocationType.Remote
        setupPlayers(HBoardView.LocationType.Remote, otherPlayerName: otherPlayerName)
        rematch()
    }

    /*
    playerTapped -
    if haveCurrentPlay
    currentPlay.setState(Clear)
    set currentPlay = thisPlay
    currentPlay.setState(Tentative)
    playerCommitted -
    currentPlay.setState(Committed)
    currentPlay = nil
    mark cells
    check for check, checkmate??
    swap players
    */
    //used by current (local) player so board will be marked
    func playerTapped(newPlay: HBoundaryView) {
        if gameOver {
            return
        }

        if currentPlay != nil {
            currentPlay?.setState(HBoundaryView.PlayState.Clear, playerNum: 0, completeColor: UIColor.clearColor())
            currentPlay = nil
        }

        updateConfirmMoveButton()   //disables it

        if newPlay.playState != HBoundaryView.PlayState.Clear {
            return
        }

        currentPlay = newPlay
        if currentPlay != nil {
            currentPlay?.setState(HBoundaryView.PlayState.Tentative, playerNum: 0, completeColor: players[currentPlayer].playerColor)
        }

        if players[currentPlayer].playerType == LocationType.AI {
            let delay = 1.0 * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(time, dispatch_get_main_queue()) { self.playerCommitted() }
        } else if (gameType == LocationType.Remote) && (players[currentPlayer].playerType == LocationType.Local) {
            mainViewController.gameCenterManager.sendTurnMessage(newPlay, isConfirmed: false)
        }

        updateConfirmMoveButton()   //enables it ... maybe?
    }

    //used by local and remote players to complete move
    //a local player will have already called playerTapped()
    //a remote player will have called playerTapped() but this is not transmitted to the other player, so the playerCommitted() must
    //also invoke playerTapped ... there should be no "cost" to calling playerTapped() twice
    func playerCommitted() {
        if gameOver {
            return
        }

        if currentPlay == nil {
            return
        }

        if currentPlay!.playState == HBoundaryView.PlayState.Committed {
            return
        }

        insideGame = true

        if (gameType == LocationType.Remote) && (players[currentPlayer].playerType == LocationType.Local) {
            mainViewController.gameCenterManager.sendTurnMessage(currentPlay!, isConfirmed: true)
        }


        currentPlay!.setState(HBoundaryView.PlayState.Committed, playerNum: currentPlayer, completeColor: players[currentPlayer].playerColor)

        processCommittedBoundary(currentPlay!)

        currentPlay = nil

        if isGameOver() == true {
            gameOver = true
            //compare scores!!!
            if scores[0] == scores[1] {
                mainViewController.setPromptText("It's a TIE!")
            } else {
                currentPlayer = scores[0] > scores[1] ? 0 : 1
                if gameType != LocationType.Local && players[currentPlayer].playerType == LocationType.Local {
                    mainViewController.setPromptText("\(players[currentPlayer].playerName) have won!")
                } else {
                    mainViewController.setPromptText("\(players[currentPlayer].playerName) has won!")
                }
            }
        } else {
            nextTurn()
        }

        updateConfirmMoveButton()   //disables it
    }

    func isGameOver() -> Bool {
        //are all cells taken?
        for cell in cells {
            if !cell.complete {
                return false
            }
        }

        return true
    }

    func resetGame() {
        //clear all boundaries

        for boundary in boundaries {
            boundary.setState(HBoundaryView.PlayState.Clear, playerNum: 0, completeColor: UIColor.clearColor())
        }

        for cell in cells {
            cell.setComplete(false, playerNum: 0, completeColor: UIColor.clearColor())
        }

        testBoard() //clear scores
        resetPointValues()

        insideGame = false
        gameOver = false
    }

    func rematch() {
        resetGame()

        if gameType == LocationType.Remote {
            //assign random # here
            randomSeedForRemoteHandshake = Int(arc4random_uniform(UInt32(INT32_MAX)))
            haveRandomSeed = true
            print("randomSeedForRemoteHandshake = \(randomSeedForRemoteHandshake)")
            print("rematch()")
            setPlayerAndPoints()

            //remote handshake
            mainViewController.gameCenterManager.sendRemoteHandshake(randomSeedForRemoteHandshake)

            return
        }

        currentPlayer = Int(arc4random_uniform(2))
        nextTurn()
    }

    func nextTurn() {
        //swap players
        currentPlayer = currentPlayer == 1 ? 0 : 1

        mainViewController.setPromptText("It's \(players[currentPlayer].playerOwnsName) turn!")

        if gameType != LocationType.Local {
            if players[currentPlayer].playerType == LocationType.Local {
                userInteractionEnabled = true
            } else {    //the other player
                userInteractionEnabled = false
                if gameType == LocationType.AI {
                    //the AI
                    if let aiPlayView = nextAIPlay() {
                        let delay = 2.0 * Double(NSEC_PER_SEC)
                        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                        dispatch_after(time, dispatch_get_main_queue()) { self.playerTapped(aiPlayView) }
                    }
                }
            }
        }
    }
    
    // MARK: remote play

    //used to sync remote game boards.
    func getPointValues() -> Array<Int> {
        var cellPoints = Array<Int>(count: 21, repeatedValue: 0)

        var index = 0
        for cell in cells {
            cellPoints[index] = cell.pointValue
            index += 1
        }

        return cellPoints
    }

    func startMatchHandshake(cellPoints: Array<Int>, randomNumber: Int) {
        remoteSeed = randomNumber
        remoteCellPoints = cellPoints
        haveRemoteSeed = true
        print("startMatchHandshake()")

        setPlayerAndPoints()
    }
    
    func getBoundaryView(boundaryIndex: Int) -> HBoundaryView {
        return boundaries[boundaryIndex]
    }

    //cellIndex is the HCellView.tag, pentagonNumber is 0...4 within that cell.
    func getBoundaryView(cellIndex: Int, pentagonNumber: Int) -> HBoundaryView? {
        if cellIndex < cell2BoundaryDict.count {
            if let cellBoundaries = cell2BoundaryDict[cellIndex] {
                let boundaryIndex = cellBoundaries[pentagonNumber]
                return boundaries[boundaryIndex]
            }
        }

        return nil
    }

    func playerTapped(cellIndex: Int, pentagonNumber: Int) {
        if let boundaryView = getBoundaryView(cellIndex, pentagonNumber: pentagonNumber) {
            playerTapped(boundaryView)
        }
    }

    func playerCommitted(cellIndex: Int, pentagonNumber: Int) {
        if let boundaryView = getBoundaryView(cellIndex, pentagonNumber: pentagonNumber) {
            //make sure this is the current play
            if boundaryView == currentPlay {
                playerCommitted()
            }
        }
    }

    func processCommittedBoundary(boundary: HBoundaryView) {
        if testBoundary(boundary) {
            if testBoard() {

            }
        }
    }

    func testBoundary(boundary: HBoundaryView) -> Bool {
        var completedCell = false

        if let boundaryCells = boundary2CellDict[boundary.tag] {
            for cellIndex in boundaryCells {
                if testCell(cellIndex) {
                    completedCell = true
                }
            }
        }

        return completedCell
    }

    func testCell(cellIndex: Int) -> Bool {
        if let cellBoundaries = cell2BoundaryDict[cellIndex] {
            var numCompleteBoundaries = 0

            for boundaryIndex in cellBoundaries {
                let boundary = boundaries[boundaryIndex]
                if boundary.playState == HBoundaryView.PlayState.Committed && boundary.playerNumber == currentPlayer {
                    numCompleteBoundaries += 1
                }
            }

            if numCompleteBoundaries > 2 {
                let cell = cells[cellIndex]
                cell.setComplete(true, playerNum: currentPlayer, completeColor: players[currentPlayer].playerColor)
                return true
            }
        }

        return false
    }

    func testBoard() -> Bool {
        //calculate scores
        var isAllDone = true

        scores[0] = 0
        scores[1] = 0
        for cell in cells {
            if cell.complete {
                scores[cell.playerNumber] += cell.pointValue
            } else {
                isAllDone = false
            }
        }

        mainViewController.player1Score.text = "\(scores[0])"
        mainViewController.player2Score.text = "\(scores[1])"

        return isAllDone
    }

    // MARK: AI!!

    /*
        AI strength in increasing order

        if hardest {
            bestScoringPlay
            bestNonscoringPlay
        } else if medium {
            randomScoringPlay
        }

        randomAIPlay

    First player with 2 sides has advantage in taking cell.
    Strategy - if player has 2 sides and other player 1 or 0, then player can delay taking this cell.

    Weight moves???
    A first side on a cell where other player has 2 sides.
    A first side on a cell where other player has 1 side.
    A first side on a cell where other player has 0 sides.
    A second side on a cell where other player has 2 sides.
    A second side on a cell where other player has 1 side.
    A second side on a cell where other player has 0 sides.

    */
    
    func nextAIPlay() -> HBoundaryView? {
        //don't check isGameOver() it should have already been called
        //first - are there any open boundaries?
        var numberOpen = 0

        for boundaryView in boundaries {
            if boundaryView.playState == HBoundaryView.PlayState.Clear {
                numberOpen += 1
            }
        }

        if numberOpen > 0 {
            if aiStrength == 2 {
                if let bestScore = findBestScoringPlay() {
                    return bestScore.boundary
                }

                if let bestAvailable = findBestNonscoringPlay() {
                    return bestAvailable.boundary
                }
            } else if aiStrength == 1 {
                if let randomScore = randomScoringPlay() {
                    return randomScore
                }
            }

            return randomAIPlay(numberOpen)
        }

        return nil
    }

    func randomAIPlay(numberOpen: Int) -> HBoundaryView? {
        let aiPlayIndex = Int(arc4random_uniform(UInt32(numberOpen)))

        var boundaryViewNum = 0
        //find the boundaryView
        for boundaryView in boundaries {
            if boundaryView.playState == HBoundaryView.PlayState.Clear {
                if boundaryViewNum == aiPlayIndex {
                    return boundaryView
                }

                boundaryViewNum += 1
            }
        }

        return nil
    }

    func randomScoringPlay() -> HBoundaryView? {
        var numberCanScore = 0

        for boundary in boundaries {
            if boundary.playState == HBoundaryView.PlayState.Clear {
                if let boundaryCells = boundary2CellDict[boundary.tag] {
                    var canComplete = false
                    for cellIndex in boundaryCells {
                        let cell = cells[cellIndex]
                        if !cell.complete {
                            if canCompleteCell(cellIndex) {
                                canComplete = true
                            }
                        }
                    }

                    if canComplete {
                        numberCanScore += 1
                    }
                }
            }
        }

        if numberCanScore > 0 {
            let aiPlayIndex = Int(arc4random_uniform(UInt32(numberCanScore)))

            var boundaryViewNum = 0
            //find the boundaryView
            for boundary in boundaries {
                if boundary.playState == HBoundaryView.PlayState.Clear {
                    if let boundaryCells = boundary2CellDict[boundary.tag] {
                        var canComplete = false
                        for cellIndex in boundaryCells {
                            let cell = cells[cellIndex]
                            if !cell.complete {
                                if canCompleteCell(cellIndex) {
                                    canComplete = true
                                }
                            }
                        }

                        if canComplete {
                            if boundaryViewNum == aiPlayIndex {
                                return boundary
                            }

                            boundaryViewNum += 1
                        }
                    }
                }
            }
        }

        return nil
    }

    //do we weigh lower cells that the opponent already has two boundaries on?
    func findBestNonscoringPlay() -> (boundary: HBoundaryView, adjacentPoints: Int)? {
        var bestAvailablePoints = 0
        var bestMove: HBoundaryView? = nil

        for boundary in boundaries {
            if boundary.playState == HBoundaryView.PlayState.Clear {
                if let boundaryCells = boundary2CellDict[boundary.tag] {
                    var availablePoints = 0
                    for cellIndex in boundaryCells {
                        let cell = cells[cellIndex]
                        if !cell.complete {
                            availablePoints += cell.pointValue
                        }
                    }

                    if bestAvailablePoints < availablePoints {
                        bestAvailablePoints = availablePoints
                        bestMove = boundary
                    }
                }
            }
        }

        if bestAvailablePoints > 0 {
            return (bestMove!, bestAvailablePoints)
        }

        return nil
    }

    func findBestScoringPlay() -> (boundary: HBoundaryView, scoringPoints: Int)? {
        var bestScoringPoints = 0
        var bestMove: HBoundaryView? = nil

        for boundary in boundaries {
            if boundary.playState == HBoundaryView.PlayState.Clear {
                if let boundaryCells = boundary2CellDict[boundary.tag] {
                    var scoringPoints = 0
                    for cellIndex in boundaryCells {
                        let cell = cells[cellIndex]
                        if !cell.complete {
                            if canCompleteCell(cellIndex) {
                                scoringPoints += cell.pointValue
                            }
                        }
                    }

                    if bestScoringPoints < scoringPoints {
                        bestScoringPoints = scoringPoints
                        bestMove = boundary
                    }
                }
            }
        }

        if bestScoringPoints > 0 {
            return (bestMove!, bestScoringPoints)
        }
        
        return nil
    }

    func canCompleteCell(cellIndex: Int) -> Bool {
        if let cellBoundaries = cell2BoundaryDict[cellIndex] {
            var numCompleteBoundaries = 0

            for boundaryIndex in cellBoundaries {
                let boundary = boundaries[boundaryIndex]
                if boundary.playState == HBoundaryView.PlayState.Committed && boundary.playerNumber == currentPlayer {
                    numCompleteBoundaries += 1
                }
            }

            if numCompleteBoundaries == 2 {
                return true
            }
        }
        
        return false
    }

    func updateConfirmMoveButton() {
        var enabled = false
        if currentPlay != nil {
            if currentPlay?.playState == HBoundaryView.PlayState.Tentative {
                enabled = true
            }
        }

        mainViewController.enableConfirmMoveButton(enabled)
    }
}
