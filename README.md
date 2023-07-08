# Double Gopher

## What?
imagine:
- you have a gopher server on a local workstation that is not always powered on
- your friend have a server with domain and frps, running 7x24
- you want to expose your local server using frp
- but you don't want that port totally unavailable when local server is offline

strange, though

## Solution
- have a "fallback" server serving non-stop.
- if the local server is online, then redirect the network flow to that server

