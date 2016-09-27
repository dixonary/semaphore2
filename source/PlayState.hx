package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import flixel.addons.nape.*;
using Lambda;

class PlayState extends FlxState
{

    var char:Character;
    var el:Float = 0;

    var position:Float = 0;

    var currentSemaphore:Null<String>;
    var activeLetter = "A";
    var correctTimer:Float = 0;

    var currentLetterTxt:FlxText;

    var positions = [
        {p:"A",l:1,r:0},
        {p:"B",l:2,r:0},
        {p:"C",l:3,r:0},
        {p:"D",l:4,r:0},
        {p:"E",l:0,r:5},
        {p:"F",l:0,r:6},
        {p:"G",l:0,r:7},
        {p:"H",l:2,r:1},
        {p:"I",l:3,r:1},
        {p:"J",l:4,r:6},
        {p:"K",l:1,r:4},
        {p:"L",l:1,r:5},
        {p:"M",l:1,r:6},
        {p:"N",l:1,r:7},
        {p:"O",l:2,r:3},
        {p:"P",l:2,r:4},
        {p:"Q",l:2,r:5},
        {p:"R",l:2,r:6},
        {p:"S",l:2,r:7},
        {p:"T",l:3,r:4},
        {p:"U",l:3,r:5},
        {p:"V",l:4,r:7},
        {p:"W",l:5,r:6},
        {p:"X",l:5,r:7},
        {p:"Y",l:3,r:6},
        {p:"Z",l:7,r:6},
        {p:" ",l:0,r:0}];

    override public function create():Void
    {
        super.create();


        FlxG.stage.quality = openfl.display.StageQuality.BEST;
        FlxG.cameras.bgColor = 0xffeeeeee;
        FlxG.camera.antialiasing=true;

        FlxNapeSpace.init();

        FlxNapeSpace.space.gravity.setxy(0,1000);

        char = new Character(FlxG.width/4, 700);
        add(char);

        currentLetterTxt = new FlxText(100,100,FlxG.width, "");
        currentLetterTxt.setFormat("assets/fonts/gs.ttf",200, 0xff000000);
        add(currentLetterTxt);


    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        currentLetterTxt.text = activeLetter;

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

        currentSemaphore = getChar();
        if(currentSemaphore == activeLetter) {
            correctTimer+=elapsed;
        }

        if(correctTimer >= 0.15) {
            FlxG.sound.play("assets/sounds/ding.ogg");
            correctTimer = 0;
            activeLetter = String.fromCharCode(activeLetter.charCodeAt(0)+1);
        }

    }

    function getChar():Null<String> {
        var nearestPosL = Math.floor((char.armPosL/Math.PI/2+0.0625)%1*8);
        var nearestPosR = Math.floor((char.armPosR/Math.PI/2+0.0625)%1*8);

        var k = positions.find(function(s) return s.l == nearestPosL && s.r == nearestPosR);
        return k==null?null:k.p;
    }

}
