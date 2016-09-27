package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.addons.nape.*;
import nape.callbacks.*;
import nape.constraint.*;
import nape.dynamics.*;
import nape.geom.*;
import nape.phys.*;
import flixel.math.FlxPoint;
using flixel.util.FlxSpriteUtil;

class Character extends FlxGroup {

    var torso    :FlxNapeSprite;
    var shoulders:FlxNapeSprite;
    var upperArmL:FlxNapeSprite;
    var upperArmR:FlxNapeSprite;
    var lowerArmL:FlxNapeSprite;
    var lowerArmR:FlxNapeSprite;
    var legL     :FlxNapeSprite;
    var legR     :FlxNapeSprite;
    var head     :FlxNapeSprite;

    var lFlag    :Flag;
    var rFlag    :Flag;

    var armPinL  :PivotJoint;
    var armPinR  :PivotJoint;

    var upperArmLength = sc(250);
    var lowerArmLength = sc(225);
    var armGirth       = sc(70);
    var armGap         = sc(5);
    var legGirth       = sc(85);
    var legLength      = sc(400);
    var headSize       = sc(160);
    var headGap        = sc(5);
    var torsoWidth     = sc(180);
    var torsoHeight    = sc(300);

    //Groups for sorting the two flags
    var upperGroup:FlxGroup;
    var lowerGroup:FlxGroup;


    public static function sc(i:Int):Int{
        return cast i/2;
    }

    public function new(startX:Float, startY:Float) {
        super();

        lowerGroup = new FlxGroup();
        upperGroup = new FlxGroup();
        buildBody(startX,startY);

        add(lowerGroup);
        add(upperGroup);

    }

    public function moveArm(which:ARM, pos:Float) {
        var arm = which==LEFT?lowerArmL:lowerArmR;
        var upperArm = which==LEFT?upperArmL:upperArmR;
        var armAnchorPos = new Vec2(0,arm.height/2-arm.width/2);
        var dist = (upperArmLength + lowerArmLength )*1.5;

        var xp = Math.cos(pos)*0.8 * dist + torso.body.position.x
            +(which==LEFT?-1:1)*(torso.width/2+armGap+armGirth/2);
        var yp = Math.sin(pos)*0.8 * dist + torso.body.position.y-torso.height/2;
        var newArmPos    = new Vec2(xp,yp);

        switch(which) {
        case LEFT:
            if(armPinL == null) {
                armPinL = new PivotJoint(arm.body,FlxNapeSpace.space.world,
                        armAnchorPos, newArmPos);
                armPinL.stiff = false;
                armPinL.damping = 3;
                armPinL.frequency = 4;
                armPinL.space = FlxNapeSpace.space;
            }
            else
                armPinL.anchor2 = newArmPos;
        case RIGHT:
            if(armPinR == null) {
                armPinR = new PivotJoint(arm.body,FlxNapeSpace.space.world,
                        armAnchorPos, newArmPos);
                armPinR.stiff = false;
                armPinR.damping = 3;
                armPinR.frequency = 4;
                armPinR.space = FlxNapeSpace.space;
            }
            else
                armPinR.anchor2 = newArmPos;
        }
    }

    function buildBody(startX:Float,startY:Float) {
        // TORSO (fixed in place)
        torso = buildBodyPart(startX, startY, torsoWidth, torsoHeight, RECTANGLE);

        torso.body.allowMovement = false;
        torso.body.allowRotation = false;

        // SHOULDERS
        shoulders=buildBodyPart(startX,startY,cast torso.width,armGirth,OBLONG_H);
        affix(torso,shoulders,0,-torso.height/2,0,0,false);

        // LEGS
        legL = buildBodyPart(startX,startY,legGirth,legLength,OBLONG_V);
        legR = buildBodyPart(startX,startY,legGirth,legLength,OBLONG_V);
        affix(torso,legL,
                legGirth/2-torso.width/2,torso.height/2,
                0,legGirth/2-legLength/2,false);
        affix(torso,legR,
                -legGirth/2+torso.width/2,torso.height/2,
                0,legGirth/2-legLength/2,false);

        // LEFT ARM
        upperArmL = buildBodyPart(startX,startY,armGirth,upperArmLength,OBLONG_V);
        lowerArmL = buildBodyPart(startX,startY,armGirth,lowerArmLength,OBLONG_V);
        affix(torso,upperArmL,
                -torso.width/2-armGirth/2-armGap,-torso.height/2,
                0,armGirth/2-upperArmLength/2,true,false);

        affix(upperArmL,lowerArmL,
                0,upperArmLength/2-armGirth/2,
                0, armGirth/2-lowerArmLength/2, true,true);

        // RIGHT ARM
        upperArmR = buildBodyPart(startX,startY,armGirth,upperArmLength,OBLONG_V);
        lowerArmR = buildBodyPart(startX,startY,armGirth,lowerArmLength,OBLONG_V);
        affix(torso,upperArmR,
                torso.width/2+armGirth/2+armGap,-torso.height/2,
                0,armGirth/2-upperArmLength/2,true,false);

        affix(upperArmR,lowerArmR,
                0,upperArmLength/2-armGirth/2,
                0, armGirth/2-lowerArmLength/2, true,true);

        lFlag = new Flag(LEFT, upperGroup, lowerGroup);
        rFlag = new Flag(RIGHT,upperGroup, lowerGroup);
        affix(lFlag, lowerArmL, 0,0, 0,lowerArmLength/2,false);
        affix(rFlag, lowerArmR, 0,0, 0,lowerArmLength/2,false);

        // HEAD
        head = buildBodyPart(startX,startY,headSize,headSize,ELLIPSE);
        affix(torso,head,
                0,-torso.height/2-shoulders.height/2,
                0,headSize/2+headGap,false);

    }

    function affix(part1:FlxNapeSprite, part2:FlxNapeSprite,
                   x1, y1, x2, y2, rotates:Bool, ?straightens:Bool=false) {
        var cons:Constraint;
        if(rotates) {
            cons = new PivotJoint(
                    part1.body,
                    part2.body,
                    new Vec2(x1,y1),
                    new Vec2(x2,y2));

            cons.space=FlxNapeSpace.space;
            if(straightens) {
                var cons2 = new AngleJoint(
                        part1.body,
                        part2.body,0,0);
                cons2.stiff = false;
                cons2.space=FlxNapeSpace.space;
                cons2.frequency=2;
                cons2.damping = 5;
            }
        }
        else {
            cons = new WeldJoint(
                    part1.body,
                    part2.body,
                    new Vec2(x1,y1),
                    new Vec2(x2,y2));
            cons.space=FlxNapeSpace.space;
        }

    }

    function buildBodyPart(
            xPosition:Float,
            yPosition:Float,
            width:Int,
            height:Int,
            shape:PART_SHAPE):FlxNapeSprite {

        var color:Int = 0xff000000;

        var sprite = new FlxNapeSprite(xPosition, yPosition);
        sprite.createRectangularBody(width,height);

        switch(shape) {
        case RECTANGLE:
            sprite.makeGraphic(width,height,color);
        case OBLONG_H:
            sprite.makeGraphic(width, height, 0x00000000);
            sprite.drawCircle(height/2,height/2,height/2,color);
            sprite.drawCircle(width-height/2,height/2,height/2,color);
            sprite.drawRect(height/2,0,width-height,height,color);
        case OBLONG_V:
            sprite.makeGraphic(width, height, 0x00000000);
            sprite.drawCircle(width/2,width/2,width/2,color);
            sprite.drawCircle(width/2,height-width/2,width/2,color);
            sprite.drawRect(0,width/2,width,height-width,color);
        case ELLIPSE:
            sprite.makeGraphic(width, height, 0x00000000);
            sprite.drawEllipse(0,0,width,height,color);
        }

        add(sprite);
        sprite.antialiasing=true;

        sprite.body.mass = 10;

        sprite.body.setShapeFilters(new InteractionFilter(0));

        return sprite;

    }

    override public function update(d:Float) {
        super.update(d);

        // Disable over-stretching of arm joints
        if(upperArmL.body.rotation - lowerArmL.body.rotation < -Math.PI)
            lowerArmL.body.rotation -= Math.PI*2;

        if(upperArmL.body.rotation - lowerArmL.body.rotation > Math.PI)
            lowerArmL.body.rotation += Math.PI*2;

        if(upperArmR.body.rotation - lowerArmR.body.rotation < -Math.PI)
            lowerArmR.body.rotation -= Math.PI*2;

        if(upperArmR.body.rotation - lowerArmR.body.rotation > Math.PI)
            lowerArmR.body.rotation += Math.PI*2;

    }

}

class Flag extends FlxNapeSprite {

    var which:ARM;

    var poleWidth = Character.sc(10);
    var poleLength = Character.sc(400);
    var flagSize = Character.sc(200);
    var upperGroup:FlxGroup;
    var lowerGroup:FlxGroup;
    var under = false;

    public function new(_which:ARM, uGroup:FlxGroup, lGroup:FlxGroup) {
        super();
        which = _which;

        createRectangularBody(flagSize, poleLength);
        body.mass=1;
        makeGraphic(flagSize, poleLength, 0x00000000);
        antialiasing=true;
        drawRect(0,0,poleWidth, poleLength, 0xff000000);
        drawRect(poleWidth, poleLength-flagSize,
                flagSize-poleWidth, flagSize,0xffff0000);
        drawPolygon([
                new FlxPoint(poleWidth, poleLength-flagSize),
                new FlxPoint(flagSize,  poleLength),
                new FlxPoint(flagSize, poleLength-flagSize)],
        0xffffff00);

        origin.set(0,0);
        body.setShapeFilters(new InteractionFilter(0));

        upperGroup = uGroup;
        lowerGroup = lGroup;

        upperGroup.add(this);

    }

    public override function update(d):Void {
        super.update(d);

        var validLeft = function(a:Float) return a < 185 || a > 355;
        var validRight = function(a:Float) return a < 175 && a > 5;

        var validator = which==LEFT ? validLeft : validRight;

        var a = angle%360;
        if(a<0)a+=360;
        scale.x += ((validator(a)?1:-1)-scale.x) /10;

        if(!under && validator(a)) {
            upperGroup.remove(this);
            lowerGroup.add(this);
            under = true;
        }
        else if(under && validator(a))  {
            upperGroup.add(this);
            lowerGroup.remove(this);
            under = false;
        }

    }

}

enum PART_SHAPE {
    RECTANGLE;
    OBLONG_H;
    OBLONG_V;
    ELLIPSE;
}

enum ARM {
    LEFT;
    RIGHT;
}
