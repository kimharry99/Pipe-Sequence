//
//  ShaderTypes.h
//  Pipe-Sequence
//
//  Created by Dong-Min KIM on 2022/10/04.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h


// Buffer index values shared between shader and C code to ensure Metal shader buffer inputs match
//   Metal API buffer set calls
typedef enum BufferIndicies {
    kBufferIndexMeshPositions    = 0
} BufferIndicies;

#endif /* ShaderTypes_h */
