//
//  VoxelsLayer.m
//  RMi
//
//  Created by Marcelo da Mata on 07/05/2013.
//
//

#import "VoxelsLayer.h"

/*
 Classe que seria utilizada na modelagem do volume atraves dos voxels.
 */

@implementation VoxelsLayer

@synthesize voxels = voxels;

-(id) init {
    self = [super init];
    
    if (self) {
        voxels = [[NSMutableArray alloc] init];
    }
    
    return self;
}

//-(void)addObject: (Voxel*)voxel {
-(void)addObject: (Shape*)voxel {
	[voxels addObject:voxel];
}


@end
