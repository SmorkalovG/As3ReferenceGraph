/**
 * Created by g.smorkalov on 28.10.2014.
 */
package ru.crazypanda.tools  {
import avmplus.getQualifiedClassName;
import avmplus.getQualifiedClassName;

import flash.events.EventDispatcher;
import flash.sampler.getLexicalScopes;
import flash.sampler.getMemberNames;
import flash.sampler.getSavedThis;
import flash.sampler.getSavedThis;
import flash.system.System;
import flash.utils.Dictionary;
import flash.utils.describeType;
import flash.utils.getQualifiedClassName;

public class Grabber {
	public function Grabber() {

	}

	private var nodes:Dictionary = new Dictionary();
	private var queue:Vector.<RefGraphNode> = new Vector.<RefGraphNode>();

	private function addLink(name:String, member:Object, parent:RefGraphNode):RefGraphNode {
		if (member is Grabber) {
			throw null;
		}
		var newLink:RefLink = new RefLink(parent, name);
		if (!nodes[member]) {
			var newNode:RefGraphNode = new RefGraphNode(newLink, member);
			nodes[member] = newNode;
			queue.push(newNode);
		} else {
			var node:RefGraphNode = nodes[member];
			node.parents.push(newLink);
		}
		return nodes[member];
	}

	private function addAllRefsFrom(node:RefGraphNode):void {
		var o:Object = node.ref;
		
		var value:*;

		var members:Object = getMemberNames(o);
		for each (var m:QName in members) {
			try {
				value = o[m];
			} catch ( e:Error ) {
				continue;
			}

			if (value is Function) {
				processFunction(m.localName, value, node);
			} else {
				addLink(m.localName, value, node);
			}
		}

		for (var dynMem:String in o) {
			value = o[dynMem];

			if (value is Function) {
				processFunction(dynMem, value, node);
			} else {
				addLink(dynMem, value, node);
			}
		}
	}

	private function processFunction(funcName:String, func:Function, node:RefGraphNode):void {
		var savedThis:Object = getSavedThis(func);

		if (savedThis == node.ref) {
			return;
		}

		addLink("function." + funcName + ".savedThis", savedThis, node);

		var scopes:Array = getLexicalScopes(func);
		for each (var curScope:Object in scopes) {
			var scopeMembers:Object = getMemberNames(curScope);
			for each(var scopedName:QName in scopeMembers) {
				//if (scopedName.localName == 'myVar') {
				//	trace();
				//}
				
				try {
					addLink("function." + funcName + ".scope." + scopedName.localName, curScope[scopedName], node);
				} catch (e:Error) {}
			}
		}
	}

	public function getHash(obj:Object):String {
		try {
			System(obj);
		} catch (error:Error) {
			var str:String = error.message;
			var m:Array = str.match(/@([\da-f]+)/);
			if (m) return m[1];
		}

		return null;
	}

	public function createRefGraphFromRoots(root:Object):void {
		var rootNode:RefGraphNode = new RefGraphNode(null, root);
		nodes[root] = rootNode;
		queue.push(rootNode);
		while (queue.length) {
			addAllRefsFrom(queue.pop());
		}
		trace('scan done');
	}

	public function printGraph():void {
		for each (var node:RefGraphNode in nodes) {
			trace(node.id, getQualifiedClassName(node.ref), "[");
			for each (var link:RefLink in node.parents) {
				if (link) {
					trace(link.parent.id + "[\"" + link.memberName + "\"]");
				}
			}
			trace("]");
		}
	}

	private var waves:Vector.<Vector.<RefGraphNode>> = new Vector.<Vector.<RefGraphNode>>();
	private var passedNodes:Dictionary = new Dictionary();

	public function printTypePathsFor(object:Object, except:Object = null):void {
		if (!nodes[object]) {
			trace("target object is not reachable from given roots");
			return;
		}
		var curWave:Vector.<RefGraphNode> = new Vector.<RefGraphNode>();
		var nextWave:Vector.<RefGraphNode> = new Vector.<RefGraphNode>();
		curWave.length = 0;
		curWave.push(nodes[object]);
		waves.push(curWave);
		waves.push(nextWave);
		passedNodes[object] = object;
		passedNodes[nodes[except]] = nodes[except];

		var counter:int = 0;
		trace("!!!!!!!!!!!!!!!!!!!!!-----Wave", counter, "-----!!!!!!!!!!!!!!!!!!!!!!!");
		while (processWave(curWave, nextWave, except)) {
			counter++;
			trace("!!!!!!!!!!!!!!!!!!!!!-----Wave", counter, "-----!!!!!!!!!!!!!!!!!!!!!!!");
			curWave = nextWave;
			nextWave = new Vector.<RefGraphNode>();
			waves.push(nextWave);
		}

	}

	private function processWave(curWave:Vector.<RefGraphNode>, nextWave:Vector.<RefGraphNode>, except:Object):Boolean {
		var res:Boolean = false;
		var nodeIndex:int = 0;
		for each (var node:RefGraphNode in curWave) {
			for each (var link:RefLink in node.parents) {
				if (link) {
					var nextNode:RefGraphNode = link.parent;
					if (passedNodes[nextNode]) {
						continue;
					}

					trace(link.parent.id, getQualifiedClassName(link.parent.ref) + "[\"" + link.memberName + "\"] refers to", getQualifiedClassName(node.ref), node.id);

					passedNodes[nextNode] = nextNode;
					nextWave.push(nextNode);
					res = true;
				}
			}
			nodeIndex++;
		}
		return res;
	}
}
}

class RefLink {
	public var parent:RefGraphNode;
	public var memberName:String;

	public function RefLink(parent:RefGraphNode, member:String) {
		this.parent = parent;
		this.memberName = member;
	}
}

class RefGraphNode {
	private static var counter:int = 0;

	public var parents:Vector.<RefLink> = new Vector.<RefLink>();
	public var ref:Object;
	public var id:int;

	public function RefGraphNode(parent:RefLink, ref:Object) {
		this.parents[0] = parent;
		this.ref = ref;
		id = counter++;
	}
}

import flash.events.EventDispatcher;

class TestClass extends EventDispatcher{
	private var q:int;
	private var obj:Object = {"mem":"val"};
}
