//
//  SKPlayScene.m
//  SKOctagonSample
//
//  Created by FumikoYamamoto on 2016/01/23.
//  Copyright © 2016年 FumikoYamamoto. All rights reserved.
//


//ビットマスク...あるビットをオンしたりオフしたりするために用いられるパターン
#import "SKPlayScene.h"
#import "YMCPhysicsDebugger.h"


//static const は定数(変数じゃないやつ)/そのクラス内で使われる
//UInt32であるため、最大で32種類までしか種類を指定出来ない
static const uint32_t paddleCategory = 0x1 << 0; //0だよ
static const uint32_t ballCategorySKPhysics = 0x1 << 1; //1だよ

/*
 パドルをあれして透明にして反射させる
 SKscene自体を正方形にしたら跳ね返るのではないのではないかと思ったよ
 viewにSKsceneつけられるかどうか、SKの中で判定している変数をラベル(UIView上)に反映させられるか
 
 今日やること
 ななめの跳ね返りをどうやって
 ジェスチャーをつける
 OCTAGONにボードだけ組み込む or spritekitの方にラベルをつける

 */

@interface SKPlayScene() <SKPhysicsContactDelegate>


@end
@implementation SKPlayScene{
    SKSpriteNode *paddle;
    SKSpriteNode *maru;
    SKSpriteNode *diagonalPaddle;
    SKAction * transform;
}

- (id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    if (self) {
        [YMCPhysicsDebugger init];
        [self makeBoard];
        /* ボールがなければボールを生成
        if (![self ballNode]) [self addBall]; */
        [self addBall];
        [self addPaddle];
        [self drawPhysicsBodies];
        //physicsBodyを設定する/重力が使えるようになる
        self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
        self.physicsWorld.contactDelegate = self;  //物理演算をselfの中でやるよ。これがないとdelegateを使えない
            }
    return self;
}

/*
 - (SKNode *)ballNode {
 return [self childNodeWithName:@"ball"];
 }
 */

- (void) makeBoard{
    SKSpriteNode *gameBoard = [SKSpriteNode spriteNodeWithImageNamed:@"gameView_board"];
    //    gameBoard.frame = CGRectMake(0, 124, 320, 320);
    gameBoard.position = CGPointMake(0 +160, 124 +160);
    gameBoard.size = CGSizeMake(320, 320);
    [self addChild:gameBoard];
}


static NSDictionary *config = nil;
+ (void)initialize {
    //設定を読み込んで、static変数configに保持
    //main bundle = SKSampleのバンドル config.jsonの内容を文字列で持ってきて、pathにしますよ
    NSString *path = [[NSBundle mainBundle] pathForResource:@"config" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!config) {
        config = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    }
}

# pragma mark - Ball

- (void)addBall {
    int random = (int)arc4random_uniform(4);
    if(random == 1){
        maru = [SKSpriteNode spriteNodeWithImageNamed:@"maru_blue"];
    }else if (random == 2){
        maru = [SKSpriteNode spriteNodeWithImageNamed:@"maru_pink_low"];
    }else if (random == 3){
        maru = [SKSpriteNode spriteNodeWithImageNamed:@"maru_yellow_low"];
    }else if (random == 0){
        maru = [SKSpriteNode spriteNodeWithImageNamed:@"maru_green_low"];
    }
    [self maruSetting];
    [self addChild:maru];
}

- (void) maruSetting{
    //config.jsonにある重力の大きさの値
    CGFloat velocityX = [config[@"maru"][@"velocity"][@"x"] floatValue]; //このふたつの値を変えることでスピードを調整できる
    CGFloat velocityY = [config[@"maru"][@"velocity"][@"y"] floatValue];
    maru.name = @"maru";
    maru.position = CGPointMake(0 +160, 124 +160);
    maru.size = CGSizeMake(50, 50);
    
    //physicsBodyを使うことで重力環境になり、衝突が可能になる
    maru.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:maru.size];
    //    maru.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:radius]; //円形の物理体を生成
    maru.physicsBody.affectedByGravity = NO;  //ボールは固定はしないけど、重力を無視するため/重力の影響を受けるかどうか
    maru.physicsBody.velocity = CGVectorMake(velocityX, velocityY);  //velocityで力を加えてる/加える力の大きさ
    maru.physicsBody.restitution = 1.0f; //a反発係数を1に
    maru.physicsBody.linearDamping = 0.0;  //b空気抵抗を0
    maru.physicsBody.friction = 0.0;       //c摩擦を0...b.cによって跳ね返り(a)を一定に保つ
    maru.physicsBody.allowsRotation = NO;
//    maru.physicsBody.angularDamping = 0.0; //回転による抵抗を0に
    maru.physicsBody.usesPreciseCollisionDetection = YES;  //yesで衝突判定が可能に
    maru.physicsBody.categoryBitMask = ballCategorySKPhysics;       //categoryBitMaskを指定
    maru.physicsBody.contactTestBitMask = paddleCategory;  //contact(跳ね返り)の対象としてpaddleを指定
    maru.physicsBody.collisionBitMask = paddleCategory; //collision(衝突)の対象としてpaddlを指定
}


# pragma mark - Paddle
- (void)addPaddle {
    [self leftdownPaddle]; //ななめのやつたす
    [self leftUpPaddle];
    [self rightUpPaddle];
    [self rightDownPaddle];
    
    
    [self paddleSetting];
    paddle.position = CGPointMake(160, 440);
    [self addChild:paddle];
    [self addSecondPaddle];
}

- (void)addSecondPaddle{
    [self paddleSetting];
    paddle.position = CGPointMake(160, 129);
    [self addChild:paddle];
}

- (void)paddleSetting{
    CGFloat width = [config[@"paddle"][@"width"] floatValue];
    CGFloat height = [config[@"paddle"][@"height"] floatValue];
    //    CGFloat y = [config[@"paddle"][@"y"] floatValue];
    paddle = [SKSpriteNode spriteNodeWithColor:[SKColor brownColor] size:CGSizeMake(width, height)];
    paddle.alpha = 0.0; //隠す
    paddle.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:paddle.size];
    paddle.physicsBody.usesPreciseCollisionDetection = YES;  //yesで衝突判定が可能に
    paddle.physicsBody.dynamic = NO;
    paddle.physicsBody.categoryBitMask = paddleCategory;
    paddle.physicsBody.collisionBitMask = ballCategorySKPhysics;
    paddle.name = @"paddle";
}

- (void)diagonalPaddleSetting{
    diagonalPaddle = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeMake(150, 150)];
    diagonalPaddle.alpha = 0.0;
    diagonalPaddle.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:diagonalPaddle.size];
    diagonalPaddle.physicsBody.usesPreciseCollisionDetection = YES;  //yesで衝突判定が可能に
    diagonalPaddle.physicsBody.dynamic = NO;
    diagonalPaddle.physicsBody.categoryBitMask = paddleCategory;
    diagonalPaddle.physicsBody.collisionBitMask = ballCategorySKPhysics;
    diagonalPaddle.name = @"diagonalPaddle";
    
    transform =  [SKAction rotateToAngle:45.0 / 180.0 * M_PI duration:0.1]; // 反時計回りに回転、最終角度は45度
    [diagonalPaddle runAction:transform];
    
    [self addChild:diagonalPaddle];
}

- (void)leftdownPaddle{
    [self diagonalPaddleSetting];
    diagonalPaddle.position = CGPointMake(0, 110);
}
- (void)rightDownPaddle{
    [self diagonalPaddleSetting];
    diagonalPaddle.position = CGPointMake(320, 110);
}
- (void)rightUpPaddle{
    [self diagonalPaddleSetting];
    diagonalPaddle.position = CGPointMake(320, 455);
}
- (void)leftUpPaddle{
    [self diagonalPaddleSetting];
    diagonalPaddle.position = CGPointMake(0, 455);
}

- (SKNode *)paddleNode {
    return [self childNodeWithName:@"paddle"];
}


# pragma mark - Touch

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    //タッチした場所を取得
    UITouch *touch = [touches anyObject];
    CGPoint locaiton = [touch locationInNode:self];

    [self addBall];
}




# pragma mark - SKPhysicsContactDelegate

- (void)didBeginContact:(SKPhysicsContact *)contact {
    SKPhysicsBody *firstBody, *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    } else {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    /*
    if (firstBody.categoryBitMask & blockCategory) {
        if (secondBody.categoryBitMask & ballCategory) {
            [self decreaseBlockLife:firstBody.node];
        }
    }
     */
}


@end
