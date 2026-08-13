package com.techub.pidelofacil.pidelofacil_moto

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {

        private const val CHANNEL = "gps_service"

        private const val GPS_EVENT_CHANNEL = "gps_location"

        private const val GPS_BROADCAST =
            "com.techub.pidelofacil.GPS_LOCATION"

        private const val REQUEST_LOCATION = 100

        private const val REQUEST_BACKGROUND = 101

        private const val PREFS = "gps_service"
    }

    private var gpsEventSink: EventChannel.EventSink? = null

    private var pendingUserId: String? = null

    private var token: String? = null

    /**
     * Recibe las ubicaciones que envía LocationService
     */
    private val gpsReceiver = object : BroadcastReceiver() {

        override fun onReceive(
            context: Context?,
            intent: Intent?
        ) {

            if (intent?.action != GPS_BROADCAST) {
                return
            }

            val lat =
                intent.getDoubleExtra(
                    "lat",
                    0.0
                )

            val lng =
                intent.getDoubleExtra(
                    "lng",
                    0.0
                )

           

            gpsEventSink?.success(
                mapOf(
                    "lat" to lat,
                    "lng" to lng
                )
            )
        }
    }

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {

        super.configureFlutterEngine(
            flutterEngine
        )

        /**
         * ==========================================
         * METHOD CHANNEL
         * ==========================================
         */

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "startGPS" -> {

                    val userId =
                        call.argument<String>(
                            "user_id"
                        )

                    val tokenId =
                        call.argument<String>(
                            "token"
                        )

                    token = tokenId

                    pendingUserId = userId

                    guardarUsuario(
                        userId,
                        tokenId
                    )

                    checkLocationPermission()

                    result.success(true)
                }

                "stopGPS" -> {

                    stopService(
                        Intent(
                            this,
                            LocationService::class.java
                        )
                    )

                    result.success(true)
                }

                else -> {

                    result.notImplemented()
                }
            }
        }

        /**
         * ==========================================
         * EVENT CHANNEL
         * ==========================================
         *
         * Flutter escuchará:
         *
         * EventChannel("gps_location")
         *
         */

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            GPS_EVENT_CHANNEL
        ).setStreamHandler(
            object : EventChannel.StreamHandler {

                override fun onListen(
                    arguments: Any?,
                    events: EventChannel.EventSink?
                ) {

                   

                    gpsEventSink = events
                }

                override fun onCancel(
                    arguments: Any?
                ) {

                   

                    gpsEventSink = null
                }
            }
        )

        /**
         * ==========================================
         * REGISTRAR BROADCAST RECEIVER
         * ==========================================
         */

        val filter =
            IntentFilter(
                GPS_BROADCAST
            )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {

            registerReceiver(
                gpsReceiver,
                filter,
                Context.RECEIVER_NOT_EXPORTED
            )

        } else {

            registerReceiver(
                gpsReceiver,
                filter
            )
        }
    }

    /**
     * ==========================================
     * GUARDAR USUARIO
     * ==========================================
     */

    private fun guardarUsuario(
        userId: String?,
        token: String?
    ) {

        if (userId == null) {
            return
        }

        if (token == null) {
            return
        }

        getSharedPreferences(
            PREFS,
            MODE_PRIVATE
        )
            .edit()
            .putString(
                "token",
                token
            )
            .putString(
                "user_id",
                userId
            )
            .apply()
    }

    /**
     * ==========================================
     * OBTENER USUARIO
     * ==========================================
     */

    private fun obtenerUsuario(): String? {

        return getSharedPreferences(
            PREFS,
            MODE_PRIVATE
        )
            .getString(
                "user_id",
                null
            )
    }

    /**
     * ==========================================
     * OBTENER TOKEN
     * ==========================================
     */

    private fun obtenerToken(): String? {

        return getSharedPreferences(
            PREFS,
            MODE_PRIVATE
        )
            .getString(
                "token",
                null
            )
    }

    /**
     * ==========================================
     * PERMISO UBICACIÓN
     * ==========================================
     */

    private fun checkLocationPermission() {

        if (
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {

            ActivityCompat.requestPermissions(
                this,
                arrayOf(
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                ),
                REQUEST_LOCATION
            )

            return
        }

        checkBackgroundPermission()
    }

    /**
     * ==========================================
     * PERMISO UBICACIÓN SEGUNDO PLANO
     * ==========================================
     */

    private fun checkBackgroundPermission() {

        if (
            Build.VERSION.SDK_INT >=
            Build.VERSION_CODES.Q
        ) {

            if (
                ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.ACCESS_BACKGROUND_LOCATION
                ) != PackageManager.PERMISSION_GRANTED
            ) {

                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(
                        Manifest.permission.ACCESS_BACKGROUND_LOCATION
                    ),
                    REQUEST_BACKGROUND
                )

                return
            }
        }

        startLocationService()
    }

    /**
     * ==========================================
     * INICIAR LOCATION SERVICE
     * ==========================================
     */

    private fun startLocationService() {

        val intent =
            Intent(
                this,
                LocationService::class.java
            )

        intent.putExtra(
            "user_id",
            pendingUserId ?: obtenerUsuario()
        )

        intent.putExtra(
            "token",
            token ?: obtenerToken()
        )

        ContextCompat.startForegroundService(
            this,
            intent
        )
    }

    /**
     * ==========================================
     * RESULTADO DE PERMISOS
     * ==========================================
     */

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {

        super.onRequestPermissionsResult(
            requestCode,
            permissions,
            grantResults
        )

        val aprobado =
            grantResults.isNotEmpty() &&
                    grantResults.all {
                        it == PackageManager.PERMISSION_GRANTED
                    }

        if (!aprobado) {
            return
        }

        when (requestCode) {

            REQUEST_LOCATION -> {

                checkBackgroundPermission()
            }

            REQUEST_BACKGROUND -> {

                startLocationService()
            }
        }
    }

    /**
     * ==========================================
     * DESTRUIR ACTIVITY
     * ==========================================
     */

    override fun onDestroy() {

        try {
            unregisterReceiver(
                gpsReceiver
            )
        } catch (e: Exception) {
            android.util.Log.e(
                "GPS_CHANNEL",
                "Error unregisterReceiver",
                e
            )
        }

        gpsEventSink = null

        super.onDestroy()
    }
}