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

fragment float4 vertex_color(Vertex v [[stage_in]]) {
    return v.color;
}


vertex Vertex spectrogram(const device float *audio [[ buffer(0) ]],
                          const device int *info [[ buffer(1) ]],
                          unsigned int vid [[vertex_id]],
                          unsigned int iid [[instance_id]]){
    int nBuffers = info[0];
    int bufferSize = info[1];
    int bufferStart = info[2];

    float x = float(nBuffers - 2 - iid + (vid % 2)) / (nBuffers - 1) * 2.0 - 1;
    float y = (vid / 2) / float(bufferSize - 1) * 2.0 - 1;

    int audioI = bufferStart;
    if (vid % 2 == 0) audioI += 1;
    if (audioI == nBuffers) audioI -= nBuffers;
    audioI += (vid / 2);
    float shade = 100*audio[audioI];

    Vertex v;
    v.position = float4(x, y, 0, 1);
    v.color = float4(shade, shade, shade, 1);
    return v;
//    Vertex v;
//    v.position = float4(int(vid) - 1, vid == 1 ? 1 : -1, 0, 1);
//    v.color = float4(vid/2.0, vid/2.0, vid/2.0, 1);
//    return v;
}
