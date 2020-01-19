//
//  GPUFunctions.metal
//  InformatiCUP
//
//  Created by Jonas Peeters on 27.12.19.
//

#include <metal_stdlib>
using namespace metal;

float rand(int x, int y, int z) {
    int seed = x + y * 57 + z * 241;
    seed = (seed<< 13) ^ seed;
    return ((( 1.0 - ( (seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f) * 2 - 0.5;
}


kernel void random(device float *results [[ buffer(0) ]],
                   device int *randomInit [[ buffer(1) ]],
                   uint i [[thread_position_in_grid]]) {
    results[i] = rand(i + randomInit[0], i * 100 + randomInit[1], i * 1000 + randomInit[2]) * rand(i + randomInit[0], i * 100 + randomInit[1], i * 1000 + randomInit[2]);
}

float sigmoid(float x) {
    return 1 / (1.0 + pow(M_E_F, -x));
}

kernel void calculate(device const float *weights [[ buffer(0) ]],
                      device const float *biases [[ buffer(1) ]],
                      device const float *inputs [[ buffer(2) ]],
                      device const int *args [[ buffer(3) ]],
                      device float *results [[ buffer(4) ]],
                      uint i [[thread_position_in_grid]]) {
    int layerSize = args[0];
    int inputsPerLayer = args[1];
    
    results[i] = biases[i];
    
    for (int j = 0; j < inputsPerLayer; j++) {
        results[i] += weights[i + j * layerSize] * inputs[j];
    }
    
    results[i] = sigmoid(results[i]);
}

kernel void calculateMulti(device const float *weights [[ buffer(0) ]],
                           device const float *biases [[ buffer(1) ]],
                           device const float *inputs [[ buffer(2) ]],
                           device const int *args [[ buffer(3) ]],
                           device float *results [[ buffer(4) ]],
                           uint i [[thread_position_in_grid]]) {
    int layerSize = args[0];
    int inputsPerLayer = args[1];
    int currentOutput = i % layerSize;

    results[i] = biases[currentOutput];

    for (int j = 0; j < inputsPerLayer; j++) {
        results[i] += weights[currentOutput + j * layerSize] * inputs[(i / layerSize) * inputsPerLayer + j];
    }
    
    results[i] = sigmoid(results[i]);
}



kernel void plus(device const float *arr1 [[ buffer(0) ]],
                 device const float *arr2 [[ buffer(1) ]],
                 device float *results [[ buffer(2) ]],
                 uint i [[thread_position_in_grid]]) {
    results[i] = arr1[i] + arr2[i];
}

kernel void mutate(device const float *multiplier [[ buffer(0) ]],
                   device const float *arr [[ buffer(1) ]],
                   device float *results [[ buffer(2) ]],
                   uint i [[thread_position_in_grid]]) {
    if (rand(int(multiplier[1] + 1 + i), int(multiplier[2] + 10 + i), int(multiplier[3] + 100 + i)) > 1.45) {
        results[i] = arr[i] + rand(int(multiplier[1] + i), int(multiplier[2] + i), int(multiplier[3] + i)) * multiplier[0] * multiplier[0] - multiplier[0] * multiplier[0] / 2;
    } else {
        results[i] = arr[i];
    }
}
