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
                transitionDictionary = TransitionDictionary()
                transitionDictionary.mapEvent(.event0, fromState: .a, toState: .b)
                transitionDictionary.mapEvent(.event1, fromState: .b, toState: .c)
                transitionDictionary.mapEvent(.event2, fromState: .c, toState: .d)
                transitionDictionary.mapEvent(.event3, fromState: .d, toState: .a)
                transitionDictionary.mapEvent(.event3, fromState: .b, toState: .d)
            }
            
            afterEach {
                transitionDictionary = nil
            }
            
            it("should return nil for event with no transition") {
                expect(transitionDictionary.toStateForEvent(.event0, fromState: .b)).to(beNil())
                expect(transitionDictionary.toStateForEvent(.event0, fromState: .d)).to(beNil())
            }
            
            it("should return new state for valid event transition") {
                expect(transitionDictionary.toStateForEvent(.event0, fromState: .a)) == .b
                expect(transitionDictionary.toStateForEvent(.event1, fromState: .b)) == .c
                expect(transitionDictionary.toStateForEvent(.event2, fromState: .c)) == .d
            }
            
            it("should return correct state for event mapped to multiple transitions") {
                expect(transitionDictionary.toStateForEvent(.event3, fromState: .b)) == .d
                expect(transitionDictionary.toStateForEvent(.event3, fromState: .d)) == .a
            }
            
            it("should create new independent copies of transition dictionaries") {
                let dictionaryCopy = TransitionDictionary(fromTransitionDictionary:transitionDictionary)
                transitionDictionary.mapEvent(.event3, fromState: .a, toState: .b)
                dictionaryCopy.mapEvent(.event3, fromState: .a, toState: .c)
                
                expect(transitionDictionary.toStateForEvent(.event0, fromState: .a)) == .b
                expect(dictionaryCopy.toStateForEvent(.event0, fromState: .a)) == .b
                
                expect(transitionDictionary.toStateForEvent(.event3, fromState: .a)) == .b
                expect(dictionaryCopy.toStateForEvent(.event3, fromState: .a)) == .c
            }
            
            it("should overwrite existing transition") {
                expect(transitionDictionary.toStateForEvent(.event2, fromState: .c)) == .d
                transitionDictionary.mapEvent(.event2, fromState: .c, toState: .a)
                expect(transitionDictionary.toStateForEvent(.event2, fromState: .c)) == .a
            }
        }
    }
}
