float3 add(float3 lhs, float3 rhs) {
  return float3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z);
}

float mag(float3 vec) {
  return sqrt(dot(vec, vec));
}

float3x3 RotY(float ang)
{
    return float3x3
    (
        cos(ang), 0, sin(ang),
        0,1,0,
        -sin(ang),0,cos(ang)
    );
}

float3x3 RotX(float ang)
{
    return float3x3
        (
            1,0,0,
            0,cos(ang),-sin(ang),
            0,sin(ang),cos(ang)
        );

}

float3x3 RotZ(float ang)
{
    return float3x3
        (
          cos(ang), -sin(ang), 0,
            sin(ang), cos(ang), 0,
            0,0,1


            );
}


float rand(float3 co)
{
    return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
}

float3 WorldSpaceViewDir (float3 v) {
  return _WorldSpaceCameraPos.xyz - v;
}

// Returns true if the point is outside the bounds set by lower and higher
bool IsOutOfBounds(float3 p, float3 lower, float3 higher) {
    return p.x < lower.x || p.x > higher.x || p.y < lower.y || p.y > higher.y || p.z < lower.z || p.z > higher.z;
}

// Returns true if the given vertex is outside the camera fustum and should be culled
bool IsPointOutOfFrustum(float4 positionCS, float tolerance) {
    float3 culling = positionCS.xyz;
    float w = positionCS.w;
    // UNITY_RAW_FAR_CLIP_VALUE is either 0 or 1, depending on graphics API
    // Most use 0, however OpenGL uses 1
    float3 lowerBounds = float3(-w - tolerance, -w - tolerance, -w * UNITY_RAW_FAR_CLIP_VALUE - tolerance);
    float3 higherBounds = float3(w + tolerance, w + tolerance, w + tolerance);
    return IsOutOfBounds(culling, lowerBounds, higherBounds);
}

// Returns true if the points in this triangle are wound counter-clockwise
bool ShouldBackFaceCull(float4 p0PositionCS, float4 p1PositionCS, float4 p2PositionCS, float tolerance) {
    float3 point0 = p0PositionCS.xyz / p0PositionCS.w;
    float3 point1 = p1PositionCS.xyz / p1PositionCS.w;
    float3 point2 = p2PositionCS.xyz / p2PositionCS.w;
    // In clip space, the view direction is float3(0, 0, 1), so we can just test the z coord
#if UNITY_REVERSED_Z
    return cross(point1 - point0, point2 - point0).z < -tolerance;
#else // In OpenGL, the test is reversed
    return cross(point1 - point0, point2 - point0).z > tolerance;
#endif
}

// Returns true if it should be clipped due to frustum or winding culling
bool ShouldClipPatch(float4 p0PositionCS, float4 p1PositionCS, float4 p2PositionCS, float tolerance_FR, float tolerance_BF) {
    bool allOutside = IsPointOutOfFrustum(p0PositionCS, tolerance_FR) &&
        IsPointOutOfFrustum(p1PositionCS, tolerance_FR) &&
        IsPointOutOfFrustum(p2PositionCS, tolerance_FR);
    return allOutside || ShouldBackFaceCull(p0PositionCS, p1PositionCS, p2PositionCS, tolerance_BF);
}
