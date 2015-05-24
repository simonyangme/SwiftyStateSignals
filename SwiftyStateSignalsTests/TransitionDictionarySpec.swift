//
//  TransitionDictionarySpec.swift
//  SwiftyStateSignals
//
//  Created by Simon Yang on 5/24/15.
//  Copyright (c) 2015 Simon Yang. All rights reserved.
//

import Quick
import Nimble
import ReactiveCocoa

import SwiftyStateSignals

class TransitionDictionarySpec: QuickSpec {
    override func spec() {
        describe("Transition Dictionary") {
            var transitionDictionary: TransitionDictionary<TestState, TestEvent>!
            
            beforeEach {
                transitionDictionary = TransitionDictionary<TestState, TestEvent>()
                transitionDictionary.mapEvent(.Event0, fromState: .A, toState: .B)
                transitionDictionary.mapEvent(.Event1, fromState: .B, toState: .C)
                transitionDictionary.mapEvent(.Event2, fromState: .C, toState: .D)
                transitionDictionary.mapEvent(.Event3, fromState: .D, toState: .A)
                transitionDictionary.mapEvent(.Event3, fromState: .B, toState: .D)
            }
            
            afterEach {
                transitionDictionary = nil
            }
            
            it("should return nil for event with no transition") {
                expect(transitionDictionary.toStateForEvent(.Event0, fromState: .B)).to(beNil())
                expect(transitionDictionary.toStateForEvent(.Event0, fromState: .D)).to(beNil())
            }
            
            it("should return new state for valid event transition") {
                expect(transitionDictionary.toStateForEvent(.Event0, fromState: .A)) == .B
                expect(transitionDictionary.toStateForEvent(.Event1, fromState: .B)) == .C
                expect(transitionDictionary.toStateForEvent(.Event2, fromState: .C)) == .D
            }
            
            it("should return correct state for event mapped to multiple transitions") {
                expect(transitionDictionary.toStateForEvent(.Event3, fromState: .B)) == .D
                expect(transitionDictionary.toStateForEvent(.Event3, fromState: .D)) == .A
            }
            
            it("should create new independent copies of transition dictionaries") {
                let dictionaryCopy = TransitionDictionary<TestState, TestEvent>(fromTransitionDictionary:transitionDictionary)
                transitionDictionary.mapEvent(.Event3, fromState: .A, toState: .B)
                dictionaryCopy.mapEvent(.Event3, fromState: .A, toState: .C)
                
                expect(transitionDictionary.toStateForEvent(.Event0, fromState: .A)) == .B
                expect(dictionaryCopy.toStateForEvent(.Event0, fromState: .A)) == .B
                
                expect(transitionDictionary.toStateForEvent(.Event3, fromState: .A)) == .B
                expect(dictionaryCopy.toStateForEvent(.Event3, fromState: .A)) == .C
            }
            
            it("should overwrite existing transition") {
                expect(transitionDictionary.toStateForEvent(.Event2, fromState: .C)) == .D
                transitionDictionary.mapEvent(.Event2, fromState: .C, toState: .A)
                expect(transitionDictionary.toStateForEvent(.Event2, fromState: .C)) == .A
            }
        }
    }
}