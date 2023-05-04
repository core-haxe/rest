package rest.macros;

import haxe.macro.Context;
import haxe.macro.Expr;

class RestErrorBuilder {
    public static macro function build():Array<Field> {
        var localClass = Context.getLocalClass();

        var fields = Context.getBuildFields();
        var parseFn = findOrAddParse(fields);
        var toStringFn = findOrAddToString(fields);

        if (!hasField(fields, "message")) {
            fields.push({
                name: "message",
                access: [APublic],
                kind: FVar(macro: String),
                pos: Context.currentPos()
            });
        }

        if (!hasField(fields, "body")) {
            fields.push({
                name: "body",
                access: [APublic],
                kind: FVar(macro: haxe.io.Bytes),
                pos: Context.currentPos()
            });
        }

        if (!hasField(fields, "httpStatus")) {
            fields.push({
                name: "httpStatus",
                access: [APublic],
                kind: FVar(macro: Int),
                pos: Context.currentPos()
            });
        }

        if (!hasField(fields, "headers")) {
            fields.push({
                name: "headers",
                access: [APublic],
                kind: FVar(macro: Map<String, Any>),
                pos: Context.currentPos()
            });
        }

        switch (parseFn.kind) {
            case FFun(f):
                switch (f.expr.expr) {
                    case EBlock(exprs):
                        exprs.insert(0, macro this.message = error.message);
                        exprs.insert(0, macro this.body = error.body);
                        exprs.insert(0, macro this.httpStatus = error.httpStatus);
                        exprs.insert(0, macro this.headers = error.headers);
                    case _:    
                }
            case _:   
        }

        return fields;
    }

    private static function hasField(fields:Array<Field>, name:String):Bool {
        for (field in fields) {
            if (field.name == name) {
                return true;
            }
        }
        return false;
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
                    args: [{
                        name: "error",
                        type: macro: rest.RestError
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
                    args: [],
                    ret: macro: String,
                    expr: macro {
                        return haxe.Json.stringify({
                            message: this.message,
                            body: this.body.toString()
                        });
                    }
                }),
                pos: Context.currentPos()
            }
            fields.push(fn);
        }

        return fn;
    }
}