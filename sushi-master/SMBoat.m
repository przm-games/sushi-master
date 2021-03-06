//
//  SMBoat.m
//  sushi-master
//
//  Created by Michael Garrido on 3/2/14.
//  Copyright (c) 2014 PRZM. All rights reserved.
//

#import "SMBoat.h"
#import "SMFisherman.h"
#import "SMChumPiece.h"
#import "SMOcean.h"
#import "SMFish.h"
#import "SMFishingScene.h"

@implementation SMBoat

@synthesize bodyNode, ocean, fishermen;

-(id) init
{
    self = [super init];
    
    if (self)
    {
        self.userInteractionEnabled = YES;
        
        caughtFishShownLimit = 5;
        
        totalWeight = 0;
        aboveWaterRatio = 0.8;
        baseColor = [SKColor brownColor];
        
        baseWidth = boatWidth;
        baseHeight = boatHeight;
        
        bodyNode = [SKSpriteNode spriteNodeWithTexture:[SKTexture textureWithImageNamed:@fileBoat] size:CGSizeMake(boatWidth,boatHeight)];
        
        bodyNode.zPosition = zBoat;
        bodyNode.position = CGPointMake(0,baseHeight/2+boatAboveWaterHeight);
        [self addChild:bodyNode];
        
        //TODO consider dynamically changing position to emulate waves
        
        fishCaught = [[NSMutableArray alloc] init];
        
        [self setupFishermenPositions];
    }
    
    return self;
}

-(void) setupFishermenPositions {
    
    activeFishermanPosition = nil;
    maxFishermenPositions = 8;
    fishermenPositionSpacing = baseWidth/(maxFishermenPositions-1)*0.9;
    
    fishermanPositionOrder = [[NSMutableArray alloc] initWithCapacity:maxFishermenPositions];
    
    fishermenPositions = [[NSMutableArray alloc] initWithCapacity:maxFishermenPositions];
    
    fishermen = [[NSMutableArray alloc] initWithCapacity:maxFishermenPositions];
    
    fishermenDeck = [SKNode node];
    fishermenDeck.position = CGPointMake(-(maxFishermenPositions-1)*fishermenPositionSpacing/2,boatDeckHeight);
    fishermenDeck.zPosition = zBoatBackground;
    [bodyNode addChild:fishermenDeck];
    
    for (int n=0;n<maxFishermenPositions;n++) {
        SKSpriteNode* fishermanPosition = [SKSpriteNode spriteNodeWithColor:[UIColor grayColor] size:CGSizeMake(20.0,20.0)];
        CGPoint position = CGPointMake(n*fishermenPositionSpacing,0);
        fishermanPosition.position = position;
        [fishermenDeck addChild:fishermanPosition];
        
        fishermanPosition.userData = [[NSMutableDictionary alloc] init];
        [fishermanPosition.userData setValue:NO forKey:@"occupied"];
        
        [fishermenPositions addObject:fishermanPosition];
        [fishermanPositionOrder addObject:[NSNull null]];
    }
    
    //TODO get number of fishermen in crew from server config
    
    [self addFishermanAtPosition:3];
    [self addFishermanAtPosition:4];
    [self addFishermanAtPosition:5];
}

-(void) setFisherman:(SMFisherman*)fisherman WithOrder:(int)order {
    
    [fishermanPositionOrder setObject:fisherman atIndexedSubscript:order];
    
}

-(void) clearFishermanAtOrder:(int)order {
    [fishermanPositionOrder setObject:[NSNull null] atIndexedSubscript:order];
}

-(SMFisherman*) getFishermanAtPosition:(int)position {
    SMFisherman* fisherman = (SMFisherman*)[fishermanPositionOrder objectAtIndex:position];
    
    NSLog(@"fisherman at position: %i,%@",position,fisherman);
    
    return fisherman;
}

-(void) addFishermanAtPosition:(int)position {
    
    if (position>=maxFishermenPositions) {
        return;
    }
    
    // TODO add a fisherman with persistent XP and stats
    
    SMFisherman* fisherman = [[SMFisherman alloc] init];
    SKSpriteNode* fishermanPosition = (SKSpriteNode*)[fishermenPositions objectAtIndex:position];
    fisherman.zPosition = zBoatForeground;
    fisherman.position = fishermanPosition.position;
    
    [fisherman setBoat:self andPosition:position];
    
    [fishermenDeck addChild:fisherman];
    [fishermen addObject:fisherman];
    
    [self setFisherman:fisherman WithOrder:position];
}

-(CGPoint) locationAtFishermanPosition:(int)index {
    
    SKSpriteNode* fishermanPosition = (SKSpriteNode*)[fishermenPositions objectAtIndex:index];
    
    return fishermanPosition.position;
    
}

-(void) highlightFishermanPositionAtLocation:(UITouch*)touch {
    int index = [self fishermanPositionAtLocation:touch];
    
    SKSpriteNode* fishermanPosition = (SKSpriteNode*)[fishermenPositions objectAtIndex:index];
    
    [self highlightFishermanPosition:fishermanPosition];
    
}

-(void) highlightFishermanPosition:(SKSpriteNode*)fishermanPosition {
    
    if (activeFishermanPosition!=fishermanPosition) {
        
        if (activeFishermanPosition!=nil) {
            activeFishermanPosition.color = [SKColor grayColor];
        }
        
        activeFishermanPosition = fishermanPosition;
        activeFishermanPosition.color = [SKColor greenColor];
        
    }
    
}

-(int) fishermanPositionAtLocation:(UITouch*)touch {
    
    CGPoint location = [touch locationInNode:fishermenDeck];
    
    NSLog(@"x location: %f",location.x);
    NSLog(@"fisherman positions: %@",fishermenPositions);
    
    int index = roundf(location.x/fishermenPositionSpacing);
    if (index<0) {
        index = 0;
    } else if (index>maxFishermenPositions-1) {
        index = maxFishermenPositions-1;
    }
    
    return index;
}

-(void) addCaughtFish:(SMFish*)fish atLocation:(CGPoint)location {
    
    // animate fish flying off hook into boat

    [fish loadIntoBoat];
    
    
    fish.position = location;
    fish.zPosition = zBoatBackground;
    [self addChild:fish];
    
    //TODO animate in arc
    //http://www.ioscreator.com/tutorials/moving-sprites-path-sprite-kit
    
    CGPoint caughtFishStorage = CGPointMake(0,50.0);
    SKAction* storeFishAction = [SKAction moveTo:caughtFishStorage duration:1.0];
    
    [fish runAction:storeFishAction completion:^{
        NSLog(@"fish stored!!!!");
        
        if ([fishCaught count]>caughtFishShownLimit) {
            [fish removeFromParent];
        } else {
            [fishCaught addObject:fish];
        }
        
        [self addWeight:fish.weight];
    }];
    
    // get weight of fish
}

-(void) addWeight:(float)weight {
    
    NSLog(@"adding weight to boat: %f",weight);
    
    totalWeight+=weight;
    SMFishingScene* scene = (SMFishingScene*)self.scene;
    
    [scene updateWeightCounter:weight];
    
    // adjust boat above water level by weight
    
    
}

-(NSDictionary*) reportCatch {
    
    
    //TODO sum fish weight
    
    NSDictionary* report = @{@"quantity":[NSNumber numberWithInt: [fishCaught count]],@"weight":[NSNumber numberWithFloat:totalWeight]};
    
    return report;
}

- (float)randomValueBetween:(float)low andValue:(float)high {
    return (((float) arc4random() / 0xFFFFFFFFu) * (high - low)) + low;
}

-(void) throwChumToLocation:(CGPoint)location {
    
    //SKAction*
    
}

-(void) scatterChumOfQuantity:(int)quantity {
    
    NSLog(@"scattering chum: %i",quantity);
    
    //underneath fishermen positions
    for (int i=0;i<quantity;i++) {
        // get position
        int index = roundf([self randomValueBetween:0 andValue:maxFishermenPositions-1]);
        
        NSLog(@"chum at position: %i",index);
        
        SKSpriteNode* fishermanPosition = (SKSpriteNode*)[fishermenPositions objectAtIndex:index];
        
        NSLog(@"fisherman position: %f,%f",fishermanPosition.position.x,fishermanPosition.position.y);
        
        CGPoint chumDestination  = [fishermenDeck convertPoint:fishermanPosition.position toNode:ocean];
        
        NSLog(@"chum destination: %f,%f",chumDestination.x,chumDestination.y);
        
        chumDestination = CGPointMake(chumDestination.x,chumDestination.y-chumDepth);
        
        [ocean addChumAtLocation:chumDestination];
    }
    
}

-(void) dumpCatch {
    
    totalWeight = 0;
    [fishCaught enumerateObjectsUsingBlock:^(id _fish, NSUInteger idx, BOOL *stop) {
        
        SMFish* fish = (SMFish*)_fish;
        [fish removeFromParent];
    }];
    
    [fishCaught removeAllObjects];
}

-(void) scatterChumContinuously {
    
    //check speed of 
    
    //check how many chum pieces in the water
    
}


@end
