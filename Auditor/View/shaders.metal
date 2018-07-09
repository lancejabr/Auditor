//
//  shaders.metal
//  Space Audity
//
//  Created by Lance Jabr on 10/16/16.
//  Copyright © 2016 Code Blue Applications. All rights reserved.
//

#include <metal_stdlib>
#include <metal_math>
using namespace metal;


struct Vertex {
    float4 position [[position]];
    float4 color;
};

/// A function that assembles x and y coordinates into a Vertex
vertex Vertex xy_vertex(const device float *x_coords    [[buffer(0)]],
                        const device float *y_coords    [[buffer(1)]],
                        unsigned int vid [[vertex_id]]) {
    Vertex v;
    
    v.position = float4(x_coords[vid], y_coords[vid], 0, 1);
    
    return v;
}

/// draws a spectrogram from the provided power spectrum
vertex Vertex spectrogram(const device float *audio [[ buffer(0) ]],
                          const device int *info [[ buffer(1) ]],
                          unsigned int vid [[vertex_id]],
                          unsigned int iid [[instance_id]]) {
    // get info from *info
    int nFrames = info[0];
    int frameSize = info[1];
    int frameOffset = info[2];
    
    // square ID
    unsigned int sqID = vid / 6;
    // point ID in square. range:[0, 6)
    unsigned int pid = vid % 6;

    float sqW = 1.0 / float(nFrames - 1) * 2.0;
    float x = iid * sqW - 1 + sqW * (pid % 2  == 0 ? -0.5 : 0.5);
    float sqHDelta = sqW * (pid < 2 || pid == 5 ? 0.25 : -0.25);
    float y = float(sqID) / float(frameSize - 1) + sqHDelta;
    y = 0.11 * log2(y) + 1;
    y = y * 2.0 - 1;

    int currentFrame = frameOffset + iid;
    if (currentFrame >= nFrames) currentFrame -= nFrames;
    int audioI = (currentFrame) * frameSize;
    audioI += sqID;
    float dB = 9 * log10(audio[audioI]);
    float shade = 1-clamp((dB + 60) / 60.0, 0.0, 1.0);

    Vertex v;
    v.position = float4(-x, y, 0, 1);
    v.color = float4(1, shade, shade, 1);
    return v;
}

/// draws a spectrogram from the provided power spectrum
vertex Vertex spectrogram2(const device float *audio [[ buffer(0) ]],
                          const device int *info [[ buffer(1) ]],
                          unsigned int vid [[vertex_id]],
                          unsigned int iid [[instance_id]]) {
    // get info from *info
    int nFrames = info[0];
    int frameSize = info[1];
    int frameOffset = info[2];
    
    float x = float(iid + (vid % 2)) / float(nFrames - 1) * 2.0 - 1.0;
    float y = float(vid / 2) / float(frameSize - 1);
    y = 0.11 * log2(y) + 1;
    y = y * 2.0 - 1;
    
    int currentFrame = frameOffset + iid;
    if (currentFrame >= nFrames) currentFrame -= nFrames;
    int audioI = (currentFrame + (vid % 2)) * frameSize;
    audioI += (vid / 2);
    float dB = 9 * log10(audio[audioI]);
    float shade = 1-clamp((dB + 60) / 60.0, 0.0, 1.0);
    
    Vertex v;
    v.position = float4(-x, y, 0, 1);
    v.color = float4(1, shade, shade, 1);
    return v;
}

fragment float4 solid_color(const device float4 &color [[ buffer(0) ]]) {
    return color;
}

fragment float4 vertex_color(Vertex v [[stage_in]]) {
    return v.color;
}
