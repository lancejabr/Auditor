//
//  shaders.metal
//  Space Audity
//
//  Created by Lance Jabr on 10/16/16.
//  Copyright © 2016 Code Blue Applications. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


struct Vertex {
    float4 position [[position]];
    float point_size [[point_size]];
    float4 color;
};

vertex Vertex xy_vertex(const device float *x_coords    [[buffer(0)]],
                        const device float *y_coords    [[buffer(1)]],
                        unsigned int vid [[vertex_id]]) {
    Vertex v;
    
    v.point_size = 7;
    v.position = float4(x_coords[vid], y_coords[vid], 0, 1);
    
    return v;
}

fragment float4 solid_color(const device float4 &color [[ buffer(0) ]]) {
    return color;
}

fragment float4 per_vertex(Vertex v [[stage_in]]) {
    return v.position.x
}
