This is an attempt to learn LÖVE and implement shoot 'em up in hyperbolic geometry.
This game is a touhou fan-game.
This game is still WIP so there could be bugs.

# How to play

It's a love2d game so you can follow [love2d tutorial](https://love2d.org/wiki/Getting_Started). Or follow steps below
1. Download [love2d](https://love2d.org/) and install
2. Download source code from this repo (click the green "Code" button near top of this page then click "Download Zip")
3. Drag the `hyperbolic_stg` folder onto `love.exe` (default install path is `C:\Program Files\LOVE`)

#### Control:
##### In Game:
Arrow keys to move.
Shift to focus (move slower).
Z to shoot.
Escape to pause.
W/R to restart current scene.
##### In Menu:
Arrow keys to move between options.
Z to choose an option.
Escape/X to go back.
###### In Choose Level Menu:
1-9 (above qwerty) to choose that level.
numpad 1-9 to choose that scene in current level.
###### In Load Replay Menu:
Enter two digits (you can use both set of number keys) to choose that replay number.
##### In Replay:
LShift to slow down by 0.5x.
LCtrl to speed up by 1x.
LAlt to speed up by 2x.

##### Dev Controls
In level: Q to switch following view or fixed view. V to switch using shader or testRotate to calculate sprites' hyperbolic rotation. (defaulted to shader and more efficient)

#### Misc:
Player gains 1 second of invincible time when hit by bullet.
Completed scenes display as green and give 10 XP each.
Perfectly completed (without being harmed) scenes display as golden and give 12 XP each.

##### Todo:
1. Rearrange levels
2. Nickname system
3. Dialogue system
4. Story


### Acknowledgements

#### Graphics

Bullet sprites and Reimu sprites (bullets.png and player.png) used in this project were shared on Discord by **Seija.Real/TryantSatanachia**. Thank you for making them available! <3
(I rearranged some sprites and drew additional sprites directly onto it)

Background and transition image in level (bg.png) is created with [Make Hyperbolic Tilings of Images](https://www.malinc.se/m/ImageTiling.php) using *Color triangle* by Vassily Kandinsky (Public Domain).

Title image (title.png) and upgrades icons (upgrades.png) are drawn by myself.

#### Audio

Music is made by me and my friend.

SFX are from th6 and [Old-school Shonen SFX](https://heltonyan.itch.io/retroanimesfx).
