//
//  GameScene.swift
//  Money Hunter
//
//  Created by Osman Dönmez on 28.11.2018.
//  Copyright © 2018 Osman Dönmez. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var moneyMan : SKSpriteNode?
    var ground : SKSpriteNode?
    var ceil : SKSpriteNode?
    
    var scoreLabel: SKLabelNode?
    var highestScoreLabel : SKLabelNode?
    var yourScoreLabel : SKLabelNode?
    var gameOverLabel : SKLabelNode?
    
    var moneyTimer = Timer()
    var copTimer = Timer()
    var bonusTimer = Timer()

    var soundNode: SKAudioNode?
    var soundController : SKSpriteNode?
    var musicIsOn = true
    var moneySound: AVAudioPlayer!
    var bonusSound: AVAudioPlayer!
    var gameOverSound: AVAudioPlayer!
    var gameMusic: AVAudioPlayer!
    
    
    var score = 0
    var highestScore = 0
    var moneyLeftDuration: Double = 4
    var copLeftDuration: Double = 4
    
    let moneyManCategory : UInt32 = 0x1 << 1
    let moneyCategory : UInt32 = 0x1 << 2
    let copCategory : UInt32 = 0x1 << 3
    let groundAndCeilCategory : UInt32 = 0x1 << 4
    let bonusCategory : UInt32 = 0x1 << 5
    
    
    override func didMove(to view: SKView) {
        
        physicsWorld.contactDelegate = self
        
        soundController = childNode(withName: "soundController") as? SKSpriteNode
        
        
        moneyMan = childNode(withName: "moneyMan") as? SKSpriteNode
        moneyMan?.physicsBody?.categoryBitMask = moneyManCategory
        moneyMan?.physicsBody?.contactTestBitMask = moneyCategory | copCategory
        moneyMan?.physicsBody?.collisionBitMask = groundAndCeilCategory
        var moneyManRun : [SKTexture] = []
        for number in 1...6 {
            moneyManRun.append(SKTexture(imageNamed: "frame-\(number)"))
        }
        moneyMan?.run(SKAction.repeatForever(SKAction.animate(with: moneyManRun, timePerFrame: 0.1)))
        
        ceil = childNode(withName: "ceil") as? SKSpriteNode
        ceil?.physicsBody?.categoryBitMask = groundAndCeilCategory
        ceil?.physicsBody?.collisionBitMask = moneyManCategory
        
        scoreLabel = childNode(withName: "scoreLabel") as? SKLabelNode
        highestScoreLabel = childNode(withName: "highestScore") as? SKLabelNode
        
        soundNode = childNode(withName: "soundNode") as? SKAudioNode

        
        guard let coinPath = Bundle.main.path(forResource: "coin", ofType: "wav") else { return }
        let coinUrl = URL(fileURLWithPath: coinPath)
        do {
            moneySound = try AVAudioPlayer(contentsOf: coinUrl)
            moneySound.prepareToPlay()
        } catch let error as NSError {
            print(error.description)
        }
        
        guard let bonusPath = Bundle.main.path(forResource: "bonus", ofType: "wav") else { return }
        let bonusUrl = URL(fileURLWithPath: bonusPath)
        do {
            bonusSound = try AVAudioPlayer(contentsOf: bonusUrl)
            bonusSound.prepareToPlay()
        } catch let error as NSError {
            print(error.description)
        }
        
        guard let gameOverPath = Bundle.main.path(forResource: "game-over", ofType: "wav") else { return }
        let gameOverUrl = URL(fileURLWithPath: gameOverPath)
        do {
            gameOverSound = try AVAudioPlayer(contentsOf: gameOverUrl)
            gameOverSound.prepareToPlay()
        } catch let error as NSError {
            print(error.description)
        }
        
        createGrass()
        startTimers()
    }
    
    func startTimers() {
        print("Start timers!")
        moneyTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(GameScene.createMoney), userInfo: nil, repeats: true)
        copTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(GameScene.createCop), userInfo: nil, repeats: true)
        let bonusTimeInterval = 50 - arc4random_uniform(42)
        bonusTimer = Timer.scheduledTimer(timeInterval: TimeInterval(bonusTimeInterval), target: self, selector: #selector(GameScene.createBonus), userInfo: nil, repeats: true)
    }
    
    func stopTimers() {
        moneyTimer.invalidate()
        copTimer.invalidate()
        bonusTimer.invalidate()
    }
    
    func createGrass() {
        let sizingGrass = SKSpriteNode(imageNamed: "grass")
        let numberOfGrass = Int(size.width / sizingGrass.size.width) + 1
        for number in 0...numberOfGrass {
            let grass = SKSpriteNode(imageNamed: "grass")
            grass.physicsBody = SKPhysicsBody(rectangleOf: grass.size)
            grass.physicsBody?.categoryBitMask = groundAndCeilCategory
            grass.physicsBody?.collisionBitMask = moneyManCategory
            grass.physicsBody?.affectedByGravity = false
            grass.physicsBody?.isDynamic = false
            addChild(grass)
            
            let grassX = -size.width / 2 + grass.size.width / 2 + grass.size.width * CGFloat(number)
            let grassY = -size.height / 2 + grass.size.height / 2 - 16
            grass.position = CGPoint(x: grassX, y: grassY)
            
            let speed = 100.0
            let firstMoveLeft = SKAction.moveBy(x: -grass.size.width - grass.size.width * CGFloat(number), y: 0, duration: TimeInterval(grass.size.width + grass.size.width * CGFloat(number)) / speed)
            
            let resetGrass = SKAction.moveBy(x: size.width + grass.size.width, y: 0, duration: 0)
            let grassFullMove = SKAction.moveBy(x: -size.width - grass.size.width, y: 0, duration: TimeInterval(size.width + grass.size.width) / speed)
            let grassMovingForever = SKAction.repeatForever(SKAction.sequence([grassFullMove, resetGrass]))
            grass.run(SKAction.sequence([firstMoveLeft, resetGrass, grassMovingForever]))
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        if scene?.isPaused != true {
        moneyMan?.physicsBody?.applyForce(CGVector(dx: 0, dy: 80000))
        }
        
        let touch = touches.first
        if let location = touch?.location(in: self) {
            let theNodes = nodes(at: location)
            for node in theNodes {
                if node.name == "playButton" {
                    // restart the game
                    gameOverSound.pause()
                    if musicIsOn == false {
                        soundNode?.run(SKAction.pause())
                    }
                    moneyLeftDuration = 4
                    copLeftDuration = 4
                    score = 0
                    scoreLabel?.text = "Score: \(score)"
                    node.removeFromParent()
                    gameOverLabel?.removeFromParent()
                    yourScoreLabel?.removeFromParent()
                    scene?.isPaused = false
                    startTimers()
                }
                if node.name == "soundController" {
                    if musicIsOn == true {
                        musicIsOn = false
                        soundController?.texture = SKTexture(imageNamed: "soundOff")
                        soundNode?.run(SKAction.pause())
                    } else {
                        musicIsOn = true
                        soundController?.texture = SKTexture(imageNamed: "soundOn")
                        soundNode?.run(SKAction.play())
                    }
                }
            }
        }
    }
    
    @objc func createMoney() {
        let money = SKSpriteNode(imageNamed: "money-bag")
        money.physicsBody = SKPhysicsBody(rectangleOf: money.size)
        money.physicsBody?.affectedByGravity = false
        money.physicsBody?.categoryBitMask = moneyCategory
        money.physicsBody?.contactTestBitMask = moneyManCategory
        money.physicsBody?.collisionBitMask = 0
        addChild(money)
        
        let sizingGrass = SKSpriteNode(imageNamed: "grass")
        let maxY = size.height / 2 - money.size.height / 2
        let minY = -size.height / 2 + money.size.height / 2 + sizingGrass.size.height
        let range = maxY - minY
        let moneyY = maxY - CGFloat(arc4random_uniform(UInt32(range)))
        
        money.position = CGPoint(x: size.width / 2 + money.size.width / 2, y: moneyY)
        
        if score >= 100 && score < 200 {
            moneyLeftDuration = 3
            copLeftDuration = 3
        } else if score >= 200 {
            moneyLeftDuration = 2.5
            copLeftDuration = 2.5
        }
        
        let moveLeft = SKAction.moveBy(x: -(size.width + money.size.width / 2), y: 0, duration: moneyLeftDuration)
        
        money.run(SKAction.sequence([moveLeft, SKAction.removeFromParent()]))
    }
    
    @objc func createBonus() {
        let bonus = SKSpriteNode(imageNamed: "bonus")
        bonus.physicsBody = SKPhysicsBody(rectangleOf: bonus.size)
        bonus.physicsBody?.affectedByGravity = false
        bonus.physicsBody?.categoryBitMask = bonusCategory
        bonus.physicsBody?.contactTestBitMask = moneyManCategory
        bonus.physicsBody?.collisionBitMask = 0
        addChild(bonus)
        
        let sizingGrass = SKSpriteNode(imageNamed: "grass")
        let maxY = size.height / 2 - bonus.size.height / 2
        let minY = -size.height / 2 + bonus.size.height / 2 + sizingGrass.size.height
        let range = maxY - minY
        let bonusY = maxY - CGFloat(arc4random_uniform(UInt32(range)))
        
        bonus.position = CGPoint(x: size.width / 2 + bonus.size.width / 2, y: bonusY)
        
        let moveLeft = SKAction.moveBy(x: -(size.width + bonus.size.width / 2), y: 0, duration: 2.5)
        
        bonus.run(SKAction.sequence([moveLeft, SKAction.removeFromParent()]))
    }
    
    @objc func createCop() {
        let cop = SKSpriteNode(imageNamed: "police-car")
        cop.physicsBody = SKPhysicsBody(rectangleOf: cop.size)
        cop.physicsBody?.affectedByGravity = false
        cop.physicsBody?.categoryBitMask = copCategory
        cop.physicsBody?.contactTestBitMask = moneyManCategory
        cop.physicsBody?.collisionBitMask = 0
        addChild(cop)
        
        let sizingGrass = SKSpriteNode(imageNamed: "grass")
        let maxY = size.height / 2 - cop.size.height / 2
        let minY = -size.height / 2 + cop.size.height / 2 + sizingGrass.size.height
        let range = maxY - minY
        let copY = maxY - CGFloat(arc4random_uniform(UInt32(range)))
        
        cop.position = CGPoint(x: size.width / 2 + cop.size.width / 2, y: copY)
        
        if score >= 100 && score < 200 {
            copLeftDuration = 3
        } else if score >= 200 {
            copLeftDuration = 2.5
        }
        
        let moveLeft = SKAction.moveBy(x: -(size.width + cop.size.width / 2), y: 0, duration: copLeftDuration)
        
        cop.run(SKAction.sequence([moveLeft, SKAction.removeFromParent()]))
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        if contact.bodyA.categoryBitMask == moneyCategory {
            moneySound.play()
            contact.bodyA.node?.removeFromParent()
            score += 1
            scoreLabel?.text = "Score: \(score)"
        }
        if contact.bodyB.categoryBitMask == moneyCategory {
            moneySound.play()
            contact.bodyB.node?.removeFromParent()
            score += 1
            scoreLabel?.text = "Score: \(score)"
        }
        
        if contact.bodyA.categoryBitMask == bonusCategory {
            bonusSound.play()
            contact.bodyA.node?.removeFromParent()
            score += 10
            scoreLabel?.text = "Score: \(score)"
        }
        if contact.bodyB.categoryBitMask == bonusCategory {
            bonusSound.play()
            contact.bodyB.node?.removeFromParent()
            score += 10
            scoreLabel?.text = "Score: \(score)"
        }
        
        if contact.bodyA.categoryBitMask == copCategory {
            contact.bodyA.node?.removeFromParent()
            gameOver()
            
        }
        if contact.bodyB.categoryBitMask == copCategory {
            contact.bodyB.node?.removeFromParent()
            gameOver()
        }
        
    }
    
    func gamePaused() {
        
    }
    
    func gameOver() {
        scene?.isPaused = true
        moneySound.pause()
        bonusSound.pause()
        gameOverSound.play()
        stopTimers()
        
        yourScoreLabel = SKLabelNode(text: "Your Score: \(score)")
        yourScoreLabel?.position = CGPoint(x: 0, y: 25)
        yourScoreLabel?.fontSize = 50
        if yourScoreLabel != nil {
          addChild(yourScoreLabel!)
        }
        
        gameOverLabel = SKLabelNode(text: "GAME OVER!")
        gameOverLabel?.position = CGPoint(x: 0, y: 100)
        gameOverLabel?.fontSize = 100
        if gameOverLabel != nil {
           addChild(gameOverLabel!)
        }
       
        let playButton = SKSpriteNode(imageNamed: "play")
        playButton.position = CGPoint(x: 0, y: -200)
        playButton.name = "playButton"
        addChild(playButton)
        
        if score > highestScore {
            highestScore = score
            highestScoreLabel?.text = "Highest Score: \(highestScore)"
        }
        
    }

}

