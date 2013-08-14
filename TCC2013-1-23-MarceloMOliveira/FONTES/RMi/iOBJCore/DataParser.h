//
//  DataParser.h
//  iOBJ
//
//  Created by felipowsky on 07/08/12.
//
//

#import <Foundation/Foundation.h>

@interface DataParser : NSObject

@property (nonatomic, strong, readonly) NSData *data;
@property (nonatomic, strong) NSString *filename;

- (id)initWithData:(NSData *)data;
- (id)initWithFilename:(NSString *)filename ofType:(NSString *)type;

@end
