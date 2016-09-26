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
    var el:Float = 0;

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
#if cpp
        if(FlxG.keys.justPressed.Q)
            Sys.exit(0);
#end


        el += elapsed;
        if(el > 2) {
            el-=2;
        var po = Math.random()*Math.PI*2;
        var xp = FlxG.width/2 + Math.cos(po)*0.8 * FlxG.width/2;
        var yp = FlxG.height/2 - Math.sin(po)*0.8 * FlxG.width/2;
        char.moveArm(LEFT,xp,yp);
        char.moveArm(RIGHT,xp,yp);
        }
    }

}
