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

    var position:Float = 0;

    override public function create():Void
    {
        super.create();


        FlxG.stage.quality = openfl.display.StageQuality.BEST;
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

#if desktop
        if(FlxG.keys.justPressed.Q)
            Sys.exit(0);
#end

        if(FlxG.keys.pressed.NUMPADTWO   ) position=0/7;
        if(FlxG.keys.pressed.NUMPADONE   ) position=1/7;
        if(FlxG.keys.pressed.NUMPADFOUR  ) position=2/7;
        if(FlxG.keys.pressed.NUMPADSEVEN ) position=3/7;
        if(FlxG.keys.pressed.NUMPADEIGHT ) position=4/7;
        if(FlxG.keys.pressed.NUMPADNINE  ) position=5/7;
        if(FlxG.keys.pressed.NUMPADSIX   ) position=6/7;
        if(FlxG.keys.pressed.NUMPADTHREE ) position=7/7;

        //convert from [0..1] to target position of arms
        var scaledPosition = position * Math.PI * 7 / 4 + Math.PI * 0.5;

        if(FlxG.keys.pressed.A)
            char.moveArm(LEFT,scaledPosition);
        if(FlxG.keys.pressed.D)
            char.moveArm(RIGHT,scaledPosition);

    }

}
