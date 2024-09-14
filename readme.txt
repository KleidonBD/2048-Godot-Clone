2048 Clone

This is a simple clone of 2048 I made completely by myself using Godot 4.x. I had no outside help and everything aside from the background shader was made from scratch by me as a personal challenge to help me learn programming and game development.

The background shader I borrowed from Exuin on godotshaders.com and made a small tweak to:
https://godotshaders.com/shader/moving-rainbow-gradient/

How to play:
 * For Windows users, simply download and run 2048.exe.
 * For other platforms, download the repository and import it to Godot 4.3. You can either run the game in debug mode through the engine or export it yourself.
 * The game is controlled with the arrow keys.

Notes:
* It is a known issue that when maximizing the game window, the last letter of some buttons get truncated. This fixes itself once the button is hovered over. I think this might be an engine bug and I have no idea how to fix it, nor do I really care to as it's pretty minor and this is just a practice project.
* High score is not saved between sessions. This would have been simple enough to implement, but I didn't think it was worth creating save files on users' systems for such a simple practice project.