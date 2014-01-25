/**
 *  Hirachical State Machine.
 *  Implements a restricted subset of UML statecharts. Advanced features like
 *  concurrent states, history and pseudo-states are presently not included.
 *
 *  Created by Ulf Inoue on 2/8/13.
 *  Copyright 2013 HakkaBon. All rights reserved.
 */
module statemachine.hsm;
private import	statemachine.rtti, statemachine.queue;
private import	core.thread,
				std.container,
				std.conv,
				std.range,
				std.stdio,
				std.traits,
				std.typetuple;

/**
 * Hierarchical State Machine
 * Simple Hierarchical State Machine modeled after UML.
 * Currently supported features:
 * • supports definition of transitions with triggers, guards, actions
 * • init/entry/exit specification of actions
 * • definition of HSM is quite declarative, should be intuitive to UML users
 * Not supported features:
 * • concurrent states
 * • shallow/deep history
 */ 
class StateMachine
{	
	this()
	{
		eventDispatcher = new Thread( &dispatch );
		events = Queue!Event();
	}
	//! Set target State type of transition.
	//! Initially this means setting the default State type, before the HSM starts
	//! executing. Initially setting a non-leaf target type is nonsense.
	@property void targetType(ClassInfo type) 
	in
	{
		assert(!list.empty());
	}
	body
	{ 
		bool reactivate = false;
		foreach (s ; list)
		{	
			// get all base classes for class, reverse order		
			auto types = baseclasses_r(typeid(s));
			
			// find this type in class hierarchy of target
			int k = indexOf(type,types);

			// is type is equal or supertype of s?
			if (k>-1) 
			{								// yes, type is equal or supertype of s
				if (a_state !is s)			// is it a NEW active state?
				{							// reactivate iff modified state
					a_state = s;			// NEW active state == leaf state
 					reactivate = true;		// do reactivate
				}
				if (k+1 == walkLength(types[]))	// is type a leaf type?
				{							// yes, target type == typeof(state)
					break;					// all done!
				}
				// otherwise find resting classes all down to the leaf
				types.removeFront(k+1);
				foreach (ci; types)
					{	
						// do entry/init action in leaf state due to lost type info here
						a_state.doEntry(ci);
						a_state.doInit(ci);
					}
				break;
			}
		}
	}

	//! Returns active State object.
	@property TopState activeState() { return a_state; }

	//! Returns target type of last successful transition.
	@property ClassInfo targetType() { return a_type; }

	//! Starts event dispatcher thread
 	void start()
	{
		eventDispatcher.start();
	}
	
 	//! Suspends the calling thread for at least the supplied period. This 
	//! may result in multiple OS calls if period is greater than the maximum 
	//! sleep duration supported by the operating system.
	void sleep(Duration duration)
	{
		eventDispatcher.sleep(duration);
	}
	
	//! Enequeues new events.
 	void enqueue(Event event)
 	{
		events.enqueue(event);
 	}
	
	//! Dispatches events as long as there are any in the queue.
 	private void dispatch()
 	{
		while (!events.empty)
		{
		 	doDispatch(events.dequeue.signal);
		}
 	}
	
	//! Dispatches given signal.
	void doDispatch(Signal sig)				
	{ 
		foreach (t ; a_state.trans)
		{
			if (t.trigger.signal == sig)
			{
				if (t.guard.evaluate())
				{	
				 	write("\ndispatching signal:", sig, " ");
					t.sm = this;
					t.preaction();
					t.action();
					t.postaction();
					break;	// skip others in super classes
				}
			} // no break - try others in super classes???
		}
	}	
	
	//! Adds leaf states to the HSM. This defines the HSM execution model.
	void addState(TopState state)
	{
		list.insert(state);
	}				

	//! Currently active state of the HSM 
	private TopState a_state;		

	//! Current target type or default target type of the HSM
	//! not necessarily the same as the active state 
	private ClassInfo a_type;

	//! List of leaf classes of the HSM
	private Queue!(Event) events;

	//! event dispatch thread
	private Thread eventDispatcher;
	
	//! List of leaf classes of the HSM
	private SList!(TopState) list;
}

/**
 * Technical construct. A base class for Transition is needed in order to be 
 * able to put Transition objects into a container.
 */
class TransitionBase
{
	StateMachine sm;
	Trigger trigger;
	Guard guard;
	void delegate() action;		

	this(Trigger trigger, Guard guard, void delegate() action)
	{
		this.trigger = trigger;
		this.guard = guard;
		this.action = action;
	}
	abstract void preaction();
	abstract void postaction();
}

/**
 * Executes transition from source to target state.
 * There is always an active state defined, not necessarily
 * the same as the active type, because an active state is per definition
 * a leaf state. An active type may be a super type of the leaf state.
 */
class Transition(S:TopState, T:TopState) : TransitionBase
{
	//! index of common ancestor of active and target classes
	//! in class hierarchy list of target class
	private int index;
		
	//! Transition constructor taking a trigger, guard and an
	//! action as its arguments.
	this(Trigger trigger, Guard guard, void delegate() action)
	{
		super(trigger,guard,action);
	}
		
	//! Executes first half of a transaction
	override void preaction() 
	{		
		// get current (active) leaf class instance 
		auto leaf = sm.activeState();
		
		// get all base classes of leaf class instance 
		auto a_types = baseclasses(typeid(leaf));

		// get all base classes for target class, reverse order		
		auto t_types = baseclasses_r(typeid(T));

		// find this source type in class hierarchy of target
		int k = indexOf(typeid(S),t_types);

		// iterate from A to AnT | S iff S < AnT 
		foreach (c ; a_types)
		{
			// do exit action in leaf state due to lost type info here
			leaf.doExit(c);

			// find this type (active type) in class hierarchy of target 
			index = indexOf(c,t_types);
			
			// type information starts overlapping here
			if (index>-1) 
			{
				// is source class a super state of current active class
				if ((k>0) && (k>index)) 
					index = k; // 
				else 
					break;
			}
		}
	}
	
	//! Executes last half of a transaction
	override void postaction() 
	{
		// get class hierarchy for target class, reverse type order	
		// same list is needed because of index
		alias Erase!(Object, Reverse!(T, BaseClassesTuple!(T))) t_types;

		// iterate from AnT | S iff S < AnT to T
		foreach (i,s; t_types)
			if (i>=index) 	// avoid active/source class common ancestors
			{
				s.entry(); 	// do entry action in state
				s.init();
			}
		// new target type
		sm.targetType = T.classinfo;
	}
}

/**
 * Guards a transition from source to target state.
 * It is essentially an expression that evauates to true or false.
 */
struct Guard 
{
	bool delegate() guard;	
	bool evaluate()	{ return guard(); }
	this(bool delegate() guard)
	{
		this.guard = guard;		
	}
	~this()	{}
}

/**
 * Event
 * Anything that can be converted into an interger type.
 */ 
alias int Signal;
struct Event
{
	@property Signal signal() { return sig; }
	this(Signal signal) 
	{		
		sig = signal;
	}
	~this()	{}
	private Signal sig;
}

/**
 * Defines a trigger that makes a transition start executing.
 * It is essentially encapsulates the signals understood by the HSM.
 */
struct Trigger
{
	@property Signal signal() { return sig; }
	this(Signal signal) 
	{		
		sig = signal;
	}
	~this()	{}
	private Signal sig;
}

/**
 * Provides types definitions for a State class as mixin construct.
 * Defines both this and its base class as type aliases.
 */
template StateTypes(B,T)
{
	alias B BaseType;
	alias T Type;	
}

/**
 * Provides init method for a State class as mixin construct.
 * This will be deprecated when RTTI info of an object can be retrieved with
 * typeof().
 */
template Init()
{
	override void doInit(ClassInfo ci) 
	{ 
		if (ci !is typeid(Type)) super.doInit(ci);
		else init();
		return;
	}	
}

/**
 * Provides entry method for a State class as mixin construct.
 * This will be deprecated when RTTI info of an object can be retrieved with
 * typeof().
 */
template Entry()
{
	override void doEntry(ClassInfo ci) 
	{ 
		if (ci !is typeid(Type)) super.doEntry(ci);
		else entry();
		return;
	}	
}

/**
 * Provides exit method for a State class as mixin construct.
 * This will be deprecated when RTTI info of an object can be retrieved with
 * typeof().
 */
template Exit()
{
	override void doExit(ClassInfo ci) 
	{
		if (ci !is typeid(Type)) super.doExit(ci);
		else exit();
		return;
	}
}

/**
 * Base class of all user-defined states.
 * All user-defined states have to be derived from TopState. 
 */
abstract class TopState
{
	mixin StateTypes!(void,TopState);
	static void init() 			{ write("INIT-ERROR;"); }
   	static void entry() 		{ write("ENTRY-ERROR;"); }
 	static void exit() 			{ write("EXIT-ERROR;"); }
	void doInit(ClassInfo ci) 	{ }
	void doEntry(ClassInfo ci) 	{ }
	void doExit(ClassInfo ci) 	{ }
 	bool guard() 				{ return true; }
	void action() 				{}
 	void add(TransitionBase tb) 
	{ 
	    trans.length = trans.length + 1;
	    trans[trans.length - 1] = tb;
	}		
	TransitionBase[] trans;
}

unittest 
{
}