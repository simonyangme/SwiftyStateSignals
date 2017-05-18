//
//  SignalMachine.swift
//  SwiftyStateSignals
//
//  Created by Simon Yang on 5/24/15.
//  Copyright (c) 2015 Simon Yang. All rights reserved.
//

import ReactiveCocoa
import ReactiveSwift
import Result

public protocol TransitionDictionaryType {
    associatedtype State
    associatedtype Event
    
    func mapEvent(_ event: Event, fromState: State, toState: State)
    func toStateForEvent(_ event: Event, fromState: State) -> State?
}

public class TransitionDictionary<S, E>: TransitionDictionaryType where S: Hashable, E: Hashable {
    public typealias State = S
    public typealias Event = E
    
    fileprivate var eventDictionary = Dictionary<Event, Dictionary<State, State>>()
    
    public func mapEvent(_ event: Event, fromState: State, toState: State) {
        if let transitions = eventDictionary[event] {
            if let currentToState = transitions[fromState] {
                print("Warning: mapEvent:\(event) from:\(fromState) to:\(toState) overwriting existing transition to '\(currentToState)'")
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
    
    public func toStateForEvent(_ event: Event, fromState: State) -> State? {
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
    associatedtype State
    associatedtype Event
    
    var fromState: State { get }
    var toState: State? { get }
    var event: Event { get }
    
    init(fromState: State, toState: State?, event: Event)
}

public struct Transition<A, B>: TransitionType, CustomStringConvertible {
    public typealias State = A
    public typealias Event = B
    
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
            return "Transition: \(fromState) -> \(String(describing: toState)), Event: \(event)"
        }
    }
}

public class SignalMachine<S, E>
    where S: Equatable, S: Hashable, E: Equatable, E: Hashable {
    
    public typealias T = Transition<S, E>
    
    public var state: S
    fileprivate let dictionary: TransitionDictionary<S, E>
    public let signal: Signal<T, NoError>
    fileprivate let sink: Observer<T, NoError>
    
    public init(transitionDictionary: TransitionDictionary<S, E>, withInitialState state: S) {
        dictionary = transitionDictionary
        self.state = state
        (signal, sink) = Signal<T, NoError>.pipe()
    }
    
    public func inputEvent(_ event: E) {
        let fromState = state
        let toState = dictionary.toStateForEvent(event, fromState: fromState)
        if let toState = toState {
            state = toState
        }
        let transition = T(fromState: fromState, toState: toState, event: event)
        sink.send(value: transition)
    }
    
    public func allTransitions() -> Signal<T, NoError> {
        return signal
    }
    
    public func transitionsFrom(_ state: S) -> Signal<T, NoError> {
        return signal.filter { $0.fromState == state }
    }
    
    public func transitionsFrom(_ fromState: S, toState: T.State) -> Signal<T, NoError> {
        return signal.filter { $0.fromState == fromState && $0.toState == toState }
    }
    
    public func transitionsTo(_ toState: S) -> Signal<T, NoError> {
        return signal.filter { $0.toState == toState }
    }
    
    public func transitionFaults() -> Signal<T, NoError> {
        return signal.filter { $0.toState == nil }
    }
}
