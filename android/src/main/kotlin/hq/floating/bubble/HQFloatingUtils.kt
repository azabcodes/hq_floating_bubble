package hq.floating.bubble

import android.app.ActivityManager
import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.math.BigInteger
import java.security.MessageDigest

fun JSONObject.toMap(): Map<String, *> = keys().asSequence().associateWith {
    when (val value = this[it])
    {
        is JSONArray ->
        {
            val map = (0 until value.length()).associate { Pair(it.toString(), value[it]) }
            JSONObject(map).toMap().values.toList()
        }
        is JSONObject -> value.toMap()
        JSONObject.NULL -> null
        else            -> value
    }
}

class HQFloatingUtils {
    companion object {
        fun getRunningService(context: Context, serviceClass: Class<*>): ActivityManager.RunningServiceInfo? {
            val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager?
            for (service in manager!!.getRunningServices(Int.MAX_VALUE)) {
                if (serviceClass.name == service.service.className) {
                    return service
                }
            }

            return null
        }

        fun md5(input:String): String {
            val md = MessageDigest.getInstance("MD5")
            return BigInteger(1, md.digest(input.toByteArray())).toString(16).padStart(32, '0')
        }

        fun genKey(vararg items: Any?): String {
            return HQFloatingUtils.md5(items.joinToString(separator="-"){ "$it" }).slice(IntRange(0, 12))
        }
    }
}