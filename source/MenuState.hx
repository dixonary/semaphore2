package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import flixel.addons.nape.*;

class MenuState extends FlxState
{

    var char:Character;

    override public function create():Void
    {
        super.create();

        FlxG.cameras.bgColor = 0xffeeeeee;
        FlxG.camera.antialiasing=true;

        FlxNapeSpace.init();

        FlxNapeSpace.space.gravity.setxy(0,1000);

        char = new Character(FlxG.width/2, FlxG.height/2);
        add(char);

    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if(FlxG.keys.justPressed.Q)
            Sys.exit(0);
    }

}
