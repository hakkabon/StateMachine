/**
 *  Hirachical State Machine Example.
 *
 *  Created by Ulf Inoue on 2/8/13.
 *  Copyright 2013 HakkaBon. All rights reserved.
 */
module main;

private import	statemachine.hsm, statemachine.queue;
private import	std.conv, std.stdio, std.random;


/**
 * Signal
 * Anything that can be converted into an interger type.
 */ 
enum DefinedSignal: int { A_SIG=0, B_SIG, C_SIG, D_SIG, E_SIG, F_SIG, G_SIG, H_SIG };

// create all state and determine its hierarchical structure
class S0: TopState
{
	mixin StateTypes!(TopState,S0);
	mixin Init;
	mixin Entry;
	mixin Exit;
	this()
	{
		add(new Transition!(S0,S211)(Trigger(DefinedSignal.E_SIG), Guard(&guard), { write("s0-E;"); }));
	}
	static void init() 	{ write("s0-INIT;"); }
	static void entry() { write("s0-ENTRY;"); }
 	static void exit() 	{ write("s0-EXIT;"); }
 	override bool guard() { return true; }
	override void action() {}
}

class S1: S0
{
	mixin StateTypes!(S0,S1);
	mixin Init;
	mixin Entry;
	mixin Exit;	
	this()
	{
		add(new Transition!(S1,S1)(Trigger(DefinedSignal.A_SIG), Guard(&guard), { write("s1-A;"); }));
		add(new Transition!(S1,S11)(Trigger(DefinedSignal.B_SIG), Guard(&guard), { write("s1-B;"); }));
		add(new Transition!(S1,S2)(Trigger(DefinedSignal.C_SIG), Guard(&guard), { write("s1-C;"); }));
		add(new Transition!(S1,S0)(Trigger(DefinedSignal.D_SIG), Guard(&guard), { write("s1-D;"); }));
		add(new Transition!(S1,S211)(Trigger(DefinedSignal.F_SIG), Guard(&guard), { write("s1-F;"); }));
	}
 	static void init() 	{ write("s1-INIT;"); }
	static void entry() { write("s1-ENTRY;"); }
	static void exit() 	{ write("s1-EXIT;"); }
	override bool guard() { return true; }
	override void action() {}
}
class S11: S1
{
	mixin StateTypes!(S1,S11);
	mixin Init;
	mixin Entry;
	mixin Exit;	
	this()
	{
		add(new Transition!(S11,S211)(Trigger(DefinedSignal.G_SIG), Guard(&guard), { write("s11-G;"); }));
		//new Transition!(S1,S11)( Trigger(DefinedSignal.H_SIG), Guard(&guard), &action )	
	}
	static void init() 	{ write("s11-INIT;"); }
	static void entry() { write("s11-ENTRY;"); }
	static void exit() 	{ write("s11-EXIT;"); }
 	override bool guard() { return true; }
	override void action() {}
}
class S2: S0
{
	mixin StateTypes!(S0,S2);
	mixin Init;
	mixin Entry;
	mixin Exit;	
	this()
	{
		add(new Transition!(S2,S1)(Trigger(DefinedSignal.C_SIG), Guard(&guard), { write("s2-C;"); }));
		add(new Transition!(S2,S11)(Trigger(DefinedSignal.F_SIG), Guard(&guard), { write("s2-F;"); }));
	}
 	static void init() { write("s2-INIT;"); }
	static void entry() { write("s2-ENTRY;"); }
	static void exit() { write("s2-EXIT;"); }
 	override bool guard() { return true; }
	override void action() {}
}
class S21: S2
{
	mixin StateTypes!(S2,S21);
	mixin Init;
	mixin Entry;
	mixin Exit;	
	this()
	{
		add(new Transition!(S21,S211)(Trigger(DefinedSignal.B_SIG), Guard(&guard), { write("s21-B;"); }));
		add(new Transition!(S21,S21)(Trigger(DefinedSignal.H_SIG), Guard(&guard), { write("s21-H;"); }));
	}
	static void init() { write("s21-INIT;"); }
	static void entry() { write("s21-ENTRY;"); }
	static void exit() { write("s21-EXIT;"); }
 	override bool guard() { return true; }
	override void action() {}
}
class S211: S21
{
	mixin StateTypes!(S21,S211);
	mixin Init;
	mixin Entry;
	mixin Exit;	
	this()
	{
		add( new Transition!(S211,S21)(Trigger(DefinedSignal.D_SIG), Guard(&guard), { write("s211-D;"); }));
		add( new Transition!(S211,S0)(Trigger(DefinedSignal.G_SIG), Guard(&guard), { write("s211-G;"); }));
	}
 	static void init() 	{ write("s211-INIT;"); }
	static void entry() { write("s211-ENTRY;"); }
	static void exit() 	{ write("s211-EXIT;"); }
 	override bool guard() { return true; }
	override void action() {}
}


void main() 
{
	writeln("Test start");
	
	// create Random number generator for teting purposes
	Random gen;
	
	// create a Hierarchical State Machine
	auto hsm = new StateMachine;
	
	// create all leaf states
	hsm.addState(new S11);
	hsm.addState(new S211);
	
	// let HSM know the initial (default/start/active) state
	// if not a leaf state, first leaf state found will be picked
	hsm.targetType = S11.classinfo;
	
	// enqueue new events 
	for (int i=0;i<100;i++)
	{
		hsm.enqueue(Event(cast(DefinedSignal)(uniform(0, 7,gen))));
	}
	// run state machine
	hsm.start();
		
	writeln("\nTest end");
}