//
//  GraphicObject.m
//  RMi
//
//  Created by Marcelo da Mata
//
//

#import "GraphicObject.h"
#import "Transform.h"
#import "Camera.h"
#import "MeshMaterial.h"
#import "Shaders.h"
#import "ConstantsDicomRender.h"
#import "Voxel.h"

GLint MESH = 1;
GLint VOLUME_SLICES = 2;

@interface GraphicObject () {
    @private
    BOOL setupCamra;
}

@property (nonatomic, strong) NSMutableArray *sortedMaterials;
@property (nonatomic, strong) NSMutableDictionary *textures;
@property (nonatomic) GLuint shaderProgram;

@end

@implementation GraphicObject

enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_LOOKAT_MATRIX,
    UNIFORM_PERSPECTIVE_MATRIX,
    UNIFORM_TEXTURE2D_ENABLED,
    UNIFORM_NORMAL_MATRIX,
    UNIFORM_LIGHT_ENABLED,
    UNIFORM_LIGHT_POSITION,
    NUM_UNIFORMS
};

GLint uniforms[NUM_UNIFORMS];


- (id)initWithVolumeSlices:(VolumeSlices *)volume
{
    self = [super init];
    nameSlice = 0;
    setupCamra = false;
    
    //VolumeSlices
    if([volume getFirstOrientation] == SLICE_ORIENTATION_AXIAL) {
        modeRender = AXIAL;
        firstModeRender = AXIAL;
    } else if([volume getFirstOrientation] == SLICE_ORIENTATION_CORONAL) {
        firstModeRender = CORONAL;
        modeRender = CORONAL;
    } else if([volume getFirstOrientation] == SLICE_ORIENTATION_SAGITAL) {
        firstModeRender = SAGITAL;
        modeRender = SAGITAL;
    }
    
    if (self) {
        [self loadShaders];
        
        self.volume = volume;
        self.textures = [[NSMutableDictionary alloc] init];
        _width = 0.0f;
        _height = 0.0f;
        _depth = 0.0f;
        
        _haveTextures = NO;
        
        [self setupCamera];
    }
    
    NSMutableArray *slices = volume.slicesAxial;
    for (Shape *slice in slices) {
        [self addTextureWithSliceMaterial:slice];
    }
    
    slices = volume.slicesCoronal;
    for (Shape *slice in slices) {
        [self addTextureWithSliceMaterial:slice];
    }
    
    slices = volume.slicesSagital;
    for (Shape *slice in slices) {
        [self addTextureWithSliceMaterial:slice];
    }
    return self;
}


-(void)setupCamera {
    NSNumber *maxX = nil;
    NSNumber *minX = nil;
    NSNumber *maxY = nil;
    NSNumber *minY = nil;
    NSNumber *maxZ = nil;
    NSNumber *minZ = nil;
    
    int pointsLength = 0;
    NSMutableArray *points = self.volume.pointsAxial;
    
    if(firstModeRender==AXIAL) {
        pointsLength = [self.volume getPointsAxialCount];
    } else if(firstModeRender==SAGITAL) {
        points = self.volume.pointsSagital;
        pointsLength = [self.volume getPointsSagitalCount];
    } else if(firstModeRender==CORONAL) {
        points = self.volume.pointsCoronal;
        pointsLength = [self.volume getPointsCoronalCount];
    }
        
    
    for (int i = 0; i < pointsLength; i++) {
        NSValue *pointValue = [points objectAtIndex:i];
        GLKVector3 point;
        [pointValue getValue:&point];
        
        if (maxX == nil || point.x > [maxX floatValue]) {
            maxX = [NSNumber numberWithFloat:point.x];
        }
        
        if (maxY == nil || point.y > [maxY floatValue]) {
            maxY = [NSNumber numberWithFloat:point.y];
        }
        
        if (maxZ == nil || point.z > [maxZ floatValue]) {
            maxZ = [NSNumber numberWithFloat:point.z];
        }
        
        if (minX == nil || point.x < [minX floatValue]) {
            minX = [NSNumber numberWithFloat:point.x];
        }
        
        if (minY == nil || point.y < [minY floatValue]) {
            minY = [NSNumber numberWithFloat:point.y];
        }
        
        if (minZ == nil || point.z < [minZ floatValue]) {
            minZ = [NSNumber numberWithFloat:point.z];
        }
    }
    
    GLfloat toOriginX = 0.0f;
    GLfloat toOriginY = 0.0f;
    GLfloat toOriginZ = 0.0f;
    
    if (maxX != nil && minX != nil) {
        GLfloat minXF = [minX floatValue];
        GLfloat maxXF = [maxX floatValue];
        
        toOriginX = (minXF + maxXF) / 2.0f;
        _width = maxXF - minXF;
    }
    
    if (maxY != nil && minY != nil) {
        GLfloat minYF = [minY floatValue];
        GLfloat maxYF = [maxY floatValue];
        
        toOriginY = (minYF + maxYF) / 2.0f;
        _height = maxYF - minYF;
    }
    
    if (maxZ != nil && minZ != nil) {
        GLfloat minZF = [minZ floatValue];
        GLfloat maxZF = [maxZ floatValue];
        
        toOriginZ = (minZF + maxZF) / 2.0f;
        _depth = maxZF - minZF;
    }
    
    _transform = [[Transform alloc] initWithToOrigin:GLKVector3Make(-toOriginX, -toOriginY, -toOriginZ)];
}

- (void)update
{
    [self.transform update];
}

- (void)drawWithDisplayMode:(GraphicObjectDisplayMode)displayMode camera:(Camera *)camera effect:(GLKBaseEffect *)  effect
{
    [self displayVolumeSlices:displayMode camera:camera effect:effect];
}

- (void)addTextureWithSliceMaterial:(Shape *)slice
{
    if (slice.material) {
        UIImage *image = slice.imageTexture;
        //BOOL t = [[NSFileManager defaultManager] fileExistsAtPath:@"/Users/User/Desktop/images/lamborguini.jpg"];
        //UIImage *image = [UIImage imageWithContentsOfFile:@"/Users/User/Desktop/images/lamborguini.jpg"];
        
        NSString *name = [NSString stringWithFormat:@"%d", nameSlice];
        
        NSError *error;
        
        NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:GLKTextureLoaderOriginBottomLeft];
        
        GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:image.CGImage options:options error:&error];
        
#ifdef DEBUG
        if (error) {
            NSLog(@"Error loading texture from image: %@", error);
        }
#endif
        if (textureInfo) {
            [self.textures setObject:textureInfo forKey:name];
            slice.name = name;
            _haveTextures = YES;
        }
        nameSlice++;
    }
}

- (void)addTextureWithMeshMaterial:(MeshMaterial *)meshMaterial
{
    if (meshMaterial.material.haveTexture) {
        NSString *textureName = meshMaterial.material.diffuseTextureMap;
        
        NSString *filename = [textureName stringByDeletingPathExtension];
        NSString *extension = [textureName pathExtension];
        
        NSString *pathFile = [[NSBundle mainBundle] pathForResource:filename ofType:extension];
        
        NSData *content = [NSData dataWithContentsOfFile:pathFile];
        
        UIImage *image = [UIImage imageWithData:content];
        
        NSError *error;
        
        NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:GLKTextureLoaderOriginBottomLeft];
        
        GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:image.CGImage options:options error:&error];
        
#ifdef DEBUG
        if (error) {
            NSLog(@"Error loading texture from image: %@", error);
        }
#endif
        if (textureInfo) {
            [self.textures setObject:textureInfo forKey:meshMaterial.material.name];
            _haveTextures = YES;
        }
    }
}

- (void)setSortedMaterials:(NSMutableArray *)sortedMaterials
{
    if (sortedMaterials) {
        /*
         sort meshes:
         1. material with texture
         2. material without texture
         3. no material
         */
        _sortedMaterials = [NSMutableArray arrayWithArray:[sortedMaterials sortedArrayUsingComparator:^NSComparisonResult(id anObject, id otherObject) {
            
            MeshMaterial *anMaterial = (MeshMaterial *)anObject;
            MeshMaterial *otherMaterial = (MeshMaterial *)otherObject;
            
            NSComparisonResult result = NSOrderedSame;
            
            if (anMaterial.material && otherMaterial.material) {
                
                if (anMaterial.material.haveTexture && !otherMaterial.material.haveTexture) {
                    result = NSOrderedAscending;
                
                } else if (!anMaterial.material.haveTexture && otherMaterial.material.haveTexture) {
                    result = NSOrderedDescending;
                }
            
            } else if (anMaterial.material && !otherMaterial.material) {
                result = NSOrderedAscending;
                
            } else if (!anMaterial.material && otherMaterial.material) {
                result = NSOrderedDescending;
                
            }
            
            return result;
        }]];
        
    } else {
        _sortedMaterials = [[NSMutableArray alloc] init];
    }
}

- (BOOL)loadShaders
{
    self.shaderProgram = glCreateProgram();
    
    GLuint vertexShader;
    
    if (![self compileShader:&vertexShader type:GL_VERTEX_SHADER source:vertexShaderSource]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    GLuint fragmentShader;
    
    if (![self compileShader:&fragmentShader type:GL_FRAGMENT_SHADER source:fragmentShaderSource]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    glAttachShader(self.shaderProgram, vertexShader);
    glAttachShader(self.shaderProgram, fragmentShader);
    
    glBindAttribLocation(self.shaderProgram, GLKVertexAttribPosition, "position");
    glBindAttribLocation(self.shaderProgram, GLKVertexAttribTexCoord0, "texture2d");
    glBindAttribLocation(self.shaderProgram, GLKVertexAttribColor, "color");
    glBindAttribLocation(self.shaderProgram, GLKVertexAttribNormal, "normal");
    
    if (![self linkShaderProgram:self.shaderProgram]) {
        NSLog(@"Failed to link program: %d", self.shaderProgram);
        
        if (vertexShader) {
            glDeleteShader(vertexShader);
            vertexShader = 0;
        }
        
        if (fragmentShader) {
            glDeleteShader(fragmentShader);
            fragmentShader = 0;
        }
        
        if (self.shaderProgram) {
            glDeleteProgram(self.shaderProgram);
            self.shaderProgram = 0;
        }
        
        return NO;
    }
    
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(self.shaderProgram, "modelViewProjectionMatrix");
    uniforms[UNIFORM_LOOKAT_MATRIX] = glGetUniformLocation(self.shaderProgram, "lookAtMatrix");
    uniforms[UNIFORM_PERSPECTIVE_MATRIX] = glGetUniformLocation(self.shaderProgram, "perspectiveMatrix");
    uniforms[UNIFORM_TEXTURE2D_ENABLED] = glGetUniformLocation(self.shaderProgram, "texture2dEnabled");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(self.shaderProgram, "normalMatrix");
    uniforms[UNIFORM_LIGHT_ENABLED] = glGetUniformLocation(self.shaderProgram, "lightEnabled");
    uniforms[UNIFORM_LIGHT_POSITION] = glGetUniformLocation(self.shaderProgram, "lightPosition");
    
    if (vertexShader) {
        glDetachShader(self.shaderProgram, vertexShader);
        glDeleteShader(vertexShader);
    }
    
    if (fragmentShader) {
        glDetachShader(self.shaderProgram, fragmentShader);
        glDeleteShader(fragmentShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type source:(const char*)source
{
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#ifdef DEBUG
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    GLint status;
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkShaderProgram:(GLuint)program
{
    glLinkProgram(program);
    
#ifdef DEBUG
    GLint logLength;
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
    
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(program, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    GLint status;
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

-(void)displayVolumeSlices: (GraphicObjectDisplayMode)displayMode camera:(Camera *)camera effect:(GLKBaseEffect *)  effect {
    
    NSMutableArray *slices;
    int index = 0;
    
    if(modeRender == AXIAL) {
        slices = self.volume.slicesAxial;
        index = [self.volume getIndexAxialSlicing];
    } else if(modeRender == CORONAL) {
        slices = self.volume.slicesCoronal;
        index = [self.volume getIndexCoronalSlicing];
    } else if(modeRender == SAGITAL) {
        slices = self.volume.slicesSagital;
        index = [self.volume getIndexSagitalSlicing];
    }
    
    Shape *slice;
    
    for (int i = 0; i < index; i++) {        
        slice = [slices objectAtIndex:i];
        
        BOOL haveTexture = NO;
        BOOL haveColors = NO;
        
        GLint texture2dEnabled = GL_FALSE;
        GLint lightEnabled = GL_FALSE;
        
        if (slice.material) {
            haveColors = YES;
            lightEnabled = GL_TRUE;
            
            GLKTextureInfo *textureInfo = [self.textures objectForKey:slice.name];
                
            if (textureInfo) {
                texture2dEnabled = GL_TRUE;
                haveTexture = YES;
                    
                glActiveTexture(GL_TEXTURE0);
                //glEnable(GL_TEXTURE_2D);
                glBindTexture(textureInfo.target, textureInfo.name);
                //glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE_ALPHA);
                
            }
        }
        
        glUseProgram(self.shaderProgram);
        
        glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, self.transform.matrix.m);
        glUniformMatrix4fv(uniforms[UNIFORM_LOOKAT_MATRIX], 1, 0, camera.lookAtMatrix.m);
        glUniformMatrix4fv(uniforms[UNIFORM_PERSPECTIVE_MATRIX], 1, 0, camera.perspectiveMatrix.m);
        
        GLKMatrix3 normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(self.transform.matrix), NULL);
        
        glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, normalMatrix.m);
        
        glUniform1i(uniforms[UNIFORM_TEXTURE2D_ENABLED], texture2dEnabled);
        glUniform1i(uniforms[UNIFORM_LIGHT_ENABLED], lightEnabled);
        glUniform3f(uniforms[UNIFORM_LIGHT_POSITION], camera.eyeX, camera.eyeY, camera.eyeZ);
        
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glEnableVertexAttribArray(GLKVertexAttribNormal);
        
        if (haveColors) {
            glEnableVertexAttribArray(GLKVertexAttribColor);
        }
        
        if (haveTexture) {
            glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
        }                
        
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, slice.trianglePoints);
        /*
        for (int i=0; i < slice.trianglePointsLength; i++) {
            GLKVector3 point = slice.trianglePoints[i];
            NSLog(@"%f , %f , %f", point.v[0], point.v[1], point.v[2]);
        }
         */
        
        glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 0, slice.triangleNormals);
        /*
        for (int i=0; i < slice.triangleNormalsLength; i++) {
            GLKVector3 point = slice.triangleNormals[i];
            NSLog(@"%f , %f , %f", point.v[0], point.v[1], point.v[2]);
        }
         */
        
        if (haveColors) {
            glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, slice.triangleColors);
            /*
            for (int i=0; i < slice.triangleColorsLength; i++) {
                GLKVector4 point = slice.triangleColors[i];
                NSLog(@"%f , %f , %f , %f", point.v[0], point.v[1], point.v[2], point.v[3]);
            }
             */
        }
        
        if (haveTexture) {
            glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, slice.triangleTextures);
            /*
            for (int i=0; i < slice.triangleTexturesLength; i++) {
                GLKVector2 point = slice.triangleTextures[i];
                NSLog(@"%f , %f", point.v[0], point.v[1]);
            }
             */
        }
        
        GLenum mode = GL_TRIANGLES;
        
        glDepthMask(GL_FALSE);
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        glDrawArrays(mode, 0, slice.trianglePointsLength);
        
        glDisable(GL_BLEND);
        glDepthMask(GL_TRUE);
        
        if (haveTexture) {
            glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
        }
        
        if (haveColors) {
            glDisableVertexAttribArray(GLKVertexAttribColor);
        }
        
        glDisableVertexAttribArray(GLKVertexAttribNormal);
        
        glDisableVertexAttribArray(GLKVertexAttribPosition);                
    }

}

- (VolumeSlices*) getVolume {
    return _volume;
}

- (void) setModeRender: (ModeRenderVolumeSlices) mode {
    //[self setupCamera];
    modeRender = mode;
    /*
    if(mode == AXIAL && [self.volume getFirstOrientation] != SLICE_ORIENTATION_AXIAL && self.volume.slicesAxial.count == 0) {
        if([self.volume getFirstOrientation] == SLICE_ORIENTATION_CORONAL){
            [self.volume calculateAxialByCoronal];
        } else {
            //[self.volume calculateAxialBySagital];
        }
        NSMutableArray *slices = self.volume.slicesAxial;
        for (Shape *slice in slices) {
            [self addTextureWithSliceMaterial:slice];
        }
    } else if(mode == CORONAL && [self.volume getFirstOrientation] != SLICE_ORIENTATION_CORONAL && self.volume.slicesCoronal.count == 0) {
        if([self.volume getFirstOrientation] == SLICE_ORIENTATION_AXIAL){
            [self.volume calculateCoronalByAxial];
        } else {
            //[self.volume calculateCoronalBySagital];
        }
        NSMutableArray *slices = self.volume.slicesCoronal;
        for (Shape *slice in slices) {
            [self addTextureWithSliceMaterial:slice];
        }
    } else if(mode == SAGITAL && [self.volume getFirstOrientation] != SLICE_ORIENTATION_SAGITAL && self.volume.slicesSagital.count == 0) {
        if([self.volume getFirstOrientation] == SLICE_ORIENTATION_AXIAL){
            [self.volume calculateSagitalByAxial];
        } else {
            //[self.volume calculateSagitalByCoronal];
        }
        NSMutableArray *slices = self.volume.slicesSagital;
        for (Shape *slice in slices) {
            [self addTextureWithSliceMaterial:slice];
        }
    }
     
    [self.volume initSlices];
     */
}

- (ModeRenderVolumeSlices) getModeRender {
    return modeRender;
}

- (void) addSlicingAxial {
    [self.volume addSlicingAxial];
}

- (void) addSlicingSagital {
    [self.volume addSlicingSagital];
}

- (void) addSlicingCoronal {
    [self.volume addSlicingCoronal];
}

- (void) subSlicingAxial {
    [self.volume subSlicingAxial];
}

- (void) subSlicingSagital {
    [self.volume subSlicingSagital];
}

- (void) subSlicingCoronal {
    [self.volume subSlicingCoronal];
}

@end
