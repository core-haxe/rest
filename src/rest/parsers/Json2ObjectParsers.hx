package rest.parsers;

import hxjsonast.Json;

using StringTools;

class Json2ObjectParsers {
    public static function parseISO8601Date(val:Json, name:String):Date {
        var r:Date = null;
        switch(val.value) {
            case JString(s):
                if (s.endsWith("Z")) {
                    s = s.substring(0, s.length - 1);
                }
                var parts = s.split("T");
                if (parts.length == 1) { // date only
                    var date = parseDate_YYYYMMDD(parts[0]);
                    if (date != null) {
                        r = new Date(date.year, date.month, date.day, 0, 0, 0);
                    }
                } else if (parts.length == 2) { // date time
                    var date = parseDate_YYYYMMDD(parts[0]);
                    var time = parseTime_HHMMSS(parts[1]);
                    if (date != null && time != null) {
                        r = new Date(date.year, date.month, date.day, time.hours, time.minutes, time.seconds);
                    } else if (date != null) {
                        r = new Date(date.year, date.month, date.day, 0, 0, 0);
                    }
                }
            case _:
        }
        return r;
    }

    private static function parseDate_YYYYMMDD(s:String):{year:Int, month:Int, day:Int} {
        s = s.trim();
        var r = null;
        var parts = s.split("-");
        if (parts.length == 3) {
            r = {
                year: Std.parseInt(parts[0]),
                month: Std.parseInt(parts[1]),
                day: Std.parseInt(parts[2])
            }
        }
        return r;
    }

    private static function parseTime_HHMMSS(s:String):{hours:Int, minutes:Int, seconds:Int, milliseconds:Int} {
        s = s.trim();
        var r = null;
        var parts = s.split(":");
        if (parts.length == 3) {
            var last = parts.pop();
            r = {
                hours: Std.parseInt(parts[0]),
                minutes: Std.parseInt(parts[1]),
                seconds: 0,
                milliseconds: 0
            }
            if (last.contains(".")) {
                var n = last.indexOf(".");
                r.seconds = Std.parseInt(last.substr(0, n));
                r.milliseconds = Std.parseInt(last.substr(n + 1));
            } else {
                r.seconds = Std.parseInt(last);
            }
        }
        return r;
    }
}