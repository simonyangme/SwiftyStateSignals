# SwiftyStateSignals

SwiftyStateSignals is a simple finite state machine framework inspired by [StateSignals](https://github.com/erikprice/StateSignals) and built on [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa) signals.

## Installation

SwiftyStateSignals can be imported just like any framework, but is easy to use with [Carthage](https://github.com/Carthage/Carthage). Just add the following to your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile):

    github "simonyangme/SwiftyStateSignals"

## Example

Begin by defining enums for states:

    enum TurnstileState {
        case Locked, Unlocked
    }

and events:

    enum TurnstileEvent {
        case Coin, Push
    }

Then create a transition dictionary with the desired transitions and create the state machine:

	let transitions = TransitionDictionary<TurnstileState, TurnstileEvent>()
	transitions.mapEvent(.Coin, fromState: .Locked, toState: .Unlocked)
    transitions.mapEvent(.Push, fromState: .Unlocked, toState: .Locked)
	
	let machine = SignalMachine(transitionDictionary: transitions, withInitialState: .Locked)

We can observe for changes by subscribing to any of the signals that the state machine vends. For example:

    machine.allTransitions().observe(next: { transition in
        NSLog("Observed an event")
        // Do stuff here
    })
    	
    	machine.transitionFaults().observe(next: { transition in
        NSLog("Invalid event; no transition occurred")
        // Do other stuff here
    })

Transitions are defined as such:

    struct Transition<State, Event> {
        let fromState: State
        let toState: State?
        let event: Event
    }

Transitions are `Printable`, but will only display `Enum Value` for your states and events if they are not. To pretty print transitions, make your enums Printable, like so:

	enum TurnstileState: Printable {
		case Locked, Unlocked
		var description: String {
			get {
				switch self {
				case .Locked:
					return "Locked"
				case .Unlocked:
					return "Unlocked"
				}
			}
		}
	}
	
	enum TurnstileEvent: Printable {
		case Coin, Push
		var description: String {
			get {
				switch self {
				case .Coin:
					return "Coin"
				case .Push:
					return "Push"
				}
			}
		}
	}

	machine.allTransitions().observe(next: { t in
        NSLog("\(t)")
    })
    machine.inputEvent(.Coin)

will print:

    Transition: Locked -> Optional(Unlocked), Event: Coin

