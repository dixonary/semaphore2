package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.addons.nape.*;
import flixel.system.FlxSound;
using StringTools;
using flixel.util.FlxSpriteUtil;
using Lambda;

class PlayState extends FlxState
{

    var char:Character;
    var el:Float = 0;

    var position:Float = 0;

    var currentSemaphore:Null<String>;
    var activeLetter = 0;
    var correctTimer:Float = 0;

    var currentLetterTxt:FlxText;

    var currentArm : Character.ARM = LEFT;

    var ding:FlxSound;
    var tick:BigGreenTick;

    var positions = [
        {p:"A",l:1,r:0},
        {p:"B",l:2,r:0},
        {p:"C",l:3,r:0},
        {p:"D",l:4,r:0},
        {p:"E",l:0,r:5},
        {p:"F",l:0,r:6},
        {p:"G",l:0,r:7},
        {p:"H",l:2,r:1},
        {p:"I",l:1,r:3},
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
        {p:"_",l:0,r:0}];

    override public function create():Void
    {
        super.create();

        var texts = openfl.Assets.getText("assets/data/tweets.txt").split("\n");


        currentLetterTxt = new FlxText(50,50,FlxG.width-100, texts[Math.floor(Math.random()*texts.length)]);
        //currentLetterTxt = new FlxText(50,50,FlxG.width-100, "hi");
        currentLetterTxt.setFormat("assets/fonts/gs.ttf",80, 0xff999999,flixel.text.FlxTextAlign.CENTER);
        add(currentLetterTxt);

        var quoteTxt = new FlxText(FlxG.width/2,300,FlxG.width/2-25,"@petermolydeux");
        quoteTxt.setFormat("assets/fonts/aramisi.ttf",60,0xffaaaaaa,flixel.text.FlxTextAlign.RIGHT);
        add(quoteTxt);

        currentLetterTxt.addFormat(new FlxTextFormat(0xffff0000),0,1);

        FlxG.stage.quality = openfl.display.StageQuality.BEST;
        FlxG.cameras.bgColor = 0xffeeeeee;
        FlxG.camera.antialiasing=true;

        FlxNapeSpace.init();
        FlxNapeSpace.space.gravity.setxy(0,1000);

        char = new Character(FlxG.width/2, 650);
        add(char);

        ding = new FlxSound().loadEmbedded("assets/sounds/ding.ogg");

        tick = new BigGreenTick();
        add(tick);
        tick.x = (FlxG.width-tick.width)/2;
        tick.y = (FlxG.height-tick.height)/2;

        char.moveArm(LEFT,Math.PI/2);
        char.moveArm(RIGHT,Math.PI/2);

    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        /*
        if(FlxG.keys.pressed.NUMPADTWO   ) position=0/7;
        if(FlxG.keys.pressed.NUMPADONE   ) position=1/7;
        if(FlxG.keys.pressed.NUMPADFOUR  ) position=2/7;
        if(FlxG.keys.pressed.NUMPADSEVEN ) position=3/7;
        if(FlxG.keys.pressed.NUMPADEIGHT ) position=4/7;
        if(FlxG.keys.pressed.NUMPADNINE  ) position=5/7;
        if(FlxG.keys.pressed.NUMPADSIX   ) position=6/7;
        if(FlxG.keys.pressed.NUMPADTHREE ) position=7/7;
        */

        position = 1-Reg.ard.getAnalogPin(Reg.DIAL_PIN);
        var switchPin : Bool = Reg.ard.getDigitalPin(Reg.BUTTON_PIN);

        //convert from [0..1] to target position of arms
        var scaledPosition = position * Math.PI * 2 + Math.PI * 0.5;

        // switch arm
        if(switchPin
           || FlxG.keys.justReleased.LEFT
           || FlxG.keys.justReleased.RIGHT) {
            currentArm = (currentArm == LEFT) ? RIGHT : LEFT;
        }
        char.moveArm(currentArm, scaledPosition);

        if(FlxG.keys.pressed.NUMPADMULTIPLY)
            FlxG.resetState();

        currentSemaphore = getChar();
        trace(currentSemaphore + "," + currentLetterTxt.text.charAt(activeLetter));
        if(currentSemaphore.toLowerCase() == currentLetterTxt.text.charAt(activeLetter)) {
            correctTimer+=elapsed;
            ding.play(true);
            correctTimer = 0;
            setTextPos(activeLetter+1);
            tick.show();
        }

        Reg.ard.requestAnalogPin(Reg.DIAL_PIN);
        Reg.ard.requestDigitalPin(Reg.BUTTON_PIN);

    }

    function doneWord() {
        FlxG.resetState();
    }

    function setTextPos(pos) {

        if(pos >= currentLetterTxt.text.length){
            doneWord();
            return;
        }

        activeLetter = pos;
        currentLetterTxt.clearFormats();

        //Black prefix
        currentLetterTxt.addFormat(new flixel.text.FlxTextFormat(0xff000000),0,pos);

        //Red current letter
        currentLetterTxt.addFormat(new flixel.text.FlxTextFormat(0xffff0000),pos,pos+1);

        currentLetterTxt.text = currentLetterTxt.text.replace("_"," ");
        if(currentLetterTxt.text.charAt(pos) == " ")
            currentLetterTxt.text = currentLetterTxt.text.substr(0,pos)+"_"+currentLetterTxt.text.substr(pos+1);
    }

    function getChar():Null<String> {
        var nearestPosL = Math.floor((char.armPosL/Math.PI/2+0.0625)%1*8);
        var nearestPosR = Math.floor((char.armPosR/Math.PI/2+0.0625)%1*8);

        var k = positions.find(function(s) return s.l == nearestPosL && s.r == nearestPosR);
        return k==null?null:k.p;
    }

}

class BigGreenTick extends FlxSprite {

    var size:Int = cast FlxG.height;
    public function new() {
        super();
        makeGraphic(size, size, 0x00ffffff);
        antialiasing = true;
        var points = [
            new FlxPoint(0.1,0.7),
            new FlxPoint(0.4,1),
            new FlxPoint(1,0.4),
            new FlxPoint(0.85,0.25),
            new FlxPoint(0.4,0.7),
            new FlxPoint(0.25,0.55)];

        var extremes = points.fold(function(p,x){
            if(p.x<x.minX) x.minX = p.x;
            if(p.x>x.maxX) x.maxX = p.x;
            if(p.y<x.minY) x.minY = p.y;
            if(p.y>x.maxY) x.maxY = p.y;
            return x;
        },{minX:Math.POSITIVE_INFINITY,maxX:Math.NEGATIVE_INFINITY,minY:Math.POSITIVE_INFINITY,maxY:Math.NEGATIVE_INFINITY});
        var shiftX = (1 - extremes.maxX + extremes.minX)/2 - extremes.minX;
        var shiftY = (1 - extremes.maxY + extremes.minY)/2 - extremes.minY;

        points = points.map(function(p) return new FlxPoint(p.x+shiftX, p.y+shiftY));
        drawPolygon(points.map(function(p) return new FlxPoint(p.x*size,p.y*size)),0xff00ff00);

        alpha = 0;
    }

    public function show():Void {
        alpha = 0.6;
        scale.set(1.3,1.3);
    }


    override public function update(d):Void {
        super.update(d);
        alpha/=1.08;
        scale.set((scale.x-1)/1.08+1,(scale.y-1)/1.08+1);
    }

}
