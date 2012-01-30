package com.as3nui.nativeExtensions.air.kinect
{
	import com.as3nui.nativeExtensions.air.kinect.constants.KinectState;
	import com.as3nui.nativeExtensions.air.kinect.data.User;
	import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.KinectEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.PointCloudEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.UserEvent;
	import com.as3nui.nativeExtensions.air.kinect.generators.DepthGenerator;
	import com.as3nui.nativeExtensions.air.kinect.generators.InfraredGenerator;
	import com.as3nui.nativeExtensions.air.kinect.generators.PointCloudGenerator;
	import com.as3nui.nativeExtensions.air.kinect.generators.RGBGenerator;
	import com.as3nui.nativeExtensions.air.kinect.generators.UserGenerator;
	import com.as3nui.nativeExtensions.air.kinect.generators.UserMaskGenerator;
	
	import flash.desktop.NativeApplication;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.external.ExtensionContext;
	import flash.utils.Dictionary;
	
	[Event(name="started", type="com.as3nui.nativeExtensions.air.kinect.events.KinectEvent")]
	[Event(name="stopped", type="com.as3nui.nativeExtensions.air.kinect.events.KinectEvent")]
	[Event(name="depthImageUpdate", type="com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent")]
	[Event(name="rgbImageUpdate", type="com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent")]
	[Event(name="userMaskImageUpdate", type="com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent")]
	[Event(name="infraredImageUpdate", type="com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent")]
	[Event(name="usersAdded", type="com.as3nui.nativeExtensions.air.kinect.events.UserEvent")]
	[Event(name="usersRemoved", type="com.as3nui.nativeExtensions.air.kinect.events.UserEvent")]
	[Event(name="usersWithSkeletonAdded", type="com.as3nui.nativeExtensions.air.kinect.events.UserEvent")]
	[Event(name="usersWithSkeletonRemoved", type="com.as3nui.nativeExtensions.air.kinect.events.UserEvent")]
	[Event(name="usersUpdated", type="com.as3nui.nativeExtensions.air.kinect.events.UserEvent")]
	[Event(name="pointCloudUpdate", type="com.as3nui.nativeExtensions.air.kinect.events.PointCloudEvent")]
	/**
	 * The Kinect class allows you to access the Kinect hardware in your AIR applications.
	 * 
	 * <p>An instance of this class will give you access to the different video streams
	 * and skeleton information of a Kinect sensor.</p>
	 * 
	 * @example The following code checks if there is a kinect available, attaches listeners
	 * and starts the kinect device with the given configuration.
	 * <listing version="3.0">
	 * if(Kinect.isSupported())
	 * {
	 * 	var kinect:Kinect = Kinect.getKinect();
	 * 
	 * 	kinect.addEventListener(KinectEvent.STARTED, kinectStartedHandler);
	 * 	kinect.addEventListener(KinectEvent.STOPPED, kinectStoppedHandler);
	 * 
	 * 	var config:KinectConfig = new KinectConfig();
	 * 	config.skeletonEnabled = true;
	 * 	config.rgbEnabled = true;
	 * 
	 * 	kinect.start(config);
	 * }
	 * </listing>
	 */
	public class Kinect extends EventDispatcher
	{
		
		private static var kinectInstanceMap:Dictionary;
		
		private static var _sharedContext:ExtensionContext;
		
		private static function get sharedContext():ExtensionContext
		{
			if(_sharedContext == null)
			{
				_sharedContext = ExtensionContext.createExtensionContext("com.as3nui.nativeExtensions.air.kinect", "shared");
			}
			return _sharedContext;
		}
		
		/**
		 * Check if there is a Kinect device available for use
		 */ 
		public static function isSupported():Boolean
		{
			return (sharedContext.call("getDeviceCount") as uint > 0);
		}
		
		/**
		 * Get an instance of the Kinect class. You'll use this method to get
		 * instances of the class, instead of creating instances yourself.
		 */ 
		public static function getKinect():Kinect
		{
			var nr:uint = 0;
			var kinect:Kinect = null;
			if(kinectInstanceMap == null) kinectInstanceMap = new Dictionary();
			if(kinectInstanceMap[nr] == null)
			{
				kinectInstanceMap[nr] = new Kinect(new Enforcer(), nr);
			}
			return kinectInstanceMap[nr];
		}
		
		private var _nr:uint;

		/**
		 * Get the index / nr of the Kinect. Used for forward compatibility with multiple devices.
		 */ 
		public function get nr():uint
		{
			return _nr;
		}
		
		private var _state:String;
		
		/**
		 * Get the current state of the Kinect.
		 * 
		 * <p>Possible options are <code>KinectState.STARTED, KinectState.STOPPED, KinectState.STARTING</code>.</p>
		 * 
		 * @see com.as3nui.nativeExtensions.air.kinect.constants.KinectState
		 */ 
		public function get state():String
		{
			return _state;
		}
		
		/**
		 * Get a list of all users
		 */ 
		public function get users():Vector.<User>
		{
			return skeletonGenerator.users;
		}
		
		/**
		 * Get a list of the users with a tracked skeleton
		 */ 
		public function get usersWithSkeleton():Vector.<User>
		{
			return skeletonGenerator.usersWithSkeleton;
		}
		
		private var context:ExtensionContext;
		private var config:KinectConfig;
		
		private var skeletonGenerator:UserGenerator;
		private var depthGenerator:DepthGenerator;
		private var rgbGenerator:RGBGenerator;
		private var userMaskGenerator:UserMaskGenerator;
		private var infraredGenerator:InfraredGenerator;
		private var pointCloudGenerator:PointCloudGenerator;
		
		/**
		 * Private constructor of the Kinect class. Use Kinect.getKinect() instead of calling this method.
		 */ 
		public function Kinect(e:Enforcer, nr:uint)
		{
			if(e == null)
			{
				throw new Error("Do not create instances of the extension directly, use Kinect.getKinect() instead");
			}
			_nr = nr;
			_state = KinectState.STOPPED;
			//create the generators for rgb, depth & user information
			skeletonGenerator = new UserGenerator(nr);
			depthGenerator = new DepthGenerator(nr);
			rgbGenerator = new RGBGenerator(nr);
			userMaskGenerator = new UserMaskGenerator(nr);
			infraredGenerator = new InfraredGenerator(nr);
			pointCloudGenerator = new PointCloudGenerator(nr);
			//dispose the kinect on application exit
			NativeApplication.nativeApplication.addEventListener("exiting", exitingHandler, false, 0, true);
		}
		
		/**
		 * Starts the kinect sensor, with the given configuration.
		 * 
		 * @see com.as3nui.nativeExtensions.air.kinect.KinectConfig
		 */ 
		public function start(kinectConfig:KinectConfig):void
		{
			if(_state == KinectState.STOPPED)
			{
				_state = KinectState.STARTING;
				//create the extension context
				context = ExtensionContext.createExtensionContext("com.as3nui.nativeExtensions.air.kinect", null);
				config = kinectConfig;
				//add status listener to the context
				context.addEventListener(StatusEvent.STATUS, contextStatusHandler, false, 0, true);
				//add listeners to the generators
				depthGenerator.addEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, redispatchHandler, false, 0, true);
				rgbGenerator.addEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, redispatchHandler, false, 0, true);
				userMaskGenerator.addEventListener(CameraImageEvent.USER_MASK_IMAGE_UPDATE, redispatchHandler, false, 0, true);
				skeletonGenerator.addEventListener(UserEvent.USERS_ADDED, redispatchHandler, false, 0, true);
				skeletonGenerator.addEventListener(UserEvent.USERS_REMOVED, redispatchHandler, false, 0, true);
				skeletonGenerator.addEventListener(UserEvent.USERS_WITH_SKELETON_ADDED, redispatchHandler, false, 0, true);
				skeletonGenerator.addEventListener(UserEvent.USERS_WITH_SKELETON_REMOVED, redispatchHandler, false, 0, true);
				skeletonGenerator.addEventListener(UserEvent.USERS_UPDATED, redispatchHandler, false, 0, true);
				infraredGenerator.addEventListener(CameraImageEvent.INFRARED_IMAGE_UPDATE, redispatchHandler, false, 0, true);
				pointCloudGenerator.addEventListener(PointCloudEvent.POINT_CLOUD_UPDATE, redispatchHandler, false, 0, true);
				//start the generators
				skeletonGenerator.start(context, config);
				depthGenerator.start(context, config);
				rgbGenerator.start(context, config);
				userMaskGenerator.start(context, config);
				infraredGenerator.start(context, config);
				pointCloudGenerator.start(context, config);
				//start the context
				context.call("start", nr);
				//the started event will be dispatched from the context, as this can take a while
			}
		}
		
		private function contextStatusHandler(event:StatusEvent):void
		{
			//trace("[Kinect] contextStatusHandler", event.code, event.level);
			switch(event.code)
			{
				case "status":
					switch(event.level)
					{
						case "started":
							_state = KinectState.STARTED;
							dispatchEvent(new KinectEvent(KinectEvent.STARTED));
							break;
						case "stopped":
							_state = KinectState.STOPPED;
							dispatchEvent(new KinectEvent(KinectEvent.STOPPED));
							break;
					}
					break;
			}
		}
		
		private function redispatchHandler(event:Event):void
		{
			dispatchEvent(event.clone());
		}
		
		/**
		 * Stops the Kinect sensor.
		 */ 
		public function stop():void
		{
			if(_state == KinectState.STARTED || _state == KinectState.STARTING)
			{
				_state = KinectState.STOPPED;
				//remove the status listener
				context.removeEventListener(StatusEvent.STATUS, contextStatusHandler);
				//remove listeners from the generators
				depthGenerator.removeEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, redispatchHandler);
				rgbGenerator.removeEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, redispatchHandler);
				userMaskGenerator.removeEventListener(CameraImageEvent.USER_MASK_IMAGE_UPDATE, redispatchHandler);
				skeletonGenerator.removeEventListener(UserEvent.USERS_ADDED, redispatchHandler);
				skeletonGenerator.removeEventListener(UserEvent.USERS_REMOVED, redispatchHandler);
				skeletonGenerator.removeEventListener(UserEvent.USERS_WITH_SKELETON_ADDED, redispatchHandler);
				skeletonGenerator.removeEventListener(UserEvent.USERS_WITH_SKELETON_REMOVED, redispatchHandler);
				skeletonGenerator.removeEventListener(UserEvent.USERS_UPDATED, redispatchHandler);
				infraredGenerator.removeEventListener(CameraImageEvent.INFRARED_IMAGE_UPDATE, redispatchHandler);
				pointCloudGenerator.removeEventListener(PointCloudEvent.POINT_CLOUD_UPDATE, redispatchHandler);
				//stop the generators
				skeletonGenerator.stop();
				depthGenerator.stop();
				rgbGenerator.stop();
				userMaskGenerator.stop();
				infraredGenerator.stop();
				pointCloudGenerator.stop();
				//stop the context
				context.call("stop", nr);
				//remove the context
				context = null;
				//dispatch the stopped event
				dispatchEvent(new KinectEvent(KinectEvent.STOPPED));
			}
		}
		
		/**
		 * Cleanup the Kinect instance.
		 */ 
		public function dispose():void
		{
			stop();
			delete kinectInstanceMap[_nr];
		}
		
		private function exitingHandler(event:Event):void
		{
			dispose();
			sharedContext.call("applicationShutdown");
		}
	}
}
internal class Enforcer{};