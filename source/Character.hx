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
using flixel.util.FlxSpriteUtil;

class Character extends FlxTypedGroup<FlxNapeSprite> {

    var torso    :FlxNapeSprite;
    var shoulders:FlxNapeSprite;
    var upperArmL:FlxNapeSprite;
    var upperArmR:FlxNapeSprite;
    var lowerArmL:FlxNapeSprite;
    var lowerArmR:FlxNapeSprite;
    var legL     :FlxNapeSprite;
    var legR     :FlxNapeSprite;
    var head     :FlxNapeSprite;

    var armPinL  :PivotJoint;
    var armPinR  :PivotJoint;

    static inline var upperArmLength = 250;
    static inline var lowerArmLength = 225;
    static inline var armGirth       = 70;
    static inline var armGap         = 5;
    static inline var legGirth       = 85;
    static inline var legLength      = 400;
    static inline var headSize       = 160;
    static inline var headGap        = 5;

    public function new(startX:Float, startY:Float) {
        super();

        buildBody(startX,startY);

        moveArm(LEFT,0,0);
    }

    public function moveArm(which:ARM, x:Float, y:Float) {
        var arm = which==LEFT?lowerArmL:lowerArmR;
        var armAnchorPos = new Vec2(0,arm.height/2-arm.width/2);
        var newArmPos    = new Vec2(x,y);

        switch(which) {
        case LEFT:
            if(armPinL == null) {
                armPinL = new PivotJoint(arm.body,FlxNapeSpace.space.world, armAnchorPos, newArmPos);
                armPinL.stiff = false;
                armPinL.damping = 2;
                armPinL.frequency = 2;
                armPinL.space = FlxNapeSpace.space;
            }
            else
                armPinL.anchor2 = newArmPos;
        case RIGHT:
            if(armPinR == null) {
                armPinR = new PivotJoint(arm.body,FlxNapeSpace.space.world, armAnchorPos, newArmPos);
                armPinR.stiff = false;
                armPinR.damping = 2;
                armPinR.frequency = 2;
                armPinR.space = FlxNapeSpace.space;
            }
            else
                armPinR.anchor2 = newArmPos;
        }
    }

    function buildBody(startX:Float,startY:Float) {
        // TORSO (fixed in place)
        torso = buildBodyPart(startX, startY, 180,300, RECTANGLE);

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
                0,armGirth/2-upperArmLength/2,true);

        affix(upperArmL,lowerArmL,
                0,upperArmLength/2-armGirth/2,
                0, armGirth/2-lowerArmLength/2, true);

        // RIGHT ARM
        upperArmR = buildBodyPart(startX,startY,armGirth,upperArmLength,OBLONG_V);
        lowerArmR = buildBodyPart(startX,startY,armGirth,lowerArmLength,OBLONG_V);
        affix(torso,upperArmR,
                torso.width/2+armGirth/2+armGap,-torso.height/2,
                0,armGirth/2-upperArmLength/2,true);

        affix(upperArmR,lowerArmR,
                0,upperArmLength/2-armGirth/2,
                0, armGirth/2-lowerArmLength/2, true);

        // HEAD
        head = buildBodyPart(startX,startY,headSize,headSize,ELLIPSE);
        affix(torso,head,
                0,-torso.height/2-shoulders.height/2,
                0,headSize/2+headGap,false);

    }

    function affix(part1:FlxNapeSprite, part2:FlxNapeSprite,
                   x1, y1, x2, y2, rotates:Bool) {
        var cons:Constraint;
        if(rotates) {
            cons = new PivotJoint(
                    part1.body,
                    part2.body,
                    new Vec2(x1,y1),
                    new Vec2(x2,y2));

            cons.space=FlxNapeSpace.space;
            /*
            cons = new AngleJoint(
                    part1.body,
                    part2.body,
                    0,0);
            cons.stiff = false;
            cons.frequency=1;
            cons.damping = 0.8;
            */
        }
        else {
            cons = new WeldJoint(
                    part1.body,
                    part2.body,
                    new Vec2(x1,y1),
                    new Vec2(x2,y2));
        }

        cons.space=FlxNapeSpace.space;
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

        sprite.body.setShapeFilters(new InteractionFilter(0));

        return sprite;

    }

    override public function update(d:Float) {
        super.update(d);
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
