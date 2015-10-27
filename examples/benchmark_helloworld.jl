# Contents: Basic benchmark
#
# To run the benchmark:
# 1) Select the desired server by commenting out the undesired server
# 2) Run the server: julia benchmark_helloworld.jl
# 3) In another terminal:
#     a) Compile the app:   ab -n 100 -c 1 http://0.0.0.0:8000/
#     b) Run the benchmark: ab -n 10000 -c 1 http://0.0.0.0:8000/

using HttpServer

function app_new(req::Request)
    Response("Hello world")
end

function app_old(req::Request, res::Response)
    Response("Hello world")
end

#server = Server(app_old)
server = Server(app_new)

run(server, 8000)
