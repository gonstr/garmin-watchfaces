import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;
import Toybox.Weather;

class OrbitView extends WatchUi.WatchFace {
    private var sleeping as Boolean = false;

    function initialize() {
        WatchFace.initialize();
    }

    function onEnterSleep() as Void {
        sleeping = true;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        sleeping = false;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var diameter = dc.getWidth() < dc.getHeight() ? dc.getWidth() : dc.getHeight();
        var scale = diameter / 300.0;
        var moment = Time.now();
        var now = Gregorian.info(moment, Time.FORMAT_SHORT);
        var is24Hour = System.getDeviceSettings().is24Hour;
        var hour = now.hour;
        if (!is24Hour) {
            hour = (hour + 11) % 12 + 1;
        }
        var timeText = hour.format(is24Hour ? "%02d" : "%d") + ":" + now.min.format("%02d");

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        if (sleeping) {
            dc.setColor(0x666A65, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy, Graphics.FONT_LARGE, timeText,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        var outer = 144 * scale;
        var inner = 125 * scale;
        var centerColor = 0x1C1E1C;
        var midColor = 0x111311;
        var edgeColor = 0x090A09;
        var hourColor = 0xDEAF73;
        var minuteColor = 0xE6EBE1;
        var dateColor = 0xC4C9BF;
        var finish = Application.Properties.getValue("Finish");
        var classic = finish != 1 && finish != 2;
        if (classic) {
            centerColor = 0x0B0B0B;
            hourColor = 0xA8FFCD;
            minuteColor = hourColor;
        } else if (finish == 1) {
            centerColor = 0x151E2B;
            midColor = 0x0D131D;
            edgeColor = 0x07090E;
            dateColor = 0x9FB4DA;
            hourColor = 0x8AB6F4;
            minuteColor = hourColor;
        } else if (finish == 2) {
            centerColor = 0x29190E;
            midColor = 0x1B1009;
            edgeColor = 0x0E0805;
            dateColor = 0xE4A763;
            hourColor = 0xFFBB64;
            minuteColor = hourColor;
        }

        var bandColor = centerColor;
        var dataColor = classic ? 0x9BBDE0 : minuteColor;
        if (classic) {
            bandColor = 0x151515;
            drawClassicDial(dc, cx, cy, scale, bandColor, centerColor);
        } else {
            for (var step = 0; step < 19; step++) {
                var color = step < 5
                    ? blendColor(edgeColor, midColor, step, 5)
                    : blendColor(midColor, centerColor, step - 5, 14);
                fillDisk(dc, cx, cy, outer - step * scale, color);
            }
            fillDisk(dc, cx, cy, inner, centerColor);
            bandColor = finish == 1 ? 0x101C34 : 0x382513;
            fillDisk(dc, cx, cy, 119 * scale, bandColor);
            fillDisk(dc, cx, cy, 84 * scale, centerColor);
        }

        for (var tick = 0; tick < 60; tick += classic ? 5 : 1) {
            var angle = tick * Math.PI / 30;
            var length = tick % 15 == 0 ? 4.8 : (tick % 5 == 0 ? 3.6 : 2.1);
            var end = outer - 1.5 * scale;
            var start = end - length * scale;
            dc.setColor(classic ? blendColor(centerColor, hourColor, 2, 3)
                : (tick % 5 == 0 ? 0xBCBFB2 : 0x767C71), Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(tick % 5 == 0 ? 2 : 1);
            if (classic && tick % 15 == 0) {
                var spread = 0.8 * Math.PI / 180;
                drawRadialLine(dc, cx, cy, start, end, angle - spread);
                drawRadialLine(dc, cx, cy, start, end, angle + spread);
            } else {
                drawRadialLine(dc, cx, cy, start, end, angle);
            }
        }

        if (Application.Properties.getValue("ShowSeconds") == true) {
            if (classic) {
                drawHand(dc, cx, cy, outer - 13 * scale, outer - 5 * scale,
                    1.4 * scale, now.sec * Math.PI / 30, hourColor, 2 * scale, 0.55);
            } else {
                drawSecondsRail(dc, cx, cy, inner - 3 * scale, now.sec, centerColor, minuteColor);
            }
        }

        var minutes = now.min + now.sec / 60.0;
        var hourAngle = (now.hour % 12 + minutes / 60.0) * Math.PI / 6;
        var minuteAngle = minutes * Math.PI / 30;
        drawHand(dc, cx, cy, inner, outer - 6 * scale, 4 * scale, hourAngle, hourColor, 4 * scale, 0.0);
        drawHand(dc, cx, cy, inner, outer - 2.2 * scale, 2 * scale, minuteAngle, minuteColor, 5 * scale, 0.0);

        if (classic) {
            dc.setColor(0xD3EDDE, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            drawHandHighlight(dc, cx, cy, inner + scale, outer - 10 * scale, -2.5 * scale, hourAngle);
            drawHandHighlight(dc, cx, cy, inner + scale, outer - 6.2 * scale, -scale, minuteAngle);
        }

        var timeSize = Application.Properties.getValue("TimeSize");
        if (!(timeSize instanceof Number) || timeSize < 32 || timeSize > 48) {
            timeSize = 40;
        }
        var digits = Graphics.getVectorFont({:face => ["RobotoCondensedBold", "RobotoMedium"], :size => timeSize * scale});
        var font = digits == null ? Graphics.FONT_NUMBER_MILD : digits;
        var dateFont = Graphics.getVectorFont({:face => "RobotoRegular", :size => 9 * scale});
        var readoutFont = Graphics.getVectorFont({:face => "RobotoRegular", :size => 10 * scale});
        var smallFont = dateFont == null ? Graphics.FONT_XTINY : dateFont;
        var hoursText = hour.format("%02d");
        var minutesText = now.min.format("%02d");
        var hoursWidth = dc.getTextWidthInPixels(hoursText, font);
        var minutesWidth = dc.getTextWidthInPixels(minutesText, font);
        var gap = 3 * scale;
        var startX = cx - (hoursWidth + gap + minutesWidth) / 2;
        var justify = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;
        var timeY = classic ? cy - 10 * scale - dc.getFontHeight(font) / 2 : cy - 24 * scale;
        var dateY = classic ? timeY - dc.getFontHeight(font) / 2
            - 8 * scale - dc.getFontHeight(smallFont) / 2 : cy - 49 * scale;
        dc.setColor(0xEDF2EF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX, timeY, font, hoursText, justify);
        dc.setColor(0xA5B2AA, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + hoursWidth + gap, timeY, font, minutesText, justify);
        dc.setColor(blendColor(centerColor, dateColor, 1, 2), Graphics.COLOR_TRANSPARENT);
        var date = Gregorian.info(moment, Time.FORMAT_MEDIUM);
        dc.drawText(cx, dateY, smallFont,
            (date.day_of_week.toString() + " " + date.day.format("%d") + " " + date.month.toString()).toUpper(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var activity = ActivityMonitor.getInfo();
        var steps = activity.steps;
        var goal = activity.stepGoal;
        var progress = goal != null && goal > 0 && steps != null
            ? steps.toFloat() / goal : 0.0;
        var centerSource = Application.Properties.getValue("CenterSource");
        var heartSamples = [] as Array<Number>;
        if (centerSource == 1) {
            var history = ActivityMonitor.getHeartRateHistory(24, true);
            if (history != null) {
                for (var sample = history.next(); sample != null; sample = history.next()) {
                    heartSamples.add(sample.heartRate);
                }
            }
        }

        if (Application.Properties.getValue("ShowComplications") != false) {
            var count = Application.Properties.getValue("ComplicationCount") as Number;
            var spacing = 360.0 / count;
            for (var slot = 0; slot < count; slot++) {
                var angle = (count == 2 ? 0.0 : -spacing / 2) + slot * spacing;
                var source = Application.Properties.getValue("Slot" + (slot + 1).format("%d"));
                var label = "BATTERY";
                var value = "--";
                var fraction = 0.0;
                if (source == 1) {
                    label = "STEPS";
                    value = steps == null ? "--" : steps.format("%d");
                    fraction = progress;
                } else if (source == 2) {
                    label = "WEATHER";
                    var conditions = Weather.getCurrentConditions();
                    if (conditions != null && conditions.temperature != null) {
                        var temperature = conditions.temperature;
                        var fahrenheit = System.getDeviceSettings().temperatureUnits == System.UNIT_STATUTE;
                        value = (fahrenheit ? temperature * 1.8 + 32 : temperature).format("%.0f")
                            + (fahrenheit ? "°F" : "°C");
                    }
                } else if (source == 3) {
                    label = "ACTIVE";
                    var active = activity.activeMinutesDay;
                    if (active != null) {
                        value = active.total.format("%d") + "m";
                    }
                } else if (source == 4) {
                    label = "DIST";
                    if (activity.distance != null) {
                        var miles = System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE;
                        value = (activity.distance / (miles ? 160934.4 : 100000.0)).format("%.1f")
                            + (miles ? "mi" : "km");
                    }
                } else if (source == 5) {
                    label = "CAL";
                    value = activity.calories == null ? "--" : activity.calories.format("%d");
                } else {
                    var battery = System.getSystemStats().battery;
                    value = battery == null ? "--" : battery.format("%.0f") + "%";
                    fraction = battery == null ? 0.0 : battery / 100.0;
                }
                drawComplication(dc, cx, cy, scale, angle, spacing - 8, label, value,
                    fraction, classic ? dataColor : (slot % 2 == 0 ? minuteColor : hourColor), bandColor, readoutFont, classic);
            }
        }
        if (Application.Properties.getValue("ShowCenterData") != false) {
            dc.setPenWidth(1);
            dc.setColor(blendColor(centerColor, dateColor, 1, 5), Graphics.COLOR_TRANSPARENT);
            var halfDivider = (classic ? 36 : 61) * scale;
            dc.drawLine(cx - halfDivider, cy, cx + halfDivider, cy);
            if (centerSource == 1) {
                drawHeartHistory(dc, cx, cy + 9 * scale, scale, heartSamples, dataColor, centerColor, smallFont);
            } else {
                drawStepMilestones(dc, cx, cy + 9 * scale, scale, steps, goal, progress,
                    dataColor, centerColor, smallFont);
            }
        }
    }

    private function drawComplication(dc as Graphics.Dc, cx as Numeric, cy as Numeric,
        scale as Numeric, angle as Numeric, span as Numeric, label as String, value as String,
        progress as Numeric, color as Number, bandColor as Number, font as Graphics.VectorFont?, classic as Boolean) as Void {
        var radius = (classic ? 115 : 110) * scale;
        var start = (90 - angle + span / 2 + 360).toNumber() % 360;
        var end = start - span;
        var track = blendColor(bandColor, color, 1, 3);
        dc.setColor(track, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, start, (end + 360).toNumber() % 360);
        if (progress > 0) {
            var marker = start - (start - end) * (progress > 1 ? 1 : progress);
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(4);
            dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, start, (marker + 360).toNumber() % 360);
            var radians = marker * Math.PI / 180;
            dc.fillCircle(cx + radius * Math.cos(radians), cy - radius * Math.sin(radians), 3);
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var textAngle = (90 - angle + 360).toNumber() % 360;
        var direction = textAngle > 180 ? Graphics.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE
            : Graphics.RADIAL_TEXT_DIRECTION_CLOCKWISE;
        var text = label + " " + value;
        var alignment = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        if (font != null) {
            dc.drawRadialText(cx, cy, font, text, alignment, textAngle, (classic ? 101 : 96) * scale, direction);
        } else {
            var radians = angle * Math.PI / 180;
            dc.drawText(cx + Math.sin(radians) * 96 * scale, cy - Math.cos(radians) * 96 * scale,
                Graphics.FONT_XTINY, value, alignment);
        }
    }

    private function drawHeartHistory(dc as Graphics.Dc, cx as Numeric, y as Numeric,
        scale as Numeric, samples as Array<Number>, color as Number, centerColor as Number,
        font as Graphics.FontType) as Void {
        var width = 110 * scale;
        var x = cx - width / 2;
        var low = 255;
        var high = 0;
        var latest = 0;
        for (var index = 0; index < samples.size(); index++) {
            var bpm = samples[index];
            if (bpm != ActivityMonitor.INVALID_HR_SAMPLE && bpm > 0) {
                low = bpm < low ? bpm : low;
                high = bpm > high ? bpm : high;
                latest = latest == 0 ? bpm : latest;
            }
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, "BPM", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(x + width, y, font, latest == 0 ? "--" : latest.format("%d") + " bpm",
            Graphics.TEXT_JUSTIFY_RIGHT);
        y += dc.getFontHeight(font) + 2;
        var height = 19 * scale;
        dc.setPenWidth(1);
        dc.setColor(blendColor(centerColor, color, 1, 4), Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x, y + height, x + width, y + height);
        if (samples.size() < 2 || latest == 0) {
            return;
        }
        var previousY = null as Numeric?;
        var stride = width / (samples.size() - 1);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        for (var index = samples.size() - 1; index >= 0; index--) {
            var bpm = samples[index];
            if (bpm == ActivityMonitor.INVALID_HR_SAMPLE || bpm <= 0) {
                previousY = null;
            } else {
                var pointX = x + (samples.size() - 1 - index) * stride;
                var pointY = y + height * (high + 5 - bpm) / (high - low + 10);
                if (previousY != null) {
                    dc.drawLine(pointX - stride, previousY as Numeric, pointX, pointY);
                }
                dc.fillCircle(pointX, pointY, 1);
                previousY = pointY;
            }
        }
    }

    private function drawStepMilestones(dc as Graphics.Dc, cx as Numeric, y as Numeric,
        scale as Numeric, steps as Number?, goal as Number?, progress as Numeric,
        color as Number, centerColor as Number, font as Graphics.FontType) as Void {
        var width = 110 * scale;
        var x = cx - width / 2;
        var unavailable = steps == null || goal == null || goal <= 0;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, "STEPS DAILY", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(x + width, y, font,
            unavailable ? "--" : (progress * 100).format("%.0f") + "%",
            Graphics.TEXT_JUSTIFY_RIGHT);

        y += dc.getFontHeight(font) + 2;
        var track = blendColor(centerColor, color, 1, 4);
        var stride = width / 10;
        var segmentWidth = stride - 2;
        var height = 7 * scale;
        for (var i = 0; i < 10; i++) {
            var segmentX = x + i * stride;
            dc.setColor(track, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(segmentX, y, segmentWidth, height);
            var fraction = progress * 10 - i;
            if (fraction > 0) {
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(segmentX, y, segmentWidth * (fraction > 1 ? 1 : fraction), height);
            }
        }
    }

    private function drawSecondsRail(dc as Graphics.Dc, cx as Numeric, cy as Numeric,
        radius as Numeric, second as Number, centerColor as Number, accentColor as Number) as Void {
        var mutedColor = blendColor(centerColor, accentColor, 1, 5);
        var halfSegment = 2.15 * Math.PI / 180;
        for (var index = 0; index < 60; index++) {
            var angle = index * Math.PI / 30;
            var start = angle - halfSegment;
            var end = angle + halfSegment;
            dc.setColor(index == second ? accentColor : mutedColor, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(index == second ? 3 : 1);
            dc.drawLine(cx + radius * Math.sin(start), cy - radius * Math.cos(start),
                cx + radius * Math.sin(end), cy - radius * Math.cos(end));
        }
    }

    private function blendColor(fromColor as Number, toColor as Number,
        step as Number, length as Number) as Number {
        var color = 0;
        for (var shift = 0; shift <= 16; shift += 8) {
            var start = (fromColor >> shift) & 255;
            var end = (toColor >> shift) & 255;
            color |= ((start * (length - step) + end * step) / length) << shift;
        }
        return color;
    }

    private function fillDisk(dc as Graphics.Dc, cx as Numeric, cy as Numeric,
        radius as Numeric, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, radius);
    }

    private function drawClassicDial(dc as Graphics.Dc, cx as Numeric, cy as Numeric,
        scale as Numeric, bandColor as Number, centerColor as Number) as Void {
        var radius = 121 * scale;
        fillDisk(dc, cx, cy, radius, bandColor);
        var tilt = -78 * Math.PI / 180;
        var dx = Math.cos(tilt);
        var dy = Math.sin(tilt);
        dc.setPenWidth(1);
        for (var grain = -42; grain <= 42; grain++) {
            var offset = grain * 2.8 * scale;
            var extent = Math.sqrt(radius * radius - offset * offset);
            var x = cx - dy * offset;
            var y = cy + dx * offset;
            dc.setColor(grain % 2 == 0 ? 0x191919 : 0x121212, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(x - dx * extent, y - dy * extent, x + dx * extent, y + dy * extent);
        }
        fillDisk(dc, cx, cy, 93 * scale, centerColor);
    }

    private function drawHandHighlight(dc as Graphics.Dc, cx as Numeric, cy as Numeric,
        start as Numeric, end as Numeric, offset as Numeric, angle as Numeric) as Void {
        drawRadialLine(dc, cx + Math.cos(angle) * offset, cy + Math.sin(angle) * offset,
            start, end, angle);
    }

    private function drawRadialLine(dc as Graphics.Dc, cx as Numeric, cy as Numeric,
        start as Numeric, end as Numeric, angle as Numeric) as Void {
        var dx = Math.sin(angle);
        var dy = -Math.cos(angle);
        dc.drawLine(cx + start * dx, cy + start * dy, cx + end * dx, cy + end * dy);
    }

    private function drawHand(dc as Graphics.Dc, cx as Numeric, cy as Numeric,
        start as Numeric, end as Numeric, width as Numeric, angle as Numeric,
        color as Number, bevel as Numeric, tipWidthRatio as Numeric) as Void {
        var dx = Math.sin(angle);
        var dy = -Math.cos(angle);
        var px = -dy * width;
        var py = dx * width;
        var shoulder = end - bevel;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [cx + dx * start - px, cy + dy * start - py],
            [cx + dx * shoulder - px, cy + dy * shoulder - py],
            [cx + dx * end - px * tipWidthRatio, cy + dy * end - py * tipWidthRatio],
            [cx + dx * end + px * tipWidthRatio, cy + dy * end + py * tipWidthRatio],
            [cx + dx * shoulder + px, cy + dy * shoulder + py],
            [cx + dx * start + px, cy + dy * start + py]
        ]);
    }
}
