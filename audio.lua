---@class AudioSystem:Object
---@field folder string folder name in assets/ that contains audio files
---@field fileSuffix string suffix of audio files, default is .wav
---@field looping boolean if true, the audio will loop
---@field unique boolean if true, only one audio in this system can be played at a time
---@field defaultAudio string if the audio is not found, this audio will be played instead
---@field fileNames string[] list of audio file names in the folder
---@field data table<string,love.Source> table that stores audio sources
---@field audioVolumes table<string,number> table that stores audio volumes of each audio
---@field private volumeCoeff number unchangable base volume coefficient of this audio system, default is 1
---@field currentVolume number similar to volumeCoeff but can be changed by player in options menu.
---@field currentAudio string name of the currently playing audio
local AudioSystem=Object:extend()
function AudioSystem:new(args)
    self.folder=args.folder
    self.fileSuffix=args.fileSuffix or '.wav'
    self.looping=args.looping or false
    self.unique=args.unique or false
    self.defaultAudio=args.defaultAudio
    self.data={}
    self.audioVolumes={}
    self.fileNames=args.fileNames
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
    -- currentVolume is used for options, while volumeCoeff is unchangable to player
    self.currentVolume=args.currentVolume or 1
end
--- play a specific audio. When the audio is already playing, if [restart] is true, the audio will be replayed from the beginning, if false it does nothing.
---@param name string
---@param restart? boolean
---@param overrideVolume? number
function AudioSystem:play(name,restart,overrideVolume)
    if self.unique==true and self.currentAudio and self.currentAudio~=name then
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
--- set master volume of all audios (0-1 range)
--- @param volume number
function AudioSystem:setVolume(volume)
    volume=math.clamp(volume,0,1)
    for k,v in pairs(self.data)do
        v:setVolume(volume*self.volumeCoeff*self.audioVolumes[k])
    end
    self.currentVolume=volume
end
--- set volume of a specific audio (normally 0-1 range but you can set it larger to counteract a <1 volumeCoeff)
--- @param name string
--- @param volume number
function AudioSystem:setAudioVolume(name,volume)
    volume=math.clamp(volume,0,1/self.volumeCoeff)
    self.audioVolumes[name]=volume
end
---@type AudioSystem
local sfx=AudioSystem{folder='sfx',fileSuffix='.wav',fileNames={'select','graze','damage','dead','kill','cancel','timeout','enemyShot','enemyCharge','enemyPowerfulShot'},volumeCoeff=0.5}
sfx:setAudioVolume('enemyShot',0.3)
sfx:setAudioVolume('enemyCharge',0.6)
sfx:setAudioVolume('enemyPowerfulShot',0.6)
---@type AudioSystem
local bgm=AudioSystem{folder='bgm',fileSuffix='.mp3',fileNames={'title','level2'},volumeCoeff=1,looping=true,unique=true,defaultAudio='title'}
bgm:setAudioVolume('title',0.7)
bgm:setAudioVolume('level2',1)
--- @type {sfx:AudioSystem,bgm:AudioSystem}
local Audio={
    sfx=sfx,
    bgm=bgm
}
return Audio