// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import XCTest
import Combine
import GRPC
import NIO
@testable import CombineGRPC

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
class StressTest: XCTestCase {

  static var serverEventLoopGroup: EventLoopGroup?
  static var unaryClient: UnaryScenariosServiceClient?
  static var serverStreamingClient: ServerStreamingScenariosServiceClient?
  static var clientStreamingClient: ClientStreamingScenariosServiceClient?
  static var bidirectionalStreamingClient: BidirectionalStreamingScenariosServiceClient?
  static var retainedCancellables: [AnyCancellable] = []
  
  override class func setUp() {
    super.setUp()

    let services: [CallHandlerProvider] = [
      UnaryTestsService(),
      ServerStreamingTestsService(),
      ClientStreamingTestsService(),
      BidirectionalStreamingTestsService()
    ]
    serverEventLoopGroup = try! makeTestServer(services: services, eventLoopGroupSize: 4)
    
    unaryClient = makeTestClient(eventLoopGroupSize: 4) { connection, callOptions in
      UnaryScenariosServiceClient(connection: connection, defaultCallOptions: callOptions)
    }
    serverStreamingClient = makeTestClient(eventLoopGroupSize: 4) { connection, callOptions in
      ServerStreamingScenariosServiceClient(connection: connection, defaultCallOptions: callOptions)
    }
    clientStreamingClient = makeTestClient(eventLoopGroupSize: 4) { connection, callOptions in
      ClientStreamingScenariosServiceClient(connection: connection, defaultCallOptions: callOptions)
    }
    bidirectionalStreamingClient = makeTestClient(eventLoopGroupSize: 4) { connection, callOptions in
      BidirectionalStreamingScenariosServiceClient(connection: connection, defaultCallOptions: callOptions)
    }
  }
  
  override class func tearDown() {
    try! unaryClient?.connection.close().wait()
    try! serverStreamingClient?.connection.close().wait()
    try! clientStreamingClient?.connection.close().wait()
    try! bidirectionalStreamingClient?.connection.close().wait()
    try! serverEventLoopGroup?.syncShutdownGracefully()
    retainedCancellables.removeAll()
    super.tearDown()
  }
  
  private func randomRequest() -> EchoRequest {
    let messageOfRandomSize = (0..<50).map { _ in UUID().uuidString }.reduce("", { $0 + $1 })
    return EchoRequest.with { $0.message = messageOfRandomSize }
  }
}
