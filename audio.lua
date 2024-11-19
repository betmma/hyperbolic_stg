local AudioSystem=Object:extend()
function AudioSystem:new(args)
    self.folder=args.folder
    self.fileSuffix=args.fileSuffix or '.wav'
    self.looping=args.looping or false
    self.data={}
    for k,v in pairs(args.fileNames)do
        self.data[v]=love.audio.newSource('assets/'..self.folder..'/'..v..self.fileSuffix,'static')
        if self.looping then
            self.data[v]:setLooping(true)
        end
    end
    self.volumeCoeff=args.volumeCoeff or 1
    -- volume is used for options, while volumeCoeff is unchangable to player
    self.volume=args.volume or 1
end
function AudioSystem:play(name,restart)
    if restart then
        love.audio.stop(self.data[name])
    end
    self.data[name]:play()
end
function AudioSystem:setVolume(volume)
    volume=math.clamp(volume,0,1)
    for k,v in pairs(self.data)do
        v:setVolume(volume*self.volumeCoeff)
    end
    self.currentVolume=volume
end
local sfx=AudioSystem{folder='sfx',fileSuffix='.wav',fileNames={'select','graze','damage','dead','kill','cancel'},volumeCoeff=0.5}
local bgm=AudioSystem{folder='bgm',fileSuffix='.mp3',fileNames={'title'},volumeCoeff=1,looping=true}
local Audio={
    sfx=sfx,
    bgm=bgm
}
return Audio