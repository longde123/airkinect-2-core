package com.as3nui.nativeExtensions.air.kinect.constants
{
	/**
	 * Names of joints, which are available on both platform.
	 * 
	 * <p>You can use these names, together with the user class:<br /><br /><code>var leftHand:SkeletonJoint = user.getJointByName(JointNames.LEFT_HAND);</code></p>
	 * <p>A user can have more than these joints, depending on the platform. You can find all joints in the <code>user.skeletonJoints</code> vector.</p>
	 */ 
	public class JointNames
	{
		
		public static const HEAD:String = "head";
		public static const NECK:String = "neck";
		public static const TORSO:String = "torso";
		
		public static const LEFT_SHOULDER:String = "left_shoulder";
		public static const LEFT_ELBOW:String = "left_elbow";
		public static const LEFT_HAND:String = "left_hand";
		
		public static const RIGHT_SHOULDER:String = "right_shoulder";
		public static const RIGHT_ELBOW:String = "right_elbow";
		public static const RIGHT_HAND:String = "right_hand";
		
		public static const LEFT_HIP:String = "left_hip";
		public static const LEFT_KNEE:String = "left_knee";
		public static const LEFT_FOOT:String = "left_foot";
		
		public static const RIGHT_HIP:String = "right_hip";
		public static const RIGHT_KNEE:String = "right_knee";
		public static const RIGHT_FOOT:String = "right_foot";
	}
}