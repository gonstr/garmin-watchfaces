import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;
import Toybox.Weather;

class SlateReading {
    var label as String;
    var value as String = "—";
    var kind as Symbol = :text;
    var fraction as Numeric? = null;
    var history as Array<Numeric>? = null;
    var temperatureRange as Array<Numeric>? = null;

    function initialize(name as String) {
        label = name;
    }
}

class OrbitSlate {
    private const PLATE_RADIUS = 117;
    private const PLATE = 0x2B373B;
    private const MUTED = 0x8EA2A6;
    private const ENGRAVED = 0x7B9094;
    private const READING = 0xC3CECE;
    private const TRACK = 0x4F6267;
    private const HAND_GREEN = 0x70F235;
    private const THREE = [
        [-6.85,-6],[-5.20,-7],[3.88,-7],[5.86,-6.5],[6.85,-5.2],[6.85,-2],[6.02,-.6],[3.71,0],[-1.90,0],
        [],[3.71,0],[6.02,.6],[6.85,2],[6.85,5.2],[5.86,6.5],[3.88,7],[-5.20,7],[-6.85,6]
    ];
    private const NINE = [
        [6.85,0],[-3.71,0],[-6.02,-.6],[-6.85,-1.8],[-6.85,-5.1],[-6.02,-6.5],[-3.71,-7],
        [3.88,-7],[6.02,-6.5],[6.85,-5.1],[6.85,5.1],[6.02,6.5],[3.88,7],[-4.37,7],[-6.19,6]
    ];
    private const LABELS = ["DAYLIGHT", "STEPS", "BODY BATTERY", "HEART RATE",
        "TEMPERATURE", "STRESS", "CALORIES", "DISTANCE", "PRESSURE", "TRAINING STATUS"];
    // Each polyline uses a small common coordinate box.
    private const ICONS = [
            [[-5,3],[5,3],[],[-4,1],[-2,-2],[0,-3],[2,-2],[4,1]],
            [[-4,-3],[-3,-1],[-2,0],[],[2,0],[3,2],[4,3]],
            [[-5,2],[-5,-2],[-4,-3],[3,-3],[4,-2],[5,-2],[5,2],[4,2],[3,3],[-4,3],[-5,2],[],[-1,1],[1,-2]],
            [[-5,0],[-3,0],[-1,-3],[0,3],[2,-1],[3,0],[5,0]],
            [[-5,2],[-5,0],[-3,-1],[-2,-3],[0,-3],[2,-1],[4,-1],[5,1],[4,2],[-5,2]],
            [[-5,2],[-3,2],[-1,-2],[1,3],[3,-1],[5,-1]],
            [[0,-4],[3,-1],[4,2],[2,4],[-2,4],[-4,2],[-2,-1],[-1,1],[0,-4]],
            [[-4,4],[-4,-4],[4,-4],[2,-2],[4,0],[-4,0]],
            [[-5,2],[-4,-1],[-2,-3],[2,-3],[4,-1],[5,2],[],[0,2],[2,-1]],
            [[-4,3],[-4,0],[],[0,3],[0,-3],[],[4,3],[4,-1]]
        ];
    private var cache as Dictionary<Number, SlateReading> = {};
    private var cacheMinute as Number = -1;

    function draw(dc as Graphics.Dc, cx as Numeric, cy as Numeric, scale as Numeric,
        moment as Time.Moment, now as Gregorian.Info, sleeping as Boolean) as Void {
        dc.setAntiAlias(true);
        var plate = sleeping ? 0x101416 : PLATE;
        var minute = now.min + (sleeping ? 0 : now.sec / 60.0);
        var hourAngle = (now.hour % 12 + minute / 60) * Math.PI / 6;
        if (sleeping) {
            disk(dc, cx, cy, 150 * scale, 0x080A0A);
        } else {
            drawChannel(dc, cx, cy, scale);
            drawChannelWash(dc, cx, cy, scale, hourAngle);
        }
        dc.setPenWidth(1);
        dc.setColor(sleeping ? 0x121818 : 0x424748, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, 149.5 * scale);
        for (var index = 0; index < 12; index++) {
            if (index == 3 || index == 9) {
                continue;
            }
            var axis = index == 0 || index == 6;
            dc.setColor(axis ? 0x050607 : 0x101314, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(sleeping ? 1 : ((axis ? 2.9 : 1.8) * scale).toNumber());
            radial(dc, cx, cy, (axis ? PLATE_RADIUS : 128) * scale, 150 * scale, index * Math.PI / 6);
        }

        hand(dc, cx, cy, scale, hourAngle, 149, 2.2, 1.7, sleeping ? 0x417D32 : HAND_GREEN);
        disk(dc, cx, cy, PLATE_RADIUS * scale, plate);
        var numeralRadius = (PLATE_RADIUS + 150) / 2.0;

        drawNumeral(dc, cx + numeralRadius * scale, cy, scale, THREE, sleeping);
        drawNumeral(dc, cx - numeralRadius * scale, cy, scale, NINE, sleeping);
        if (!sleeping) {
            var date = Gregorian.info(moment, Time.FORMAT_MEDIUM);
            label(dc, cx + 88 * scale, cy - 7 * scale, scale,
                date.day_of_week.toString().toUpper(), 7, 0x9BA9AB);
            label(dc, cx + 88 * scale, cy + 4 * scale, scale,
                date.day.format("%d") + " " + date.month.toString().toUpper(), 10, 0xB9C6C7);
            drawComplications(dc, cx, cy, scale, moment);
        }
        dc.setAntiAlias(false);
    }

    private function drawNumeral(dc as Graphics.Dc, cx as Numeric, cy as Numeric,
        scale as Numeric, points as Array<Array<Numeric>>, sleeping as Boolean) as Void {
        if (!sleeping) {
            dc.setColor(0x42494B, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth((2.1 * scale).toNumber());
            drawNumeralStroke(dc, cx + .4 * scale, cy + .65 * scale, scale, points);
        }
        dc.setColor(sleeping ? 0x374344 : 0x0C1113, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth((1.9 * scale).toNumber());
        drawNumeralStroke(dc, cx, cy, scale, points);
    }

    private function drawNumeralStroke(dc as Graphics.Dc, cx as Numeric, cy as Numeric,
        scale as Numeric, points as Array<Array<Numeric>>) as Void {
        for (var i = 1; i < points.size(); i++) {
            var a = points[i - 1];
            var b = points[i];
            if (a.size() == 2 && b.size() == 2) {
                dc.drawLine(cx + a[0] * scale, cy + a[1] * scale,
                    cx + b[0] * scale, cy + b[1] * scale);
            }
        }
    }

    private function drawChannel(dc as Graphics.Dc, cx as Numeric, cy as Numeric,
        scale as Numeric) as Void {
        // Keep the channel floor matte, with a short falloff at the outer wall.
        var colors = [0x111416, 0x191D1F, 0x202426, 0x25292B, 0x272B2D];
        for (var i = 0; i < colors.size(); i++) {
            disk(dc, cx, cy, (150 - 2 * i) * scale, colors[i]);
        }
        // Center the contact shadow under the raised plate.
        var shadow = [0x282D30, 0x24292C, 0x202528, 0x1C2123,
            0x171C1E, 0x121719, 0x0E1214, 0x0B0F11];
        for (var i = 0; i < shadow.size(); i++) {
            disk(dc, cx, cy, (PLATE_RADIUS + 8 - i) * scale, shadow[i]);
        }
    }

    private function drawChannelWash(dc as Graphics.Dc, cx as Numeric, cy as Numeric,
        scale as Numeric, hourAngle as Numeric) as Void {
        var x = cx + 83 * scale * Math.sin(hourAngle);
        var y = cy - 83 * scale * Math.cos(hourAngle);
        var layers = [0x010401, 0x010601, 0x020802, 0x020A02, 0x020D03];
        dc.setBlendMode(Graphics.BLEND_MODE_ADDITIVE);
        for (var i = 0; i < layers.size(); i++) {
            disk(dc, x, y, (66 - i * 6.5) * scale, layers[i]);
        }
        dc.setBlendMode(Graphics.BLEND_MODE_SOURCE_OVER);
    }

    private function drawComplications(dc as Graphics.Dc, cx as Numeric, cy as Numeric,
        scale as Numeric, now as Time.Moment) as Void {
        var minute = now.value() / 60;
        if (cacheMinute != minute) {
            cacheMinute = minute;
            cache = {};
        }

        if (Application.Properties.getValue("ShowCenterData") != false) {
            var source = selected("SlateFeatured", 0);
            drawFeatured(dc, cx, cy, scale, reading(source, now));
        }
        if (Application.Properties.getValue("ShowComplications") != false) {
            var left = selected("SlateLeft", 1);
            var right = selected("SlateRight", 2);
            drawSmall(dc, cx - 33 * scale, cy + 45 * scale, scale, left, reading(left, now));
            drawSmall(dc, cx + 33 * scale, cy + 45 * scale, scale, right, reading(right, now));
        }
    }

    private function selected(key as String, fallback as Number) as Number {
        var value = Application.Properties.getValue(key);
        return value instanceof Number && value >= 0 && value < LABELS.size() ? value : fallback;
    }

    private function reading(source as Number, now as Time.Moment) as SlateReading {
        var cached = cache[source];
        if (cached != null) {
            return cached;
        }
        var result = new SlateReading(LABELS[source]);
        if (source == 0) {
            readDaylight(result, now);
        } else if (source == 1 || source == 6 || source == 7) {
            readActivity(result, source);
        } else if (source == 2) {
            var value = complication(Complications.COMPLICATION_TYPE_BODY_BATTERY);
            if ((value instanceof Number || value instanceof Float) && value >= 0 && value <= 100) {
                result.value = value.format("%.0f") + "%";
                result.fraction = value.toFloat() / 100;
            }
            result.kind = :progress;
        } else if (source == 3 || source == 5 || source == 8) {
            readHistory(result, source);
        } else if (source == 4) {
            readWeather(result);
        } else {
            var status = complication(Complications.COMPLICATION_TYPE_TRAINING_STATUS);
            if (status instanceof String && status.length() > 0) {
                result.value = status;
            }
        }
        cache[source] = result;
        return result;
    }

    private function readActivity(result as SlateReading, source as Number) as Void {
        var activity = ActivityMonitor.getInfo();
        var steps = activity.steps;
        var goal = activity.stepGoal;
        var calories = activity.calories;
        var distance = activity.distance;
        result.kind = :progress;
        if (source == 1 && steps != null) {
            result.value = steps.format("%d");
            if (goal != null && goal > 0) {
                result.fraction = steps.toFloat() / goal;
            }
        } else if (source == 6 && calories != null) {
            result.value = calories.format("%d") + " kcal";
            result.fraction = calories / 2400.0;
        } else if (source == 7 && distance != null) {
            var miles = System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE;
            result.value = (distance / (miles ? 160934.4 : 100000.0)).format("%.1f") + (miles ? " mi" : " km");
            result.fraction = distance / 1000000.0;
        }
    }

    private function complication(kind as Complications.Type) as Complications.Value? {
        try {
            return Complications.getComplication(new Complications.Id(kind)).value;
        } catch (ex instanceof Complications.ComplicationNotFoundException) {
            return null;
        }
    }

    private function readWeather(result as SlateReading) as Void {
        var conditions = Weather.getCurrentConditions();
        if (conditions == null) {
            return;
        }
        var temperature = conditions.temperature;
        if (temperature == null) {
            return;
        }
        var fahrenheit = System.getDeviceSettings().temperatureUnits == System.UNIT_STATUTE;
        result.value = (fahrenheit ? temperature * 1.8 + 32 : temperature).format("%.0f") + (fahrenheit ? "°F" : "°C");
        var low = conditions.lowTemperature;
        var high = conditions.highTemperature;
        if (low != null && high != null && high > low) {
            result.kind = :range;
            result.temperatureRange = [temperature, low, high];
        }
    }

    private function readDaylight(result as SlateReading, now as Time.Moment) as Void {
        result.kind = :window;
        var conditions = Weather.getCurrentConditions();
        var position = conditions == null ? null : conditions.observationLocationPosition;
        if (position == null) {
            return;
        }
        var rise = Weather.getSunrise(position, now);
        var sunset = Weather.getSunset(position, now);
        if (rise != null && sunset != null && rise.value() < sunset.value()) {
            var current = now.value();
            if (current >= rise.value() && current < sunset.value()) {
                var remaining = (sunset.value() - current + 59) / 60;
                result.value = (remaining / 60).format("%d") + "h " + (remaining % 60).format("%02d") + "m left";
                result.fraction = (current - rise.value()).toFloat() / (sunset.value() - rise.value());
                return;
            }
            if (current >= sunset.value()) {
                rise = Weather.getSunrise(position, now.add(new Time.Duration(86400)));
            }
        }
        if (rise != null) {
            var time = Gregorian.info(rise, Time.FORMAT_SHORT);
            var is24Hour = System.getDeviceSettings().is24Hour;
            var hour = is24Hour ? time.hour : (time.hour + 11) % 12 + 1;
            var suffix = is24Hour ? "" : (time.hour < 12 ? " AM" : " PM");
            result.value = "Sunrise " + hour.format(is24Hour ? "%02d" : "%d") + ":" + time.min.format("%02d") + suffix;
        }
    }

    private function readHistory(result as SlateReading, source as Number) as Void {
        var values = [] as Array<Numeric>;
        if (source == 3) {
            var heart = ActivityMonitor.getHeartRateHistory(24, true);
            if (heart != null) {
                for (var item = heart.next(); item != null; item = heart.next()) {
                    if (item.heartRate != ActivityMonitor.INVALID_HR_SAMPLE && item.heartRate > 0) {
                        values.add(item.heartRate);
                    }
                }
            }
        } else {
            var options = {:period => 24, :order => SensorHistory.ORDER_NEWEST_FIRST};
            var iterator = source == 5 ? SensorHistory.getStressHistory(options) : SensorHistory.getPressureHistory(options);
            for (var sample = iterator.next(); sample != null; sample = iterator.next()) {
                var value = sample.data;
                if (value != null && (source == 5 ? value >= 0 && value <= 100 : value > 0)) {
                    values.add(value);
                }
            }
        }
        result.kind = :history;
        result.history = values;
        if (values.size() > 0) {
            result.value = source == 3 ? values[0].format("%.0f") + " bpm"
                : source == 5 ? values[0].format("%.0f") : (values[0] / 100.0).format("%.0f") + " hPa";
        }
    }

    private function drawFeatured(dc as Graphics.Dc, cx as Numeric, cy as Numeric,
        scale as Numeric, reading as SlateReading) as Void {
        var width = 74 * scale;
        var left = cx - width / 2;
        var x = left;
        var y = cy - 20 * scale;
        labelFit(dc, cx, cy + 1 * scale, scale, reading.value,
            reading.kind == :window ? 15 : 20, 116, READING);
        label(dc, cx, cy + 20 * scale, scale, reading.label, 7, ENGRAVED);
        if (reading.kind == :text) {
            return;
        }
        dc.setPenWidth((1.15 * scale).toNumber());
        if (reading.kind == :window) {
            var fraction = reading.fraction;
            dc.setColor(TRACK, Graphics.COLOR_TRANSPARENT);
            for (var i = 0; i < 2; i++) {
                if (i == 1 && fraction == null) {
                    break;
                }
                var limit = i == 0 ? 1.0 : fraction as Numeric;
                dc.setColor(i == 0 ? TRACK : MUTED, Graphics.COLOR_TRANSPARENT);
                var lastX = left;
                var lastY = cy - 20 * scale;
                for (var j = 1; j <= 20; j++) {
                    var t = limit * j / 20;
                    x = left + width * t;
                    y = cy + (-20 - 48 * t * (1 - t)) * scale;
                    dc.drawLine(lastX, lastY, x, y);
                    lastX = x;
                    lastY = y;
                }
            }
            if (fraction != null) {
                disk(dc, x, y, 1.65 * scale, READING);
            }
        } else if (reading.kind == :progress) {
            var segment = width / 10;
            var progress = reading.fraction;
            for (var i = 0; i < 10; i++) {
                var start = left + i * segment;
                var barWidth = segment - 2 * scale;
                dc.setColor(TRACK, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(start, y - 1.4 * scale, barWidth, 2.8 * scale, scale);
                if (progress != null && progress * 10 > i) {
                    var filled = progress * 10 - i;
                    dc.setColor(MUTED, Graphics.COLOR_TRANSPARENT);
                    dc.fillRoundedRectangle(start, y - 1.4 * scale, barWidth * (filled > 1 ? 1 : filled), 2.8 * scale, scale);
                }
            }
            dc.setColor(MUTED, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(left + width + scale, y - 2.8 * scale, left + width + scale, y + 2.8 * scale);
        } else if (reading.kind == :range) {
            var range = reading.temperatureRange as Array<Numeric>;
            var low = range[0] < range[1] ? range[0] : range[1];
            var high = range[0] > range[2] ? range[0] : range[2];
            var stride = width / (high - low + 8);
            var origin = low - 4;
            dc.setColor(TRACK, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(left, y, left + width, y);
            dc.fillRoundedRectangle(left + (range[1] - origin) * stride,
                y - 2.75 * scale, (range[2] - range[1]) * stride, 5.5 * scale, 1.4 * scale);
            disk(dc, left + (range[0] - origin) * stride, y, 1.65 * scale, READING);
        } else {
            drawSparkline(dc, left, cy, width, scale, reading.history as Array<Numeric>);
        }
    }

    private function drawSparkline(dc as Graphics.Dc, left as Numeric, cy as Numeric,
        width as Numeric, scale as Numeric, values as Array<Numeric>) as Void {
        if (values.size() == 0) {
            dc.setColor(TRACK, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(left, cy - 20 * scale, left + width, cy - 20 * scale);
            return;
        }
        var low = values[0];
        var high = low;
        for (var i = 1; i < values.size(); i++) {
            low = values[i] < low ? values[i] : low;
            high = values[i] > high ? values[i] : high;
        }
        var spread = high - low;
        var x = left;
        var y = cy - 20 * scale;
        dc.setColor(MUTED, Graphics.COLOR_TRANSPARENT);
        for (var i = values.size() - 1; i >= 0; i--) {
            var px = values.size() == 1 ? left + width
                : left + (values.size() - 1 - i) * width / (values.size() - 1);
            var py = cy + (-16 - (spread > 0 ? 10 * (values[i] - low) / spread : 4)) * scale;
            if (i < values.size() - 1) {
                dc.drawLine(x, y, px, py);
            }
            x = px;
            y = py;
        }
        disk(dc, x, y, 1.65 * scale, READING);
    }

    private function drawSmall(dc as Graphics.Dc, cx as Numeric, cy as Numeric,
        scale as Numeric, source as Number, reading as SlateReading) as Void {
        var font = fittedFont(dc, reading.value, 10, 46, scale);
        var width = dc.getTextWidthInPixels(reading.value, font);
        var left = cx - (width + 14 * scale) / 2;
        drawIcon(dc, left + 5 * scale, cy, .85 * scale, source);
        dc.setColor(MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(left + 14 * scale, cy, font, reading.value,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawIcon(dc as Graphics.Dc, x as Numeric, y as Numeric,
        scale as Numeric, source as Number) as Void {
        dc.setColor(MUTED, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(scale.toNumber());
        var points = ICONS[source];
        for (var i = 1; i < points.size(); i++) {
            var previous = points[i - 1];
            var point = points[i];
            if (previous.size() == 2 && point.size() == 2) {
                dc.drawLine(x + previous[0] * scale, y + previous[1] * scale,
                    x + point[0] * scale, y + point[1] * scale);
            }
        }
    }

    private function fontFor(size as Numeric) as Graphics.FontType {
        var font = Graphics.getVectorFont({:face => "RobotoRegular", :size => size});
        return font == null ? Graphics.FONT_XTINY : font;
    }

    private function fittedFont(dc as Graphics.Dc, text as String, size as Numeric,
        maxWidth as Numeric, scale as Numeric) as Graphics.FontType {
        var font = fontFor(size * scale);
        var width = dc.getTextWidthInPixels(text, font);
        return width > maxWidth * scale ? fontFor(size * maxWidth * scale * scale / width) : font;
    }

    private function labelFit(dc as Graphics.Dc, x as Numeric, y as Numeric, scale as Numeric,
        text as String, size as Numeric, maxWidth as Numeric, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, fittedFont(dc, text, size, maxWidth, scale), text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function label(dc as Graphics.Dc, x as Numeric, y as Numeric, scale as Numeric,
        text as String, size as Numeric, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, fontFor(size * scale), text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function disk(dc as Graphics.Dc, cx as Numeric, cy as Numeric,
        radius as Numeric, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, radius);
    }

    private function radial(dc as Graphics.Dc, cx as Numeric, cy as Numeric,
        start as Numeric, end as Numeric, angle as Numeric) as Void {
        var dx = Math.sin(angle);
        var dy = -Math.cos(angle);
        dc.drawLine(cx + start * dx, cy + start * dy, cx + end * dx, cy + end * dy);
    }

    private function hand(dc as Graphics.Dc, cx as Numeric, cy as Numeric, scale as Numeric,
        angle as Numeric, tip as Number, baseWidth as Numeric, tipWidth as Numeric, color as Number) as Void {
        var dx = Math.sin(angle) * scale;
        var dy = -Math.cos(angle) * scale;
        var root = PLATE_RADIUS - 2;
        var baseX = cx + root * dx;
        var baseY = cy + root * dy;
        var tipX = cx + tip * dx;
        var tipY = cy + tip * dy;
        var vertices = [
            [baseX + dy * baseWidth, baseY - dx * baseWidth],
            [tipX + dy * tipWidth, tipY - dx * tipWidth],
            [tipX - dy * tipWidth, tipY + dx * tipWidth],
            [baseX - dy * baseWidth, baseY + dx * baseWidth]
        ];
        dc.setColor(0x141614, Graphics.COLOR_TRANSPARENT);
        var shadow = [] as Array<[Numeric, Numeric]>;
        for (var i = 0; i < vertices.size(); i++) {
            shadow.add([vertices[i][0] + 1, vertices[i][1] + 1]);
        }
        dc.fillPolygon(shadow);
        // Darken only the roots while keeping the hands visible over the channel.
        dc.setColor(color == HAND_GREEN ? 0x418522 : color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(vertices);
        if (color == HAND_GREEN) {
            var light = [0x499725, 0x55B129, 0x64D92F, HAND_GREEN];
            for (var i = 0; i < light.size(); i++) {
                var start = root + 3 + i * 2;
                var width = baseWidth + (tipWidth - baseWidth) * (start - root) / (tip - root);
                var x = cx + start * dx;
                var y = cy + start * dy;
                dc.setColor(light[i], Graphics.COLOR_TRANSPARENT);
                dc.fillPolygon([[x + dy * width, y - dx * width], vertices[1],
                    vertices[2], [x - dy * width, y + dx * width]]);
            }
        }
    }
}
