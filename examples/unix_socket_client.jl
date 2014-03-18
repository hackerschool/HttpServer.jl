clientside = connect("/tmp/julia.socket")

write(clientside,"GET /hello/test HTTP/1.1\
                    Host: localhost:80\n\n")
write(STDOUT,readline(clientside))

