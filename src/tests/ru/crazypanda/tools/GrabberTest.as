/**
 * Created by g.smorkalov on 05.11.2014.
 */
package ru.crazypanda.tools {
import org.flexunit.asserts.assertTrue;

public class GrabberTest {
	public function GrabberTest() {
	}

	[Test]
	public function testCreateRefGraphFromRoots():void {
		var root:Object = new Object();
		var o1:Object = new Object();
		var o2:Object = new Object();
		var o3:Object = new Object();

		o1["o2"] = o2;
		o2["o3"] = o3;
		o3["o1"] = o3;

		var grabber:Grabber = new Grabber();
		grabber.createRefGraphFromRoots(root);
		grabber.printTypePathsFor(o3);

		assertTrue(true);
	}
}
}
