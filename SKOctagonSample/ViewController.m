//
//  ViewController.m
//  SKOctagonSample
//
//  Created by FumikoYamamoto on 2016/01/23.
//  Copyright © 2016年 FumikoYamamoto. All rights reserved.
//

#import "ViewController.h"
#import "SKPlayScene.h"
@import SpriteKit;

@interface ViewController ()

@end

@implementation ViewController

- (void) loadView{
    //self.viewをSKViewに差し替え
    SKView *skView = [[SKView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view = skView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //情報表示の設定、表示しない
    SKView *skView = (SKView *)self.view;
    
    skView.showsDrawCount = YES;
    skView.showsNodeCount = YES;
    skView.showsFPS = YES;
    
    /*
    skView.showsDrawCount = NO;
    skView.showsNodeCount = NO;
    skView.showsFPS = NO;
     */
    
    //SKSceneをインスタンス化
    SKScene *scene = [SKPlayScene sceneWithSize:self.view.bounds.size];
    [skView presentScene:scene];
    scene.scaleMode = SKSceneScaleModeAspectFill;  //sizeをfitさせる
    [skView presentScene:scene];
}

//タップでplayへ
/*
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    SKScene *scene = [SKPlayScene sceneWithSize:self.view.bounds.size];
    SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionUp duration:1.0f];
    [self.view presentScene:scene transition:transition];
    // Present the scene.
//    [SKPlayScene presentScene:scene];
}
 */

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//ステータスバーを設定
- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
