package rest.macros;

import haxe.macro.Context;
import haxe.macro.Expr;

@:access(rest.macros.AddDefaultConstructor)
class MappableBuilder {
    public static macro function build():Array<Field> {
        var fields = Context.getBuildFields();
        if (!Context.getLocalClass().get().isInterface && !Context.getLocalClass().get().meta.has(":structInit")) {
            AddDefaultConstructor.findOrAddConstructor(fields);
        }

        var toMapFn = findOrAddToMap(fields);
        switch (toMapFn.kind) {
            case FFun(f):
                switch (f.expr.expr) {
                    case EBlock(exprs):
                        var mapExprs = [];
                        for (field in fields) {
                            switch (field.kind) {
                                case FVar(t, e):
                                    var fieldName = field.name;
                                    mapExprs.push(macro $v{fieldName} => this.$fieldName);
                                case _:    
                            }
                        }
                        exprs.push(macro return $a{mapExprs});
                    case _:
                }
            case _:    
        }

        var toObjectFn = findOrAddToObject(fields);
        switch (toObjectFn.kind) {
            case FFun(f):
                switch (f.expr.expr) {
                    case EBlock(exprs):
                        exprs.push(macro var o:Dynamic = {});
                        for (field in fields) {
                            switch (field.kind) {
                                case FVar(t, e):
                                    var fieldName = field.name;
                                    exprs.push(macro o.$fieldName = this.$fieldName);
                                case _:    
                            }
                        }
                        exprs.push(macro return o);
                    case _:
                }
            case _:    
        }

        return fields;
    }

    private static function findOrAddToMap(fields:Array<Field>):Field {
        var fn:Field = null;
        for (field in fields) {
            if (field.name == "toMap") {
                fn = field;
            }
        }

        if (fn == null) {
            fn = {
                name: "toMap",
                access: [APrivate],
                kind: FFun({
                    args:[],
                    expr: macro {
                    },
                    ret: macro: Map<String, Any>
                }),
                pos: Context.currentPos()
            }
            fields.push(fn);
        }

        return fn;
    }

    private static function findOrAddToObject(fields:Array<Field>):Field {
        var fn:Field = null;
        for (field in fields) {
            if (field.name == "toObject") {
                fn = field;
            }
        }

        if (fn == null) {
            fn = {
                name: "toObject",
                access: [APrivate],
                kind: FFun({
                    args:[],
                    expr: macro {
                    },
                    ret: macro: Dynamic
                }),
                pos: Context.currentPos()
            }
            fields.push(fn);
        }

        return fn;
    }
}