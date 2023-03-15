package rest.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type.ClassField;
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
                meta: [{name: ":noCompletion", pos: Context.currentPos()}],
                pos: Context.currentPos()
            });
    
            subApiExprs.push(macro $i{varName} = new $t());
        }
        
        fields.push({
            name: "_restServer",
            kind: FVar(macro: rest.server.RestServer),
            meta: [{name: ":noCompletion", pos: Context.currentPos()}],
            pos: Context.currentPos()
        });

        var calls = [];
        buildApiCalls(apiClass.get(), fields, mappings, calls);
        var routeExprs:Array<Expr> = [];
        for (call in calls) {
            if (call.method == "get") {
                routeExprs.push(macro _restServer.get($v{call.path}, $i{call.proxyCallName}));
            } else if (call.method == "post") {
                routeExprs.push(macro _restServer.post($v{call.path}, $i{call.proxyCallName}));
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
                    buildApiCallFn(f, fields, mappings, calls, prefix, args);   
                case TLazy(fn):
                    var r = fn();
                    switch (r) {
                        case TFun(args, ret):
                            buildApiCallFn(f, fields, mappings, calls, prefix, args);   
                        case _:    
                            trace(fn);
                    }
                case _:    
                    trace(f);
            }
        }
    }

    private static function buildApiCallFn(f:ClassField, fields:Array<Field>, mappings:Map<String, String>, calls:Array<RestServerCallInfo>, prefix:String, args:Array<{name:String, opt:Bool, t:haxe.macro.Type}>) {
        var method = null;
        var path = null;

        var requestType = null;
        for (m in f.meta.get()) {
            if (m.name == ":get") {
                method = "get";
                path = ExprTools.toString(m.params[0]);
                path = path.replace("\"", "");
                path = path.replace("'", "");
            } else if (m.name == ":post") {
                method = "post";
                path = ExprTools.toString(m.params[0]);
                path = path.replace("\"", "");
                path = path.replace("'", "");
            }

            if (m.params[2] != null) {
                if (ExprTools.toString(m.params[2]).toLowerCase() == "json") {
                    requestType = "json";
                }
            }
        }

        if (path == null || method == null) {
            return;
        }

        var objectName = "_" + prefix;
        if (prefix == null) {
            objectName = null;
        }
        var fieldName = f.name;
        var functionExpr = null;
        
        var callSite = macro $i{fieldName};
        if (objectName != null) {
            callSite = macro $i{objectName}.$fieldName;
        }
        var callRequest = macro null;
        var call = macro @:privateAccess $callSite();
        
        if (args.length > 0) {
            // build up call request info
            var callRequestTypeString = null;
            var callRequestSubTypeString = null;
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
                    var module = t.get().module;
                    var type = t.toString();
                    
                    if (module != type) {
                        callRequestTypeString = module;
                        callRequestSubTypeString = type.split(".").pop();
                    } else {
                        callRequestTypeString = type;
                    }
                case _:
            }

            var callRequestExpr:Expr = null;
            if (requestType == "json") {
                // TODO: use json2object
                callRequestExpr = macro haxe.Json.parse(request.body);
            } else {
                var callRequestFields = [];
                for (requestVar in callRequestVars) {
                    switch (requestVar.type) {
                        case "Int":
                            callRequestFields.push({ field: requestVar.name, expr: macro request.paramInt($v{requestVar.name}) });
                        case _:
                        callRequestFields.push({ field: requestVar.name, expr: macro request.param($v{requestVar.name}) });
                    }
                }
                callRequestExpr = {
                    expr: EObjectDecl(callRequestFields),
                    pos: Context.currentPos()
                }
            }

            var callRequestParts = callRequestTypeString.split(".");
            var callRequestTypeName = callRequestParts.pop();
            var callRequestType = TPath({
                pack: callRequestParts,
                name: callRequestTypeName,
                sub: callRequestSubTypeString
            });

            callRequest = macro var callRequest:$callRequestType = $callRequestExpr;
            call = macro @:privateAccess $callSite(callRequest);
        }

        var functionExpr = macro {
            return new promises.Promise((resolve, reject) -> {
                $callRequest;
                $call.then(callResponse -> {                                            
                    if ((callResponse is rest.IJson2ObjectParsable)) {
                        var jsonParsableResponse = cast(callResponse, rest.IJson2ObjectParsable);
                        var jsonString = @:privateAccess jsonParsableResponse.toString();
                        response.headers = [http.StandardHeaders.ContentType => http.ContentTypes.ApplicationJson];
                        if (jsonString != null) {
                            response.write(jsonString);
                        }
                        resolve(response);
                    } else if (callResponse is Array) {
                        var s = Std.string(callResponse);
                        response.write(s);
                        resolve(response);
                    } else {
                        reject("Unknown response type");
                    }
                }, error -> {
                    // TODO: might need to be more clever here
                    if ((error is rest.IParsableError)) {
                        var restError = new rest.RestError();
                        restError.httpStatus = error.httpStatus;
                        restError.message = error.message;
                        restError.body = error.body;
                        reject(restError);
                    } else {
                        reject(error);
                    }
                });
            });
        }

        var callName = "_" + f.name;
        if (prefix != null) {
            callName = "_" + prefix + "_" + f.name;
        }
        var proxyCall:Field = {
            name: callName,
            access: [APrivate],
            meta: [{name: ":noCompletion", pos: Context.currentPos()}],
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
    }
}

private typedef RestServerCallInfo = {
    var path:String;
    var method:String;
    var callName:String;
    var proxyCallName:String;
}