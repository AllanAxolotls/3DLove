local mathlib = {}

--// optimisations
local sin = math.sin
local cos = math.cos
local tan = math.tan
local rad = math.rad
local abs = math.abs
local min = math.min
local max = math.max

local pi = math.pi
local sqrt = math.sqrt
local floor = math.floor
local ceil = math.ceil
local huge = math.huge
local round = function(x) return floor(x + 0.5) end

local asin = math.asin
local acos = math.acos
local atan = math.atan

--// Utility
function mathlib.Type(T)
    return T.Type or type(T)
end

function mathlib.Class(T)
    if type(T) ~= "table" then return type(T) end
    if T.Type == "Vector2" or T.Type == "Vector3" or T.Type == "Vector4" then return "Vector" end
    if T.Type == "Matrix3" or T.Type == "Matrix4" then return "Matrix" end
end

function mathlib.Convert(T, To)
    if To == "Vector2" then
        if mathlib.Type(T) == "Vector2" then return T end
        if mathlib.Type(T) == "Vector3" then return mathlib.Vector2(T.x, T.y) end
        if mathlib.Type(T) == "Vector4" then return mathlib.Vector2(T.x, T.y) end
    elseif To == "Vector3" then
        if mathlib.Type(T) == "Vector2" then return mathlib.Vector3(T.x, T.y, 0) end
        if mathlib.Type(T) == "Vector3" then return T end
        if mathlib.Type(T) == "Vector4" then return mathlib.Vector3(T.x, T.y, T.z) end
    elseif To == "Vector4" then
        if mathlib.Type(T) == "Vector2" then return mathlib.Vector4(T.x, T.y, 0, 1) end
        if mathlib.Type(T) == "Vector3" then return mathlib.Vector4(T.x, T.y, T.z, 1) end
        if mathlib.Type(T) == "Vector4" then return T end

    elseif To == "Matrix3" then
        if mathlib.Type(T) == "Matrix3" then return T end
        if mathlib.Type(T) == "Matrix4" then return mathlib.Matrix3(T[1], T[2], T[3], T[5], T[6], T[7], T[9], T[10], T[11]) end
    elseif To == "Matrix4" then
        if mathlib.Type(T) == "Matrix3" then return mathlib.Matrix4(T[1], T[2], T[3], 0, T[4], T[5], T[6], 0, T[7], T[8], T[9], 0, 0, 0, 0, 0) end
        if mathlib.Type(T) == "Matrix4" then return T end

    elseif To == "string" then
        if mathlib.Type(T) == "Vector2" then return "(" .. T.x .. ", " .. T.y .. ")" end
        if mathlib.Type(T) == "Vector3" then return "(" .. T.x .. ", " .. T.y .. ", " .. T.z .. ")" end
        if mathlib.Type(T) == "Vector4" then return "(" .. T.x .. ", " .. T.y .. ", " .. T.z .. ", " .. T.w .. ")" end
        if mathlib.Type(T) == "Matrix3" then
            return "{" .. T[1] .. ", " .. T[2] .. ", " .. T[3] .. "},\n" ..
            "{" .. T[4] .. ", " .. T[5] .. ", " .. T[6] .. "},\n" ..
            "{" .. T[7] .. ", " .. T[8] .. ", " .. T[9] .. "},\n"
        end
        if mathlib.Type(T) == "Matrix4" then
            return "{" .. T[1] .. ", " .. T[2] .. ", " .. T[3] .. ", " .. T[4] .. "},\n" ..
            "{" .. T[5] .. ", " .. T[6] .. ", " .. T[7] .. ", " .. T[8] .. "},\n" ..
            "{" .. T[9] .. ", " .. T[10] .. ", " .. T[11] .. ", " .. T[12] .. "},\n" ..
            "{" .. T[13] .. ", " .. T[14] .. ", " .. T[15] .. ", " .. T[16] .. "},\n"
        end
    end
end

function mathlib.Color3ToArray4(Color3)
    return {Color3[1], Color3[2], Color3[3], 1}
end

--// Vector2
local Vector2 = {Type = "Vector2"}
Vector2.__index = Vector2

function mathlib.Vector2(X, Y)
    local self = setmetatable({
        x = X or 0;
        y = Y or 0;
    }, Vector2)
    return self
end

function Vector2:Unpack() return self.x, self.y end
function Vector2:Copy() return mathlib.Vector2(self.x, self.y) end
function Vector2:Length() return sqrt(self:Dot(self)) end
function Vector2:Dot(V) return self.x * V.x + self.y * V.y end
function Vector2:Unit() local l = self:Length(); return mathlib.Vector2(self.x / l, self.y / l) end
function Vector2:Normalise() local l = self:Length(); self.x = self.x / l; self.y = self.y / l; return self end
function Vector2:ToArray() return {self.x, self.y} end
function Vector2:Negate() return mathlib.Vector2(-self.x, -self.y) end
function Vector2:Set(V) self.x = V.x; self.y = V.y end
function Vector2:SetXY(x, y) self.x = x or 0; self.y = y or 0 end
function Vector2:IsEq(x, y) if self.x == x and self.y == y then return true end; return false end

function Vector2.__add(self, V) return mathlib.Vector2(self.x + V.x, self.y + V.y) end
function Vector2.__sub(self, V) return mathlib.Vector2(self.x - V.x, self.y - V.y) end
function Vector2.__mul(self, k) return mathlib.Vector2(self.x * k, self.y * k) end
function Vector2.__div(self, k) return mathlib.Vector2(self.x / k, self.y / k) end
--// Vector3
local Vector3 = {Type = "Vector3"}
Vector3.__index = Vector3

function mathlib.Vector3(X, Y, Z)
    local self = setmetatable({
        x = X or 0;
        y = Y or 0;
        z = Z or 0;
    }, Vector3)
    return self
end

function Vector3:Cross(V)
    return mathlib.Vector3(
        self.y * V.z - self.z * V.y,
        self.z * V.x - self.x * V.z,
        self.x * V.y - self.y * V.x
    )
end

function Vector3:Unpack() return self.x, self.y, self.z end
function Vector3:Copy() return mathlib.Vector3(self.x, self.y, self.z) end
function Vector3:Length() return sqrt(self:Dot(self)) end
function Vector3:Dot(V) return self.x * V.x + self.y * V.y + self.z * V.z end
function Vector3:Unit() local l = self:Length(); return mathlib.Vector3(self.x / l, self.y / l, self.z / l) end
function Vector3:Normalise() local l = self:Length(); self.x = self.x / l; self.y = self.y / l; self.z = self.z / l; return self end
function Vector3:ToArray(w) return {self.x, self.y, self.z, w or 1} end
function Vector3:ToString() return "(" .. self.x .. ", " .. self.y .. ", " .. self.z .. ")" end
function Vector3:ToIntString() return "(" .. round(self.x) .. ", " .. round(self.y) .. ", " .. round(self.z) .. ")" end
function Vector3:Negate() return mathlib.Vector3(-self.x, -self.y, -self.z) end
function Vector3:Set(V) self.x = V.x; self.y = V.y; self.z = V.z end
function Vector3:SetXYZ(x, y, z) self.x = x or 0; self.y = y or 0; self.z = z or 0; end
function Vector3:IsEq(x, y, z) if self.x == x and self.y == y and self.z == z then return true end; return false end

function Vector3.__add(self, V) return mathlib.Vector3(self.x + V.x, self.y + V.y, self.z + V.z) end
function Vector3.__sub(self, V) return mathlib.Vector3(self.x - V.x, self.y - V.y, self.z - V.z) end
function Vector3.__mul(self, k) return mathlib.Vector3(self.x * k, self.y * k, self.z * k) end
function Vector3.__div(self, k) return mathlib.Vector3(self.x / k, self.y / k, self.z / k) end

--// Vector4
local Vector4 = {Type = "Vector4"}
Vector4.__index = Vector4

function mathlib.Vector4(X, Y, Z, W)
    local self = setmetatable({
        x = X or 0;
        y = Y or 0;
        z = Z or 0;
        w = W or 1;
    }, Vector4)
    return self
end

function Vector4:Unpack(notw) if notw then return self.x, self.y, self.z else return self.x, self.y, self.z, self.w end end
function Vector4:Copy() return mathlib.Vector4(self.x, self.y, self.z, self.w) end
function Vector4:Length() return sqrt(self:Dot(self)) end
function Vector4:Dot(V) return self.x * V.x + self.y * V.y + self.z * V.z + self.w * V.w end
function Vector4:Unit() local l = self:Length(); return mathlib.Vector4(self.x / l, self.y / l, self.z / l, self.w / l) end
function Vector4:Normalise() local l = self:Length(); self.x = self.x / l; self.y = self.y / l; self.z = self.z / l; self.w = self.w / l; return self end
function Vector4:ToArray(w) return {self.x, self.y, self.z, w or self.w} end
function Vector4:ToString() return "(" .. self.x .. ", " .. self.y .. ", " .. self.z .. ", " .. self.w ..  ")" end
function Vector4:Negate(UseW) return mathlib.Vector4(-self.x, -self.y, -self.z, UseW and -self.w or 1) end
function Vector4:Set(V) self.x = V.x; self.y = V.y; self.z = V.z; self.w = V.w end
function Vector4:SetXYZ(x, y, z) self.x = x or 0; self.y = y or 0; self.z = z or 0; end
function Vector4:IsEq(x, y, z, w) if self.x == x and self.y == y and self.z == z and self.w == w then return true end; return false end

function Vector4.__add(self, V) return mathlib.Vector4(self.x + V.x, self.y + V.y, self.z + V.z, self.w + V.w) end
function Vector4.__sub(self, V) return mathlib.Vector4(self.x - V.x, self.y - V.y, self.z - V.z, self.w - V.w) end
function Vector4.__mul(self, k) return mathlib.Vector4(self.x * k, self.y * k, self.z * k, self.w * k) end
function Vector4.__div(self, k) return mathlib.Vector4(self.x / k, self.y / k, self.z / k, self.w / k) end

--// Matrix3
local Matrix3 = {Type = "Matrix3"}
Matrix3.__index = Matrix3

function mathlib.Matrix3(m1, m2, m3,  m4, m5, m6,  m7, m8, m9)
    local self = setmetatable({
        m1 or 0, m2 or 0, m3 or 0, m4 or 0, m5 or 0, m6 or 0, m7 or 0, m8 or 0, m9 or 0
    }, Matrix3)
    return self
end

function Matrix3:Transpose()
    return mathlib.Matrix3(self[1], self[4], self[7], self[2], self[5], self[8], self[3], self[6], self[9])
end

function Matrix3:Inverse()
    local a, b, c, d, e, f, g, h, i = unpack(self)
    local determinant = (a*e*i)+(b*f*g)+(c*d*h)-(c*e*g)-(b*d*i)-(a*f*h)
    if determinant == 0 then error("Matrix is not invertible") end
    --// Craete Inverse
    return mathlib.Matrix3(
        ((e*i)-(f*h))/determinant, ((c*h)-(b*i))/determinant, ((b*f)-(c*e))/determinant,
        ((f*g)-(d*i))/determinant, ((a*i)-(c*g))/determinant, ((c*d)-(a*f))/determinant,
        ((d*h)-(e*g))/determinant, ((b*g)-(a*h))/determinant, ((a*e)-(b*d))/determinant
    )
end

function Matrix3.__mul(self, T)
    local IsVector3 = mathlib.Type(T) == "Vector3"
    local IsMatrix3 = mathlib.Type(T) == "Matrix3"
    assert(IsVector3 or IsMatrix3, "Can only be multiplied by Vector3 or another Matrix3, used: " .. mathlib.Type(T))

    if IsVector3 then
        local M, X, Y, Z = self, T.x, T.y, T.z
        return mathlib.Vector3(
            X * M[1] + Y * M[4] + Z * M[7], --// X
            X * M[2] + Y * M[5] + Z * M[8], --// Y
            X * M[3] + Y * M[6] + Z * M[9] --// Z
        )
    elseif IsMatrix3 then
        local a, b, c, d, e, f, g, h, i = unpack(self)
        local j, k, l, m, n, o, p, q, r = unpack(T)
        return mathlib.Matrix3(
            a*j + b*m + c*p, a*k + b*n + c*q, a*l + b*o + c*r,
            d*j + e*m + f*p, d*k + e*n + f*q, d*l + e*o + f*r,
            g*j + h*m + i*p, g*k + h*n + i*q, g*l + h*o + i*r
        )
    end
end

--// Matrix4
local Matrix4 = {Type = "Matrix4"}
Matrix4.__index = Matrix4

function mathlib.Matrix4(m1,m2,m3,m4, m5,m6,m7,m8, m9,m10,m11,m12, m13,m14,m15,m16)
    local self = setmetatable({
        m1 or 0,m2 or 0,m3 or 0,m4 or 0,m5 or 0,m6 or 0,m7 or 0,m8 or 0,m9 or 0,m10 or 0,m11 or 0,m12 or 0,m13 or 0,m14 or 0,m15 or 0,m16 or 0
    }, Matrix4)
    return self
end

function Matrix4:Transpose()
    return mathlib.Matrix4(
        self[1], self[5], self[9], self[13],
        self[2], self[6], self[10], self[14],
        self[3], self[7], self[11], self[15],
        self[4], self[8], self[12], self[16]
    )
end

function Matrix4:ToString()
    return "{" .. self[1] .. ", " .. self[2] .. ", " .. self[3] .. ", " .. self[4] .. "}/n" .. 
    "{" .. self[5] .. ", " .. self[6] .. ", " .. self[7] .. ", " .. self[8] .. "}/n" .. 
    "{" .. self[9] .. ", " .. self[10] .. ", " .. self[11] .. ", " .. self[12] .. "}/n" .. 
    "{" .. self[13] .. ", " .. self[14] .. ", " .. self[15] .. ", " .. self[16] .. "}/n"
end

function Matrix4:Inverse()
    local a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p = unpack(self)
    local determinant = a*((f*((k*p)-(l*o)))-(g*((j*p)-(l*n)))+(h*((j*o)-(k*n)))) -
                        b*((e*((k*p)-(l*o)))-(g*((i*p)-(l*m)))+(h*((i*o)-(k*m)))) +
                        c*((e*((j*p)-(l*n)))-(f*((i*p)-(l*m)))+(h*((i*n)-(j*m)))) -
                        d*((e*((j*o)-(k*n)))-(f*((i*o)-(k*m)))+(g*((i*n)-(j*m))))
    if determinant == 0 then error("Matrix is not invertible") end
    return mathlib.Matrix4(
        ((f*((k*p)-(l*o)))-(g*((j*p)-(l*n)))+(h*((j*o)-(k*n))))/determinant,
        -((b*((k*p)-(l*o)))-(c*((j*p)-(l*n)))+(d*((j*o)-(k*n))))/determinant,
        ((b*((g*p)-(h*o)))-(c*((f*p)-(h*n)))+(d*((f*o)-(g*n))))/determinant,
        -((b*((g*l)-(h*k)))-(c*((f*l)-(h*j)))+(d*((f*k)-(g*j))))/determinant,
        -((e*((k*p)-(l*o)))-(g*((i*p)-(l*m)))+(h*((i*o)-(k*m))))/determinant,
        ((a*((k*p)-(l*o)))-(c*((i*p)-(l*m)))+(d*((i*o)-(k*m))))/determinant,
        -((a*((g*p)-(h*o)))-(c*((e*p)-(h*m)))+(d*((e*o)-(g*m))))/determinant,
        ((a*((g*l)-(h*k)))-(c*((e*l)-(h*i)))+(d*((e*k)-(g*i))))/determinant,
        ((e*((j*p)-(l*n)))-(f*((i*p)-(l*m)))+(h*((i*n)-(j*m))))/determinant,
        -((a*((j*p)-(l*n)))-(b*((i*p)-(l*m)))+(d*((i*n)-(j*m))))/determinant,
        ((a*((f*p)-(h*n)))-(b*((e*p)-(h*m)))+(d*((e*n)-(f*m))))/determinant,
        -((a*((f*l)-(h*j)))-(b*((e*l)-(h*i)))+(d*((e*j)-(f*i))))/determinant,
        ((a*((j*o)-(k*n)))-(b*((i*o)-(k*m)))+(c*((i*n)-(j*m))))/determinant
    )
end

function Matrix4.__mul(self, T)
    local IsVector4 = mathlib.Type(T) == "Vector4"
    local IsMatrix4 = mathlib.Type(T) == "Matrix4"
    assert(IsVector4 or IsMatrix4, "Can only be multiplied by Vector4 or another Matrix4, used: " .. mathlib.Type(T))

    if IsVector4 then
        local X, Y, Z, W = T.x, T.y, T.z, T.w
        return mathlib.Vector4(
            X * self[1] + Y * self[5] + Z * self[9]  + W * self[13], --// X
            X * self[2] + Y * self[6] + Z * self[10] + W * self[14], --// Y
            X * self[3] + Y * self[7] + Z * self[11] + W * self[15], --// Z
            X * self[4] + Y * self[8] + Z * self[12] + W * self[16]  --// W
        )
    elseif IsMatrix4 then
        local s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15, s16 = unpack(self)
        local t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16 = unpack(T)

        return mathlib.Matrix4(
            s1 * t1 + s2 * t5 + s3 * t9 + s4 * t13,
            s1 * t2 + s2 * t6 + s3 * t10 + s4 * t14,
            s1 * t3 + s2 * t7 + s3 * t11 + s4 * t15,
            s1 * t4 + s2 * t8 + s3 * t12 + s4 * t16,
    
            s5 * t1 + s6 * t5 + s7 * t9 + s8 * t13,
            s5 * t2 + s6 * t6 + s7 * t10 + s8 * t14,
            s5 * t3 + s6 * t7 + s7 * t11 + s8 * t15,
            s5 * t4 + s6 * t8 + s7 * t12 + s8 * t16,
    
            s9 * t1 + s10 * t5 + s11 * t9 + s12 * t13,
            s9 * t2 + s10 * t6 + s11 * t10 + s12 * t14,
            s9 * t3 + s10 * t7 + s11 * t11 + s12 * t15,
            s9 * t4 + s10 * t8 + s11 * t12 + s12 * t16,
    
            s13 * t1 + s14 * t5 + s15 * t9 + s16 * t13,
            s13 * t2 + s14 * t6 + s15 * t10 + s16 * t14,
            s13 * t3 + s14 * t7 + s15 * t11 + s16 * t15,
            s13 * t4 + s14 * t8 + s15 * t12 + s16 * t16
        )
    end
end

--// More advances functions
function mathlib.IdentityMatrix4()
    return mathlib.Matrix4(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)
end

function mathlib.TranslationMatrix4(X, Y, Z)
    return mathlib.Matrix4(1,0,0,X, 0,1,0,Y, 0,0,1,Z, 0,0,0,1)
end

function mathlib.ReverseTranslation(M)
    return mathlib.TranslationMatrix4(-M[4], -M[8], -M[12])
end

function mathlib.ScaleMatrix(X, Y, Z, Uniform)
    if Uniform then
        return mathlib.Matrix4(X,0,0,0, 0,X,0,0, 0,0,X,0, 0,0,0,1)
    else
        return mathlib.Matrix4(X,0,0,0, 0,Y,0,0, 0,0,Z,0, 0,0,0,1)
    end
end

function mathlib.XRotationMatrix4(Rad)
   local s, c = sin(Rad), cos(Rad)
   return mathlib.Matrix4(1,0,0,0, 0,c,-s,0, 0,s,c,0, 0,0,0,1)
end

function mathlib.YRotationMatrix4(Rad)
    local s, c = sin(Rad), cos(Rad)
    return mathlib.Matrix4(c,0,-s,0, 0,1,0,0, s,0,c,0, 0,0,0,1)
end

function mathlib.ZRotationMatrix4(Rad)
    local s, c = sin(Rad), cos(Rad)
    return mathlib.Matrix4(c,-s,0,0, s,c,0,0, 0,0,1,0, 0,0,0,1)
end

function mathlib.RotationMatrix4(X, Y, Z, IsRad)
    if IsRad then
        return mathlib.ZRotationMatrix4(Z) * (mathlib.YRotationMatrix4(Y) * mathlib.XRotationMatrix4(X))
    else
        return mathlib.ZRotationMatrix4(rad(Z)) * (mathlib.YRotationMatrix4(rad(Y)) * mathlib.XRotationMatrix4(rad(X)))
    end
end

function mathlib.ReverseRotation(M)
    local Z = asin(M[5]) --// Index 5 only used by ZRotation
    local Y = asin(M[9]) --// Same here
    local X = asin(M[10])
    return mathlib.RotationMatrix4(X, Y, Z, true)
end

function mathlib.WorldMatrix(Object)
    local Position, Rotation, Size = Object.Position or Object.position, Object.Rotation or Object.rotation, Object.Size or Object.size
    local TranslationMatrix = mathlib.TranslationMatrix4(Position.x, Position.y, Position.z)
    local RotationMatrix = mathlib.RotationMatrix4(Rotation.x, Rotation.y, Rotation.z)
    local ScaleMatrix = mathlib.ScaleMatrix(Size.x, Size.y, Size.z, false)
    return TranslationMatrix * (RotationMatrix * ScaleMatrix)
end

function mathlib.ProjectionMatrix(Near, Far, FOV)
    local TanFOV = tan( rad(FOV * 0.5) )
    local d = -1 / TanFOV
    local zRange = Near - Far
    local A = (-Far - Near) / zRange
    local B = -2 * Far * Near / zRange
    return mathlib.Matrix4(d,0,0,0, 0,d,0,0, 0,0,A,B, 0,0,1,0)
end

function mathlib.CameraTransform(Target, Up)
    local N = Target
    local U = Up:Cross(N):Normalise()
    local V = N:Cross(U)

    return mathlib.Matrix4(
        U.x, U.y, U.z, 0,
        V.x, V.y, V.z, 0,
        N.x, N.y, N.z, 0,
        0,   0,   0,   1
    )
end

function mathlib.WorldToLocal(World, Position)
    local Inverse = mathlib.Convert(World, "Matrix3"):Inverse()
    return Inverse * Position
end

local PiShiftLookup = {
    1.57; -- 1.10010110101001
    1.25; -- 1.00000000000000
    0.79; -- 0.11000000000000
    0.49; -- 0.01100100100100
    0.24; -- 0.00011001001001
    0.12; -- 0.00000110010010
    0.06; -- 0.00000001100101
    0.03; -- 0.00000000110010
    0.01; -- 0.00000000011001
    0.005; -- 0.00000000001110
    0.003; -- 0.00000000000111
    0.001; -- 0.00000000000001
    0.0005; -- 0.00000000000000
    0.0002; -- 0.00000000000000
    0.0001; -- 0.00000000000000
    0.00005; -- 0.00000000000000
    0.00003; -- 0.00000000000000
    0.00001; -- 0.00000000000000
    0.000005; -- 0.00000000000000
    0.000003; -- 0.00000000000000
}

local k = 1 / (2^0.5)
local bit32 = require("bit")

function mathlib.Sin(Angle)
    local x, y, z = bit32.lshift(1, 15), 0, Angle
    for i = 0, 19 do
        local dtheta = PiShiftLookup[i + 1]
        local new_x
        if z >= 0 then
            new_x = x - bit32.rshift(y, i)
            y = bit32.rshift(x, i) + y
            x = new_x
            z = z - dtheta
        else
            new_x = x + bit32.rshift(y, i)
            y = -bit32.rshift(x, i) + y
            x = new_x
            z = z + dtheta
        end
    end
    return y
end

function mathlib.Cos(Angle)
    local x, y, z = bit32.lshift(1, 15), 0, Angle
    for i = 0, 19 do
        local dtheta = PiShiftLookup[i + 1]
        local new_x
        if z >= 0 then
            new_x = x - bit32.rshift(y, i)
            y = bit32.rshift(x, i) + y
            x = new_x
            z = z - dtheta
        else
            new_x = x + bit32.rshift(y, i)
            y = -bit32.rshift(x, i) + y
            x = new_x
            z = z + dtheta
        end
    end
    return x
end

--// Globals
mathlib.VectorY1 = mathlib.Vector3(0, 1, 0)

return mathlib