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

enum SequenceType: CaseIterable{
    case oneNoBomb, one, twoWithOneBomb, two, three, four, chain, fastChain
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
    
    
    
    var popUpTime = 0.9
    var sequence = [SequenceType]()
    var sequencePosition = 0
    var chainDelay = 3.0
    var nextSequenceQueued = true
    
    
    var isGameEnded = false
    
    
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
        
        
        sequence = [.oneNoBomb, .oneNoBomb, .twoWithOneBomb, .twoWithOneBomb, .three, .one, .chain]
        
        
        for _ in 0...1000 {
            if let nextSequence = SequenceType.allCases.randomElement(){
                sequence.append(nextSequence)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {[weak self] in
            self?.tossEnemy()
        }
        
        
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
        
        if isGameEnded {
            return
        }
        
        guard let touch = touches.first else {return}
        let location = touch.location(in: self)
        activeSlicePoint.append(location)
        redrawActiveSlice()
        
        if !isShooshSoundActive{
            playshooshSound()
        }
        
        
        let nodesAtPoint = nodes(at: location)
        
        for case let node as SKSpriteNode in nodesAtPoint {
            if node.name == "enemy"{
                
                if let emitter = SKEmitterNode(fileNamed: "sliceHitEnemy"){
                    emitter.position = node.position
                    addChild(emitter)
                }
                node.name = ""
                
                node.physicsBody?.isDynamic = false
                
                let scaleOut = SKAction.scale(to: 0.001, duration: 0.2)
                let fadeOut = SKAction.fadeOut(withDuration: 0.2)
                let group = SKAction.group([scaleOut, fadeOut])
                
                
                let seq = SKAction.sequence([group, .removeFromParent()])
                node.run(seq)
                
                
                score += 1
                
                if let index = activeEnemies.firstIndex(of: node){
                    activeEnemies.remove(at: index)
                }
                
                
                run(SKAction.playSoundFileNamed("whack.caf", waitForCompletion: false))
                
            } else if node.name == "bomb" {
                
                guard let bombContainer = node.parent as? SKSpriteNode else {continue}
                
                
                if let emitter = SKEmitterNode(fileNamed: "sliceHitBomb"){
                    emitter.position = bombContainer.position
                    addChild(emitter)
                }
                
                
                node.name = ""
                
               bombContainer.physicsBody?.isDynamic = false
                
                let scaleOut = SKAction.scale(to: 0.001, duration: 0.2)
                let fadeOut = SKAction.fadeOut(withDuration: 0.2)
                let group = SKAction.group([scaleOut, fadeOut])
                
                let seq = SKAction.sequence([group, .removeFromParent()])
                bombContainer.run(seq)
                
                
                if let index = activeEnemies.firstIndex(of: bombContainer){
                    activeEnemies.remove(at: index)
                }
                
                
                run(SKAction.playSoundFileNamed("explosion.caf", waitForCompletion: false))
                
                endGame(triggeredByBomb: true)
                
                
            }
        }
        
        
        
        
    }
    
    func endGame(triggeredByBomb: Bool){
        if isGameEnded {
            return
        }
        
        isGameEnded = true
        physicsWorld.speed = 0
        isUserInteractionEnabled = false
        
        bombSoundEffect?.stop()
        bombSoundEffect = nil
        
        if triggeredByBomb{
            
            liveImages[0].texture = SKTexture(imageNamed: "sliceLifeGone")
            liveImages[1].texture = SKTexture(imageNamed: "sliceLifeGone")
            liveImages[2].texture = SKTexture(imageNamed: "sliceLifeGone")
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
    
    func  subtractLife(){
        
        lives -= 1
        
        
        run(SKAction.playSoundFileNamed("wrong.caf", waitForCompletion: false))
        
        var life: SKSpriteNode
        
        if lives == 2 {
            life = liveImages[0]
        }else if lives == 1{
            life = liveImages[1]
        }else {
            life = liveImages[2]
            endGame(triggeredByBomb: false)
        }
        
        life.texture = SKTexture(imageNamed: "sliceLifeGone")
        
        
        life.xScale = 1.3
        life.yScale = 1.3
        life.run(SKAction.scale(to: 1, duration: 0.1))
        
        
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        if activeEnemies.count > 0 {
            for (index, node) in activeEnemies.enumerated().reversed(){
                if node.position.y < -140{
                    node.removeAllActions()
                    
                    if node.name == "enemy"{
                        node.name = ""
                        subtractLife()
                        
                        node.removeFromParent()
                        activeEnemies.remove(at: index)
                    }else if node.name == "bombContainer"{
                        node.name = ""
                        node.removeFromParent()
                        activeEnemies.remove(at: index)
                    }
                }
            }
            
        }else{
            if !nextSequenceQueued {
                DispatchQueue.main.asyncAfter(deadline: .now() + popUpTime) {[weak self] in
                    self?.tossEnemy()
                }
                nextSequenceQueued = true
            }
            
        }
        
        
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
    
    func tossEnemy(){
        
        if isGameEnded {
            return
        }
        
        popUpTime *= 0.991
        chainDelay *= 0.99
        physicsWorld.speed *= 1.02
        
        
        
        let sequenceType = sequence[sequencePosition]
        
        
        switch sequenceType {
        case .oneNoBomb:
            creatEnemy(forceBomb: .never)
            
        case .one:
            creatEnemy()
            
            
        case .twoWithOneBomb:
            creatEnemy(forceBomb: .never)
            creatEnemy(forceBomb: .always)
            
            
        case .two:
            creatEnemy()
            creatEnemy()
            
            
        case .three:
            
            creatEnemy()
            creatEnemy()
            creatEnemy()
            
        case .four:
            
            creatEnemy()
            creatEnemy()
            creatEnemy()
            creatEnemy()
            
        case .chain:
            creatEnemy()
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0)) { [weak self] in self?.creatEnemy()}
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0 * 2)) { [weak self] in self?.creatEnemy()}
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0 * 3)) { [weak self] in self?.creatEnemy()}
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0 * 4)) { [weak self] in self?.creatEnemy()}
            
            
        case .fastChain:
            creatEnemy()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0)) { [weak self] in self?.creatEnemy()}
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0 * 2)) { [weak self] in self?.creatEnemy()}
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0 * 3)) { [weak self] in self?.creatEnemy()}
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0 * 4)) { [weak self] in self?.creatEnemy()}
            
            
            
            
        }
        
        sequencePosition += 1
        nextSequenceQueued = false
    }
    
    
    
    
    
}
