package rest.macros;

import haxe.macro.TypeTools;
import haxe.macro.ComplexTypeTools;
import haxe.macro.ExprTools;
import haxe.macro.Type.Ref;
import haxe.macro.Type.ClassType;
import haxe.macro.Context;
import haxe.macro.Expr;

using StringTools;

class RestApiBuilder {
    public static macro function build():Array<Field> {
        var localClass = Context.getLocalClass();
        var errorClass:Ref<ClassType> = switch (localClass.get().superClass.params[0]) {
            case TInst(t, params):
                t;
            case _: null;    
        }

        var s = errorClass.toString();
        var parts = s.split(".");
        s = parts.pop();

        var errorType = TPath({
            pack: parts,
            name: s
        });

        var fields = Context.getBuildFields();
        for (field in fields) {
            switch (field.kind) {
                case FFun(f):
                    if (f.expr == null) {
                        var requestType = macro: rest.None;
                        var argName = null;
                        if (f.args.length > 0) {
                            requestType = f.args[0].type;
                            argName = f.args[0].name;
                        }

                        var verbMeta = extractVerbMeta(field);
                        var responseType = verbMeta.responseType;
                        var verb = switch (verbMeta.verb) {
                            case "get": http.HttpMethod.Get;
                            case "post": http.HttpMethod.Post;
                            case "put": http.HttpMethod.Put;
                            case "patch": http.HttpMethod.Patch;
                            case "delete": http.HttpMethod.Delete;
                            case _: null;
                        }

                        if (verb == null) {
                            continue;
                        }

                        var path = verbMeta.path;
                        var bodyType = verbMeta.bodyType;
                        if (bodyType == null) {
                            bodyType = "None";
                        }
                        var queryParams:Map<String, Any> = null;
                        if (path.indexOf("?") != -1) {
                            var n = path.indexOf("?");
                            var queryParamStrings = path.substr(n + 1);
                            path = path.substr(0, n);

                            var params = queryParamStrings.split("&");
                            for (p in params) {
                                p = p.trim();
                                if (p.length == 0) {
                                    continue;
                                }
                                var parts = p.split("=");
                                var name = parts[0].trim();
                                var value = parts[1].trim();
                                if (queryParams == null) {
                                    queryParams = [];
                                }
                                queryParams.set(name, value);
                            }
                        }
                        if (argName != null) {
                            f.expr = macro {
                                var operation = new rest.RestOperation<$requestType, $responseType, $errorType>();
                                operation.verb = $v{verb};
                                operation.path = $v{path};
                                operation.queryParams = $v{queryParams};
                                operation.bodyType = rest.BodyType.$bodyType;
                                operation.client = this.client;
                                return operation.call($i{argName});
                            }
                        } else {
                            f.expr = macro {
                                var operation = new rest.RestOperation<$requestType, $responseType, $errorType>();
                                operation.verb = $v{verb};
                                operation.path = $v{path};
                                operation.queryParams = $v{queryParams};
                                operation.bodyType = rest.BodyType.$bodyType;
                                operation.client = this.client;
                                return operation.call();
                            }
                        }
                    }
                case FVar(t, e):
                    var varName = field.name;
                    var s = ComplexTypeTools.toString(t);
                    var parts = s.split(".");
                    s = parts.pop();
                    var varType:TypePath = {
                        pack: parts,
                        name: s
                    };

                    var ctor = findOrAddConstructor(fields);
                    switch(ctor.kind) {
                        case FFun(f):
                            switch (f.expr.expr) {
                                case EBlock(exprs): {
                                    exprs.push(macro $i{varName} = new $varType(client));
                                }
                                case _:
                            }
                        case _:    
                    }
                case _:    
            }
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
                    args:[{
                        name: "client",
                        type: macro: rest.RestClient
                    }],
                    expr: macro {
                        super(client);
                    }
                }),
                pos: Context.currentPos()
            }
            fields.push(ctor);
        }

        return ctor;
    }

    private static function extractVerbMeta(field:Field):{verb:String, path:String, responseType:ComplexType, bodyType:String} {
        var verbMeta = {
            verb: null,
            path: null,
            responseType: null,
            bodyType: null
        }

        for (m in field.meta) {
            if (m.name == ":get" || m.name == ":post" || m.name == ":put" || m.name == ":patch" || m.name == ":delete") {
                verbMeta.verb = m.name.substring(1);
                verbMeta.path = ExprTools.getValue(m.params[0]);
                verbMeta.responseType = switch (m.params[1].expr) {
                    case EConst(CIdent(s)):
                        var parts = s.split(".");
                        s = parts.pop();

                        TPath({
                            pack: parts,
                            name: s
                        });
                    case EArray({expr:EConst(CIdent(s1))}, {expr:EConst(CIdent(s2))}):  
                        var parts1 = s1.split(".");
                        s1 = parts1.pop();
                        var parts2 = s2.split(".");
                        s2 = parts2.pop();

                        TPath({
                            pack: parts1,
                            name: s1,
                            params: [TPType(
                                TPath({
                                    pack: parts2,
                                    name: s2
                                })
                            )]
                        });
                    case _:    
                        null;
                }

                if (m.params[2] != null) {
                    verbMeta.bodyType = switch (m.params[2].expr) {
                        case EConst(CIdent(s)):
                            s;
                        case _: "None";
                    }
                }
            }
        }

        return verbMeta;
    }
}