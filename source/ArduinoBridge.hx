package;

import hxSerial.Serial;
using Lambda;

@:enum
abstract Command (String) to String {
    var READ    = "r";
    var SET     = "s";
    var MODE    = "m";
}

@:enum
abstract PinType (String) to String{
    var ANALOG  = "a";
    var DIGITAL = "d";
}

@:enum
abstract Mode (String) to String{
    var INPUT   = "i";
    var OUTPUT  = "o";
}

@:enum
abstract Level (String) to String{
    var HIGH    = "h";
    var LOW     = "l";
}

class ArduinoBridge
{
    static inline var ANALOG_PIN_COUNT = 6;
    static inline var DIGITAL_PIN_COUNT = 14;
    static inline var MAX_PWM_OUTPUT = 255;

    var device_ : Serial;
    var analogValues_ : Array<Null<Int>>   = [];
    var digitalValues_ : Array<Null<Bool>> = [];
    var analogMaxValues_ : Array<Int>      = [];
    var pinIsPwm_ : Array<Bool>      = [
        false, false, false, true, false, true, true, false, false, true, true,
        true, false, false
    ];

    public var report:Dynamic->Void = function(s){trace(s);}
    public var verbose:Bool;

    public function new(reportingFunction:Dynamic->Void, ver:Bool)
    {

        verbose = ver;
        report = reportingFunction;

        var deviceList;
        var usbPath : Null<String> = null;

        // Locate USB device (or wait to be plugged in)
        var count=0;
        while(usbPath == null) {
            report('Finding USB device... [${count++}]');
            Sys.sleep(1);
            deviceList = Serial.getDeviceList();
            usbPath = deviceList.find(function (path) return path.toLowerCase().indexOf("usb") != -1);
            report(usbPath);
        }

        // Establish connection with device
        device_ = new Serial(usbPath, 9600, true);
        device_.flush(true);

        count=0;
        while(device_.available() == 0) {
            Sys.sleep (1);
            report('Waiting for USB to be ready... [${count++}]');
        }

        // Say hello
        device_.flush(true);
        device_.writeBytes("A");

        // Initialise pins to no data
        for (i in 0 ... ANALOG_PIN_COUNT)
        {
            analogMaxValues_.push(1023);
            analogValues_.push(null);
        }

        for (i in 0 ... DIGITAL_PIN_COUNT)
        {
            digitalValues_.push(null);
        }
    }

    public function sync() : Void
    {
        if(device_.available() == 0)
            if(verbose) report("No data to sync");

        while (device_.available() > 0)
        {
            var command = readCommand();

            if(command==null)
                if(verbose) report("NULL COMMAND")
            else {
                if(verbose) report(command);
                parseCommand(command);
            }
        }
    }

    private function readCommand() : Null<String>
    {
        if (device_.available() == 0) {
            if(verbose) report("Nothing to read...");
            return null;
        }

        var command = "";
        var c : String = "";
        do
        {
            if (device_.available() > 0) {
                c = String.fromCharCode(device_.readByte());
                command = command + c;
            }
        }
        while (c != '\n');
        return command;
    }

    private function parseCommand(command: String) : Void
    {
        var firstByte = command.charAt(0);
        if (firstByte == HIGH || firstByte == LOW) {
            var pin = Std.parseInt(command.substring(1));
            digitalValues_[pin] = (firstByte == HIGH) ? true : false;
            if(verbose) report('Digital pin $pin set to $firstByte');
        } else {
            var indexOfPin = command.indexOf("a");
            var pin = Std.parseInt(command.substring(indexOfPin + 1));
            var value = Std.parseInt(command.substring(0, indexOfPin));
            analogValues_[pin] = value;
            if(verbose) report('Analog pin $pin set to $value');
        }
    }

    private function parseBuffer() : Void
    {
        var bytesToRead = device_.available();
        if (bytesToRead < 1) return;
        var bytes = device_.readBytes(bytesToRead);

        var readings = bytes.split("\n");
        for (reading in readings)
        {
            /*
            var firstByte = reading.charAt(0);
            if (firstByte == HIGH || firstByte == LOW) {
                var pin = Std.parseInt(reading.substring(1));
                digitalValues_[pin] = (firstByte == HIGH) ? true : false;
            } else {
                var indexOfPin = reading.indexOf("a");
                var pin = Std.parseInt(reading.substring(indexOfPin + 1));
                var value = Std.parseInt(reading.substring(0, indexOfPin));
                analogValues_[pin] = value;
            }
            */
        }
    }

    public function setDigitalPinMode(pin : Int, mode : Mode) {
        checkPin(DIGITAL, pin);

        sendCommand(MODE, [DIGITAL, mode, pin]);
    }

    public function setAnalogPinActive(pin : Int, active: Bool)
    {
        sendCommand(MODE, [ANALOG, active ? 1 : 0, pin]);
    }

    public function setDigitalPin(pin : Int, setting : Level)
    {
        if (pinIsPwm_[pin])
        {
            setPwmPin(pin, 255);
        }
        else
        {
            sendCommand(SET, [DIGITAL, pin, setting]);
        }
    }

    public function setPwmPin(pin : Int, setting : Int)
    {
        if (pinIsPwm_[pin] == false)
        {
            throw "Called setPwmPin on non-PWM pin " + pin;
        }
        if (setting < 0 || setting > MAX_PWM_OUTPUT)
        {
            throw "Invalid analog setting. Must be below" + MAX_PWM_OUTPUT;
        }
        sendCommand(SET, [ANALOG, pin, setting]);
    }


    public function setAnalogPinMax(pin : Int, maxVal: Int) : Void
    {
        checkPin(ANALOG, pin);
        analogMaxValues_[pin] = maxVal;
    }

    public function readAnalogPinRaw(pin : Int) : Null<Int>
    {
        checkPin(ANALOG, pin);
        sync();
        return analogValues_[pin];
    }

    public function readAnalogPin(pin : Int) : Null<Float>
    {
        var rawVal = readAnalogPinRaw(pin);
        if (rawVal == null)
        {
            return null;
        }
        return Math.min(rawVal / analogMaxValues_[pin], 1);
    }

    public function readDigitalPin(pin : Int) : Null<Bool>
    {
        checkPin(DIGITAL, pin);
        sync();

        return digitalValues_[pin];
    }


    private function checkPin(type : PinType, pin : Int)
    {
        var n_pins = (type == ANALOG) ? ANALOG_PIN_COUNT : DIGITAL_PIN_COUNT;
        if (pin < 0 || pin >= n_pins) {
            throw "Invalid pin. Must be below " + n_pins;
        }
    }

    public function write(bytes : String) : Void
    {
        device_.writeBytes(bytes);
    }

    public function available() : Int
    {
        return device_.available();
    }

    public function read(bytesToRead : Int) : String
    {
        return device_.readBytes(bytesToRead);
    }

    private function sendCommand(command: String, ?args : Array<Dynamic>)
    {
        if (args != null) {
            command = command + args.fold(function(x, acc)
                    return  acc + "," + Std.string(x), "") + "\n";
        }

        report("Sending command " + command);
        device_.writeBytes(command);
    }
}
