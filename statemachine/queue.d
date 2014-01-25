/**
 *  Queue Abstract Datatype.
 *  Manages primitive types, structs and instanses of classes using operations
 *  associated with queueus.
 *
 *  Created by Ulf Inoue on 2/8/11.
 *  Copyright 2011 HakkaBon. All rights reserved.
 */
module statemachine.queue;

/**
 * Implements a very simple LILO container.
 */
struct Queue(T) {
	
	// Internal representation of queue.
	private T[]	data;
	
	// References current header (first) element.
	private size_t head = 0;
	
	// References current tail (last) element.
	private size_t tail = 0;
	
	invariant() { 
		assert(head <= tail); 
	}
	
	/** 
	 * Creates one queue containiing given array of elements whose order is 
	 * maintained while inserted into the queue.
	 */
	this(T[] elements) {
		data.length = elements.length;
		foreach (e ; elements) {
			enqueue(e);
		}
	}
	
	/** Constructs one empty queue. */
	static Queue!(T) opCall(const size_t size = 16)
	in	{ assert(size > 0);	} 
	body {
		Queue!(T) queue;
		queue.data.length = size;
		return queue;
	}
	
	/** Returns true if queue is empty, otherwise false. */
	@property bool empty() { return tail-head == 0; }
	
	/** Returns length of queue. */
	@property size_t length() { return tail-head; }
	
	/** Returns first element in queue. */
	@property T first()
	in { assert(!empty); }
	body {
		return data[head];
	}
	
	/** Returns last element in queue. */
	@property T last()
	in { assert(!empty); }
	body {
		return data[tail-1];
	}
	
	/** 
	 *  Appends given element at end of queue.
	 * 	Length of queue grows by one element.
	 */
	void enqueue(T element)
	out	{ assert(tail < data.length); }
	body {
		auto tt = (tail+1) % data.length;
		if (tt > head) {	// free
			data[tail] = element;
			tail=tt;
		}
		else { // double it
			auto m = data.length;
			T[] newdata;
			newdata.length = m*2;
			for (size_t i=0; i<m-1; i++) {
				newdata[i] = data[(head+i)%m]; // copy entries
			}
			data = newdata;
			head = 0;
			tail = m-1;
			data[tail] = element;
			tail++;
		}
	}
	
	/**
	 * 	Removes frontmost element from queue.
	 *  Length of queue shrinks by one element.
	 */
	T dequeue()
	in { assert(!empty); }
	out	(result) { assert(head < data.length); }
	body {
		T tmp = data[head];
		head = (head+1)%data.length;
		return tmp;
	}
}

unittest
{
	import std.stdio;
	
//	auto queue = Queue!int([1,2,3,4]);
	auto queue = Queue!int();
	queue.enqueue(1);
	queue.enqueue(2);
	queue.enqueue(3);
	queue.enqueue(4);
	assert(queue.empty != true);
	assert(queue.empty == false);
	assert(queue.length == 4);		
	assert(queue.first() == 1);		
		
	auto element = queue.dequeue();
	assert(element == 1);
	assert(queue.length == 3);		
	assert(queue.first() == 2);		
	
	element = queue.dequeue();
	assert(element == 2);
	assert(queue.length == 2);		
	assert(queue.empty == false);		
	assert(queue.first() == 3);		
	
	element = queue.dequeue();
	assert(element == 3);
	assert(queue.length == 1);		
	assert(queue.empty == false);		
	assert(queue.first() == 4);		
	
	element = queue.dequeue();
	assert(element == 4);
	assert(queue.length == 0);		
	assert(queue.empty == true);
	
	queue.enqueue(876876);
	queue.enqueue(345);
	queue.enqueue(987345);
	queue.enqueue(789798798);
	queue.enqueue(43895797);
	queue.enqueue(3586736);
	queue.enqueue(2475892);
	queue.enqueue(-300);
	assert(queue.empty == false);
	assert(queue.length == 8);		
	assert(queue.first() == 876876);
}