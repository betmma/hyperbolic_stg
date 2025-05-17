This is an attempt to learn LÖVE and implement shoot 'em up in hyperbolic geometry.
This game is a touhou fan-game.
This game is still WIP so there could be bugs.

#### Control:
##### In Game:
Arrow keys to move.
Shift to focus (move slower).
Z to shoot.
Escape to pause.
##### In Menu:
Arrow keys to move between options.
Z to choose an option.
Escape/X to go back.
##### In Replay:
LShift to slow down by 0.5x.
LCtrl to speed up by 1x.
LAlt to speed up by 2x.

#### Misc:
Player gains 1 second of invincible time when hit by bullet.
Completed scenes display as green and give 10 XP each.
Perfectly completed (without being harmed) scenes display as golden and give 12 XP each.

##### Todo:
1. Use shader to draw hyperbolic polygon in background.
2. Use shader to perform Player:testRotate (hyperbolic rotate).
(I suppose these two will hugely improve efficiency)


### Acknowledgements

#### Graphics

Bullet sprites and Reimu sprites (bullets.png and player.png) used in this project were shared on Discord by **Seija.Real/TryantSatanachia**. Thank you for making them available! <3
(I rearranged some sprites and drew additional sprites directly onto it)

Background and transition image in level (bg.png) is created with [Make Hyperbolic Tilings of Images](https://www.malinc.se/m/ImageTiling.php) using *Color triangle* by Vassily Kandinsky (Public Domain).

Title image (title.png) and upgrades icons (upgrades.png) are drawn by myself.

#### Audio

Music is made by myself.

SFX are from th6.
