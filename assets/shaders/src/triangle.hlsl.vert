struct VSInput {
    uint VertexID : SV_VertexID;
};

struct VSOutput {
    float4 Position : SV_POSITION;
    float3 Color : COLOR0;
};

VSOutput main(VSInput input) {
    VSOutput output;
    
    // Define three vertices for a triangle in clip space
    float2 positions[3] = {
        float2(0.0, 0.5),    // Top center
        float2(-0.5, -0.5),  // Bottom left
        float2(0.5, -0.5)    // Bottom right
    };
    
    // Define vertex colors (RGB)
    float3 colors[3] = {
        float3(1.0, 0.0, 0.0),  // Red
        float3(0.0, 1.0, 0.0),  // Green
        float3(0.0, 0.0, 1.0)   // Blue
    };
    
    // Set position based on vertex ID
    output.Position = float4(positions[input.VertexID], 0.0, 1.0);
    
    // Pass color to fragment shader
    output.Color = colors[input.VertexID];
    
    return output;
} 