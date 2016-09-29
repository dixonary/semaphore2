package;

import cpp.vm.Thread;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.addons.nape.*;
import flixel.system.FlxSound;
import haxe_arduino.ArduinoBridge;
using StringTools;
using flixel.util.FlxSpriteUtil;
using Lambda;

class SetupState extends FlxState
{

    var setupText:FlxText;
    var recheck:Float = 0;
    var ready:Bool = false;

    override public function create():Void
    {
        super.create();

        FlxG.cameras.bgColor = 0xffffffff;
        setupText = new FlxText(0,0,FlxG.width,"");
        setupText.color = 0xff000000;
        setupText.size = 16;
        add(setupText);
        var t = Thread.create(setupArduino);

    }

    function setupArduino() {

        Reg.ard = new ArduinoBridge();

        Reg.ard.setDigitalPin(Reg.LED_PIN, HIGH);
        Reg.ard.setAnalogPinMax(Reg.DIAL_PIN, 650);
        Reg.ard.setAnalogPinActive(Reg.DIAL_PIN, true);

        while(true) {
            Sys.sleep(0.0016);
            Reg.ard.sync();
        }

    }

    function writeOut(s:Dynamic):Void {
        trace(s);
        setupText.text += Std.string(s)+"\n";
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if(Reg.ard != null) {
            recheck -= elapsed;
            if(recheck <= 0) {
                recheck += 0.25;

                if(Reg.ard.getAnalogPin(Reg.DIAL_PIN) != null) {
                    writeOut("CONNECTION ESTABLISHED!");
                    writeOut("Press SPACE to continue");
                    ready = true;
                }
                Reg.ard.requestAnalogPin(Reg.DIAL_PIN);
            }
        }

        if(FlxG.keys.justPressed.SPACE && ready)
            FlxG.switchState(new PlayState());

    }

}

