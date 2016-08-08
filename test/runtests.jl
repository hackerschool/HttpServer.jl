using HttpCommon
using FactCheck
using HttpServer

facts("HttpServer utility functions:") do
    context("`write` correctly writes data response") do
        response = Response(200, "Hello World!")
        buf = IOBuffer();
        HttpServer.write(buf, response)
        response_string = takebuf_string(buf)
        vals = split(response_string, "\r\n")
        grep(a::Array, k::AbstractString) = filter(x -> ismatch(Regex(k), x), a)[1]
        @fact grep(vals, "HTTP") --> "HTTP/1.1 200 OK "
        @fact grep(vals, "Server") --> "Server: Julia/$VERSION"
        # default to text/html
        @fact grep(vals, "Content-Type") --> "Content-Type: text/html; charset=utf-8"
        # skip date
        @fact grep(vals, "Content-Language") --> "Content-Language: en"
        @fact grep(vals, "Hello") --> "Hello World!"
    end
end

import Requests: get, text, statuscode

facts("HttpServer runs") do
    context("using HTTP protocol on 0.0.0.0:8000") do
        http = HttpHandler() do req::Request, res::Response
            res = Response( ismatch(r"^/hello/",req.resource) ? string("Hello ", split(req.resource,'/')[3], "!") : 404 )
            setcookie!(res, "sessionkey", "abc", Dict("Path"=>"/test", "Secure"=>""))
        end
        server = Server(http)
        @async run(server, 8000)
        sleep(1.0)

        ret = Requests.get("http://localhost:8000/hello/travis")

        @fact text(ret) --> "Hello travis!"
        @fact statuscode(ret) --> 200
        @fact haskey(ret.cookies, "sessionkey") --> true

        let cookie = ret.cookies["sessionkey"]
            @fact cookie.value --> "abc"
            @fact cookie.attrs["Path"] --> "/test"
            @fact haskey(cookie.attrs, "Secure") --> true
        end

        ret = Requests.get("http://localhost:8000/bad")
        @fact text(ret) --> ""
        @fact statuscode(ret) --> 404
        close(server)
    end

    context("using HTTP/2 protocol on 0.0.0.0:8000") do
        http = HttpHandler() do req::Request, res::Response
            res = Response( ismatch(r"^/hello/",req.resource) ? string("Hello ", split(req.resource,'/')[3], "!") : 404 )
            setcookie!(res, "sessionkey", "abc", Dict("Path"=>"/test", "Secure"=>""))
        end
        server = Server(http, true)
        @async run(server, 8000)
        sleep(1.0)

        ret = Requests.get("http://localhost:8000/hello/travis", http2=true)
        @fact text(ret) --> "Hello travis!"
        @fact statuscode(ret) --> 200

        close(server)
    end

    context("using HTTP/2 protocol upgrade on 0.0.0.0:8000") do
        http = HttpHandler() do req::Request, res::Response
            res = Response( ismatch(r"^/hello/",req.resource) ? string("Hello ", split(req.resource,'/')[3], "!") : 404 )
            setcookie!(res, "sessionkey", "abc", Dict("Path"=>"/test", "Secure"=>""))
        end
        server = Server(http, true)
        @async run(server, 8000)
        sleep(1.0)

        ret = Requests.get("http://localhost:8000/hello/travis", http2=true, upgrade=true)
        @show ret
        @fact text(ret) --> "Hello travis!"
        @fact statuscode(ret) --> 200

        close(server)
    end

    context("using HTTP/2 protocol with promises on 0.0.0.0:8000") do
        http = HttpHandler() do req::Request, res::Response
            promise_request = Request()
            promise_request.headers[":path"] = "/promise"
            (Response("Hello travis!"), [(promise_request, Response("A promise!"))])
        end
        server = Server(http, true)
        @async run(server, 8000)
        sleep(1.0)

        ret = Requests.get("http://localhost:8000/hello/travis", http2=true)
        @show ret[1].headers
        @fact text(ret[1]) --> "Hello travis!"
        @fact length(ret[2]) --> 1
        @fact text(ret[2][1][2]) --> "A promise!"

        close(server)
    end

    context("Rerun test using HTTP protocol on 0.0.0.0:8000 after closing") do
        http = HttpHandler() do req::Request, res::Response
            res = Response( ismatch(r"^/hello/",req.resource) ? string("Hello ", split(req.resource,'/')[3], "!") : 404 )
            setcookie!(res, "sessionkey", "abc", Dict("Path"=>"/test", "Secure"=>""))
        end
        server = Server(http)
        @async run(server, 8000)
        sleep(1.0)

        ret = Requests.get("http://localhost:8000/hello/travis")

        @fact text(ret) --> "Hello travis!"
        @fact statuscode(ret) --> 200
        @fact haskey(ret.cookies, "sessionkey") --> true

        let cookie = ret.cookies["sessionkey"]
            @fact cookie.value --> "abc"
            @fact cookie.attrs["Path"] --> "/test"
            @fact haskey(cookie.attrs, "Secure") --> true
        end

        ret = Requests.get("http://localhost:8000/bad")
        @fact text(ret) --> ""
        @fact statuscode(ret) --> 404
        close(server)
    end

    context("using HTTP protocol on 127.0.0.1:8001") do
        http = HttpHandler() do req::Request, res::Response
            Response( ismatch(r"^/hello/",req.resource) ? string("Hello ", split(req.resource,'/')[3], "!") : 404 )
        end
        server = Server(http)
        @async run(server, host=ip"127.0.0.1", port=8001)
        sleep(1.0)

        ret = Requests.get("http://127.0.0.1:8001/hello/travis")
        @fact text(ret) --> "Hello travis!"
        @fact statuscode(ret) --> 200
        close(server)
    end

    context("Rerun test using HTTP protocol on 127.0.0.1:8001 after closing") do
        http = HttpHandler() do req::Request, res::Response
            Response( ismatch(r"^/hello/",req.resource) ? string("Hello ", split(req.resource,'/')[3], "!") : 404 )
        end
        server = Server(http)
        @async run(server, host=ip"127.0.0.1", port=8001)
        sleep(1.0)

        ret = Requests.get("http://127.0.0.1:8001/hello/travis")
        @fact text(ret) --> "Hello travis!"
        @fact statuscode(ret) --> 200
        close(server)
    end

    context("Testing HTTPS on port 8002") do
        http = HttpHandler() do req, res
            Response("hello")
        end
        server = Server(http)
        cert = MbedTLS.crt_parse_file(Pkg.dir("HttpServer","test","cert.pem"))
        key = MbedTLS.parse_keyfile(Pkg.dir("HttpServer","test","key.pem"))
        @async run(server, port=8002, ssl=(cert, key))
        sleep(1.0)
        client_tls_conf = Requests.TLS_VERIFY
        MbedTLS.ca_chain!(client_tls_conf, cert)
        ret = Requests.get("https://localhost:8002", tls_conf=client_tls_conf)
        @fact text(ret) --> "hello"
        close(server)
    end

    context("Testing HTTPS with HTTP/2 on port 8002") do
        http = HttpHandler() do req, res
            Response("hello")
        end
        server = Server(http, true)
        cert = MbedTLS.crt_parse_file(Pkg.dir("HttpServer","test","cert.pem"))
        key = MbedTLS.parse_keyfile(Pkg.dir("HttpServer","test","key.pem"))
        @async run(server, port=8002, ssl=(cert, key))
        sleep(1.0)
        client_tls_conf = Requests.TLS_VERIFY
        MbedTLS.ca_chain!(client_tls_conf, cert)
        ret = Requests.get("https://localhost:8002", tls_conf=client_tls_conf, http2=true)
        @fact text(ret) --> "hello"
        close(server)
    end

    context("Rerun test of HTTPS on port 8002 after closing") do
        http = HttpHandler() do req, res
            Response("hello")
        end
        server = Server(http)
        cert = MbedTLS.crt_parse_file(Pkg.dir("HttpServer","test","cert.pem"))
        key = MbedTLS.parse_keyfile(Pkg.dir("HttpServer","test","key.pem"))
        @async run(server, port=8002, ssl=(cert, key))
        sleep(1.0)
        client_tls_conf = Requests.TLS_VERIFY
        MbedTLS.ca_chain!(client_tls_conf, cert)
        ret = Requests.get("https://localhost:8002", tls_conf=client_tls_conf)
        @fact text(ret) --> "hello"
        close(server)
    end
end
