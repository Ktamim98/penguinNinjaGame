//
//  GameScene.swift
//  project23
//
//  Created by Tamim Khan on 23/3/23.
//
import AVFoundation
import SpriteKit

enum ForceBomb{
    case never, always, random
}


class GameScene: SKScene {
    var gameScore: SKLabelNode!
    
    
    var score = 0 {
        didSet{
            gameScore.text = "score: \(score)"
        }
    }
    
    var liveImages = [SKSpriteNode]()
    var lives = 3
    
    
    var activeSliceBG: SKShapeNode!
    var activeSliceFG: SKShapeNode!
    
    var activeSlicePoint = [CGPoint]()
    
    var isShooshSoundActive = false
    
    var activeEnemies = [SKSpriteNode]()
    var bombSoundEffect: AVAudioPlayer?
    
    
    override func didMove(to view: SKView) {
        
        let background = SKSpriteNode(imageNamed: "sliceBackground")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -6)
        physicsWorld.speed = 0.85
        
        
        creatScore()
        creatLives()
        creatSlices()
        
        
        
    }
    
    func creatScore(){
        gameScore = SKLabelNode(fontNamed: "Chalkduster")
        gameScore.horizontalAlignmentMode = .left
        gameScore.fontSize = 48
        addChild(gameScore)
        
        
        gameScore.position = CGPoint(x: 8, y: 8)
        score = 0
    }
    
    func creatLives(){
        
        for i in 0..<3{
            let spriteNode = SKSpriteNode(imageNamed: "sliceLife")
            spriteNode.position = CGPoint(x: CGFloat(834 + (i * 70)), y: 720)
            addChild(spriteNode)
            liveImages.append(spriteNode)
            
        }
        
        
    }
    
    
    func creatSlices(){
        
        activeSliceBG = SKShapeNode()
        activeSliceBG.zPosition = 2
        
        activeSliceFG = SKShapeNode()
        activeSliceFG.zPosition = 3
        
        activeSliceBG.strokeColor = UIColor(red: 1, green: 0.9, blue: 0, alpha: 1)
        activeSliceBG.lineWidth = 9
        
        
        activeSliceFG.strokeColor = UIColor.white
        activeSliceFG.lineWidth = 5
        
        
        addChild(activeSliceBG)
        addChild(activeSliceFG)
        
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {return}
        let location = touch.location(in: self)
        activeSlicePoint.append(location)
        redrawActiveSlice()
        
        if !isShooshSoundActive{
            playshooshSound()
        }
        
    }
    
    func playshooshSound(){
        isShooshSoundActive = true
        
        let randomNumber = Int.random(in: 1...3)
        let soundName = "swoosh\(randomNumber).caf"
        
        let swooshSound = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
        
        run(swooshSound){ [weak self] in
            self?.isShooshSoundActive = false
            
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeSliceBG.run(SKAction.fadeOut(withDuration: 0.25))
        activeSliceFG.run(SKAction.fadeOut(withDuration: 0.25))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {return}
        activeSlicePoint.removeAll(keepingCapacity: true)
        
        
        let location = touch.location(in: self)
        activeSlicePoint.append(location)
        
        
        redrawActiveSlice()
        
        
        activeSliceBG.removeAllActions()
        activeSliceFG.removeAllActions()
        
        
        activeSliceBG.alpha = 1
        activeSliceFG.alpha = 1
    }
    
    
    
    
    func redrawActiveSlice(){
        
        if activeSlicePoint.count < 2{
            activeSliceBG.path = nil
            activeSliceFG.path = nil
            return
        }
        
        if activeSlicePoint.count > 12{
            activeSlicePoint.removeFirst(activeSlicePoint.count - 12)
        }
        
        let path = UIBezierPath()
        path.move(to: activeSlicePoint[0])
        
        
        for i in 1..<activeSlicePoint.count {
            path.addLine(to: activeSlicePoint[i])
        }
        
        activeSliceBG.path = path.cgPath
        activeSliceFG.path = path.cgPath
        
        
        
    }
    
    func creatEnemy(forceBomb: ForceBomb = .random){
        let enemy: SKSpriteNode
        
        var enemyType = Int.random(in: 0...6)
        
        if forceBomb == .never {
            enemyType = 1
        }else if forceBomb == .always {
            enemyType = 0
        }
        
        if enemyType == 0{
            enemy = SKSpriteNode()
            enemy.zPosition = 1
            enemy.name = "bombContainer"
            
            
            let bombImage = SKSpriteNode(imageNamed: "sliceBomb")
            bombImage.name = "bomb"
            enemy.addChild(bombImage)
            
            if bombSoundEffect != nil{
                bombSoundEffect?.stop()
                bombSoundEffect = nil
            }
            
            if let path = Bundle.main.url(forResource: "sliceBombFuse", withExtension: "caf"){
                if let sound = try? AVAudioPlayer(contentsOf: path){
                bombSoundEffect = sound
                sound.play()
            }
            }
            
            if let emitter = SKEmitterNode(fileNamed: "sliceFuse"){
                emitter.position = CGPoint(x: 76, y: 64)
                enemy.addChild(emitter)
            }
                
            
            
            
            
        }else{
            enemy = SKSpriteNode(imageNamed: "penguin")
            run(SKAction.playSoundFileNamed("launch.caf", waitForCompletion: false))
            
            enemy.name = "enemy"
        }
        
        let randomPosition = CGPoint(x: Int.random(in: 64...960), y: -128)
        enemy.position = randomPosition
        
        
        let randomAunglarVelocity = CGFloat.random(in: -3...3)
        let randomXvelocity: Int
        
        if randomPosition.x < 256{
            randomXvelocity = Int.random(in: 8...15)
        }else if randomPosition.x < 512{
            randomXvelocity = Int.random(in: 3...5)
        }else if randomPosition.x < 768{
            randomXvelocity = -Int.random(in: 3...5)
        }else {
            randomXvelocity = -Int.random(in: 8...15)
        }
        
        let randomYvelocity = Int.random(in: 24...32)
        
        
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: 64)
        enemy.physicsBody?.velocity = CGVector(dx: randomXvelocity * 40, dy: randomYvelocity * 40)
        enemy.physicsBody?.angularVelocity = randomAunglarVelocity
        enemy.physicsBody?.collisionBitMask = 0
        
        
        
        
        addChild(enemy)
        activeEnemies.append(enemy)
        
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        var bombCount = 0
        
        for node in activeEnemies {
            if node.name == "bombContainer" {
                bombCount += 1
                break
            }
        }
        
        if bombCount == 0 {
            bombSoundEffect?.stop()
            bombSoundEffect = nil
        }
        
    }
    
    
}
