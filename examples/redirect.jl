using HttpServer

function redirect(url::String)
    response = "<!DOCTYPE HTML>\
                <html lang=\"en-US\">\
                    <head>\
                        <meta http-equiv=\"refresh\" content=\"0; url=http://$url/\" />\
                    </head>\
                </html>"
    return response
end

http = HttpHandler() do req::Request, res::Response
    print("$req")
    m = match(r"^/redirect/(.*)/",req.resource)
    if m == nothing return Response(404) end
    url = string(m.captures[1])
    return Response(redirect(url))
end

http.events["error"]  = (client, err) -> println(err)

server = Server(http)
run(server, IPv4(127,0,0,1), 8000)

# Url Example: http://localhost:8000/redirect/julialang.org/
