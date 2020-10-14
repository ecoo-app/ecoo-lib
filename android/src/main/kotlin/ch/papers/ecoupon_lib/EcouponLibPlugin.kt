package ch.papers.ecoupon_lib

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import androidx.annotation.NonNull;
import ch.papers.ecoupon_lib.securityutils.storage.AuthenticationFailedException
import ch.papers.ecoupon_lib.securityutils.storage.Errors
import ch.papers.ecoupon_lib.securityutils.storage.Storage

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.lang.Exception
import java.security.InvalidAlgorithmParameterException

/** EcouponLibPlugin */
public class EcouponLibPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var storage: Storage
  private lateinit var activity: Activity
  private var keyguardManager: KeyguardManager? = null
  private var onAuthCompletion: ((kotlin.Result<Unit>) -> Unit)? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.getFlutterEngine().dartExecutor, "ecoupon_lib")
    channel.setMethodCallHandler(this);
    storage = Storage(flutterPluginBinding.applicationContext, "ecoupon_storage", false);
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    setup(binding)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onDetachedFromActivity() {
    keyguardManager = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    setup(binding)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    keyguardManager = null
  }
  
  private fun setup(binding: ActivityPluginBinding) {
    activity = binding.activity
    keyguardManager = binding.activity.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
    binding.addActivityResultListener { requestCode, resultCode, _ ->
      val completion = onAuthCompletion
      onAuthCompletion = null
      when (requestCode) {
        REQUEST_CODE_CONFIRM_DEVICE_CREDENTIALS -> {
          var result = if (resultCode == Activity.RESULT_OK) kotlin.Result.success(Unit) else kotlin.Result.failure(AuthenticationFailedException())
          completion?.let { it(result) }
          return@addActivityResultListener true
        }
        else -> {
          return@addActivityResultListener false
        }
      }
    }
  }

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  companion object {

    const val REQUEST_CODE_CONFIRM_DEVICE_CREDENTIALS = 1

    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "ecoupon_lib")
      channel.setMethodCallHandler(EcouponLibPlugin())
    }
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method)  {
      "getPlatformVersion" -> { result.success("Android ${android.os.Build.VERSION.RELEASE}") }
      "store" -> {
        var key = call.argument<String>("key")
        var value = call.argument<String>("value")
        if (key != null && value != null) {
          try {
            store(key, value, result)
          } catch (error: InvalidAlgorithmParameterException) {
            result.error("-5", "Store illegal state", error.localizedMessage);
          } catch (error: Exception) {
            result.error("-1", "Storage store failed", error.localizedMessage);
          }
        } else {
          result.error("-4", "Wrong arguments", "Wrong arguments for " + call.method);
        }
      }
      "load" -> {
        var key = call.argument<String>("key")
        if (key != null) {
          try {
            load(key, result)
          } catch (error: InvalidAlgorithmParameterException) {
            result.error("-5", "Store illegal state", error.localizedMessage);
          } catch (error: Exception) {
            result.error("-1", "Storage store failed", error.localizedMessage);
          }
        } else {
          result.error("-3", "Wrong arguments", "Wrong arguments for " + call.method);
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun store(key: String, value: String, result: Result) {
    storage.writeString(key, value, {
      showAuthenticationScreen { it ->
        if (it.isSuccess) {
          it()
        }
      }
    }) {
      activity.runOnUiThread {
        try {
          it.getOrThrow()
          result.success(null)
        } catch (error: Exception) {
          result.error("-1", "Storage store failed", error.localizedMessage)
        }
      }
    }
  }

  private fun load(key: String, result: Result) {
    storage.readString(key, {
      showAuthenticationScreen { it ->
        if (it.isSuccess) {
          it()
        }
      }
    }) {
      activity.runOnUiThread {
        try {
          result.success(it.getOrThrow())
        } catch (error: Exception) {
          result.error("-1", "Storage load failed", error.localizedMessage)
        }
      }
    }
  }

  private fun showAuthenticationScreen(completion: (kotlin.Result<Unit>) -> Unit) {
    onAuthCompletion = completion
    val intent = keyguardManager?.createConfirmDeviceCredentialIntent(null, null)
    if (intent != null) {
      activity.startActivityForResult(intent, REQUEST_CODE_CONFIRM_DEVICE_CREDENTIALS)
    }
  }
}
