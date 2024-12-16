local AudioSystem=Object:extend()
function AudioSystem:new(args)
    self.folder=args.folder
    self.fileSuffix=args.fileSuffix or '.wav'
    self.looping=args.looping or false
    self.data={}
    self.audioVolumes={}
    for k,v in pairs(args.fileNames)do
        self.data[v]=love.audio.newSource('assets/'..self.folder..'/'..v..self.fileSuffix,'static')
        self.audioVolumes[v]=1
        if self.looping then
            self.data[v]:setLooping(true)
        end
    end
    self.volumeCoeff=args.volumeCoeff or 1
    -- volume is used for options, while volumeCoeff is unchangable to player
    self.volume=args.volume or 1
end
function AudioSystem:play(name,restart,overrideVolume)
    if restart then
        love.audio.stop(self.data[name])
    end
    self.data[name]:setVolume(self.currentVolume*self.volumeCoeff*(overrideVolume or self.audioVolumes[name]))
    self.data[name]:play()
end
-- set master volume of all audios (0-1 range)
function AudioSystem:setVolume(volume)
    volume=math.clamp(volume,0,1)
    for k,v in pairs(self.data)do
        v:setVolume(volume*self.volumeCoeff*self.audioVolumes[k])
    end
    self.currentVolume=volume
end
-- set volume of a specific audio (0-1 range)
function AudioSystem:setAudioVolume(name,volume)
    volume=math.clamp(volume,0,1)
    self.audioVolumes[name]=volume
end
local sfx=AudioSystem{folder='sfx',fileSuffix='.wav',fileNames={'select','graze','damage','dead','kill','cancel','timeout','enemyShot','enemyCharge','enemyPowerfulShot'},volumeCoeff=0.5}
sfx:setAudioVolume('enemyShot',0.3)
sfx:setAudioVolume('enemyCharge',0.6)
sfx:setAudioVolume('enemyPowerfulShot',0.6)
local bgm=AudioSystem{folder='bgm',fileSuffix='.mp3',fileNames={'title'},volumeCoeff=1,looping=true}
local Audio={
    sfx=sfx,
    bgm=bgm
}
return Audio