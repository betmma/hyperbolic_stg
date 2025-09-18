return {
    ID=122,
    user='nina',
    spellName='Truth "Manmade Virus"',
    make=function()
        G.levelIsTimeoutSpellcard=true
        G.levelRemainingFrame=3600
        Shape.removeDistance=10000
        local center={x=400,y=1000}
        local a,b
        local en
        local player=Player{x=400,y=2000}
        player.moveMode=Player.moveModes.Natural
        player.border:remove()
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,150,12))
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
    end,
}