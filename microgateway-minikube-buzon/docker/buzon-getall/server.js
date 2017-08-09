var http = require('http')

var port = 5552

var server = http.createServer(function (request, response) {
  response.writeHead(200, {'Content-Type': 'text/plain'})
  response.end('Buzon getall is working\n')
})

server.listen(port)

console.log('Server running at http://localhost:' + port)
