local AudioSystem=Object:extend()
function AudioSystem:new(args)
    self.folder=args.folder
    self.fileSuffix=args.fileSuffix or '.wav'
    self.looping=args.looping or false
    self.unique=args.unique or false -- if true, only one audio in this system can be played at a time
    self.defaultAudio=args.defaultAudio
    self.data={}
    self.audioVolumes={}
    for k,v in pairs(args.fileNames)do
        local path='assets/'..self.folder..'/'..v..self.fileSuffix
        if not love.filesystem.getInfo(path)then
            goto continue
        end
        self.data[v]=love.audio.newSource(path,'static')
        self.audioVolumes[v]=1
        if self.looping then
            self.data[v]:setLooping(true)
        end
        ::continue::
    end
    self.volumeCoeff=args.volumeCoeff or 1
    -- volume is used for options, while volumeCoeff is unchangable to player
    self.currentVolume=args.currentVolume or 1
end
-- play a specific audio. If restart is true, the audio will be played from the beginning, otherwise if the audio is already playing, it does nothing.
function AudioSystem:play(name,restart,overrideVolume)
    if self.unique and self.currentAudio and self.currentAudio~=name then
        love.audio.stop(self.data[self.currentAudio])
    end
    if not self.data[name] then
        if self.defaultAudio then
            name=self.defaultAudio
        else
            return
        end
    end
    if restart==true then
        love.audio.stop(self.data[name])
    end
    self.data[name]:setVolume(self.currentVolume*self.volumeCoeff*(overrideVolume or self.audioVolumes[name]))
    self.data[name]:play()
    self.currentAudio=name
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
local bgm=AudioSystem{folder='bgm',fileSuffix='.mp3',fileNames={'title','level1','level2'},volumeCoeff=1,looping=true,unique=true,defaultAudio='title'}
bgm:setAudioVolume('level1',0.8)
local Audio={
    sfx=sfx,
    bgm=bgm
}
return Audio