// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import NIO
import SwiftProtobuf

@available(OSX 10.15, *)
class ClientStreamingHandlerSubscriber<Request, Response>: Subscriber, Cancellable where Request: Message, Response: Message {
  typealias Input = Response
  typealias Failure = GRPCStatus
  
  var futureEventStreamProcessor: EventLoopFuture<(StreamEvent<Request>) -> Void>
  
  private var subscription: Subscription?
  private let context: UnaryResponseCallContext<Response>
  private let requests: PassthroughSubject<Request, Never>
    
  init(context: UnaryResponseCallContext<Response>, requests: PassthroughSubject<Request, Never>) {
    self.context = context
    self.requests = requests
    self.futureEventStreamProcessor = context.eventLoop.makeSucceededFuture({ streamEvent in
      switch streamEvent {
      case .message(let request):
        requests.send(request)
      case .end:
        requests.send(completion: .finished)
      }
    })
  }
  
  func receive(subscription: Subscription) {
    self.subscription = subscription
    self.subscription?.request(.max(1))
  }
  
  func receive(_ input: Response) -> Subscribers.Demand {
    context.responsePromise.succeed(input)
    return .max(1)
  }
  
  func receive(completion: Subscribers.Completion<GRPCStatus>) {
    switch completion {
    case .failure(let status):
      context.responsePromise.fail(status)
    case .finished:
      let status = GRPCStatus(code: .aborted, message: "Handler completed without a response")
      context.responsePromise.fail(status)
    }
  }
  
  func cancel() {
    subscription?.cancel()
  }
}
