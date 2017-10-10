using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;
using UnityEngine;
using SpilGames.Unity.Utils;
using System.Collections;
using SpilGames.Unity.Helpers;
using Newtonsoft.Json;
using System.Runtime.Serialization.Formatters;

namespace SpilGames.Unity.Implementations
{
	#if UNITY_IPHONE || UNITY_TVOS
	public class SpiliOSUnityImplementation : SpilUnityImplementationBase
	{
        protected bool disableAutomaticRegisterForPushNotifications = false;

		#region Inherited members

		public override void SetPluginInformation (string PluginName, string PluginVersion)
		{
			setPluginInformationNative(PluginName, PluginVersion);
		}

		[DllImport("__Internal")]
		private static extern void setPluginInformationNative(string pluginName, string pluginVersion);

		#region Game config

		/// <summary>
		/// Returns the game config as a json string.
		/// This is not essential for developers so could be made private (getConfig<T>() uses it so it cannot be removed entirely) but might be handy for some developers so we left it in.
		/// </summary>
		/// <returns></returns>
		public override string GetConfigAll()
		{
			return getConfigNative();
		}

		/// <summary>
		/// Method that returns a configuration value from the game config based on key 
		/// </summary>
		/// <param name="key"></param>
		/// <returns></returns>
		public override string GetConfigValue(string key)
		{
			return getConfigValueNative(key);
		}

		#endregion

		#region Packages and promotions

		/// <summary>
		/// Method that requests packages and promotions from the server.
		/// This is called automatically by the Spil SDK when the game starts.
		/// This is not essential so could be removed but might be handy for some developers so we left it in.
		/// </summary>
		public override void UpdatePackagesAndPromotions()
		{
			requestPackagesNative();
		}

		// Method that returns the all packages
		protected override string GetAllPackages()
		{
			return getAllPackagesNative();
		}

		// Method that returns a package based on key
		protected override string GetPackage(string key)
		{
			return getPackageNative(key);
		}

		/// <summary>
		/// This method is marked as internal and should not be exposed to developers.
		/// The Spil Unity SDK is not packaged as a seperate assembly yet so this method is currently visible, this will be fixed in the future.
		/// Internal method names start with a lower case so you can easily recognise and avoid them.
		/// </summary>
		internal override string getPromotion(string key)
		{
			return getPromotionNative(key);
		}

		[DllImport("__Internal")]
		private static extern void requestPackagesNative();

		[DllImport("__Internal")]
		private static extern string getAllPackagesNative();

		[DllImport("__Internal")]
		private static extern string getPackageNative(string keyName);

		[DllImport("__Internal")]
		private static extern string getPromotionNative(string keyName);

		#endregion

		/// <summary>
		/// This method is marked as internal and should not be exposed to developers.
		/// The Spil Unity SDK is not packaged as a seperate assembly yet so this method is currently visible, this will be fixed in the future.
		/// Internal method names start with a lower case so you can easily recognise and avoid them.
		/// </summary>
		internal override void SpilInit()
		{
			JSONObject options = new JSONObject();
			options.AddField ("isUnity",true);
			initEventTrackerWithOptions(options.ToString());
			applicationDidBecomeActive();

            if (disableAutomaticRegisterForPushNotifications == false) 
			{
                RegisterForPushNotifications ();
				CheckForRemoteNotifications();
			}
		}

		/// <summary>
		/// Sends an event to the native Spil SDK which will send a request to the back-end.
		/// Custom events may be tracked as follows:
		/// To track an simple custom event, simply call Spil.Instance.SendCustomEvent(String eventName); from anywhere in your code.
		/// To pass more information with the event create a &lt;String, String&gt; Dictionary and pass that as the second parameter like so:
		/// Dictionary&lt;String, String&gt; eventParams = new Dictionary&lt;String,String&gt;();
		/// eventParams.Add(“level”,levelName);
		/// Spil.Instance.SendCustomEvent(“PlayerDeath”, eventParams);
		/// See https://github.com/spilgames/spil_event_unity_plugin for more information on events.
		/// This method was previously called "TrackEvent".
		/// </summary>
		/// <param name="eventName"></param>
		/// <param name="dict"></param>
		public override void SendCustomEvent(string eventName, Dictionary<string, object> dict)
		{
			if (dict != null)
			{
				// Create a new dict json string
				string jsonString = "{";

				// Add each passed kv to the json dict
				foreach (var item in dict) {
					string key = item.Key;
					object value = item.Value;
					jsonString += "\"" + key + "\":";

					// Detect the value type
					if (value != null) {
						if (value is String) {
							// Determine if there is nested json included in the json, in that case reformat it
							try {
								string jsonInputString = ((string)item.Value).Replace ("\\\"", "\"").Trim (new char[]{ '\"' });
								JSONObject inputJsonObject = new JSONObject (jsonInputString);
								if (inputJsonObject.IsArray || inputJsonObject.IsObject) {
									jsonString += jsonInputString;
								} else {
									jsonString += "\"" + value + "\"";
								}
							} catch (Exception e) {
								Debug.Log ("---JSON DETECTION FAILED" + e.Message);
								jsonString += "\"" + value + "\"";
							}
						} else if (value is bool) {
							// Value is a bool, add it without quotes
							jsonString += (bool)value ? "true" : "false";
						} else if (value is int || value is float || value is double || value is long) {
							// Value is a number, add it without quotes
							jsonString += value.ToString ();
						} else if (value is JSONObject) {
							jsonString += ((JSONObject)value).Print();
						} else {
							try {
								jsonString += JsonHelper.getJSONFromObject(value);
							} catch (Exception) {
								// Value is unknown or not supported
								jsonString += "\"INVALID PARAMETER TYPE\"";
								Debug.LogError ("---INVALID JSON FOR KEY: " + key + ", expected type: string, bool, int, float, double, long");
							}
						}
					} else {
						// Value is empty
						jsonString += "\"\"";
					}

					jsonString += ",";
				}

				// Close the json dict
				if (jsonString.EndsWith(",")){
					jsonString = jsonString.Substring(0, jsonString.Length - 1);
				}
				jsonString += "}";

				Debug.Log ("---JSON BUILDED:" + jsonString);

				if (jsonString != "{}") {
					trackEventWithParamsNative (eventName, jsonString);
				} else {
					trackEventNative(eventName);
				}
			} else {
				trackEventNative(eventName);
			}
		}

		/// <summary>
		/// This can be called to show a video, for instance after calling "SendrequestRewardVideoEvent()"
		/// and receiving an "AdAvailable" event the developer could call this method from the event handler.
		/// When calling this method "SendrequestRewardVideoEvent()" must first have been called to request and cache a video.
		/// If no video is available then nothing will happen.
		/// </summary>
		public override void PlayVideo()
		{
			playRewardVideoNative();
		}

		[DllImport("__Internal")]
		private static extern void playRewardVideoNative();

		/// <summary>
		/// When Fyber has shown a reward video and the user goes back to the game to receive his/her reward Fyber can
		/// automatically show a toast message with information about the reward, for instance "You've received 50 coins". 
		/// This is disabled by default to allow the developer to create a reward notification for the user.
		/// Developers can call SetShowToastOnVideoReward(true) to enable Fyber's automatic toast message.
		/// </summary>
		public override void SetShowToastOnVideoReward(bool value)
		{
			showToastOnVideoReward(value);
		}

		[DllImport("__Internal")]
		private static extern void showToastOnVideoReward(bool show);		

		/// <summary>
		/// Call to inform the SDK that the parental gate was (not) passes
		/// </summary>
		public override void ClosedParentalGate(bool pass)
		{
			closedParentalGateNative (pass);
		}

		[DllImport("__Internal")]
		private static extern void closedParentalGateNative(bool pass);

		/// <summary>
		/// This can be called to show the "more apps" activity, for instance after calling "RequestMoreApps()"
		/// and receiving an "AdAvailable" event the developer could call this method from the event handler.
		/// When calling this method "RequestMoreApps()" must first have been called to request and cache a video.
		/// If no video is available then nothing will happen.
		/// </summary>
		public override void PlayMoreApps()
		{
			showMoreAppsNative();
		}

		/// <summary>
		/// Method that initiaties a Test Ad.
		/// This is not essential for developers so could be hidden but it might be handy for some developers so we left it in.
		/// </summary>
		/// <param name="adUnitId"></param>
		public override void TestRequestAd(string providerName, string adType, bool parentalGate)
		{
			devRequestAdNative(providerName, adType, parentalGate);
		}

		[DllImport("__Internal")]
		private static extern void showMoreAppsNative();

		/// <summary>
		/// Sends the "requestAd" event with the "moreApps" parameter to the native Spil SDK which will send a request to the back-end.
		/// When a response has been received from the back-end the SDK will fire either an "AdAvailable" or and "AdNotAvailable"
		/// event to which the developer can subscribe and for instance call PlayVideo(); or PlayMoreApps();
		/// </summary>
		public override void RequestMoreApps()
		{
			devRequestAdNative("Chartboost", "moreApps", false);
		}

		[DllImport("__Internal")]
		private static extern void devRequestAdNative(string providerName, string adTypeName, bool parentalGate);

		/// <summary>
		/// Retrieves the Spil User Id so that developers can show this in-game for users.
		/// If users contact Spil customer service they can supply this Id so that 
		/// customer support can help them properly. Please make this Id available for users
		/// in one of your game's screens.
		/// </summary>
		public override string GetSpilUserId()
		{
			return getSpilUserIdNative();
		}

		[DllImport("__Internal")]
		private static extern string getSpilUserIdNative();

		/// <summary>
		/// Retrieves the custom User Id
		/// </summary>
		public override string GetUserId()
		{
			return getUserIdNative();
		}

		[DllImport("__Internal")]
		private static extern string getUserIdNative();

		/// <summary>
		/// Sets the custom User Id for a provider
		/// </summary>
		/// <param name="providerId"></param>
		/// <param name="userId"></param>
		public override void SetUserId(string providerId, string userId)
		{
			setUserIdNative(providerId, userId);
		}

		public override void SetCustomBundleId (string bundleId) {
			setCustomBundleIdNative (bundleId);
		}

		[DllImport("__Internal")]
		private static extern void setCustomBundleIdNative(string bundleId);

		[DllImport("__Internal")]
		private static extern void setUserIdNative(string providerId, string userId);

		/// <summary>
		/// Gets the user provider.
		/// </summary>
		/// <returns>The user provider native.</returns>
		public override string GetUserProvider() {
			return getUserProviderNative ();
		}

		[DllImport("__Internal")]
		private static extern string getUserProviderNative();

		/// <summary>
		/// Sets the state of the private game.
		/// </summary>
		/// <param name="privateData">Private data.</param>
		public override void SetPrivateGameState(string privateData) {
			setPrivateGameStateNative (privateData);
		}

		[DllImport("__Internal")]
		private static extern void setPrivateGameStateNative(string privateData);

		/// <summary>
		/// Gets the state of the private game.
		/// </summary>
		/// <returns>The private game state.</returns>
		public override string GetPrivateGameState() {
			return getPrivateGameStateNative();
		}

		[DllImport("__Internal")]
		private static extern string getPrivateGameStateNative();

		/// <summary>
		/// Sets the public game state.
		/// </summary>
		/// <param name="publicData">Public data.</param>
		public override void SetPublicGameState(string publicData) {
			setPublicGameStateNative(publicData);
		}

		[DllImport("__Internal")]
		private static extern void setPublicGameStateNative(string publicData);

		/// <summary>
		/// Gets the public game state.
		/// </summary>
		/// <returns>The public game state.</returns>
		public override string GetPublicGameState() {
			return getPublicGameStateNative();
		}

		[DllImport("__Internal")]
		private static extern string getPublicGameStateNative();

		/// <summary>
		/// Gets the public game state of other users.
		/// </summary>
		/// <param name="provider">Provider.</param>
		/// <param name="userIdsJsonArray">User identifiers json array.</param>
		public override void GetOtherUsersGameState(string provider, string userIdsJsonArray) {
			getOtherUsersGameStateNative(provider, userIdsJsonArray);
		}

		[DllImport("__Internal")]
		private static extern void getOtherUsersGameStateNative(string provider, string userIdsJsonArray);

		#region Spil Game Objects

		public override string GetSpilGameDataFromSdk ()
		{
			return getSpilGameDataNative();
		}

		[DllImport("__Internal")]
		private static extern string getSpilGameDataNative();

		#endregion

		#region Player Data

		public override void UpdatePlayerData ()
		{
			updatePlayerDataNative ();
		}

		[DllImport("__Internal")]
		private static extern void updatePlayerDataNative();

		public override string GetWalletFromSdk()
		{
			return getWalletNative();
		}

		[DllImport("__Internal")]
		private static extern string getWalletNative();

		public override string GetInvetoryFromSdk()
		{
			return getInventoryNative();
		}

		[DllImport("__Internal")]
		private static extern string getInventoryNative();

		public override void AddCurrencyToWallet (int currencyId, int amount, string reason)
		{
			addCurrencyToWalletNative(currencyId, amount, reason);
		}

		[DllImport("__Internal")]
		private static extern void addCurrencyToWalletNative(int currencyId, int amount, string reason);

		public override void SubtractCurrencyFromWallet (int currencyId, int amount, string reason)
		{
			subtractCurrencyFromWalletNative(currencyId, amount, reason);
		}

		[DllImport("__Internal")]
		private static extern void subtractCurrencyFromWalletNative(int currencyId, int amount, string reason);

		public override void AddItemToInventory (int itemId, int amount, string reason)
		{
			addItemToInventoryNative(itemId, amount, reason);
		}

		[DllImport("__Internal")]
		private static extern void addItemToInventoryNative (int itemId, int amount, string reason);

		public override void SubtractItemFromInventory (int itemId, int amount, string reason)
		{
			subtractItemFromInventoryNative(itemId, amount, reason);
		}

		[DllImport("__Internal")]
		private static extern void subtractItemFromInventoryNative (int itemId, int amount, string reason);

	
		public override void BuyBundle (int bundleId, string reason)
		{
			// Possibly only needed on tvOS. So if this doesn't work on iOS. Use buyBundleNative instead. Also see below.
	#if UNITY_IPHONE
			consumeBundleNative(bundleId, reason);
	#endif
		}

//		[DllImport("__Internal")]
	#if UNITY_IPHONE
		private static extern void consumeBundleNative (int bundleId, string reason);
	#endif
		
		#endregion

		#endregion



		#region Non inherited members (iOS only members)

		#region Game config

		[DllImport("__Internal")]
		private static extern string getConfigNative();

		[DllImport("__Internal")]
		private static extern string getConfigValueNative(string keyName);

		#endregion

        #region Customer support

        public override void ShowHelpCenter() {
            showHelpCenterNative();
        }

        [DllImport("__Internal")]
        private static extern void showHelpCenterNative();

        public override void ShowContactCenter() {
            showContactCenterNative();
        }

        [DllImport("__Internal")]
        private static extern void showContactCenterNative();

        public override void ShowHelpCenterWebview()
        {
            showHelpCenterWebviewNative();
        }

        [DllImport("__Internal")]
        private static extern void showHelpCenterWebviewNative();

        #endregion

	#region Web

        public override void RequestDailyBonus ()
		{
			requestDailyBonusNative ();
		}

		[DllImport("__Internal")]
		private static extern void requestDailyBonusNative();

		public override void RequestSplashScreen ()
		{
			requestSplashScreenNative ();
		}

		[DllImport("__Internal")]
		private static extern void requestSplashScreenNative();

	#endregion

		#region Push notifications

        /// <summary>
        /// Disables the automatic register for push notifications.
        /// Should be called before SpilInit!
        /// </summary>
        public void DisableAutomaticRegisterForPushNotifications()
        {
            disableAutomaticRegisterForPushNotifications = true;
            disableAutomaticRegisterForPushNotificationsNative();
        }

        [DllImport("__Internal")]
        private static extern void disableAutomaticRegisterForPushNotificationsNative();

        [DllImport("__Internal")]
        private static extern void registerForPushNotifications();

		[DllImport("__Internal")]
		private static extern void setPushNotificationKey(string key);

		[DllImport("__Internal")]
		private static extern void handlePushNotification(string notificationStringParams);

        /// <summary>
        /// Registers for push notifications for iOS.
        /// Can be used then the automatic registration was disabled using: DisableAutomaticRegisterForPushNotifications();
        /// </summary>
		public void RegisterForPushNotifications()
		{
			Debug.Log ("UNITY: REGISTERING FOR PUSH NOTIFICATIONS");
	#if UNITY_IPHONE || UNITY_TVOS
	#if UNITY_5
			UnityEngine.iOS.NotificationServices.RegisterForNotifications(
				UnityEngine.iOS.NotificationType.Alert |
				UnityEngine.iOS.NotificationType.Badge |
				UnityEngine.iOS.NotificationType.Sound,
				true
			);
	#else
	UnityEngine.iOS.NotificationServices.RegisterForNotifications (
	UnityEngine.iOS.NotificationType.Alert|
	UnityEngine.iOS.NotificationType.Badge|
	UnityEngine.iOS.NotificationType.Sound
	);
	#endif
	#endif
		}

		internal void CheckForRemoteNotifications()
		{
	bool proccessedNotifications = false;
	#if UNITY_IPHONE || UNITY_TVOS
	#if UNITY_5
			if (UnityEngine.iOS.NotificationServices.remoteNotificationCount > 0)
			{			
				foreach(UnityEngine.iOS.RemoteNotification notification in 	UnityEngine.iOS.NotificationServices.remoteNotifications)
				{
	#else
	if (UnityEngine.iOS.NotificationServices.remoteNotificationCount > 0)
	{			
	foreach(UnityEngine.iOS.RemoteNotification notification in 	UnityEngine.iOS.NotificationServices.remoteNotifications)
	{
	#endif
					foreach(var key in notification.userInfo.Keys)
					{
						if(notification.userInfo[key].GetType() == typeof(Hashtable))
						{
							Hashtable userInfo = (Hashtable) notification.userInfo[key];
							JSONObject notificationPayload = new JSONObject();
							foreach(var pKey in userInfo.Keys)
							{
								if(userInfo[pKey].GetType() == typeof(string))
								{
									string keyStr = pKey.ToString();
									string value = userInfo[pKey].ToString();
									notificationPayload.AddField(keyStr,value);
								}
								if(userInfo[pKey].GetType() == typeof(Hashtable))
								{
									JSONObject innerJson = new JSONObject();
									Hashtable innerTable = (Hashtable)userInfo[pKey];
									foreach(var iKey in innerTable.Keys)
									{
										string iKeyStr = iKey.ToString();
										if(innerTable[iKey].GetType() == typeof(Hashtable))
										{
											Hashtable innerTableB = (Hashtable)innerTable[iKey];
											JSONObject innerJsonB = new JSONObject();
											foreach(var bKey in innerTableB.Keys)
											{
												innerJsonB.AddField(bKey.ToString(),innerTableB[bKey].ToString());
											}
											innerJson.AddField(iKeyStr,innerJsonB);
										}
										if(innerTable[iKey].GetType() == typeof(string))
										{
											string iValue = innerTable[iKey].ToString();
											innerJson.AddField(iKeyStr,iValue);
										}
									}
									string keyStr = pKey.ToString();
									notificationPayload.AddField(keyStr,innerJson);
								}
							}

							String notificationJsonForNative = notificationPayload.ToString().Replace("'","\"");
							if(!proccessedNotifications){									
								SendCustomEvent("notificationOpened", new Dictionary<string, object>() { { "notificationPayload", notificationJsonForNative}});
								proccessedNotifications = true;
							}
						}
					}
				}
	#if UNITY_5
				UnityEngine.iOS.NotificationServices.ClearRemoteNotifications();
	#else
	UnityEngine.iOS.NotificationServices.ClearRemoteNotifications();
	#endif
			} else {
				Debug.Log("NO REMOTE NOTIFICATIONS FOUND");
			}
	#endif
		}

		//is the IOS notification service token sent
		private bool tokenSent;

		/// This method is marked as internal and should not be exposed to developers.
		/// The Spil Unity SDK is not packaged as a seperate assembly yet so this method is currently visible, this will be fixed in the future.
		/// Internal method names start with a lower case so you can easily recognise and avoid them.
		internal void SendNotificationTokenToSpil()
		{
			if (!tokenSent)
			{
	#if UNITY_IPHONE || UNITY_TVOS
	#if UNITY_5
				byte[] token = UnityEngine.iOS.NotificationServices.deviceToken;
	#else
	byte[] token = UnityEngine.iOS.NotificationServices.deviceToken;
	#endif
				if (token != null)
				{
					// send token to a provider
					string tokenToBeSent = System.BitConverter.ToString (token).Replace ("-", "");
					Dictionary<string,string> param = new Dictionary<string, string> ();
					param.Add ("regId", tokenToBeSent);
					setPushNotificationKey (tokenToBeSent);
					tokenSent = true;
				}
	#endif
			}
		}

		#endregion

		#region App lifecycle handlers

		[DllImport("__Internal")]
		private static extern void applicationDidEnterBackground();

		[DllImport("__Internal")]
		private static extern void applicationDidBecomeActive();

		private void OnApplicationPause(bool pauseStatus)
		{
			if(!pauseStatus)
			{
				applicationDidBecomeActive();
				CheckForRemoteNotifications();
			} else {
				applicationDidEnterBackground();
			}
		}

		#endregion

		[DllImport("__Internal")]
		private static extern void initEventTrackerWithOptions(string options);	

		[DllImport("__Internal")]
		private static extern void trackEventNative(string eventName);

		[DllImport("__Internal")]
		private static extern void trackEventWithParamsNative(string eventName, string jsonStringParams);
		#endregion
	}        
	#endif
}