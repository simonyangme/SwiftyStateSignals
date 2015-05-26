//
//  SignalMachine.swift
//  SwiftyStateSignals
//
//  Created by Simon Yang on 5/24/15.
//  Copyright (c) 2015 Simon Yang. All rights reserved.
//

import ReactiveCocoa

public protocol TransitionDictionaryType {
    typealias State
    typealias Event
    
    func mapEvent(event: Event, fromState: State, toState: State)
    func toStateForEvent(event: Event, fromState: State) -> State?
}

public class TransitionDictionary<S, E where S: Hashable, E: Hashable>: TransitionDictionaryType {
    typealias State = S
    typealias Event = E
    
    private var eventDictionary = Dictionary<Event, Dictionary<State, State>>()
    
    public func mapEvent(event: Event, fromState: State, toState: State) {
        if let transitions = eventDictionary[event] {
            if let currentToState = transitions[fromState] {
                println("Warning: mapEvent:\(event) from:\(fromState) to:\(toState) overwriting existing transition to '\(currentToState)'")
            }
            var newTransitions = transitions
            newTransitions[fromState] = toState
            eventDictionary[event] = newTransitions
        } else {
            var emptyTransitions = Dictionary<State, State>()
            emptyTransitions[fromState] = toState
            eventDictionary[event] = emptyTransitions
        }
    }
    
    public func toStateForEvent(event: Event, fromState: State) -> State? {
        if let transition = eventDictionary[event] {
            return transition[fromState]
        } else {
            return nil
        }
    }
    
    public init(fromTransitionDictionary transitionDictionary: TransitionDictionary<S, E>) {
        for event in transitionDictionary.eventDictionary.keys {
            let transitions = transitionDictionary.eventDictionary[event]!
            var transitionsCopy = Dictionary<S, S>()
            for transitionKey in transitions.keys {
                transitionsCopy[transitionKey] = transitions[transitionKey]
            }
            eventDictionary[event] = transitionsCopy
        }
    }
    
    public init() {}
}

public protocol TransitionType {
    typealias State
    typealias Event
    
    var fromState: State { get }
    var toState: State? { get }
    var event: Event { get }
    
    init(fromState: State, toState: State?, event: Event)
}

public struct Transition<A, B>: TransitionType, Printable {
    typealias State = A
    typealias Event = B
    
    public let fromState: State
    public let toState: State?
    public let event: Event
    
    public init(fromState: State, toState: State?, event: Event) {
        self.fromState = fromState
        self.toState = toState
        self.event = event
    }
    
    public var description: String {
        get {
            return "Transition: \(fromState) -> \(toState), Event: \(event)"
        }
    }
}

public class SignalMachine<
    S, E
    where S: Equatable, S: Hashable, E: Equatable, E: Hashable> {
    
    typealias T = Transition<S, E>
    
    public var state: MutableProperty<S>
    private let dictionary: TransitionDictionary<S, E>
    private let signalProducer: SignalProducer<T, NoError>
    private let sink: SinkOf<Event<T, NoError>>
    
    public init(transitionDictionary: TransitionDictionary<S, E>, withInitialState state: S) {
        dictionary = transitionDictionary
        self.state = MutableProperty(state)
        (signalProducer, sink) = SignalProducer.buffer(0)
    }
    
    public func inputEvent(event: E) {
        let fromState = state.value
        let toState = dictionary.toStateForEvent(event, fromState: fromState)
        if let toState = toState {
            state.value = toState
        }
        let transition = T(fromState: fromState, toState: toState, event: event)
        sendNext(sink, transition)
    }
    
    public func allTransitions() -> SignalProducer<T, NoError> {
        return signalProducer
    }
    
    public func transitionsFrom(state: S) -> SignalProducer<T, NoError> {
        return signalProducer |> filter { $0.fromState == state }
    }
    
    public func transitionsFrom(fromState: S, toState: T.State) -> SignalProducer<T, NoError> {
        return signalProducer |> filter { $0.fromState == fromState && $0.toState == toState }
    }
    
    public func transitionsTo(toState: S) -> SignalProducer<T, NoError> {
        return signalProducer |> filter { $0.toState == toState }
    }
    
    public func transitionFaults() -> SignalProducer<T, NoError> {
        return signalProducer |> filter { $0.toState == nil }
    }
}
