using Requests
using HttpCommon
using HttpParser

function process_response(stream)
    r = Response()
    rp = Requests.ResponseParser(r,stream)
    while isopen(stream)
        data = readavailable(stream)
        if length(data) > 0
            http_parser_execute(rp.parser, rp.settings, data)
        end
    end
    http_parser_execute(rp.parser,rp.settings,"") #EOF
    r
end

# emulates Requests.do_request but with a socket connection
stream = connect("/tmp/julia.socket")
req = Requests.default_request("GET", "/", "/tmp/julia.socket", "")
dump(req)
resp = Requests.Response()
resp.request = Nullable(req)
stream = Requests.ResponseStream(resp, stream)
Requests.send_headers(stream)
Requests.process_response(stream)
while stream.state < Requests.BodyDone
  wait(stream)
end
close(stream)
ret = stream.response
ret.data = read(stream)
println(Requests.text(ret))

