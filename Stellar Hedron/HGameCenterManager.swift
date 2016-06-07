//
//  HGameCenterManager.swift
//  Stellar Hedron
//
//  Created by David S Reich on 27/10/2015.
//  Copyright © 2015 Stellar Software Pty Ltd. All rights reserved.
//

import Foundation
import GameKit

class HGameCenterManager: NSObject, GKMatchmakerViewControllerDelegate, GKMatchDelegate, UIAlertViewDelegate {
    var havePlayer = false
    var mainViewController: HMainViewController!
    var theMatch: GKMatch!
    var matchStarted = false
    var keepAlive = false
    var turnMessage = TurnMessage()
    var turnData = NSMutableData(length: sizeof(TurnMessage))
    var insideMatchRematch = false
    var otherPlayerName = ""

    let kReconnectAgainAlert = 1
    let kRematchRequestAlert = 2

    enum MessageType {
        case None
        case Turn
        case StartMatchHandshake
        case RematchRequest
        case StartRematch
        case KeepAlive
    }
    
    struct TurnMessage {
        var messageType = MessageType.None
        var boundaryIndex = -1
        var isConfirmed = false
        var pt0 = 0
        var pt1 = 0
        var pt2 = 0
        var pt3 = 0
        var pt4 = 0
        var pt5 = 0
        var pt6 = 0
        var pt7 = 0
        var pt8 = 0
        var pt9 = 0
        var pt10 = 0
        var pt11 = 0
    }

    init(theViewController: HMainViewController) {
        mainViewController = theViewController
        havePlayer = false
        super.init()
        NSNotificationCenter.defaultCenter().addObserverForName(GKPlayerDidChangeNotificationName, object: nil, queue: NSOperationQueue.mainQueue()) { _ in self.authenticationChanged()}
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: GKPlayerDidChangeNotificationName, object: nil)
    }

    func turnMessageValuesToArray() -> Array<Int> {
        var pointValues = Array<Int>(count: 12, repeatedValue: 0)

        pointValues[0] = turnMessage.pt0
        pointValues[1] = turnMessage.pt1
        pointValues[2] = turnMessage.pt2
        pointValues[3] = turnMessage.pt3
        pointValues[4] = turnMessage.pt4
        pointValues[5] = turnMessage.pt5
        pointValues[6] = turnMessage.pt6
        pointValues[7] = turnMessage.pt7
        pointValues[8] = turnMessage.pt8
        pointValues[9] = turnMessage.pt9
        pointValues[10] = turnMessage.pt10
        pointValues[11] = turnMessage.pt11

        return pointValues
    }

    func arrayToTurnMessageValues(pointValues: Array<Int>) {

        turnMessage.pt0 = pointValues[0]
        turnMessage.pt1 = pointValues[1]
        turnMessage.pt2 = pointValues[2]
        turnMessage.pt3 = pointValues[3]
        turnMessage.pt4 = pointValues[4]
        turnMessage.pt5 = pointValues[5]
        turnMessage.pt6 = pointValues[6]
        turnMessage.pt7 = pointValues[7]
        turnMessage.pt8 = pointValues[8]
        turnMessage.pt9 = pointValues[9]
        turnMessage.pt10 = pointValues[10]
        turnMessage.pt11 = pointValues[11]
    }
    
    func authenticationChanged() {
        let localPlayer = GKLocalPlayer()
        if (localPlayer.authenticated == true) {
            print("Authentication changed: Player is Authenticated")
            self.havePlayer = true
        } else {
            //GC still has bug - never sets .authenticated = true
            //popupGCNotAvailable()
            print("Authentication changed: Player Still Not Authenticated")
            self.havePlayer = false
            self.havePlayer = true  //should be false!
        }
    }

    func authenticateLocalPlayer() {
        let localPlayer = GKLocalPlayer()
        localPlayer.authenticateHandler = {(viewController, error) -> Void in
            if (viewController != nil) {
                self.havePlayer = false
                print("Showing GC")
                self.mainViewController.presentViewController(viewController!, animated: true, completion: nil)
            } else {
                if (localPlayer.authenticated == true) {
                    print("Player is Authenticated")
                    self.havePlayer = true
                } else {
                    //self.popupGCNotAvailable()
                    print("Player Still Not Authenticated")
                    self.havePlayer = false
                    self.havePlayer = true  //should be false!
                }

                if !self.matchStarted {
                    self.requestAMatch()
                }
            }
        }
    }
    
    func matchMakerMatchMaker() {
        if !havePlayer {
            authenticateLocalPlayer()
            return
        }

        requestAMatch()
    }

    func requestAMatch() {
        let gcRequest = GKMatchRequest()
        gcRequest.minPlayers = 2
        gcRequest.maxPlayers = 2
        gcRequest.defaultNumberOfPlayers = 2
        
        let gcViewController = GKMatchmakerViewController(matchRequest: gcRequest)
        gcViewController!.matchmakerDelegate = self
        
        self.mainViewController.presentViewController(gcViewController!, animated: true, completion: nil)
    }

    // MARK: GKMatchmakerViewControllerDelegate
    func matchmakerViewControllerWasCancelled(viewController: GKMatchmakerViewController) {
        print("CANCELLEDCANCELLED")
        viewController.dismissViewControllerAnimated(true, completion: nil)
        if mainViewController.boardView.gameType == HBoardView.LocationType.Remote {  //can't go back to remote if we cancel or fail here
            mainViewController.boardView.startLocalGame()
        }
    }

    func matchmakerViewController(viewController: GKMatchmakerViewController, didFailWithError error: NSError) {
        print("FAILEDFAILED")
        viewController.dismissViewControllerAnimated(true, completion: nil)
        if mainViewController.boardView.gameType == HBoardView.LocationType.Remote {
            //can't go back to remote if we cancel or fail here
            mainViewController.boardView.startLocalGame()
        }
    }

    func matchmakerViewController(viewController: GKMatchmakerViewController, didFindMatch match: GKMatch) {
        print("MATCHMATCH")
        viewController.dismissViewControllerAnimated(true, completion: nil)
        theMatch = match
        match.delegate = self
        if match.expectedPlayerCount == 0 {
            //GKPlayer.loadPlayersForIdentifiers() still requires deprecated playerIDs
            GKPlayer.loadPlayersForIdentifiers(match.playerIDs, withCompletionHandler: {(players: [GKPlayer]?, error: NSError?) in
                let otherPlayer = players![0]
                self.otherPlayerName = otherPlayer.displayName!.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "\u{200e}\u{201c}\u{201d}\u{202a}\u{202c}"))
                self.matchStarted = true
                self.mainViewController.boardView.startRemoteGame(self.otherPlayerName)
            })
        }
    }
    
    func matchmakerViewController(viewController: GKMatchmakerViewController, hostedPlayerDidAccept player: GKPlayer) {
        print("ACCEPTEDACCEPTED")
        viewController.dismissViewControllerAnimated(true, completion: nil)
    }

    func matchmakerViewController(viewController: GKMatchmakerViewController, didFindHostedPlayers players: [GKPlayer]) {
        print("HOSTEDHOSTED")
        viewController.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: GKMatchDelegate
    func match(match: GKMatch, didFailWithError error: NSError?) {
        print("Match Failed: \(match) :: \(error)")
    }

    func match(match: GKMatch, didReceiveData data: NSData, fromRemotePlayer player: GKPlayer) {
        receivedData(match, data: data)
    }

    func match(match: GKMatch, didReceiveData data: NSData, fromPlayer playerID: String) {
        receivedData(match, data: data)
    }

    func match(match: GKMatch, player: GKPlayer, didChangeConnectionState state: GKPlayerConnectionState) {
        print("Match player connection state changed: \(player) :: \(state)")
        self.match(match, player: player.playerID!, didChangeState: state)
    }

    func match(match: GKMatch, player playerID: String, didChangeState state: GKPlayerConnectionState) {
        if state == GKPlayerConnectionState.StateConnected {
            print("DIDCHANGESTATE: StateConnected")
        } else if state == GKPlayerConnectionState.StateDisconnected {
            let now = NSDate()
            print("DIDCHANGESTATE: StateDisconnected: \(now) : \(otherPlayerName)")
            self.reconnectToMatch(match, playerName: otherPlayerName)
        } else if state == GKPlayerConnectionState.StateUnknown {
//            var alertBox = UIAlertView(title: "StateUnknown", message: "StateUnknown: \(now) : \(otherPlayerName)", delegate: nil, cancelButtonTitle: "Cancel")
//            alertBox.show()
            print("DIDCHANGESTATE: StateUnknown")
        } else {
//            var alertBox = UIAlertView(title: "Bad", message: "Bad", delegate: nil, cancelButtonTitle: "Cancel")
//            alertBox.show()
            print("DIDCHANGESTATE: bad state")
        }
    }

    func match(match: GKMatch, shouldReinvitePlayer playerID: String) -> Bool {
        print("SHOULDREINVITEPLAYER")
        return true
    }

    func match(match: GKMatch, shouldReinviteDisconnectedPlayer player: GKPlayer) -> Bool {
        print("SHOULDREINVITEDISCONNECTEDPLAYER")
        return true
    }

    func receivedData(match: GKMatch!, data: NSData!) {
        //make sure message is correct size?
        if data.length == sizeof(TurnMessage) {
            data.getBytes(&turnMessage, length: sizeof(TurnMessage))
            if turnMessage.messageType == MessageType.Turn {
                //find HBoundaryView
                let boundaryView = mainViewController.boardView.getBoundaryView(turnMessage.boundaryIndex)
                //tap it
                mainViewController?.boardView.playerTapped(boundaryView)
                //if confirmed then commit it
                if turnMessage.isConfirmed {
                    mainViewController?.boardView.playerCommitted()
                }
            } else if turnMessage.messageType == MessageType.RematchRequest {
                rematchRequestAlert()
            } else if turnMessage.messageType == MessageType.StartRematch {
                self.mainViewController?.boardView.initRemoteGame()
                self.mainViewController?.boardView.rematch()
            } else if turnMessage.messageType == MessageType.KeepAlive {
                //keep alive message ... ignore it
                //we send our own keep alive separately
            } else if turnMessage.messageType == MessageType.StartMatchHandshake {
                mainViewController?.boardView.startMatchHandshake(turnMessageValuesToArray(), randomNumber: turnMessage.boundaryIndex)
            }
        }
    }

    func localPlayerTapped(boundaryView: HBoundaryView) {
        sendTurnMessage(boundaryView, isConfirmed: false)
    }
    
    func localPlayerCommitted(boundaryView: HBoundaryView) {
        sendTurnMessage(boundaryView, isConfirmed: true)
    }
    
    func sendTurnMessage(boundaryView: HBoundaryView, isConfirmed: Bool) {
        turnMessage.messageType = MessageType.Turn
        turnMessage.boundaryIndex = boundaryView.tag
        turnMessage.isConfirmed = isConfirmed
        sendGameMessage()
    }

    func sendRemoteHandshake(randomNumber: Int) {
        turnMessage.messageType = MessageType.StartMatchHandshake
        turnMessage.boundaryIndex = randomNumber
        arrayToTurnMessageValues(mainViewController.boardView.getPointValues())
        sendGameMessage()
    }

    func sendRematchRequestMessage() {
        turnMessage.messageType = MessageType.RematchRequest
        sendGameMessage()
    }
    
    func sendStartRematchMessage() {
        turnMessage.messageType = MessageType.StartRematch
        sendGameMessage()
    }
    
//    func sendKeepAliveMessage() {
//        turnMessage.messageType = MessageType.KeepAlive
//        turnMessage.col = 0
//        sendGameMessage()
//        if keepAlive {
//            let delay = 1.0 * Double(NSEC_PER_SEC)
//            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
//            dispatch_after(time, dispatch_get_main_queue()) { self.sendKeepAliveMessage() } //do it again
//        }
//    }

    func sendGameMessage() {
        turnData!.replaceBytesInRange(NSMakeRange(0, sizeof(TurnMessage)), withBytes: &turnMessage, length: sizeof(TurnMessage))
        do {
            try theMatch.sendDataToAllPlayers(turnData!, withDataMode: GKMatchSendDataMode.Reliable)
        } catch let aError as NSError {
            //handle send error???
            print("SendDataError: \(aError)")
            keepAlive = false
        } catch {
        }
    }

    func timedAlert(message: String, seconds: Double) {
        let alertBox = UIAlertView(title: message, message: nil, delegate: nil, cancelButtonTitle: nil)
        alertBox.show()

        let delay = seconds * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) { alertBox.dismissWithClickedButtonIndex(0, animated: true) }
    }

    func popupGCNotAvailable() {
        timedAlert("The Game Center is not yet available - please try again.", seconds: 2)
    }
    
    func reconnectToMatch(match: GKMatch, playerName: String) {
        if !self.insideMatchRematch {    //need this because sometimes (but not always) we get two of these and only want to rematch once
            print("DIDCHANGESTATE: attempting rematchWithCompletionHandler")
            let alertBox = UIAlertView(title: "Reconnecting ...", message: "We were disconnected from the match.  Attempting to reconnect to \(otherPlayerName).", delegate: nil, cancelButtonTitle: nil)
            alertBox.show()
            self.insideMatchRematch = true
            match.rematchWithCompletionHandler({(newMatch: GKMatch?, error: NSError?) in
                alertBox.dismissWithClickedButtonIndex(0, animated: true)
                self.insideMatchRematch = false
                if error == nil && newMatch != nil && newMatch!.expectedPlayerCount == 0 {
                    //GKPlayer.loadPlayersForIdentifiers() still requires deprecated playerIDs
                    GKPlayer.loadPlayersForIdentifiers(newMatch!.playerIDs, withCompletionHandler: {(players: [GKPlayer]?, error: NSError?) in
                        if error == nil {
                            self.theMatch = newMatch
                            newMatch!.delegate = self
                            let otherPlayer = players![0]
                            self.otherPlayerName = otherPlayer.displayName!.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "\u{200e}\u{201c}\u{201d}\u{202a}\u{202c}"))
                            self.timedAlert("Successfully reconnected with \(self.otherPlayerName)", seconds: 1.0)
                        } else {
                            self.reconnectFailedAlert()
                        }
                    })
                    //game just resumes where it was!! How convenient!
                } else {
                    self.reconnectFailedAlert()
                }
            })
        }
    }

    func reconnectFailedAlert() {
        let alertView = UIAlertView()
        alertView.title = "Reconnect failed ..."
        alertView.message = "Unable to reconnect the current game.  Do you want to try to reconnect again?"
        alertView.delegate = self
        alertView.addButtonWithTitle("Reconnect")
        alertView.addButtonWithTitle("Cancel")
        alertView.cancelButtonIndex = 1
        alertView.tag = kReconnectAgainAlert
        alertView.show()
    }

    func rematchRequestAlert() {
        let alertView = UIAlertView()
        alertView.title = "Rematch Requested!"
        alertView.message = "\(otherPlayerName) has asked for a rematch.  Do you want to start a new game right now?"
        alertView.delegate = self
        alertView.addButtonWithTitle("Rematch")
        alertView.addButtonWithTitle("No")
        alertView.cancelButtonIndex = 1
        alertView.tag = kRematchRequestAlert
        alertView.show()
    }

    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if alertView.tag == kReconnectAgainAlert {
            if buttonIndex == 1 {   //canceled
                if theMatch != nil {
                    theMatch.disconnect()
                    theMatch = nil
                }
                requestAMatch()
                return
            }
            
            reconnectToMatch(theMatch, playerName: otherPlayerName)
        } else if alertView.tag == kRematchRequestAlert {
            if buttonIndex == 1 {   //canceled
                return
            }

            self.sendStartRematchMessage()
            self.mainViewController?.boardView.initRemoteGame()
            self.mainViewController?.boardView.rematch()
        }
    }

    func disconnectMatch() {
        if theMatch != nil {
            theMatch.disconnect()
        }
    }
}
