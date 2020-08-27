//
//  WebSocketsHandler.swift
//  Sea Battle 2D iOS
//
//  Created by Vlad Nechiporenko on 12/1/19.
//  Copyright © 2019 Vlad Nechyporenko. All rights reserved.
//

import PerfectLib
import PerfectWebSockets
import PerfectHTTP

func makeRoutes() -> Routes {
    
    var routes = Routes()
    // Add a default route which lets us serve the static index.html file
    routes.add(method: .get, uri: "*", handler: { request, response in
        StaticFileHandler(documentRoot: request.documentRoot, allowResponseFilters: true).handleRequest(request: request, response: response)
    })
    
    // Add the endpoint for the WebSocket example system
    routes.add(method: .get, uri: "/echo", handler: {
        request, response in
        
        // To add a WebSocket service, set the handler to WebSocketHandler.
        // Provide your closure which will return your service handler.
        WebSocketHandler(handlerProducer: {
            (request: HTTPRequest, protocols: [String]) -> WebSocketSessionHandler? in
            
            // Check to make sure the client is requesting our "echo" service.
            guard protocols.contains("echo") else {
                return nil
            }
            
            // Return our service handler.
            return EchoHandler()
        }).handleRequest(request: request, response: response)
    })
    
    return routes
}

// A WebSocket service handler must impliment the `WebSocketSessionHandler` protocol.
// This protocol requires the function `handleSession(request: WebRequest, socket: WebSocket)`.
// This function will be called once the WebSocket connection has been established,
// at which point it is safe to begin reading and writing messages.
//
// The initial `WebRequest` object which instigated the session is provided for reference.
// Messages are transmitted through the provided `WebSocket` object.
// Call `WebSocket.sendStringMessage` or `WebSocket.sendBinaryMessage` to send data to the client.
// Call `WebSocket.readStringMessage` or `WebSocket.readBinaryMessage` to read data from the client.
// By default, reading will block indefinitely until a message arrives or a network error occurs.
// A read timeout can be set with `WebSocket.readTimeoutSeconds`.
// When the session is over call `WebSocket.close()`.
class EchoHandler: WebSocketSessionHandler {
    
    // The name of the super-protocol we implement.
    // This is optional, but it should match whatever the client-side WebSocket is initialized with.
    let socketProtocol: String? = "echo"
    
    // This function is called by the WebSocketHandler once the connection has been established.
    func handleSession(request: HTTPRequest, socket: WebSocket) {
        
        // Read a message from the client as a String.
        // Alternatively we could call `WebSocket.readBytesMessage` to get binary data from the client.
        socket.readStringMessage {
            // This callback is provided:
            //    the received data
            //    the message's op-code
            //    a boolean indicating if the message is complete (as opposed to fragmented)
            string, op, fin in
            
            // The data parameter might be nil here if either a timeout or a network error, such as the client disconnecting, occurred.
            // By default there is no timeout.
            guard let string = string else {
                // This block will be executed if, for example, the browser window is closed.
                socket.close()
                return
            }
            
            // Print some information to the console for informational purposes.
            print("Read msg: \(string) op: \(op) fin: \(fin)")
            
            // Echo the data we received back to the client.
            // Pass true for final. This will usually be the case, but WebSockets has the concept of fragmented messages.
            // For example, if one were streaming a large file such as a video, one would pass false for final.
            // This indicates to the receiver that there is more data to come in subsequent messages but that all the data is part of the same logical message.
            // In such a scenario one would pass true for final only on the last bit of the video.
            socket.sendStringMessage(string: string, final: true) {
                
                // This callback is called once the message has been sent.
                // Recurse to read and echo new message.
                self.handleSession(request: request, socket: socket)
            }
        }
    }
}
