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

//<<...2でかけます
//static const は定数(変数じゃないやつ)/そのクラス内で使われる
//uint32_tは4バイト消費する
//UInt32であるため、最大で32種類までしか種類を指定出来ない
static const uint32_t paddleCategory = 0x1 << 0; //*1の意味
static const uint32_t ballCategorySKPhysics = 0x1 << 1; //*2だよ

/*
 __doneボールを画像に変更する
 __doneボールに重力
 パドルをあれして透明にして反射させる
 パドルとボールを跳ね返るように
 SKscene自体を正方形にしたら跳ね返るのではないのではないかと思ったよ
 viewにSKsceneつけられるかどうか、SKの中で判定している変数をラベル(UIView上)に反映させられるか
 maruを4個かつランダムな色に
 */

@interface SKPlayScene() <SKPhysicsContactDelegate>


@end
@implementation SKPlayScene{
    SKSpriteNode *paddle;
    SKSpriteNode *maru;
}

- (id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    if (self) {
        [YMCPhysicsDebugger init];
        [self makeBoard];
    
        //ボールがなければボールを生成
        if (![self ballNode]) {
            [self addBall];
        }

        [self addPaddle];
        [self drawPhysicsBodies];
        //physicsBodyを設定する/重力が使えるようになる
        self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
        self.physicsWorld.contactDelegate = self;  //物理演算をselfの中でやるよ。これがないとdelegateを使えない
            }
    return self;
}

- (void) makeBoard{
    SKSpriteNode *gameBoard = [SKSpriteNode spriteNodeWithImageNamed:@"gameView_board"];
    //    gameBoard.frame = CGRectMake(0, 124, 320, 320);
    gameBoard.position = CGPointMake(0 +160, 124 +160);
    gameBoard.size = CGSizeMake(320, 320);
    [self addChild:gameBoard];
    
//    [self.view sendSubviewToBack:gameBoard];		// backView を最背面に移動
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
    //config.jsonにある重力の大きさの値
    CGFloat velocityX = [config[@"maru"][@"velocity"][@"x"] floatValue]; //このふたつの値を変えることでスピードを調整できる
    CGFloat velocityY = [config[@"maru"][@"velocity"][@"y"] floatValue];
    
    //    CGFloat radius = [config[@"maru"][@"radius"] floatValue];
    
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
    maru.physicsBody.angularDamping = 0.0; //回転による抵抗を0に
    maru.physicsBody.usesPreciseCollisionDetection = YES;  //yesで衝突判定が可能に
    maru.physicsBody.categoryBitMask = ballCategorySKPhysics;       //categoryBitMaskはそれが何のクラスか判別する。contactTestBitMaskに設定したものとcontact(接触)した場合didBeginContact:が呼ばれる
    maru.physicsBody.contactTestBitMask = paddleCategory;  //contactTestBitMaskにblockCategoryを設定してる
    //    maru.physicsBody.mass = 10.0; //重さを指定してるけど、重力は受けないことになってるから意味ない
    maru.physicsBody.collisionBitMask = paddleCategory; //collisionの対象としてpaddlを指定
    
    [self addChild:maru];
}



- (SKNode *)ballNode {
    return [self childNodeWithName:@"ball"];
}



# pragma mark - Paddle
- (void)addPaddle {
    [self paddleSetting];
    paddle.position = CGPointMake(160, 449);
    [self addChild:paddle];
    
    [self addSecondPaddle];
}

- (void)addSecondPaddle{
    [self paddleSetting];
    paddle.position = CGPointMake(160, 119);
    [self addChild:paddle];
}

- (void)paddleSetting{
    CGFloat width = [config[@"paddle"][@"width"] floatValue];
    CGFloat height = [config[@"paddle"][@"height"] floatValue];
    //    CGFloat y = [config[@"paddle"][@"y"] floatValue];
    paddle = [SKSpriteNode spriteNodeWithColor:[SKColor brownColor] size:CGSizeMake(width, height)];
    //    paddle.position = CGPointMake(CGRectGetMidX(self.frame), y);
    paddle.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:paddle.size];
    paddle.physicsBody.usesPreciseCollisionDetection = YES;  //yesで衝突判定が可能に
    paddle.physicsBody.dynamic = NO;
    paddle.physicsBody.categoryBitMask = paddleCategory;
    paddle.physicsBody.collisionBitMask = ballCategorySKPhysics;
    paddle.name = @"paddle";
}

- (SKNode *)paddleNode {
    return [self childNodeWithName:@"paddle"];
}


# pragma mark - Touch

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

    //ボールがあればゲーム中だから、パドルを等速で動かす
    UITouch *touch = [touches anyObject];
    CGPoint locaiton = [touch locationInNode:self];
    

    /* --------パドルの移動について--------- */
    /*
    CGFloat speed = [config[@"paddle"][@"speed"] floatValue];
    CGFloat x = locaiton.x;
    CGFloat diff = abs(x - [self paddleNode].position.x);
    CGFloat duration = speed * diff;
    SKAction *move = [SKAction moveToX:x duration:duration];
    [[self paddleNode] runAction:move];
     */
    
    
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
