package com.teranet.oauth2_client

import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build

import androidx.wear.phone.interactions.authentication.*

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.util.concurrent.Executors

class OAuth2ClientPlugin(private var context: Context? = null, private var channel: MethodChannel? = null): MethodCallHandler, FlutterPlugin {
  private lateinit var remoteAuthClient: RemoteAuthClient

  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val plugin = OAuth2ClientPlugin()
      plugin.initInstance(registrar.messenger(), registrar.context())
    }

  }

  fun initInstance(messenger: BinaryMessenger, context: Context) {
    this.context = context
    remoteAuthClient = RemoteAuthClient.create(context)
    channel = MethodChannel(messenger, "oauth2_client")
    channel?.setMethodCallHandler(this)
  }

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    initInstance(binding.binaryMessenger, binding.applicationContext)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    context = null
    channel = null
  }

  private fun buildWatchAuthUri(url: Uri): Uri? {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N_MR1 && context != null &&
      context!!.packageManager.hasSystemFeature(PackageManager.FEATURE_WATCH)) {
      val context = context!!
      val request = OAuthRequest.Builder(context)
        .setAuthProviderUrl(url)
        .build()
      request.requestUrl
    } else {
      null
    }
  }

  override fun onMethodCall(call: MethodCall, resultCallback: MethodChannel.Result) {
    when (call.method) {
      "authUrl" -> {
        val url = call.argument<String>("url")
        val authUri = buildWatchAuthUri(Uri.parse(url))
        if (authUri == null) {
          resultCallback.notImplemented()
          return
        }
        resultCallback.success(authUri.toString())
      }
      "authenticate" -> {
        val url = Uri.parse(call.argument("url")!!)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N_MR1 && context != null &&
          context!!.packageManager.hasSystemFeature(PackageManager.FEATURE_WATCH)) {
          val context = context!!
          val request = OAuthRequest.Builder(context)
            .setAuthProviderUrl(url)
            .build()
          remoteAuthClient.sendAuthorizationRequest(request,
            Executors.newSingleThreadExecutor(),
            object : RemoteAuthClient.Callback() {
              override fun onAuthorizationResponse(
                request: OAuthRequest,
                response: OAuthResponse
              ) {
                resultCallback.success(response.responseUrl.toString())
              }

              override fun onAuthorizationError(request: OAuthRequest, errorCode: Int) {
                val message = when (errorCode) {
                  RemoteAuthClient.ERROR_UNSUPPORTED -> "Auth not supported"
                  RemoteAuthClient.ERROR_PHONE_UNAVAILABLE -> "Phone unavailable"
                  else -> "Unknown error: $errorCode"
                }
                resultCallback.error(errorCode.toString(), message, "No details")
              }
            }
          )
          return
        } else {
          // Pass through if not compatible
          resultCallback.notImplemented()
        }
      }
      else -> resultCallback.notImplemented()
    }
  }
}
