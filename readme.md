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
1-9 (above qwerty) to choose that level. '0' chooses 10, '-' chooses 11, '=' chooses 12 (current EX).
numpad 1-9 to choose that scene in current level.
###### In Load Replay Menu:
Enter three digits (you can use both set of number keys) to choose that replay number.
##### In Replay:
LShift to slow down by 0.5x.
LCtrl to speed up by 1x.
LAlt to speed up by 2x.

##### Dev Controls
###### In level:
Q to switch following view or fixed view. 
V to switch using shader or testRotate to calculate sprites' hyperbolic rotation. It's defaulted to shader that is more efficient, and will display "Using Rotation Shader" at bottom right.
E to switch Hyperbolic model if is following view (player is fixed at center of the screen) and using hyperbolic rotation shader. There are UHP, Poincare Disk and Klein Disk available.

#### Misc:
Player gains 1 second of invincible time when hit by bullet.
Completed scenes display as green and give 10 XP each.
Perfectly completed (without being harmed) scenes display as golden and give 12 XP each.

##### Todo:
1. Story
2. Current notice.lua is for modals, and nickname unlock notices (toasts) are arranged by Nickname. Could possibly merge


### Acknowledgements

#### Graphics

Bullet sprites and Reimu sprites (bullets.png and player.png) used in this project were shared on Discord by **Seija.Real/TryantSatanachia**. Thank you for making them available! <3
(I rearranged some sprites and drew additional sprites directly onto it)

Background and transition image in level (bg.png) is created with [Make Hyperbolic Tilings of Images](https://www.malinc.se/m/ImageTiling.php) using *Color triangle* by Vassily Kandinsky (Public Domain).

Title image (title.png) and upgrades icons (upgrades.png) are drawn by myself.

Enemy portraits in dialogue and small portraits in level are drawn by myself.

#### Audio

Music is made by me and my friend.

SFX are from th6 and [Old-school Shonen SFX](https://heltonyan.itch.io/retroanimesfx).
Sticky SFX is by [freesound_community](https://pixabay.com/users/freesound_community-46691455/?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=43763) from [Pixabay](https://pixabay.com//?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=43763)
