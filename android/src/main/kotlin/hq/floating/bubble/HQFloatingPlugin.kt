package hq.floating.bubble

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import org.json.JSONObject
import java.lang.Exception

/** HQFloatingPlugin */
class HQFloatingPlugin: FlutterPlugin, ActivityAware, MethodCallHandler, PluginRegistry.ActivityResultListener {

  private lateinit var mContext: Context
  private lateinit var mActivity: Activity
  private lateinit var channel : MethodChannel
  private lateinit var engine: FlutterEngine
  private var waitPermissionResult: Result? = null

  private var serviceChannelInstalled = false
  private var isMain = false

  private var myEngine: FlutterEngine? = null
  private var myWindowId: String? = null
  private var myConfig: HQFloatingWindow.Config? = null

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    mContext = binding.applicationContext
    myEngine = binding.flutterEngine

    // Register method channel
    channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
    channel.setMethodCallHandler(this)

    // Register the window channel on this engine
    MethodChannel(binding.binaryMessenger, "${HQFloatingService.METHOD_CHANNEL}/window")
      .setMethodCallHandler(this)

    val startingId = HQFloatingService.startingWindowId
    val startingConfig = HQFloatingService.startingWindowConfig
    if (startingId != null) {
      myWindowId = startingId
      myConfig = startingConfig
    }

    if (FlutterEngineCache.getInstance().contains(FLUTTER_ENGINE_CACHE_KEY)) {
      Log.d(TAG, "[plugin] on attached to window engine: $myWindowId")
    } else {
      isMain = true
      engine = binding.flutterEngine
      FlutterEngineCache.getInstance().put(FLUTTER_ENGINE_CACHE_KEY, engine)
      serviceChannelInstalled = HQFloatingService.installChannel(engine)
      Log.d(TAG, "[plugin] on attached to main engine")
    }
  }

  private fun saveSystemConfig(data: Map<*, *>?): Boolean {
    if (data == null) return false
    
    val newScreen = data["screen"] as? Map<*, *>
    val newWidth = (newScreen?.get("width") as? Number)?.toInt() ?: 0
    val newHeight = (newScreen?.get("height") as? Number)?.toInt() ?: 0
    val newConfigValid = newWidth > 0 && newHeight > 0
    
    val old = mContext.getSharedPreferences(SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE)
      .getString(SYSTEM_CONFIG_KEY, null)
    
    if (old != null) {
      try {
        val oldJson = JSONObject(old)
        val oldScreen = oldJson.optJSONObject("screen")
        val oldWidth = oldScreen?.optInt("width", 0) ?: 0
        val oldHeight = oldScreen?.optInt("height", 0) ?: 0
        val oldConfigValid = oldWidth > 0 && oldHeight > 0
        
        if (oldConfigValid) {
          Log.d(TAG, "[plugin] system config already exists with valid screen: $old")
          return false
        }
        
        if (!newConfigValid) {
          Log.d(TAG, "[plugin] both old and new config have invalid screen size, skipping update")
          return false
        }
        
        Log.d(TAG, "[plugin] updating system config: old has 0x0 screen, new has ${newWidth}x${newHeight}")
      } catch (e: Exception) {
        Log.e(TAG, "[plugin] error parsing old system config: ${e.message}")
      }
    }

    @Suppress("UNCHECKED_CAST")
    HQFloatingService.instance?.systemConfig = data as Map<String, Any?>

    return try {
      val str = JSONObject(data).toString()
      // json encode map to string
      // try to save
      mContext.getSharedPreferences(SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE).edit()
        .putString(SYSTEM_CONFIG_KEY, str)
        .apply()
      true
    } catch (e: Exception) {
      e.printStackTrace()
      false
    }
  }

  private fun savePixelRadio(pixelRadio: Double): Boolean {
    val old = mContext.getSharedPreferences(SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE)
      .getFloat(PIXEL_RADIO_KEY, 0F)
    if (old > 1F) {
      Log.d(TAG, "[plugin] pixel radio already exits")
      return false
    }

    HQFloatingService.instance?.pixelRadio = pixelRadio

    // we need to save pixel radio
    Log.d(TAG, "[plugin] pixel radio need to be saved")
    mContext.getSharedPreferences(SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE).edit()
      .putFloat(PIXEL_RADIO_KEY, pixelRadio.toFloat())
      .apply()
    return true
  }

  private fun cleanCache(): Boolean {
    // delete all of cache files
    Log.w(TAG, "[plugin] will delete all of contents")
    mContext.getSharedPreferences(SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE).edit()
      .clear().apply()
    return true
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "window.sync") {
      val currentWindow = HQFloatingService.instance?.windows?.values?.find { it.engine == myEngine }
      if (currentWindow != null) {
        result.success(currentWindow.toMap())
      } else if (myWindowId != null && myConfig != null) {
        val map = HashMap<String, Any?>()
        map["id"] = myWindowId
        val shared = mContext.getSharedPreferences(SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE)
        map["pixelRadio"] = shared.getFloat(PIXEL_RADIO_KEY, 0F).toDouble()
        try {
          val sysConfigStr = shared.getString(SYSTEM_CONFIG_KEY, null)
          if (sysConfigStr != null) {
            val sysJson = JSONObject(sysConfigStr)
            val sysMap = HashMap<String, Any?>()
            val keys = sysJson.keys()
            while (keys.hasNext()) {
              val key = keys.next()
              sysMap[key] = sysJson.get(key)
            }
            map["system"] = sysMap
          }
        } catch (_: Exception) {}
        map["config"] = myConfig?.toMap()?.filter { it.value != null }
        result.success(map)
      } else {
        result.success(null)
      }
      return
    }

    if (call.method.startsWith("window.") || call.method.startsWith("service.") || call.method == "data.share") {
      val currentWindow = HQFloatingService.instance?.windows?.values?.find { it.engine == myEngine }
      if (currentWindow != null) {
        currentWindow.onMethodCall(call, result)
      } else if (HQFloatingService.instance != null) {
        HQFloatingService.instance!!.onMethodCall(call, result)
      } else {
        result.error("SERVICE_NOT_RUNNING", "Floating service is not running", null)
      }
      return
    }

    when (call.method) {
      "plugin.initialize" -> {
        // the main engine should call initialize?
        // but the sub engine don't
        val pixelRadio = call.argument("pixelRadio") ?: 1.0
        val systemConfig = call.argument<Map<*, *>?>("system") as Map<*, *>

        val map = HashMap<String, Any?>()
        map["permission_grated"] = permissionGiven(mContext)
        map["service_running"] = HQFloatingService.isRunning(mContext)
        map["windows"] = HQFloatingService.instance?.windows?.map { it.value.toMap() }

        map["pixel_radio_updated"] = savePixelRadio(pixelRadio)
        map["system_config_updated"] = saveSystemConfig(systemConfig)

        return result.success(map)
      }
      "plugin.has_permission" -> {
        return result.success(permissionGiven(mContext))
      }
      "plugin.open_permission_setting" -> {
        return result.success(requestPermissions())
      }
      "plugin.grant_permission" -> {
        return grantPermission(result)
      }
      // remove
      "plugin.create_window" -> {
        val id = call.argument<String>("id") ?: "default"
        val cfg = call.argument<Map<String, *>>("config")!!
        val start = call.argument<Boolean>("start") ?: false
        val config = HQFloatingWindow.Config.from(cfg)
        
        // Use async version to avoid main thread blocking
        HQFloatingService.createWindowAsync(mContext, id, config, start, null) { windowResult ->
          result.success(windowResult)
        }
        return
      }
      "plugin.is_service_running" -> {
        return result.success(HQFloatingService.isRunning(mContext))
      }
      "plugin.start_service" -> {
        return result.success(HQFloatingService.isRunning(mContext)
          .or(HQFloatingService.start(mContext)))
      }
      "plugin.clean_cache" -> {
        return result.success(cleanCache())
      }
      "plugin.sync_windows" -> {
        return result.success(HQFloatingService.instance?.windows?.map { it.value.toMap() })
      }
      else -> {
        Log.d(TAG, "[plugin] method ${call.method} not implement")
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    try {
      MethodChannel(binding.binaryMessenger, "${HQFloatingService.METHOD_CHANNEL}/window")
        .setMethodCallHandler(null)
    } catch (_: Exception) {}
    myEngine = null
    myConfig = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    mActivity = binding.activity

    // TODO: notify the window to show and return the result?

    Log.d(TAG, "[plugin] on attached to activity")

    // how to known are the main
     HQFloatingService.onActivityAttached(mActivity)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    HQFloatingService.activityRef?.clear()
    HQFloatingService.activityRef = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    mActivity = binding.activity
    HQFloatingService.onActivityAttached(mActivity)
  }

  override fun onDetachedFromActivity() {
    HQFloatingService.activityRef?.clear()
    HQFloatingService.activityRef = null
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (requestCode == ALERT_WINDOW_PERMISSION) {
      waitPermissionResult?.success(permissionGiven(mContext))
      waitPermissionResult = null
      return true
    }
    return false
  }

  private fun requestPermissions(): Boolean {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      mActivity.startActivityForResult(Intent(
        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
        Uri.parse("package:${mContext.packageName}")
      ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK), ALERT_WINDOW_PERMISSION)
      return true
    }
    return false
  }

  private fun grantPermission(result: Result) {
    waitPermissionResult = result
    requestPermissions()
  }

  companion object {
    private const val TAG = "HQFloatingPlugin"
    private const val CHANNEL_NAME = "hq.floating.bubble/method"
    private const val ALERT_WINDOW_PERMISSION = 1248

    const val FLUTTER_ENGINE_CACHE_KEY = "flutter_engine_main"
    const val SHARED_PREFERENCES_KEY = "hq_floating_bubble_cache"
    const val CALLBACK_KEY = "callback_key"
    const val PIXEL_RADIO_KEY = "pixel_radio"
    const val SYSTEM_CONFIG_KEY = "system_config"

    fun permissionGiven(context: Context): Boolean {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        return Settings.canDrawOverlays(context)
      }
      return false
    }
  }
}
