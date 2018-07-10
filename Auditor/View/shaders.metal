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
                          unsigned int vertexID [[vertex_id]],
                          unsigned int frameID [[instance_id]]) {
    
    // get info from *info
    int nFrames = info[0]; // number of frames (columns) in the spetrogram
    int frameSize = info[1]; // number of bins (rows) in each frame
    int frameOffset = info[2]; // this increases by 1 each frame so the spectrogram moves
    
    // each frame is a column of bins, each bin is a rectangle
    unsigned int binID = vertexID / 6;
    // each bin is 6 points (two triangles)
    unsigned int pointID = vertexID % 6;

    // each bin is six points:
    //
    // (2/4)-(3)
    //   | \  |
    //   |  \ |
    //  (0)-(1/5)
    //
    // this way, even numbers are left, odd are right
    
    // make x from the frame ID
    float x = frameID;
    // adjust if this is the right side of the square
    if(pointID % 2 != 0) x += 1;
    // scale to unit space
    x = 2.0 * x / float(nFrames - 1) - 1;
    
    // make y from the bin ID
    float y = binID;
    // adjust if this is the top side of the square
    if (!(pointID < 2 || pointID == 5)) y += 1;
    // scale to [0, 1]
    y /= float(frameSize - 1);
    // make logarithmic
//    y = -0.5 / log10(1000.0/22050.0) * log10(y);
    // rescale to unit space
    y = 2.0 * y - 1;

    // find the intensity of this square
    int currentFrame = frameOffset + frameID;
    if (currentFrame >= nFrames) currentFrame -= nFrames;
    int audioI = currentFrame * frameSize + binID;
    float dB = 5 * log10(audio[audioI]);
    if(dB < -60) dB = -60;
    dB = -dB / 60.0;

    Vertex v;
    v.position = float4(-x, y, 0, 1);
    v.color = float4(1, dB, dB, 1);
    return v;
}

/// draws a spectrogram from the provided power spectrum
/// (old version)
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
