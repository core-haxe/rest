package rest.macros;

import haxe.macro.Expr;
import haxe.macro.Context;

class AddDefaultConstructor {
    public static macro function build():Array<Field> {
        var fields = Context.getBuildFields();
        
        if (!Context.getLocalClass().get().isInterface && !Context.getLocalClass().get().meta.has(":structInit")) {
            var hasSuper = (Context.getLocalClass().get().superClass != null);
            findOrAddConstructor(fields, hasSuper);
        }

        return fields;
    }

    private static function findOrAddConstructor(fields:Array<Field>, hasSuper:Bool = false):Field {
        var ctor:Field = null;
        for (field in fields) {
            if (field.name == "new") {
                ctor = field;
            }
        }

        if (ctor == null) {
            var expr = macro {

            }
            if (hasSuper) {
                expr = macro {
                    super();
                }
            }
            ctor = {
                name: "new",
                access: [APublic],
                kind: FFun({
                    args:[],
                    expr: expr
                }),
                pos: Context.currentPos()
            }
            fields.push(ctor);
        }

        return ctor;
    }
}