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

// Attribute index values shared between shader and C code to ensure Metal shader vertex
//   attribute indices match the Metal API vertex descriptor attribute indices
typedef enum VertexAttributes {
    kVertexAttributePosition  = 0,
    kVertexAttributeTexcoord  = 1,
    kVertexAttributeNormal    = 2
} VertexAttributes;

#endif /* ShaderTypes_h */
