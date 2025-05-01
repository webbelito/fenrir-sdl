struct PSInput {
    float4 Position : SV_POSITION;
    float3 Color : COLOR0;
};

float4 main(PSInput input) : SV_TARGET {
    // Use the interpolated color from the vertex shader
    return float4(input.Color, 1.0);
    
    // Alternatively, for a solid red color, uncomment this:
    // return float4(1.0, 0.0, 0.0, 1.0);
} 