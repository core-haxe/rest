package rest.macros;

import haxe.macro.Context;
import haxe.macro.Expr;

using StringTools;

class Json2ObjectParser {
    public static macro function build():Array<Field> {
        var fields = Context.getBuildFields();
        findOrAddConstructor(fields);

        var parseFn = findOrAddParse(fields);
        var toStringFn = findOrAddToString(fields);
        
        var localClass = Context.getLocalClass();
        var parts = localClass.toString().split(".");
        var s = parts.pop();

        var type = TPath({
            pack: parts,
            name: s
        });

        switch (parseFn.kind) {
            case FFun(f): {
                switch (f.expr.expr) {
                    case EBlock(exprs):
                        // we want to use "insert" here as maybe there is custom logic in an already existing function
                        // this way we insert all the parsing and variable assignment before any of that happens
                        exprs.insert(0, macro { // if the response isnt a string, lets turn it into one
                            if (!(response is String)) {
                                response = haxe.Json.stringify(response);
                            }
                        });
                        exprs.insert(1, macro var parser = new json2object.JsonParser<$type>());
                        exprs.insert(2, macro var data = parser.fromJson(response));

                        var n = 3;
                        for (field in fields) {
                            switch (field.kind) {
                                case FVar(t, e):
                                    var fieldName = field.name;
                                    exprs.insert(n, macro this.$fieldName = data.$fieldName);
                                    n++;
                                case _:
                            }
                        }
                    case _:    
                }
            }
            case _:
        }

        switch (toStringFn.kind) {
            case FFun(f): {
                switch (f.expr.expr) {
                    case EBlock(exprs):
                        exprs.push(macro var writer = new json2object.JsonWriter<$type>());
                        exprs.push(macro var json = writer.write(this));
                        exprs.push(macro return json);
                    case _:    
                }
            }
            case _:
        }

        return fields;
    }

    private static function findOrAddConstructor(fields:Array<Field>):Field {
        var ctor:Field = null;
        for (field in fields) {
            if (field.name == "new") {
                ctor = field;
            }
        }

        if (ctor == null) {
            ctor = {
                name: "new",
                access: [APublic],
                kind: FFun({
                    args:[],
                    expr: macro {
                    }
                }),
                pos: Context.currentPos()
            }
            fields.push(ctor);
        }

        return ctor;
    }

    private static function findOrAddParse(fields:Array<Field>):Field {
        var fn:Field = null;
        for (field in fields) {
            if (field.name == "parse") {
                fn = field;
            }
        }

        if (fn == null) {
            fn = {
                name: "parse",
                access: [APrivate],
                kind: FFun({
                    args:[{
                        name: "response",
                        type: macro: Any
                    }],
                    expr: macro {
                    }
                }),
                pos: Context.currentPos()
            }
            fields.push(fn);
        }

        return fn;
    }

    private static function findOrAddToString(fields:Array<Field>):Field {
        var fn:Field = null;
        for (field in fields) {
            if (field.name == "toString") {
                fn = field;
            }
        }
        
        if (fn == null) {
            fn = {
                name: "toString",
                access: [APrivate],
                kind: FFun({
                    args:[],
                    expr: macro {
                    },
                    ret: macro: String,
                }),
                pos: Context.currentPos()
            }
            fields.push(fn);
        }

        return fn;
    }
}