//
//  SwiftMachineSpec.swift
//  SwiftyStateSignals
//
//  Created by Simon Yang on 5/24/15.
//  Copyright (c) 2015 Simon Yang. All rights reserved.
//

import Quick
import Nimble
import ReactiveCocoa

import SwiftyStateSignals

enum TestEvent: CustomStringConvertible {
    case start, event0, event1, event2, event3
    var description: String {
        get {
            switch self {
            case .start:
                return "Start"
            case .event0:
                return "Event0"
            case .event1:
                return "Event1"
            case .event2:
                return "Event2"
            case .event3:
                return "Event3"
            }
        }
    }
}
enum TestState: CustomStringConvertible {
    case initial, a, b, c, d
    var description: String {
        get {
            switch self {
            case .initial:
                return "Initial"
            case .a:
                return "A"
            case .b:
                return "B"
            case .c:
                return "C"
            case .d:
                return "D"
            }
        }
    }
}



class SwiftMachineSepc: QuickSpec {
    override func spec() {
        describe("State Machine") {
            var transitionDictionary: TransitionDictionary<TestState, TestEvent>!
            var stateMachine: SignalMachine<TestState, TestEvent>!
    
            beforeEach {
                transitionDictionary = TransitionDictionary()
                transitionDictionary.mapEvent(.start, fromState: .initial, toState: .a)
                transitionDictionary.mapEvent(.event0, fromState: .a, toState: .b)
                transitionDictionary.mapEvent(.event1, fromState: .b, toState: .c)
                transitionDictionary.mapEvent(.event2, fromState: .c, toState: .d)
                transitionDictionary.mapEvent(.event3, fromState: .d, toState: .a)
                transitionDictionary.mapEvent(.event3, fromState: .b, toState: .d)
                
                stateMachine = SignalMachine(transitionDictionary: transitionDictionary, withInitialState: .initial)
            }
            
            afterEach {
                transitionDictionary = nil
                stateMachine = nil
            }
            
            describe("allTransitions") {
                it("should transition when signal is sent after observation") {
                    var counter = 0
                    let signal = stateMachine.allTransitions()
                    signal.observe { _ in counter += 1 }
                    
                    expect(counter) == 0
                    
                    stateMachine.inputEvent(.event1)
                    
                    expect(counter) == 1
                }
                
                it("should not transistion before observation") {
                    var counter = 0
                    stateMachine.inputEvent(.event0)
                    
                    expect(counter) == 0
                    
                    stateMachine.allTransitions().observe { _ in counter += 1 }
                    
                    expect(counter) == 0
                }
                
                it("should send nil state when there is no transition for event") {
                    stateMachine.inputEvent(.start)
                    stateMachine.inputEvent(.event0)
                    var executed = false
                    stateMachine.allTransitions().observe { e in
                        expect(e.value?.toState).to(beNil())
                        executed = true
                    }
                    stateMachine.inputEvent(.start)
                    expect(executed).to(beTruthy())
                }
            }
            describe("transitionsFrom") {
                it("should send transition") {
                    stateMachine.allTransitions().observe { e in
                        NSLog("\(e)")
                    }
                    stateMachine.inputEvent(.start)
                    stateMachine.inputEvent(.event0)
                    
                    var executed = false
                    stateMachine.transitionsFrom(.b).observe { e in
                        executed = true
                        expect(e.value?.fromState) == TestState.b
                        expect(e.value?.toState) == .c
                    }
                    
                    stateMachine.inputEvent(.event1)
                    
                    expect(executed).to(beTruthy())
                }
                
                it("should not transition when fromState is not current state") {
                    var executed = false
                    stateMachine.transitionsFrom(.b).observe { _ in
                        executed = true
                    }
                    stateMachine.inputEvent(.start)
                    stateMachine.inputEvent(.event0)
                    
                    expect(executed).toNotEventually(beTruthy())
                }
            }
            describe("transitionFault") {
                it("should send transition with nil toState") {
                    var executed = false
                    stateMachine.transitionFaults().observe { e in
                        executed = true
                        expect(e.value?.toState).to(beNil())
                    }
                    stateMachine.inputEvent(.event0)
                    expect(executed).to(beTruthy())
                }
                
                it("should not send transitions for successful transitions") {
                    var executed = false
                    stateMachine.transitionFaults().observe { _ in
                        executed = true
                    }
                    stateMachine.inputEvent(.start)
                    expect(executed).toNotEventually(beTruthy())
                }
            }
        }
    }
}
