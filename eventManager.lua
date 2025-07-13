local EventManager = {}
EventManager.listeners = {}
function EventManager.listenTo(eventName, func)
    if not EventManager.listeners[eventName] then
        EventManager.listeners[eventName] = {}
    end
    table.insert(EventManager.listeners[eventName], func)
end
-- though arbitrary params can be used, since there is no ide to hint the listener function, it's suggested to use:
-- first arg: main object (if listener is a method, it will be the self)
-- second arg: quantity
-- third arg: string to tell different source 
function EventManager.post(eventName, ...)
    if EventManager.listeners[eventName] then
        for _, func in ipairs(EventManager.listeners[eventName]) do
            func(...)
        end
    end
end
return EventManager