# Samba Server

Blazing-ly fast & highly optimized backend development framework for developing Api's & Event-Driven
WebSocket's which written completely in Dart.

## Quickstart

```dart
import 'dart:async';

import 'package:samba_server/samba_server.dart';

class ChatSocketRoute extends WebSocketRoute {
  @override
  FutureOr<void> onConnected(WebSocket webSocket) {
    throw UnimplementedError();
  }
}

class HelloRoute extends Route {
  HelloRoute() : super(HttpMethod.get, '/');

  @override
  FutureOr<Response> handler(Request request) {
    return Response.ok(body: 'Hello from SAMBA_SERVER');
  }
}

Future<void> main() async {
  final httpServer = HttpServer();
  httpServer..registerRoute(HelloRoute())..registerRoute(ChatSocketRoute());
  await httpServer.bind(address: '127.0.0.1', port: 8080);
}
```

## Features

- Focus on blazing fast speed & performance
- Robust routing based on [Radix Trie](https://en.wikipedia.org/wiki/Radix_tree).
- Event-Driven WebSockets with Rooms support.
- Intercept any request or response for pre or post processing.
- Graceful error handling.
- Super-high test coverage.

## Installation

- This is a [Dart](https://dart.dev/) package available through the [pub.dev](https://pub.dev)
  package repository.
- Before installing, download and setup [Dart SDK](https://dart.dev/get-dart). Dart SDK 3.0.0 or
  higher is required.
- Installation is done using the [`dart pub add` command](https://dart.dev/tools/pub/cmd/pub-add)

```bash
dart pub add samba_server
```

## Running Tests

To run the test suite, first install the dependencies, then run test suite.

`-j 1` is mandatory in the `test` command. Without that all tests will run in parallel which forces
some tests to fail because all tests were using same port for binding the server.

```bash
dart pub get
dart test -j 1
```

## Authors

The original author & lead maintainer of **Samba Server**
is **[@tejHackerDev](https://github.com/tejHackerDev)**

# Index

- [Request](#request)
    - [Path Parameters](#path-parameters)
    - [Query Parameters](#query-parameters)
    - [Request Headers](#request-headers)
    - [Request Body](#request-body)
    - [Request Decoders](#request-decoders)
- [Response](#response)
    - [Response Headers](#response-headers)
    - [Response Body](#response-body)
    - [Response Encoders](#response-encoders)
- [Routes](#routes)
    - [Static Routes](#static-routes)
    - [Parametric Routes](#parametric-routes)
        - [Non-Regex Routes](#non-regexp-routes)
        - [Regex Routes](#regexp-routes)
    - [Wildcard Routes](#wildcard-routes)
    - [PathParameters Priority](#pathparameters-priority)
- [WebSockets](#websockets)
    - [WebSocket Route](#websocket-route)
    - [WebSocket](#websocket)
    - [Rooms](#rooms)
- [Interceptors](#interceptors)
    - [Interceptor Levels](#interceptor-levels)
        - [Global Level Interceptors](#global-level-interceptors)
        - [Route Level Interceptors](#route-level-interceptors)
    - [Interceptors Priority](#interceptors-priority)
- [Cross-Origin](#cross-origin)
- [HttpServer](#httpserver)
    - [Bind](#bind)
    - [Supported Methods](#supported-methods)
    - [Register Route](#register-route)
    - [Register interceptors](#register-interceptors)
    - [Error Handling](#error-handling)
    - [Shutdown](#shutdown)

## Request

This is an wrapper around the `HttpRequest` class of `dart:io` package. Basically this class
contains the necessary information about the incoming request that comes to the server for handling.

### Path Parameters

This is an type of `Map<String, String>` where the `key` is the name of the dynamic pathParameter
that is given at the time of route registration & `value` is the one that is passed in-place of the
dynamic pathParameter at the run-time. Check [routes](#routes) section for more understanding.

### Query Parameters

This is an type of `Map<String, dynamic>` where the `key` is the name that is passed in the request
& `value` is the data passed in the request for the respective `key`.

Basically `value` is of type `dynamic` but to be precise it will be either `String`
or `List<String>`. It will be `String` if only one value is passed for the respective `key`, if more
that one value is passed for the same `key` then it will `List<String>`.

### Request Headers

This is an type of `Map<String, String>` where the `key` is the name of the header & `value` is the
data passed for the name. If multiple values for passed for the same `key` then they will be joined
with a comma `,` & finally converted to the `String`.

### Request Body

This is an type of `dynamic`. By default this value may be of `null` if nothing is passed in
request `body` else if any is passed then it will be of type `Stream<Uint8List>` unless converted by
any [request decoders](#request-decoders).

So before accessing `this` value, it is advised to check its type for safer code.

### Request Decoders

This is an custom [interceptor](#interceptors) class which can be used to decode the `body` based on
the `content-type` present in the `headers`. Also by default it will only decode the `body` if it is
of type `Stream<Uint8List>`.

By default **Samba Server** ships with some default request decoders as mentioned below

1. StringRequestDecoder
2. FormUrlencodedRequestDecoder
3. JsonRequestDecoder
4. MultipartRequestDecoder

In an order to create any other or custom request decoder, one should `extends`
the `RequestDecoder<T>` class. As we can see the class is taking an generic type `T`, so one should
replace that generic type to the actual type, which is basically the output they are looking to
generate for the `body` parameter by that decoder. Based on the type passed one should override the
required methods to achieve that effect.

So let say if we want the `body` to be decoded as `String` we should `extends` the class
as `RequestDecoder<String>` & implement required methods. Finally add it as
a [interceptor](#interceptors) for the whole [http-server](#httpserver) or for
individual [Route](#routes).

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:samba_server/samba_server.dart';

class StringRequestDecoder extends RequestDecoder<String> {
  const StringRequestDecoder()
      : super(
    // by default all decoders will try to decode
    // all requests who's content-type value present in
    // header starts with one specified here.
    //
    // If we don't want that behaviour, then one should
    // override the `canDecode` function where we basically
    // return `true` or `false` based on the content-type passed.
    contentType: 'text/',

    // by default the encoding will be detected based on value
    // passed in the content-type, if no encoding is passed in the
    // content-type then this value will be used for the decoding purpose
    fallbackEncoding: utf8,
  );

  @override
  FutureOr<String> decode(io.ContentType contentType,
      Encoding encoding,
      Stream<Uint8List> stream,) async {
    // Actual logic to convert the `stream` into our desired type.
    //
    // This will only gets invoked if `canDecode` function returns `true`.
    return encoding.decoder.bind(stream).join();
  }
}
```

## Response

This is an wrapper around the `HttpResponse` class of `dart:io` package. Basically this class
contains the necessary information about the outgoing data for an particular [request](#request).

There are several named constructors to create `this` class like `ok`, `created`, `notFound` etc.,
but you can use the default constructor to create your own instance with your specified values.

### Response Headers

This is an type of `Map<String, String>` where the `key` is the name of the header & `value` is the
data passed for the name. If multiple values should be passed for the same `key` then join with a
comma `,`.

### Response Body

This is an type of `Object?`. By default this value will be `null` if nothing is passed in
response `body` & if its `null` then empty body will be sent along with the response.

### Response Encoders

This is an custom [interceptor](#interceptors) class which can be used to encode the `body`
to `String` based on the `type` of value. Also by default it will only encode the `body` if
the `content-type` is not already set in the response `headers`. This is to prevent for not calling
multiple encoders to encode the same value again & again.

By default **Samba Server** ships with some default request encoders as mentioned below

1. StringResponseDecoder
2. NumResponseDecoder
3. BoolResponseDecoder
4. JsonListResponseDecoder
5. JsonMapResponseDecoder

In an order to create any other or custom response encoder, one should `extends`
the `ResponseDecoder<T>` class. As we can see the class is taking an generic type `T`, so one should
replace that generic type to the actual type, which is basically the input they are looking to
convert by that encoder. Based on the type passed one should override the required methods to
achieve that effect.

So let say if we want the `body` to be encode from `String` we should `extends` the class
as `ResponseDecoder<String>` & implement required methods. Finally add it as
a [interceptor](#interceptors) for the whole [http-server](#httpserver) or for
individual [Route](#routes).

```dart
import 'dart:async';

import 'package:samba_server/samba_server.dart';

class StringResponseEncoder extends ResponseEncoder<String> {
  const StringResponseEncoder()
      : super(
    // What ever value that is passed here will be
    // set as the `content-type` in the headers of the
    // response which is encoder by `this` encoder.
    contentType: 'text/plain',
  );

  @override
  FutureOr<String> encode(String value) {
    // Actual logic to convert the `value` into the String.
    //
    // This will only gets invoked if `canEncode` func`tion returns `true`.
    //
    // In this example there is no much computation happening
    // because the `value` which we are trying to convert is already
    // as string, so we are returning it simply.
    return value;
  }
}
```

## Routes

In order to create a route for the [http-server](#httpserver) one should `extends` a class
with `Route` class & should [register](#register-route) it to the server. Should also needs to
specify the `HttpMethod` & `path` for the route, which is later on used for matching criteria.

Every route should implement the `handler`function which should returns an [Response](#response)
which can later of sent as a response for the request for which this route is invoked.

One can add [interceptors](#interceptors) to a route by overriding the `interceptors` function &
these interceptors will be invoked only if the route is selected as the matched one.

Unlike [interceptors](#interceptors) state should not stored in a route because, you can imagine
the `Route` as a [singleton class](#https://en.wikipedia.org/wiki/Singleton_pattern), so storing
state in it results in side effects such as other request state may be used in some other requests (
which in general no one wills to happen).

**Samba Server** supports three types of routes as mentioned below. But we can also write a path by
combining all types in a single path.

### Static Routes

These are the routes where there will be no dynamic parameters present in the path.

```dart
import 'package:samba_server/samba_server.dart';

class GetUsersRoute extends Route {
  GetUsersRoute() : super(HttpMethod.get, '/users');

  @override
  FutureOr<Response> handler(Request request) {
    return Response.ok(body: 'Users');
  }
}
```

_Matchable Path_

```text
/users
```

_Some Non-Matchable Paths_

```text
/users/1234
/users/some_random_id
/users/someRandomId
/users/1234_id/radom
```

### Parametric Routes

These are the routes that contains some dynamic pathParameters in the path. An dynamic pathParameter
can be defined in a path by wrapping that path inside flower brackets `{}`.

So when any incoming path is matched with the route then the value present in-place of dynamic
pathParameter will come as a value under the key which is the name that is given at the time of
registration (See the examples below for more clarification). That is the reason there should not be
two pathParameter with the same name inside a single path, as they key will be overridden while
decoding the path.

These routes are divided into two types of routes as mentioned below. But we can also write a path
by combining both types in a single path.

#### Non-RegExp Routes

These are the routes which doesn't contain any RegExp in the dynamic pathParameter.

```dart
import 'package:samba_server/samba_server.dart';

class GetUserRoute extends Route {
  GetUserRoute() : super(HttpMethod.get, '/users/{id}');

  @override
  FutureOr<Response> handler(Request request) {
    final userId = request.pathParameters['id'];
    return Response.ok(body: userId);
  }
}
```

As per the above example in-place of `id` anything can be passed & that value can be read from
the `request` parameter.

_Some Matchable Paths_

```text
/users/1234 -> 1234
/users/someRandomId -> someRandomId
/users/1234_id -> 1234_id
```

_Some Non-Matchable Paths_

```text
/users
/users/1234/anything
/users/someRandomId/1234
/users/1234_id/radom
```

#### RegExp Routes

These are the routes which contains a RegExp in the dynamic pathParameter which is separated by
colon `:` from the pathParameter name.

```dart
import 'package:samba_server/samba_server.dart';

class GetUserRoute extends Route {
  GetUserRoute() : super(HttpMethod.get, '/users/{id:^[a-z]+\$}');

  @override
  FutureOr<Response> handler(Request request) {
    final userId = request.pathParameters['id'];
    return Response.ok(body: userId);
  }
}
```

As per the above example in-place of `id` only lower-case alphabet values can be passed because
RegExp `^[a-z]+\$` only accepts them & that value can be read from the `request` parameter.

_Some Matchable Paths_

```text
/users/a -> a
/users/somerandomid -> somerandomid
```

_Some Non-Matchable Paths_

```text
/users
/users/1234
/users/some_random_id
/users/someRandomId
/users/1234/anything
/users/someRandomId/1234
/users/1234_id/radom
```

### Wildcard Routes

These are the routes which ends with a `*` in the path.

As mentioned a path can contain `*` but it should be the last pathParameter. Containing any
pathParameter after `*` will ends in throwing an error as it is not supported.

So when any incoming path is matched with the route then the remainingPath present in-place of
wildcard pathParameter will come as a value under the key `*` (See the examples below for more
clarification).

```dart
import 'package:samba_server/samba_server.dart';

class UsersWildcardRoute extends Route {
  UsersWildcardRoute() : super(HttpMethod.get, '/users/*');

  @override
  FutureOr<Response> handler(Request request) {
    final remainingPath = request.pathParameters['*'];
    return Response.ok(body: 'Remaining path $remainingPath');
  }
}
```

As per the above example any pathParameters passed after `/users` will be matched by the route.

_Some Matchable Paths_

```text
/users/1234 -> 1234
/users/somerandomid -> somerandomid
/users/1234_id -> 1234_id
/users/1234_id/anyRandomStuff -> 1234_id/anyRandomStuff
/users/1234_id/8764/anyRandomStuff -> 1234_id/8764/anyRandomStuff
```

_Some Non-Matchable Paths_

```text
/users
```

### PathParameters Priority

If there is a chance for multiple routes getting matched for a single `pathParameter`, then a route
will be selected among them based on the below mentioned priority order of `pathParameter` present
in their path.

1. Static PathParameter
2. NonRegExp PathParameter
3. RegExp PathParameter
4. Wildcard PathParameter

## WebSockets

This a type of communication protocol that is used in order to achieve bi-directional way of
communication between client & server. Read more about it
from [here](https://en.wikipedia.org/wiki/WebSocket)

### WebSocket Route

This is an extended version of regular [Route](#routes) class for handling the web socket
connections. By default the `path` for this route will be set to `/ws` & the `httpMethod`
to `HttpMethod.get`, if needed they can be changed in the same way we change for regular route.

As it is an extended version what ever things applicable for a route all those will be applicable to
this class too.
**_Note_:-** As web socket is an active connection which won't be removed unless either server or
client gets disconnected, so the [interceptors](#interceptors) `onDispose` function added to this
route will only gets called when the client gets disconnected from the route not when any data
emitted to them.

In order to make a route handle web socket connections one should `extends` the `WebSocketRoute`
class.

```dart
import 'dart:async';

import 'package:samba_server/samba_server.dart';

class ChatSocketRoute extends WebSocketRoute {
  @override
  FutureOr<void> onConnected(WebSocket webSocket) {
    throw UnimplementedError();
  }
}
```

There are several function present in the `WebSocketRoute` which can overridden in order to make
working with web socket much easier.

**`onConnected:-`** will get triggered, when ever new client is connected to the route.
**`onJoined:-`** will get triggered, when ever new client joined a room.
**`onLeft:-`** will get triggered, when ever a client left a room.
**`onError:-`** will get triggered, when ever any error occurred while handling a specific client.
**`onDone:-`** will get triggered, when ever a client got disconnected from the route.

### WebSocket

This is an wrapper around the `WebSocket` class of `dart:io` package. Basically this class contains
the necessary information about the connected client.

Using this class we can communicate with the client bi-directionally.

```dart
import 'dart:async';

import 'package:samba_server/samba_server.dart';

class ChatSocketRoute extends WebSocketRoute {
  @override
  FutureOr<void> onConnected(WebSocket webSocket) {
    // emits an message to the client
    // indicating that the connection was successful
    webSocket.emit(
      'message',
      {
        'connectionStatus': 'successful',
      },
    );

    // listen for the data emitted by the client to the server
    // under a specific event
    webSocket.on('message', (data) {});
  }
}
```

As we seen in the above example we are listening on a event named `message`, like that we can listen
on `n` number of events at the server side. Also there were some other function similar to `on` that
can be used on `WebSocket` class to achieve desired effect as per needs.

### Rooms

This is a concept which can be only handled from the server side not from the client side.

As in a regular day-to-day life several persons can live in a single or multiple rooms, in the same
wise at server side a client can live in single or multiple rooms. It is upto to the server whether
to `join` or `leave` a client from respective room & client don't know to which rooms they are
connected with unless server specifies it to the client explicitly through some process.

Server can add a client to a room by calling `join` function & can remove a client from a room by
calling `leave` function on a `WebSocket` instance. And server can `emit` to all clients at one
present in rooms by calling `emit` function present in the `WebSocketRoute` class

```dart
import 'dart:async';

import 'package:samba_server/samba_server.dart';

class ChatSocketRoute extends WebSocketRoute {
  @override
  FutureOr<void> onConnected(WebSocket webSocket) {
    // Add the client to the room named `discussions`
    webSocket.join('discussions');

    if (true) {
      // emit to all clients in the specified rooms
      // indicating the id of the connected user
      emit(
        'message',
        {
          'connectedUserId': webSocket.id,
        },
        rooms: ['discussion'],
      );
    }

    if (true) {
      // Removes the client from the room named `discussions`
      webSocket.leave('discussions');
    }
  }
}
```

## Interceptors

This is a class which can be used to pre or post modify the `request` or `response` classes. Even
helps in returning the response directly without invoking any further interceptors or route.

Interceptor can hold the state, because interceptor will be created (with new state) when ever it is
required & gets destroyed (along with the state) after the usage. So for every request unique
interceptor of same instance will be created.

In order to create an interceptor one should `extends` the `Interceptor` class.

```dart
import 'dart:async';

import 'package:samba_server/samba_server.dart';

class LoggerInterceptor extends Interceptor {
  @override
  FutureOr<Response?> onInit(Request request) {
    // Will get invoked when ever interceptor came into the execution scope.
    // If interceptor is added for a route then,
    // `this` function will get invoked before invoking the route.
    return super.onInit(request);
  }

  @override
  FutureOr<Response> onDispose(Request request, Response response) {
    // Will get invoked when ever interceptor is going out of execution scope.
    // If interceptor is added for a route then,
    // `this` function will get invoked after route returns its response.
    return super.onDispose(request, response);
  }
}
```

**_Note_:-** If `onInit` function returns a [response](#response) instead of `null` then any
next `interceptor`s or `route` wont be invoked.

### Interceptor Levels

Interceptors can be added at different levels as mentioned below

1. Global Level Interceptors
2. Route Level Interceptors

#### Global Level Interceptors

These are the interceptors that can be added to the [http-server](#httpserver) directly & will get
invoked for all matched routes.

Click [here](#register-interceptors) to know how to register them.

#### Route Level Interceptors

These are the interceptors that can be added to the individual route & will get invoked only for
that route.

```dart
import 'dart:async';

import 'package:samba_server/samba_server.dart';

class AuthInterceptor extends Interceptor {
  @override
  FutureOr<Response?> onInit(Request request) {
    // TODO: implement onInit
    return super.onInit(request);
  }

  @override
  FutureOr<Response> onDispose(Request request, Response response) {
    // TODO: implement onDispose
    return super.onDispose(request, response);
  }
}

class HelloRoute extends Route {
  HelloRoute() : super(HttpMethod.get, '/');

  @override
  FutureOr<Iterable<Interceptor>>? interceptors(Request request) {
    return [
      AuthInterceptor(),
    ];
  }

  @override
  FutureOr<Response> handler(Request request) {
    return Response.ok(body: 'Hello from SAMBA_SERVER');
  }
}
```

### Interceptors Priority

Interceptors priority is calculated how they are stacked or added to the [http-server](#httpserver)
for a particular [route](#routes) ie., `onInit` function
of  [global level interceptors](#global-level-interceptors) will be invoked first
then [route level interceptors](#route-level-interceptors) will be invoked & their order will be
same as they were added as a `Iterable`.

But when the interceptors were going out of scope their execution order will be the reverse order of
the way they were executed ie., `onDispose` function
of [route level interceptors](#route-level-interceptors) will be invoked first
then [global level interceptors](#global-level-interceptors) will be invoked & their order will be
reverse order of their `Iterable` version.

## Cross-Origin

These are some set of rules that should be set by the server in an order for the requests made from
website works properly. This also refers with some other names like _CORS_, _Cross-Origin Resource
Sharing_ etc., Read more about it [here](#https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS).

**Samba Server** by defaults ships with a `CrossOriginInterceptor` which can be used as a regular
interceptor & this will helps in setting up the cross-origin rules based on the properties passed.

## HttpServer

This is an wrapper around the `HttpServer` class of `dart:io` package. Basically this is the core of
the whole project.

### Bind

Server can be started by binding it to a specific `address` & `port` as mentioned below. Once it is
binding then server will start listen to all incoming requests under then specified `address`
& `port`.

```dart
import 'package:samba_server/samba_server.dart';

Future<void> main() async {
  final httpServer = HttpServer();
  await httpServer.bind(address: '127.0.0.1', port: 8080);
}
```

### Supported Methods

Below are the methods that were supported by **Samba Server** at the current moment these may change
in future as per the community needs.

```dart
enum HttpMethod {
  get,
  post,
  put,
  patch,
  delete,
  options,
  all,
}
```

### Register Route

A route should be registered to the http-server in order to start handling for matched paths.

```dart
import 'dart:async';

import 'package:samba_server/samba_server.dart';

class HelloRoute extends Route {
  HelloRoute() : super(HttpMethod.get, '/');

  @override
  FutureOr<Response> handler(Request request) {
    return Response.ok(body: 'Hello from SAMBA_SERVER');
  }
}

Future<void> main() async {
  final httpServer = HttpServer();
  httpServer.registerRoute(HelloRoute());
  await httpServer.bind(address: '127.0.0.1', port: 8080);
}
```

### Register Interceptors

Multiple interceptors can be registered to the http-server directly which in-turn called as global
level interceptors.

```dart
import 'dart:async';

import 'package:samba_server/samba_server.dart';

class LoggerInterceptor extends Interceptor {
  @override
  FutureOr<Response?> onInit(Request request) {
    // TODO: implement onInit
    return super.onInit(request);
  }

  @override
  FutureOr<Response> onDispose(Request request, Response response) {
    // TODO: implement onDispose
    return super.onDispose(request, response);
  }
}

Future<void> main() async {
  final httpServer = HttpServer();
  httpServer.registerInterceptors((request) {
    return [
      LoggerInterceptor(),
    ];
  });
  await httpServer.bind(address: '127.0.0.1', port: 8080);
}
```

### Error Handling

Any error occurred in the server while handling any request will be caught & will be propagated to
the `errorHandler` if passed any.

```dart
import 'package:samba_server/samba_server.dart';

Future<void> main() async {
  final httpServer = HttpServer();
  httpServer.registerErrorHandler((request, response, error, stackTrace) {
    return Response.internalServerError(body: 'Some error has occurred');
  });
  await httpServer.bind(address: '127.0.0.1', port: 8080);
}
```

**Samba Server** is smart enough to even caught the errors occurred by the `errorHandler` & handle
itself internally by sending an default error response.

```dart

final defaultErrorResponse = Response.internalServerError(
  body: 'Something went wrong, please try again later.',
);
```

### Shutdown

Server can be stopped by calling `shutdown` function associated to the server. By default server
will get stopped gracefully ie., waits for any pending requests completion & closes it. But if we
don't want this kind of behaviour, we can pass `gracefully` flag as `false`, which make pending
requests to force close immediately.

```dart
import 'package:samba_server/samba_server.dart';

Future<void> main() async {
  final httpServer = HttpServer();
  await httpServer.bind(address: '127.0.0.1', port: 8080);

  // terminate the server based as per appropriate condition
  if (true) {
    await httpServer.shutdown();
  }
}
```