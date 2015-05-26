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

enum TestEvent: Printable {
    case Start, Event0, Event1, Event2, Event3
    var description: String {
        get {
            switch self {
            case .Start:
                return "Start"
            case .Event0:
                return "Event0"
            case .Event1:
                return "Event1"
            case .Event2:
                return "Event2"
            case .Event3:
                return "Event3"
            }
        }
    }
}
enum TestState: Printable {
    case Initial, A, B, C, D
    var description: String {
        get {
            switch self {
            case .Initial:
                return "Initial"
            case .A:
                return "A"
            case .B:
                return "B"
            case .C:
                return "C"
            case .D:
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
                transitionDictionary.mapEvent(.Start, fromState: .Initial, toState: .A)
                transitionDictionary.mapEvent(.Event0, fromState: .A, toState: .B)
                transitionDictionary.mapEvent(.Event1, fromState: .B, toState: .C)
                transitionDictionary.mapEvent(.Event2, fromState: .C, toState: .D)
                transitionDictionary.mapEvent(.Event3, fromState: .D, toState: .A)
                transitionDictionary.mapEvent(.Event3, fromState: .B, toState: .D)
                
                stateMachine = SignalMachine(transitionDictionary: transitionDictionary, withInitialState: .Initial)
            }
            
            afterEach {
                transitionDictionary = nil
                stateMachine = nil
            }
            
            describe("allTransitions") {
                it("should transition when signal is sent after observation") {
                    var counter = 0
                    let signalProducer = stateMachine.allTransitions()
                    signalProducer.start(next: { _ in counter += 1 })
                    
                    expect(counter) == 0
                    
                    stateMachine.inputEvent(.Event1)
                    
                    expect(counter) == 1
                }
                
                it("should not transistion before observation") {
                    var counter = 0
                    stateMachine.inputEvent(.Event0)
                    
                    expect(counter) == 0
                    
                    stateMachine.allTransitions().start(next: { _ in counter += 1 })
                    
                    expect(counter) == 0
                }
                
                it("should send nil state when there is no transition for event") {
                    stateMachine.inputEvent(.Start)
                    stateMachine.inputEvent(.Event0)
                    var executed = false
                    stateMachine.allTransitions().start(next: { t in
                        expect(t.toState).to(beNil())
                        executed = true
                    })
                    stateMachine.inputEvent(.Start)
                    expect(executed).to(beTruthy())
                }
            }
            describe("transitionsFrom") {
                it("should send transition") {
                    stateMachine.allTransitions().start(next: { t in
                        NSLog("\(t)")
                    })
                    stateMachine.inputEvent(.Start)
                    stateMachine.inputEvent(.Event0)
                    
                    var executed = false
                    stateMachine.transitionsFrom(.B).start(next: { t in
                        executed = true
                        expect(t.fromState) == TestState.B
                        expect(t.toState) == .C
                    })
                    
                    stateMachine.inputEvent(.Event1)
                    
                    expect(executed).to(beTruthy())
                }
                
                it("should not transition when fromState is not current state") {
                    var executed = false
                    stateMachine.transitionsFrom(.B).start(next: { t in
                        executed = true
                    })
                    stateMachine.inputEvent(.Start)
                    stateMachine.inputEvent(.Event0)
                    
                    expect(executed).toNotEventually(beTruthy())
                }
            }
            describe("transitionFault") {
                it("should send transition with nil toState") {
                    var executed = false
                    stateMachine.transitionFaults().start(next: { t in
                        executed = true
                        expect(t.toState).to(beNil())
                    })
                    stateMachine.inputEvent(.Event0)
                    expect(executed).to(beTruthy())
                }
                
                it("should not send transitions for successful transitions") {
                    var executed = false
                    stateMachine.transitionFaults().start(next: { t in
                        executed = true
                    })
                    stateMachine.inputEvent(.Start)
                    expect(executed).toNotEventually(beTruthy())
                }
            }
        }
    }
}
