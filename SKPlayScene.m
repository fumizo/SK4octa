//
//  SKPlayScene.m
//  SKOctagonSample
//
//  Created by FumikoYamamoto on 2016/01/23.
//  Copyright © 2016年 FumikoYamamoto. All rights reserved.
//

#import "SKPlayScene.h"

//<<...2でかけます
//static const は定数(変数じゃないやつ)/そのクラス内で使われる
//uint32_tは4バイト消費する
static const uint32_t blockCategory = 0x1 << 0; //*1の意味
static const uint32_t ballCategory = 0x1 << 1; //*2だよ


@implementation SKPlayScene

- (id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    if (self) {
        [self addPaddle];
        [self makeBoard];
        
        if (![self ballNode]) {
            [self addBall];
        }
    }
    return self;
}

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


# pragma mark - Paddle
- (void)addPaddle {
    CGFloat width = [config[@"paddle"][@"width"] floatValue];
    CGFloat height = [config[@"paddle"][@"height"] floatValue];
    CGFloat y = [config[@"paddle"][@"y"] floatValue];
    
    SKSpriteNode *paddle = [SKSpriteNode spriteNodeWithColor:[SKColor brownColor] size:CGSizeMake(width, height)];
    paddle.name = @"paddle";
    paddle.position = CGPointMake(CGRectGetMidX(self.frame), y);
    
    [self addChild:paddle];
}

- (SKNode *)paddleNode {
    return [self childNodeWithName:@"paddle"];
}

# pragma mark - Ball

- (void)addBall {
    CGFloat radius = [config[@"ball"][@"radius"] floatValue];
    
    SKShapeNode *ball = [SKShapeNode node];
    ball.name = @"ball";
    ball.position = CGPointMake(CGRectGetMidX([self paddleNode].frame), CGRectGetMaxY([self paddleNode].frame) + radius);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddArc(path, NULL, 0, 0, radius, 0, M_PI * 2, YES);
    ball.path = path;
    ball.fillColor = [SKColor yellowColor];
    ball.strokeColor = [SKColor clearColor];
    
    CGPathRelease(path);
    
    [self addChild:ball];
    
}

- (SKNode *)ballNode {
    return [self childNodeWithName:@"ball"];
}


# pragma mark - Touch
/*
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (![self ballNode]) {
        [self addBall];
        return;
    }
    UITouch *touch = [touches anyObject];
 
    //パドルを動かすためのコード
    CGPoint locaiton = [touch locationInNode:self];
    CGFloat speed = [config[@"paddle"][@"speed"] floatValue];
    CGFloat x = locaiton.x;
    CGFloat diff = abs(x - [self paddleNode].position.x);
    CGFloat duration = speed * diff;
    SKAction *move = [SKAction moveToX:x duration:duration];
    [[self paddleNode] runAction:move];
}
*/


@end