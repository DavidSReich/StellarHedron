//
//  HMainViewController.swift
//  Stellar Hedron
//
//  Created by David S Reich on 26/09/2015.
//  Copyright © 2015 Stellar Software Pty Ltd. All rights reserved.
//

import UIKit

class HMainViewController: UIViewController, UITabBarDelegate, UIAlertViewDelegate {

    @IBOutlet weak var outerView: UIView!
    @IBOutlet weak var outerOuterView: UIView!
    @IBOutlet weak var boardContainerView: UIView!
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var newButton: UITabBarItem!
    @IBOutlet weak var rematchButton: UITabBarItem!
    @IBOutlet weak var infoButton: UITabBarItem!
    @IBOutlet weak var confirmMoveButton: UITabBarItem!
    @IBOutlet weak var playerPrompt: UILabel!
    @IBOutlet weak var player1Score: UILabel!
    @IBOutlet weak var player2Score: UILabel!
    @IBOutlet weak var p1ScoreContainer: UIView!

    var boardView: HBoardView!
    var gameCenterManager: HGameCenterManager! = nil

    let kNewGameCommand = 0
    let kRematchCommand = 1
    var firstTime = true

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if firstTime {
            firstTime = false

            tabBar.delegate = self
            gameCenterManager = HGameCenterManager(theViewController: self)

            createBoard()
            boardView.setupPlayers(HBoardView.LocationType.Local, otherPlayerName: nil)
            boardView.setupBoard(self)
            tabBar.tintColor = UIColor.grayColor()
        }
    }

    func createBoard() {
        self.view.clipsToBounds = false
//        print("view.bounds: \(view.bounds)")
//        print("view.frame: \(view.frame)")
//        print("bvbounds: \(boardContainerView.bounds)")
//        print("bvframe: \(boardContainerView.frame)")
        if boardView == nil {
            boardView = HBoardView(frame: boardContainerView.bounds)
            boardContainerView.addSubview(boardView)
            boardView.createBoard(boardContainerView.center)
        }

        let fontSize = floor(27 * boardView.bounds.width / 320)
        playerPrompt.font = UIFont(name: "Trebuchet-BoldItalic", size: fontSize) //adjust font sizes for different screens?
        player1Score.font = UIFont(name: "Verdana-Bold", size: fontSize) //adjust font sizes for different screens?
        player2Score.font = UIFont(name: "Verdana-Bold", size: fontSize) //adjust font sizes for different screens?

        let tHeight = floor(48 * boardView.bounds.width / 320)
        var frameRect = playerPrompt.frame
        playerPrompt.translatesAutoresizingMaskIntoConstraints = true
        playerPrompt.frame = CGRectMake(frameRect.origin.x, frameRect.origin.y, frameRect.width, tHeight)

        let tWidth = floor(64 * boardView.bounds.width / 320)
        frameRect = p1ScoreContainer.frame
        p1ScoreContainer.frame = CGRectMake(frameRect.origin.x, frameRect.origin.y, tWidth, frameRect.height)
        p1ScoreContainer.bounds = CGRectMake(0, 0, tWidth, frameRect.height)

        //this is probably redundant
        playerPrompt.backgroundColor = UIColor(red: 40.0 / 256.0, green: 40.0 / 256.0, blue: 40.0 / 256.0, alpha: 1.0)
        player1Score.backgroundColor = UIColor(red: 40.0 / 256.0, green: 40.0 / 256.0, blue: 40.0 / 256.0, alpha: 1.0)
        player2Score.backgroundColor = UIColor(red: 40.0 / 256.0, green: 40.0 / 256.0, blue: 40.0 / 256.0, alpha: 1.0)
    }

    func setPromptText(prompt: String) {
        playerPrompt.text = prompt
    }

    // MARK: game control mechanics

    func newGame() {
        var actionSheet: UIAlertController
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
            actionSheet = UIAlertController(title: "New Game", message: "Do you want to play?", preferredStyle: UIAlertControllerStyle.Alert)
        } else {
            actionSheet = UIAlertController(title: "New Game", message: "Do you want to play?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        }

        actionSheet.addAction(UIAlertAction(title: "Two Player", style: UIAlertActionStyle.Default, handler: { (action :UIAlertAction!)in
            self.boardView.startLocalGame()
        }))
        actionSheet.addAction(UIAlertAction(title: "You vs. AI", style: UIAlertActionStyle.Default, handler: { (action :UIAlertAction!)in
            self.newAIGame()
        }))
        actionSheet.addAction(UIAlertAction(title: "Two Player OnLine", style: UIAlertActionStyle.Default, handler: { (action :UIAlertAction!)in
            self.gameCenterManager.matchMakerMatchMaker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }

    func newAIGame() {
        var actionSheet: UIAlertController
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
            actionSheet = UIAlertController(title: "Select an AI", message: "Which AI do you want to play against?", preferredStyle: UIAlertControllerStyle.Alert)
        } else {
            actionSheet = UIAlertController(title: "Select an AI", message: "Which AI do you want to play against?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        }

        actionSheet.addAction(UIAlertAction(title: "Very Easy", style: UIAlertActionStyle.Default, handler: { (action :UIAlertAction!)in
            self.startAIGame(0)
        }))
        actionSheet.addAction(UIAlertAction(title: "Easy", style: UIAlertActionStyle.Default, handler: { (action :UIAlertAction!)in
            self.startAIGame(1)
        }))
        actionSheet.addAction(UIAlertAction(title: "Normal", style: UIAlertActionStyle.Default, handler: { (action :UIAlertAction!)in
            self.startAIGame(2)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }

    func startAIGame(strength: Int) {
        boardView.aiStrength = strength
        boardView.startAIGame()
    }

    func rematchGame() {
        if boardView.gameType == HBoardView.LocationType.Remote {
            //ask other player
            gameCenterManager.sendRematchRequestMessage()
            //if the other player wants to rematch then they will start on their system and send a startRematch message.
            return
        }

        boardView.rematch()
    }

    // MARK: UIAlertViewDelegate
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if alertView.tag == kNewGameCommand {
            if buttonIndex == 1 {   //canceled
                return
            }

            newGame()
        } else if alertView.tag == kRematchCommand {
            if buttonIndex == 1 {   //canceled
                return
            }

            rematchGame()
        }
    }

    // MARK: UITabBarDelegate
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        if boardView.insideGame && !boardView.gameOver {
            if item == newButton || item == rematchButton {
                //ask about abandoning game
                //then in completion handler either call newGame, rematchGame, or do nothing

                let alertController = UIAlertController(title: "Stop the current game?", message: "This will stop the current game.  Are you sure you want to start a new game?", preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "New Game", style: UIAlertActionStyle.Default, handler: { (action :UIAlertAction!)in
                    if item == self.newButton {
                        self.newGame()
                    } else if item == self.rematchButton {
                        self.rematchGame()
                    }
                }))
                alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)

                return
            }
        }

        if item == newButton {
            newGame()
        } else if item == rematchButton {
            rematchGame()
        } else if item == confirmMoveButton {
            boardView.playerCommitted()
        } else if item == infoButton {
            performSegueWithIdentifier("InfoViewSegue", sender: self)
        }
    }

    func enableConfirmMoveButton(enabled: Bool) {
        confirmMoveButton.enabled = enabled
    }
}

