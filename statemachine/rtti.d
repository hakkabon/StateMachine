/**
 *  Run Time Type info.
 *
 *  Created by Ulf Inoue on 2/8/11.
 *  Copyright 2011 HakkaBon. All rights reserved.
 */
module statemachine.rtti;
private import 	std.container, std.stdio,
				std.conv,
				std.traits,
				std.typetuple;

/**
 * Returns true if both types have a common base class not equal to Object.
 */ 
bool isRelated(T)(ClassInfo t)
in
{
	assert(t !is null);	
}
body
{
	ClassInfo c = typeid(T);
	while(c !is Object.classinfo)
	{	
		auto ci = t;
		while(ci !is Object.classinfo)
		{
			if (c == ci) return true;
			ci = ci.base;
		}
		c = c.base;
	}
	return false;
}

/**
 * Returns true if T is a subclass of t
 */ 
bool isSubclass(T)(ClassInfo t)
in
{
	assert(t !is null);	
}
body
{
	ClassInfo c = typeid(T);
	while(c !is Object.classinfo)
	{
		if (c == t) return true;
		c = c.base;
	}
	return false;
}

/**
 * Returns a range of baseclasses of T between T and t. 
 * If t is not a baseclass of T, all baseclasses are included except Object.
 * Most general class in front.
 */ 
SList!(ClassInfo) TBaseclasses_r(T)(ClassInfo t)
in
{
	assert(t !is null);	
}
body
{
	SList!(ClassInfo) list;
	ClassInfo c = typeid(T);
	while(c !is Object.classinfo)
	{
		list.insert(c);
		if (c == t) return list;
		c = c.base;
	}
	return list;
}	

/**
 * Returns a range of baseclasses of T between T and t. 
 * If t is not a baseclass of T, all baseclasses are included except Object.
 * Most derived class in front.
 */ 
ClassInfo[] TBaseclasses(T)(ClassInfo t)
in
{
	assert(t !is null);	
}
body
{
	ClassInfo[] a;
	ClassInfo c = typeid(T);
	while(c !is Object.classinfo)
	{
	    a.length = a.length + 1;
	    a[a.length - 1] = c;			
		if (c == t) return a;
		c = c.base;
	}
	return a;
}	

/**
 * Returns true if T is a superclass of t
 */ 
bool TSuperclass(T)(ClassInfo t)
in
{
	assert(t !is null);	
}
body
{
	ClassInfo c = typeid(T);
	while(t !is Object.classinfo)
	{
		if (c == t) return true;
		t = t.base;
	}
	return false;
}

/**
 * Returns all baseclasses of T between T and Object, not including Object.
 * Most general class in front.
 */ 
SList!(ClassInfo) baseclasses_r(ClassInfo t)
in
{
	assert(t !is null);	
}
body
{
	SList!(ClassInfo) list;
	while(t !is Object.classinfo)
	{
		if (t == Object.classinfo) return list;
		list.insert(t);
		t = t.base;
	}
	return list;
}	

/**
 * Returns a range of baseclasses of t1 between t1 and t2. 
 * If t2 is not a baseclass of t1, all baseclasses are included except Object.
 * Most general class in front.
 */ 
SList!(ClassInfo) baseclasses_r(ClassInfo t1, ClassInfo t2)
in
{
	assert((t1 !is null)&&(t2 !is null));
}
body
{
	SList!(ClassInfo) list;
	ClassInfo c = t1;
	while(c !is Object.classinfo)
	{
		list.insert(c);
		if (c == t2) return list;
		c = c.base;
	}
	return list;
}	

/**
 * Returns all baseclasses of T between T and Object, not including Object.
 * Most derived class in front.
 */ 
ClassInfo[] baseclasses(ClassInfo t)
in
{
	assert(t !is null);	
}
body
{
	ClassInfo[] a;
	while(t !is Object.classinfo)
	{
	    a.length = a.length + 1;
	    a[a.length - 1] = t;			
		if (t == Object.classinfo) return a;
		t = t.base;
	}
	return a;
}	

/**
 * Returns a range of baseclasses of t1 between t1 and t2. 
 * If t2 is not a baseclass of t1, all baseclasses are included except Object.
 * Most derived class in front.
 */ 
ClassInfo[] baseclasses(ClassInfo t1, ClassInfo t2)
in
{
	assert((t1 !is null)&&(t2 !is null));
}
body
{
	ClassInfo[] a;
	ClassInfo c = t1;
	while(c !is Object.classinfo)
	{
	    a.length = a.length + 1;
	    a[a.length - 1] = c;			
		if (c == t2) return a;
		c = c.base;
	}
	return a;
}	
	
/**
 * Returns index of class c in types. First index is 0.
 * If c is not found -1 is returned.
 */ 
static int indexOf(ClassInfo c, SList!(ClassInfo) types)
{
	int i;
	foreach(ci;types)
	{
		if (c == ci) return i;
		i++;
	}
	return -1;
}

/**
 * Returns index of class c in types. First index is 0.
 * If c is not found -1 is returned.
 */ 
static auto indexOf(ClassInfo c, ClassInfo[] types)
{
	foreach(i,ci;types)
	{
		if (c == ci) return i;
	}
	return -1;
}

unittest
{
	class A {}
	class B {}
	class C: A {}
	class D: B {}
	class E: C {}
	class F: E {}

	auto a = new A;
	auto e = new E;
	auto f = new F;
	
	writeln(isRelated!(A)(typeid(C)));
	writeln(isRelated!(C)(typeid(A)));
	writeln(isSubclass!(A)(typeid(A)));
	writeln(isSubclass!(E)(typeid(C)));
	writeln(isSubclass!(A)(typeid(C)));
	writeln(isSubclass!(C)(typeid(A)));
	writeln(isSubclass!(C)(typeid(C)));
	writeln();
	{
		auto list = TBaseclasses_r!(F)(typeid(A));
		foreach (ci ; list)
			write(ci," ");
		writeln();
	}
	{
		auto list = TBaseclasses!(F)(typeid(A));
		foreach (ci ; list)
			write(ci," ");
		writeln();
	}
	{
		auto list = TBaseclasses!(F)(typeid(B));
		foreach (ci ; list)
			write(ci," ");
		writeln();
	}
	{
		auto list = TBaseclasses!(F)(typeid(C));
		foreach (ci ; list)
			write(ci," ");
		writeln();
	}
	{
		auto list = baseclasses(typeid(F));
		foreach (ci ; list)
			write(ci," ");
		writeln();
	}
	{
		auto list = baseclasses_r(typeid(F));
		foreach (ci ; list)
			write(ci," ");
		writeln();
	}
}
