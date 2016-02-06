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
 ___done___ななめの跳ね返りをどうやって
 ジェスチャーをつける
 OCTAGONにボードだけ組み込む or spritekitの方にラベルをつける
 
 View自体にジェスチャーの判定をつける
 押したところにmaruがあればスワイプを呼ぶ
 maruは一度スワイプされたらもう呼ばれないように
 */

@interface SKPlayScene() <SKPhysicsContactDelegate>

@end
@implementation SKPlayScene {
    SKSpriteNode *paddle;
    SKSpriteNode *maru;
    SKSpriteNode *diagonalPaddle;
    SKAction * transform;
    CGFloat velocityX;
    CGFloat velocityY;
    
    SKSpriteNode * gestureView;
}

- (id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    if (self) {
        //        [YMCPhysicsDebugger init]; //これをONすれば物理演算をのせるものに赤い線が出てデバッグできる
        [self makeBoard];
        /* ボールがなければボールを生成
         if (![self ballNode]) [self addBallSetting]; */
        [self addGestureView];
        [self leftUpBall];
        [self leftDownBall];
        [self rightDownBall];
        [self rightUpBall];
        [self addPaddle];
        [self drawPhysicsBodies];
        //physicsBodyを設定する/重力が使えるようになる
        self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
        self.physicsWorld.contactDelegate = self;  //物理演算をselfの中でやるよ。これがないとdelegateを使えない
    }
    
    return self;
}

- (void)addGestureView {
    gestureView = [SKSpriteNode spriteNodeWithColor:[SKColor brownColor] size:CGSizeMake(320, 568)];
    gestureView.position = CGPointMake(568/2,320/2);
    gestureView.userInteractionEnabled = YES;
    SKAction * transform45 =  [SKAction rotateToAngle:M_PI/4 duration:0.1]; // 反時計回りに回転、最終角度は45度
    [gestureView runAction:transform45];
    [self addChild:gestureView];
}

- (void)didMoveToView:(SKView *)view {
    
    //左
    UISwipeGestureRecognizer *swipeLeft=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipe:)];
    swipeLeft.direction= UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeLeft];
    //右t
    UISwipeGestureRecognizer *swipeRight=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipe:)];
    swipeRight.direction= UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRight];
    //上
    UISwipeGestureRecognizer *swipeUp=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipe:)];
    swipeUp.direction= UISwipeGestureRecognizerDirectionUp;
    [self.view addGestureRecognizer:swipeUp];
    //下
    UISwipeGestureRecognizer *swipeDown=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipe:)];
    swipeDown.direction= UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeDown];

}

/*
 - (SKNode *)ballNode {
 return [self childNodeWithName:@"ball"];
 }
 */

- (void)swipe:(UISwipeGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:[recognizer view]];
    CGPoint skPoint = [recognizer locationInView:[recognizer view]];
    skPoint.y = 568- point.y;  //CGPointの(0,0)とSK内での(0,0)が相違しているため
    
    //得られた位置にあるlayerを取得
    SKNode *node = [self nodeAtPoint:skPoint];
    // CALayer *layer = [[recognizer view].layer hitTest:point];
    NSLog(@"layer class is ... %@",node);
    
    if ([node.class isSubclassOfClass:[SKSpriteNode class]] && node.name != NULL) {
        NSLog(@"うごかすのはこいつです %@", node);
        if (recognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
            [self leftUpBallPhysics:node];
        }else if(recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
            [self rightDownBallPhysics:node];
        }else if(recognizer.direction == UISwipeGestureRecognizerDirectionUp) {
            [self rightUpBallPhysics:node];
        }else if(recognizer.direction == UISwipeGestureRecognizerDirectionDown) {
            [self leftDownBallPhysics:node];
        }
    }
    /*
    if (node == maru) {
        if (recognizer.state == UIGestureRecognizerStateBegan)
            NSLog(@"start coordinates: %@", NSStringFromCGPoint(point));
        [self leftUpBallPhysics];
    }
     */

}



- (void)makeBoard {
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

- (void)leftUpBall {
    [self ballSetting];
    maru.position = CGPointMake(160 -27, 124+160 +28);
    [gestureView addChild:maru];
}
- (void)leftDownBall {
    [self ballSetting];
    maru.position = CGPointMake(160 -27, 124+160 -28);
    [gestureView addChild:maru];
}
- (void)rightUpBall {
    [self ballSetting];
    maru.position = CGPointMake(160 +27, 124+160 +28);
    [gestureView addChild:maru];
}
- (void)rightDownBall{
    [self ballSetting];
    maru.position = CGPointMake(160 +27, 124+160 -28);
    [gestureView addChild:maru];
}

- (void)ballSetting {
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
    maru.name = @"maru";
//    maru.position = CGPointMake(0 +160, 124 +160);
    maru.size = CGSizeMake(50, 50);
}

- (void)ballPhysicsSetting:(SKNode *)node {
    //config.jsonにある重力の大きさの値
    velocityX = [config[@"maru"][@"velocity"][@"x"] floatValue]; //このふたつの値を変えることでスピードを調整できる
    velocityY = [config[@"maru"][@"velocity"][@"y"] floatValue];
    
    //physicsBodyを使うことで重力環境になり、衝突が可能になる
    node.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:maru.size];
    node.physicsBody.affectedByGravity = NO;  //ボールは固定はしないけど、重力を無視するため/重力の影響を受けるかどうか
    node.physicsBody.restitution = 1.0f; //a反発係数を1に
    node.physicsBody.linearDamping = 0.0;  //b空気抵抗を0
    node.physicsBody.friction = 0.0;       //c摩擦を0...b.cによって跳ね返り(a)を一定に保つ
    node.physicsBody.allowsRotation = NO;  //回転しないように
    //    maru.physicsBody.angularDamping = 0.0; //回転による抵抗を0に
    node.physicsBody.usesPreciseCollisionDetection = YES;  //yesで衝突判定が可能に
    node.physicsBody.categoryBitMask = ballCategorySKPhysics;       //categoryBitMaskを指定
    node.physicsBody.contactTestBitMask = paddleCategory;  //contact(跳ね返り)の対象としてpaddleを指定
    node.physicsBody.collisionBitMask = paddleCategory; //collision(衝突)の対象としてpaddlを指定
}

- (void)rightUpBallPhysics:(SKNode *)node {
    [self ballPhysicsSetting:node];
    node.physicsBody.velocity = CGVectorMake(velocityX, velocityY);  //velocityで力を加えてる/加える力の大きさ
}
- (void)rightDownBallPhysics:(SKNode *)node {
    [self ballPhysicsSetting:node];
    node.physicsBody.velocity = CGVectorMake(velocityX, -velocityY);
}
- (void)leftUpBallPhysics:(SKNode *)node {
    [self ballPhysicsSetting:node];
    node.physicsBody.velocity = CGVectorMake(-velocityX, velocityY);
}
- (void)leftDownBallPhysics:(SKNode *)node {
    [self ballPhysicsSetting:node];
    node.physicsBody.velocity = CGVectorMake(-velocityX, -velocityY);
}

# pragma mark - Paddle
- (void)addPaddle {
    [self leftdownPaddle]; //ななめのやつを足す
    [self leftUpPaddle];
    [self rightUpPaddle];
    [self rightDownPaddle];
    
    //上のパドルを生成
    [self paddleSetting];
    paddle.position = CGPointMake(160, 440);
    [self addChild:paddle];
    [self addSecondPaddle];
}

- (void)addSecondPaddle {
    //下のパドルを生成
    [self paddleSetting];
    paddle.position = CGPointMake(160, 129);
    [self addChild:paddle];
}

- (void)paddleSetting {
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
- (void)leftdownPaddle {
    [self diagonalPaddleSetting];
    diagonalPaddle.position = CGPointMake(0, 110);
}
- (void)rightDownPaddle {
    [self diagonalPaddleSetting];
    diagonalPaddle.position = CGPointMake(320, 110);
}
- (void)rightUpPaddle {
    [self diagonalPaddleSetting];
    diagonalPaddle.position = CGPointMake(320, 455);
}
- (void)leftUpPaddle {
    [self diagonalPaddleSetting];
    diagonalPaddle.position = CGPointMake(0, 455);
}

- (SKNode *)paddleNode {
    return [self childNodeWithName:@"paddle"];
}


# pragma mark - Touch

/*
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    //タッチした場所を取得
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    
    NSLog(@"%@", NSStringFromCGPoint(location));
    
    //    [self addBall];
    // [self ballPhysics];
}
 */



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
