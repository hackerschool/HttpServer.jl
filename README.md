# HttpServer.jl

[![Build Status](https://travis-ci.org/JuliaWeb/HttpServer.jl.svg?branch=master)](https://travis-ci.org/JuliaWeb/HttpServer.jl)
[![codecov.io](http://codecov.io/github/JuliaWeb/HttpServer.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaWeb/HttpServer.jl?branch=master)

[![HttpServer](http://pkg.julialang.org/badges/HttpServer_0.3.svg)](http://pkg.julialang.org/?pkg=HttpServer&ver=0.3)
[![HttpServer](http://pkg.julialang.org/badges/HttpServer_0.4.svg)](http://pkg.julialang.org/?pkg=HttpServer&ver=0.4)
[![HttpServer](http://pkg.julialang.org/badges/HttpServer_0.5.svg)](http://pkg.julialang.org/?pkg=HttpServer&ver=0.5)
[![HttpServer](http://pkg.julialang.org/badges/HttpServer_0.6.svg)](http://pkg.julialang.org/?pkg=HttpServer&ver=0.6)

This is a basic, non-blocking HTTP server in Julia.

You can write a basic application using just this if you're happy dealing with values representing HTTP requests and responses directly.
For a higher-level view, you could use [Mux](https://github.com/one-more-minute/Mux.jl).
If you'd like to use WebSockets as well, you'll need to grab [WebSockets.jl](https://github.com/JuliaWeb/WebSockets.jl).

##Installation
Use Julia package manager to install this package as follows:
```
Pkg.add("HttpServer")
```

## Functionality
* binds to any address and port
* supports IPv4 & IPv6 addresses
* supports HTTP, HTTPS and Unix socket transports

You can find many examples of how to use this package in the `examples` folder.

## Example

```julia
using HttpServer

http = HttpHandler() do req::Request, res::Response
    Response( ismatch(r"^/hello/",req.resource) ? string("Hello ", split(req.resource,'/')[3], "!") : 404 )
end

server = Server( http )
run( server, 8000 )
# or
run(server, host=IPv4(127,0,0,1), port=8000)
```
If you open up `localhost:8000/hello/name/` in your browser, you should get a greeting from the server.

---

```
:::::::::::::
::         ::
:: Made at ::
::         ::
:::::::::::::
     ::
Hacker School
:::::::::::::
```
