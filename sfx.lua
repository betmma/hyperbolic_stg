local sfx
sfx={
    select=...,
    graze=...,
    damage=...
}
for k,v in pairs(sfx)do
    sfx[k]=love.audio.newSource('assets/audio/'..k..'.wav','static')
end
return sfx