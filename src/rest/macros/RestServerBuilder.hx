package rest.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type.ClassType;
import haxe.macro.Type.Ref;
import haxe.macro.Type.TVar;
import haxe.macro.TypeTools;

using StringTools;

class RestServerBuilder {
    public static macro function build():Array<Field> {
        var localClass = Context.getLocalClass();
        var apiClass:Ref<ClassType> = switch (localClass.get().superClass.params[0]) {
            case TInst(t, params):
                t;
            case _: null;    
        }

        var fields = Context.getBuildFields();
        var ctor = findOrAddConstructor(fields);

        var mappingsMeta = localClass.get().meta.extract(":mapping");
        var mappings:Map<String, String> = [];
        for (m in mappingsMeta) {
            switch (m.params[0].expr) {
                case EArrayDecl(values):
                    for (v in values) {
                        switch (v.expr) {
                            case EBinop(op, e1, e2):
                                var from = ExprTools.toString(e1);
                                var to = ExprTools.toString(e2);
                                mappings.set(from, to);
                            case _:    
                        }
                    }
                case _:    
            }
        }
        
        var subApiExprs:Array<Expr> = [];
        for (k in mappings.keys()) {
            var v = mappings.get(k);
            var parts = v.split(".");
            var name = parts.pop();
            var t:TypePath = {
                pack: parts,
                name: name
            };
            var tt = TPath(t);

            var varName = "_" + k;
            fields.push({
                name: varName,
                kind: FVar(macro: $tt),
                access: [APrivate],
                pos: Context.currentPos()
            });
    
            subApiExprs.push(macro $i{varName} = new $t());
        }
        
        fields.push({
            name: "_restServer",
            kind: FVar(macro: rest.server.RestServer),
            pos: Context.currentPos()
        });

        var calls = [];
        buildApiCalls(apiClass.get(), fields, mappings, calls);
        var routeExprs:Array<Expr> = [];
        for (call in calls) {
            if (call.method == "get") {
                routeExprs.push(macro _restServer.get($v{call.path}, $i{call.proxyCallName}));
            }
        }

        switch (ctor.kind) {
            case FFun(f):
                switch (f.expr.expr) {
                    case EBlock(exprs):
                        for (e in subApiExprs) {
                            exprs.push(e);
                        }
                        exprs.push(macro _restServer = new rest.server.RestServer());
                        for (e in routeExprs) {
                            exprs.push(e);
                        }
                    case _:    
                }
            case _:    
        }

        fields.push({
            name: "start",
            kind: FFun({
                args: [{name: "port", type: macro: Int}],
                expr: macro {
                    _restServer.start(port);
                }
            }),
            access: [APublic],
            pos: Context.currentPos()
        });

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

    private static function buildApiCalls(apiClass:ClassType, fields:Array<Field>, mappings:Map<String, String>, calls:Array<RestServerCallInfo>, prefix:String = null) {
        for (f in apiClass.fields.get()) {
            switch (f.type) {
                case TInst(t, params):
                    if (t.get().superClass.t.toString() == "rest.RestApi") {
                        buildApiCalls(t.get(), fields, mappings, calls, f.name);
                    }
                case TFun(args, ret):    
                    var method = null;
                    var path = null;

                    for (m in f.meta.get()) {
                        if (m.name == ":get") {
                            method = "get";
                            path = ExprTools.toString(m.params[0]);
                            path = path.replace("\"", "");
                            path = path.replace("'", "");
                        }
                    }

                    if (path == null || method == null) {
                        continue;
                    }

                    var objectName = "_" + prefix;
                    var fieldName = f.name;
                    var functionExpr = null;
                    
                    if (args.length > 0) {
                        var callSite = macro $i{objectName}.$fieldName;
                        
                        // build up call request infor
                        var callRequestTypeString = null;
                        var callRequestVars:Array<{name:String, type:String}> = [];
                        switch(args[0].t) {
                            case TInst(t, params):
                                for (ff in t.get().fields.get()) {
                                    switch (ff.kind) {
                                        case FVar(read, write):
                                            callRequestVars.push({
                                                name: ff.name,
                                                type: TypeTools.toString(ff.type)
                                            });
                                        case _:    
                                    }
                                }
                                callRequestTypeString = t.toString();
                            case _:
                        }

                        var callRequestFields = [];
                        for (requestVar in callRequestVars) {
                            switch (requestVar.type) {
                                case "Int":
                                    callRequestFields.push({ field: requestVar.name, expr: macro request.paramInt($v{requestVar.name}) });
                                case _:
                                callRequestFields.push({ field: requestVar.name, expr: macro request.param($v{requestVar.name}) });
                            }
                        }
                        var callRequestExpr = {
                            expr: EObjectDecl(callRequestFields),
                            pos: Context.currentPos()
                        }

                        var callRequestParts = callRequestTypeString.split(".");
                        var callRequestTypeName = callRequestParts.pop();
                        var callRequestType = TPath({
                            pack: callRequestParts,
                            name: callRequestTypeName
                        });

                        functionExpr = macro {
                            return new promises.Promise((resolve, reject) -> {
                                var callRequest:$callRequestType = $callRequestExpr;
                                $callSite(callRequest).then(callResponse -> {                                            
                                    if ((callResponse is rest.IJson2ObjectParsable)) {
                                        var jsonParsableResponse = cast(callResponse, rest.IJson2ObjectParsable);
                                        var jsonString = @:privateAccess jsonParsableResponse.toString();
                                        response.headers = [http.StandardHeaders.ContentType => http.ContentTypes.ApplicationJson];
                                        if (jsonString != null) {
                                            response.write(jsonString);
                                        }
                                        resolve(response);
                                    } else {
                                        reject("Unknown response type");
                                    }
                                }, error -> {
                                    reject(error);
                                });
                            });
                        }
                    } else {
                        var callSite = macro $i{fieldName};
                        
                        functionExpr = macro {
                            return new promises.Promise((resolve, reject) -> {
                                $callSite().then(callResponse -> {                                            
                                    if ((callResponse is rest.IJson2ObjectParsable)) {
                                        var jsonParsableResponse = cast(callResponse, rest.IJson2ObjectParsable);
                                        var jsonString = @:privateAccess jsonParsableResponse.toString();
                                        response.headers = [http.StandardHeaders.ContentType => http.ContentTypes.ApplicationJson];
                                        if (jsonString != null) {
                                            response.write(jsonString);
                                        }
                                        resolve(response);
                                    } else {
                                        reject("Unknown response type");
                                    }
                                }, error -> {
                                    reject(error);
                                });
                            });
                        }
                    }

                    var callName = "_" + f.name;
                    if (prefix != null) {
                        callName = "_" + prefix + "_" + f.name;
                    }
                    var proxyCall:Field = {
                        name: callName,
                        access: [APrivate],
                        kind: FFun({
                            args: [{
                                name: "request",
                                type: macro: rest.RestRequest
                            },{
                                name: "response",
                                type: macro: rest.RestResponse
                            }],
                            expr: functionExpr,
                            ret: macro: promises.Promise<rest.RestResponse>
                        }),
                        pos: Context.currentPos()
                    }

                    fields.push(proxyCall);
                    calls.push({
                        path: path,
                        method: method,
                        callName: f.name,
                        proxyCallName: proxyCall.name
                    });
                case _:    
                    trace(f);
            }
        }
    }
}

private typedef RestServerCallInfo = {
    var path:String;
    var method:String;
    var callName:String;
    var proxyCallName:String;
}