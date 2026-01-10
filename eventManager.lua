local EventManager = {}
EventManager.EVENTS={
    PLAYER_HIT='playerHit',
    PLAYER_GRAZE='playerGraze',
    PLAYER_ACCUMULATE_FLASHBOMB='playerAccumulateFlashbomb',
    NICKNAME_GET='nicknameGet',
    WIN_LEVEL='winLevel',
    LOSE_LEVEL='loseLevel',
    LEAVE_LEVEL='leaveLevel',
    SHOCKWAVE_REMOVE_BULLET='shockwaveRemoveBullet',
    SWITCH_STATE='switchState'
}
EventManager.DELETE_LISTENER='deleteListener'

EventManager.listeners = {}

---@param eventName string
---@param func function
---@param removeEventName string|nil
--- Registers a listener for an event. If `removeEventName` is provided, the listener will be removed when that event is posted.
function EventManager.listenTo(eventName, func, removeEventName)
    if not EventManager.listeners[eventName] then
        EventManager.listeners[eventName] = {}
    end
    table.insert(EventManager.listeners[eventName], func)
    if removeEventName then
        local removeFunc
        removeFunc = function()
            EventManager.removeListener(eventName, func)
            EventManager.removeListener(removeEventName, removeFunc)
        end
        EventManager.listenTo(removeEventName, removeFunc)
    end
end

function EventManager.removeListener(eventName, func)
    if not EventManager.listeners[eventName] then
        return
    end
    for i, listener in ipairs(EventManager.listeners[eventName]) do
        if listener == func then
            table.remove(EventManager.listeners[eventName], i)
            return
        end
    end
end
-- though arbitrary params can be used, since there is no ide to hint the listener function, it's suggested to use:
-- first arg: main object (if listener is a method, it will be the self)
-- second arg: quantity
-- third arg: string to tell different source 
---@param eventName string
function EventManager.post(eventName, ...)
    if EventManager.listeners[eventName] then
        for _, func in ipairs(EventManager.listeners[eventName]) do
            local ret=func(...)
            if ret == EventManager.DELETE_LISTENER then
                EventManager.removeListener(eventName, func)
            end
        end
    end
end
return EventManager