package hq.floating.bubble

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.WindowManager.LayoutParams
import android.view.WindowManager.LayoutParams.*
import io.flutter.embedding.android.FlutterTextureView
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.JSONMessageCodec
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

@SuppressLint("ClickableViewAccessibility")
class HQFloatingWindow(
    context: Context,
    wmr: WindowManager,
    engKey: String,
    eng: FlutterEngine,
    cfg: Config): View.OnTouchListener, MethodChannel.MethodCallHandler,
    BasicMessageChannel.MessageHandler<Any?> {

    var parent: HQFloatingWindow? = null

    var config = cfg

    var key: String = "default"

    var engineKey = engKey
    var engine = eng

    var wm = wmr

    var subscribedEvents: MutableMap<String, Boolean> = mutableMapOf()

    var view: FlutterView = FlutterView(context, FlutterTextureView(context))

    lateinit var layoutParams: LayoutParams

    lateinit var service: HQFloatingService

    // method and message channel for window engine call
    var _channel: MethodChannel = MethodChannel(eng.dartExecutor.binaryMessenger,
        "${HQFloatingService.METHOD_CHANNEL}/window").also {
        it.setMethodCallHandler(this) }
    var _message: BasicMessageChannel<Any?> = BasicMessageChannel(eng.dartExecutor.binaryMessenger,
        "${HQFloatingService.MESSAGE_CHANNEL}/window_msg", JSONMessageCodec.INSTANCE)
        .also { it.setMessageHandler(this) }

    var _started = false

    fun init(): HQFloatingWindow {
        layoutParams = config.to()

        config.focusable?.let{
            view.isFocusable = it
            view.isFocusableInTouchMode = it
        }

        view.setBackgroundColor(Color.TRANSPARENT)
        view.fitsSystemWindows = true

        config.visible?.let{ setVisible(it) }

        view.setOnTouchListener(this)

        // view.attachToFlutterEngine(engine)
        return this
    }

    fun destroy(force: Boolean = true): Boolean {
        Log.i(TAG, "[window] destroy window: $key force: $force")

        view.animate().cancel()

        // remote from manager must be first
        try {
            if (_started) wm.removeView(view)
        } catch (_: Exception) {}

        view.detachFromFlutterEngine()


        // TODO: should we stop the engine for flutter?
        if (force) {
            // stop engine and remove from cache
            FlutterEngineCache.getInstance().remove(engineKey)
            service.createdEngineKeys.remove(engineKey)
            engine.destroy()
            service.windows.remove(key)
            emit("destroy", null)
        } else {
            _started = false
            engine.lifecycleChannel.appIsPaused()
            emit("paused", null)
        }
        return true
    }

    fun setVisible(visible: Boolean = true): Boolean {
        Log.d(TAG, "[window] set window $key => $visible")
        emit("visible", visible)
        view.animate().cancel()
        if (visible) {
            view.visibility = View.VISIBLE
            view.alpha = 0f
            view.scaleX = 0.5f
            view.scaleY = 0.5f
            view.animate()
                .alpha(1f)
                .scaleX(1f)
                .scaleY(1f)
                .setDuration(250)
                .setInterpolator(android.view.animation.DecelerateInterpolator())
                .start()
        } else {
            view.animate()
                .alpha(0f)
                .scaleX(0.5f)
                .scaleY(0.5f)
                .setDuration(250)
                .setInterpolator(android.view.animation.DecelerateInterpolator())
                .withEndAction {
                    view.visibility = View.GONE
                }
                .start()
        }
        return visible
    }

    fun update(cfg: Config): Map<String, Any?> {
        Log.d(TAG, "[window] update window $key => $cfg")
        val oldX = layoutParams.x
        val oldY = layoutParams.y
        val oldWidth = layoutParams.width
        val oldHeight = layoutParams.height
        val oldGravity = layoutParams.gravity

        config = config.update(cfg).also {
            val newParams = it.to()
            if (newParams.x != oldX || newParams.y != oldY || 
                newParams.width != oldWidth || newParams.height != oldHeight || 
                newParams.gravity != oldGravity) {
                layoutParams = newParams
                if (_started) wm.updateViewLayout(view, layoutParams)
            }
        }
        return toMap()
    }

    fun start(): Boolean {
        if (_started) {
            Log.d(TAG, "[window] window $key already started")
            return true
        }

        _started = true
        Log.d(TAG, "[window] start window: $key")

        engine.lifecycleChannel.appIsResumed()

        // if engine is paused, send re-render message
        // make sure reuse engine can be re-render
        emit("resumed")

        view.attachToFlutterEngine(engine)

        wm.addView(view, layoutParams)

        emit("started")

        return true
    }

    fun shareData(data: Map<*, *>, source: String? = null, result: MethodChannel.Result? = null) {
        shareData(_channel, data, source, result)
    }

    fun simpleEmit(msgChannel: BasicMessageChannel<Any?>, name: String, data: Any?=null, senderId: String? = null) {
        val map = HashMap<String, Any?>()
        map["name"] = name
        map["id"] = senderId ?: key // this is special for main engine
        map["data"] = data
        msgChannel.send(map)
    }

    fun emit(name: String, data: Any? = null, prefix: String?="window", pluginNeed: Boolean = true) {
        val evtName = "$prefix.$name"
        // Log.i(TAG, "[window] emit event: HQFloatingWindow[$key] $name ")

        // Always emit to my own window engine/isolate
        simpleEmit(_message, evtName, data, key)

        // Always emit to the plugin/service (main engine)
        if (pluginNeed) {
            simpleEmit(service._message, evtName, data, key)
        }

        // emit parent engine
        // if fire to parent need have no need to fire to service again
        if(parent!=null&&parent!=this) {
            parent!!.simpleEmit(parent!!._message, evtName, data, key)
        }
    }

    fun toMap(): Map<String, Any?> {
        // must not null if success created
        val map = HashMap<String, Any?>()
        map["id"] = key
        map["pixelRadio"] = service.pixelRadio
        map["system"] = service.systemConfig
        map["config"] = config.toMap().filter { it.value != null }
        return map
    }

    override fun toString(): String {
        return "${toMap()}"
    }

    // return window from svc.windows by id
    fun take(id: String): HQFloatingWindow? {
        return service.windows[id]
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        return when (call.method) {
            // just take current engine's window
            "window.sync" -> {
                // when flutter is ready should call this to sync the window object.
                Log.i(TAG, "[window] window.sync from flutter side: $key")
                result.success(toMap())
            }

            // we need to support call window.* in window engine
            // but the window engine register as window channel
            // so we should take the id first and then get window from windows cache
            // TODO: those code should move to service

            "window.create_child" -> {
                val id = call.argument<String>("id") ?: "default"
                val cfg = call.argument<Map<String, *>>("config")
                    ?: return result.error("invalid_args", "Missing config argument", null)
                val start = call.argument<Boolean>("start") ?: false
                val config = HQFloatingWindow.Config.from(cfg)
                Log.d(TAG, "[service] window.create_child request_id: $id")
                HQFloatingService.createWindowAsync(service.applicationContext, id, config, start, this) { windowResult ->
                    result.success(windowResult)
                }
                return
            }
            "window.close" -> {
                val id = call.argument<String?>("id")?:"<unset>"
                Log.d(TAG, "[window] window.close request_id: $id, my_id: $key")
                val force = call.argument("force") ?: false
                return result.success(take(id)?.destroy(force))
            }
            "window.destroy" -> {
                val id = call.argument<String?>("id")?:"<unset>"
                Log.d(TAG, "[window] window.destroy request_id: $id, my_id: $key")
                return result.success(take(id)?.destroy(true))
            }
            "window.start" -> {
                val id = call.argument<String?>("id")?:"<unset>"
                Log.d(TAG, "[window] window.start request_id: $id, my_id: $key")
                return result.success(take(id)?.start())
            }
            "window.update" -> {
                val id = call.argument<String?>("id")?:"<unset>"
                Log.d(TAG, "[window] window.update request_id: $id, my_id: $key")
                val cfg = call.argument<Map<String, *>>("config")
                    ?: return result.error("invalid_args", "Missing config argument", null)
                val config = Config.from(cfg)
                return result.success(take(id)?.update(config))
            }
            "window.show" -> {
                val id = call.argument<String?>("id")?:"<unset>"
                Log.d(TAG, "[window] window.show request_id: $id, my_id: $key")
                val visible = call.argument<Boolean>("visible") ?: true
                return result.success(take(id)?.setVisible(visible))
            }
            "window.launch_main" -> {
                Log.d(TAG, "[window] window.launch_main")
                return result.success(service.launchMainActivity())
            }
            "window.lifecycle" -> {

            }
            "event.subscribe" -> {
                val id = call.argument<String?>("id")?:"<unset>"

            }
            "data.share" -> {
                // communicate with other window, only 1 - 1 with id
                val args = call.arguments as? Map<*, *>
                if (args == null) {
                    Log.d(TAG, "[window] data.share called with invalid/missing arguments")
                    return result.error("invalid_args", "Expected a map for data.share", null)
                }
                val targetId = call.argument<String?>("target")
                Log.d(TAG, "[window] share data from $key with $targetId: $args")
                if (targetId == null) {
                    Log.d(TAG, "[window] share data with plugin")
                    return result.success(shareData(service._channel, args, source=key, result=result))
                }
                if (targetId == key) {
                    Log.d(TAG, "[window] can't share data with self")
                    return result.error("no allow", "share data from $key to $targetId", "")
                }
                val target = service.windows[targetId]
                    ?: return result.error("not found", "target window $targetId not exits", "");
                return target.shareData(args, source=key, result=result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onMessage(msg: Any?, reply: BasicMessageChannel.Reply<Any?>) {
        // stream message
    }

    companion object {
        private const val TAG = "HQFloatingWindow"

        fun shareData(channel: MethodChannel, data: Map<*, *>, source: String? = null,
                      result: MethodChannel.Result? = null): Any? {
            // id is the data comes from
            // invoke the method channel
            val map = HashMap<String, Any?>()
            map["source"] = source
            data.forEach { map[it.key as String] = it.value }
            channel.invokeMethod("data.share", map, result)
            // how to get data back
            return null
        }
    }

    // window is dragging
    private var dragging = false
    private var lastDragEmitTime = 0L
    private val dragHandler = android.os.Handler(android.os.Looper.getMainLooper())
    private val dragRunnable = Runnable {
        if (_started) {
            wm.updateViewLayout(view, layoutParams)
        }
        emit("dragging", listOf(layoutParams.x, layoutParams.y))
        lastDragEmitTime = System.currentTimeMillis()
    }

    // start point
    private var lastX = 0f
    private var lastY = 0f

    // border around
    // TODO: support generate around edge

    private fun getInterpolator(curveName: String?): android.view.animation.Interpolator {
        return when (curveName?.lowercase()) {
            "accelerate" -> android.view.animation.AccelerateInterpolator()
            "bounce" -> android.view.animation.BounceInterpolator()
            "overshoot" -> android.view.animation.OvershootInterpolator()
            "linear" -> android.view.animation.LinearInterpolator()
            else -> android.view.animation.DecelerateInterpolator()
        }
    }

    private fun performMagnetSnap(currentX: Int, currentY: Int?, screenWidth: Int, wWidth: Int, onEnd: ((Int) -> Unit)? = null) {
        val targetX = if (currentX + wWidth / 2 < screenWidth / 2) 0 else (screenWidth - wWidth)
        Log.d(TAG, "[window] performMagnetSnap window $key currentX=$currentX targetX=$targetX currentY=$currentY")
        val animator = android.animation.ValueAnimator.ofInt(layoutParams.x, targetX)
        animator.duration = (config.snapDuration ?: 250).toLong()
        animator.interpolator = getInterpolator(config.snapCurve)
        animator.addUpdateListener { valueAnimator ->
            val animX = valueAnimator.animatedValue as Int
            update(Config().apply {
                x = animX
                if (currentY != null) {
                    y = currentY
                }
            })
        }
        if (onEnd != null) {
            animator.addListener(object : android.animation.AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: android.animation.Animator) {
                    onEnd(targetX)
                }
            })
        }
        animator.start()
    }

    fun onConfigurationChanged(newConfig: android.content.res.Configuration) {
        if (!_started) return
        val displayMetrics = service.resources.displayMetrics
        val screenWidth = displayMetrics.widthPixels
        val screenHeight = displayMetrics.heightPixels

        val wWidth = if (view != null && view.width > 0) view.width else (config.width ?: 0)
        val wHeight = if (view != null && view.height > 0) view.height else (config.height ?: 0)

        // Constrain current positions to new screen boundaries
        val constrainedX = Math.max(0, Math.min(layoutParams.x, screenWidth - wWidth))
        val constrainedY = Math.max(0, Math.min(layoutParams.y, screenHeight - wHeight))

        if (config.magnet != false) {
            performMagnetSnap(constrainedX, constrainedY, screenWidth, wWidth)
        } else {
            update(Config().apply {
                x = constrainedX
                y = constrainedY
            })
        }
    }

    override fun onTouch(view: View?, event: MotionEvent?): Boolean {
        // default draggable should be false
        if (config.draggable != true) return false
        val displayMetrics = service.resources.displayMetrics
        val screenWidth = displayMetrics.widthPixels
        val screenHeight = displayMetrics.heightPixels

        val wWidth = if (view != null && view.width > 0) view.width else (config.width ?: 0)
        val wHeight = if (view != null && view.height > 0) view.height else (config.height ?: 0)

        val touchSlop = android.view.ViewConfiguration.get(service).scaledTouchSlop
        val touchSlopSquare = touchSlop * touchSlop

        when (event?.action) {
            MotionEvent.ACTION_DOWN -> {
                // touch start
                dragging = false
                lastX = event.rawX
                lastY = event.rawY
            }
            MotionEvent.ACTION_MOVE -> {
                // touch move
                val dx = event.rawX - lastX
                val dy = event.rawY - lastY
                Log.v(TAG, "[window] onTouch ACTION_MOVE window $key rawX=${event.rawX} rawY=${event.rawY} dx=$dx dy=$dy")

                // ignore too small first start moving(some time is click)
                if (!dragging && dx*dx+dy*dy < touchSlopSquare) {
                    return false
                }

                // update the last point
                lastX = event.rawX
                lastY = event.rawY

                val xx = layoutParams.x + dx.toInt()
                val yy = layoutParams.y + dy.toInt()

                // Constrain values within screen boundaries
                val constrainedX = Math.max(0, Math.min(xx, screenWidth - wWidth))
                val constrainedY = Math.max(0, Math.min(yy, screenHeight - wHeight))

                if (!dragging) {
                    // first time dragging
                    emit("drag_start", listOf(constrainedX, constrainedY))
                }

                dragging = true
                
                // Keep local layoutParams updated
                layoutParams.x = constrainedX
                layoutParams.y = constrainedY

                // Throttle visual layout update and dragging event (max once every 16ms)
                val currentTime = System.currentTimeMillis()
                if (currentTime - lastDragEmitTime >= 16) {
                    dragHandler.removeCallbacks(dragRunnable)
                    if (_started) {
                        wm.updateViewLayout(view, layoutParams)
                    }
                    emit("dragging", listOf(constrainedX, constrainedY))
                    lastDragEmitTime = currentTime
                } else {
                    dragHandler.removeCallbacks(dragRunnable)
                    dragHandler.postDelayed(dragRunnable, 16)
                }
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                dragHandler.removeCallbacks(dragRunnable)
                // touch end
                if (dragging) {
                    // Ensure final position is applied and emitted before snapping
                    if (_started) {
                        wm.updateViewLayout(view, layoutParams)
                    }
                    emit("dragging", listOf(layoutParams.x, layoutParams.y))
                    
                    if (config.magnet != false) {
                        performMagnetSnap(layoutParams.x, null, screenWidth, wWidth) { targetX ->
                            emit("drag_end", listOf(targetX.toDouble(), layoutParams.y.toDouble()))
                        }
                    } else {
                        emit("drag_end", listOf(layoutParams.x.toDouble(), layoutParams.y.toDouble()))
                    }
                }
                return dragging
            }
            else -> {
                return false
            }
        }
        return false
    }

    class Config {
        // this three fields can not be changed
        // var id: String = "default"
        var entry: String? = null
        var route: String? = null
        var callback: Long? = null

        var autosize: Boolean? = null

        var width: Int? = null
        var height: Int? = null
        var x: Int? = null
        var y: Int? = null

        var format: Int? = null
        var gravity: Int? = null
        var type: Int? = null

        var clickable: Boolean? = null
        var draggable: Boolean? = null
        var focusable: Boolean? = null

        var immersion: Boolean? = null

        var visible: Boolean? = null
        var magnet: Boolean? = null
        var snapDuration: Int? = null
        var snapCurve: String? = null


        // inline fun <reified T: Any?>to(): T {
        fun to(): LayoutParams {
            val cfg = this
            return LayoutParams().apply {
                // set size
                width = cfg.width ?: 1 // we must have 1 pixel, let flutter can generate the pixel radio
                height = cfg.height ?: 1 // we must have 1 pixel, let flutter can generate the pixel radio

                // set position fixed if with (x, y)
                cfg.x?.let { x = it } // default not set
                cfg.y?.let { y = it } // default not set

                // format
                format = cfg.format ?: PixelFormat.TRANSPARENT

                // default start from center
                gravity = cfg.gravity ?: Gravity.TOP or Gravity.LEFT

                // default flags
                flags = FLAG_LAYOUT_IN_SCREEN or FLAG_NOT_TOUCH_MODAL
                // if immersion add flag no limit
                cfg.immersion?.let{ if (it) flags = flags or FLAG_LAYOUT_NO_LIMITS }
                // default we should be clickable
                // if not clickable, add flag not touchable
                cfg.clickable?.let{ if (!it) flags = flags or FLAG_NOT_TOUCHABLE }
                // default we should be no focusable
                if (cfg.focusable == null) { cfg.focusable = false }
                // if not focusable, add no focusable flag
                cfg.focusable?.let { if (!it) flags = flags or FLAG_NOT_FOCUSABLE }

                // default type is overlay
                type = cfg.type ?: if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) TYPE_APPLICATION_OVERLAY else TYPE_PHONE
            }
        }

        fun toMap(): Map<String, Any?> {
            val map = HashMap<String, Any?>()
            map["entry"] = entry
            map["route"] = route
            map["callback"] = callback

            map["autosize"] = autosize

            map["width"] = width
            map["height"] = height
            map["x"] = x
            map["y"] = y

            map["format"] = format
            map["gravity"] = gravity
            map["type"] = type

            map["clickable"] = clickable
            map["draggable"] = draggable
            map["focusable"] = focusable

            map["immersion"] = immersion

            map["visible"] = visible
            map["magnet"] = magnet
            map["snapDuration"] = snapDuration
            map["snapCurve"] = snapCurve

            return map;
        }

        fun update(cfg: Config): Config {
            // entry, route, callback shouldn't be updated

            cfg.autosize?.let { autosize = it }

            cfg.width?.let { width = it }
            cfg.height?.let { height = it }
            cfg.x?.let { x = it }
            cfg.y?.let { y = it }

            cfg.format?.let { format = it }
            cfg.gravity?.let { gravity = it }
            cfg.type?.let { type = it }

            cfg.clickable?.let{ clickable = it }
            cfg.draggable?.let { draggable = it }
            cfg.focusable?.let { focusable = it }

            cfg.immersion?.let { immersion = it }

            cfg.visible?.let { visible = it }
            cfg.magnet?.let { magnet = it }
            cfg.snapDuration?.let { snapDuration = it }
            cfg.snapCurve?.let { snapCurve = it }

            return this
        }

        override fun toString(): String {
            val map = toMap()?.filter { it.value != null }
            return "$map"
        }

        companion object {

            fun from(data: Map<String, *>): Config {
                val cfg = Config()

                // (data["id"]?.let { it as String } ?: "default").also { cfg.id = it }
                cfg.entry = data["entry"] as String?
                cfg.route = data["route"] as String?

                val int_callback = data["callback"] as Number?
                cfg.callback = int_callback?.toLong()

                cfg.autosize = data["autosize"] as Boolean?

                cfg.width = (data["width"] as? Number)?.toInt()
                cfg.height = (data["height"] as? Number)?.toInt()
                cfg.x = (data["x"] as? Number)?.toInt()
                cfg.y = (data["y"] as? Number)?.toInt()

                cfg.gravity = (data["gravity"] as? Number)?.toInt()
                cfg.format = (data["format"] as? Number)?.toInt()
                cfg.type = (data["type"] as? Number)?.toInt()

                cfg.clickable = data["clickable"] as Boolean?
                cfg.draggable = data["draggable"] as Boolean?
                cfg.focusable = data["focusable"] as Boolean?

                cfg.immersion = data["immersion"] as Boolean?

                cfg.visible = data["visible"] as Boolean?
                cfg.magnet = data["magnet"] as Boolean?
                cfg.snapDuration = (data["snapDuration"] as? Number)?.toInt()
                cfg.snapCurve = data["snapCurve"] as String?

                return cfg
            }
        }
    }

}