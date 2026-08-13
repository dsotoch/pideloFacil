package com.techub.pidelofacil.pidelofacil_moto

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.google.android.gms.location.*
import kotlinx.coroutines.*
import androidx.work.Constraints
import androidx.work.NetworkType

class LocationService : Service() {

    companion object {

        private const val TAG = "GPS"

        private const val CHANNEL_ID = "gps_channel"

        private const val NOTIFICATION_ID = 100

    }

    private lateinit var fusedLocationClient: FusedLocationProviderClient

    private lateinit var prefs: SharedPreferences

    private lateinit var repository: GpsRepository

    private var userId: String? = null
    private var token: String? = null

    private var gpsActivo = false

    private val serviceScope = CoroutineScope(
        SupervisorJob() + Dispatchers.IO
    )

    private val locationRequest =
        LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            10000L
        )
            .setMinUpdateIntervalMillis(5000)
            .setMinUpdateDistanceMeters(10f)
            .setWaitForAccurateLocation(false)
            .build()

    private val callback = object : LocationCallback() {

        override fun onLocationResult(result: LocationResult) {

            super.onLocationResult(result)

            result.lastLocation?.let {

               val lat = it.latitude
    val lng = it.longitude

  

    guardarUbicacion(lat, lng)

    enviarUbicacion(lat, lng)

            }

        }

    }

    override fun onCreate() {

        super.onCreate()

        prefs = getSharedPreferences(
            "gps_service",
            Context.MODE_PRIVATE
        )

        repository = GpsRepository(this)

        fusedLocationClient =
            LocationServices.getFusedLocationProviderClient(this)

        iniciarForeground()


    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {


        intent?.getStringExtra("user_id")?.let {

            userId = it

            prefs.edit()
                .putString(
                    "user_id",
                    it
                )
                .apply()

        }


        intent?.getStringExtra("token")?.let {

            token = it

            prefs.edit()
                .putString(
                    "token",
                    it
                )
                .apply()

        }



        if (userId == null) {

            userId =
                prefs.getString(
                    "user_id",
                    null
                )

        }


        if (token == null) {

            token =
                prefs.getString(
                    "token",
                    null
                )

        }




        iniciarGPS()


        return START_STICKY

    }
    private fun enviarUbicacion(lat: Double, lng: Double) {

    val intent = Intent("com.techub.pidelofacil.GPS_LOCATION")

    intent.setPackage(packageName)

    intent.putExtra("lat", lat)
    intent.putExtra("lng", lng)

    sendBroadcast(intent)

}

    private fun iniciarGPS() {

        if (gpsActivo) return

        gpsActivo = true

        try {

            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                callback,
                Looper.getMainLooper()
            )


        } catch (e: SecurityException) {

            Log.e(TAG, "Sin permisos: ${e.message}")

        }

    }

    private fun guardarUbicacion(
        lat: Double,
        lng: Double
    ) {

        val id = userId ?: return


        serviceScope.launch {

            try {

                repository.insertarUbicacion(
                    id,
                    lat,
                    lng,
                    System.currentTimeMillis()
                )

                programarEnvio()

            } catch (e: Exception) {

                Log.e(
                    TAG,
                    e.message ?: ""
                )

            }

        }

    }

    private fun programarEnvio() {

        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        val request =
            OneTimeWorkRequestBuilder<LocationWorker>()
                .setConstraints(constraints)
                .build()

        WorkManager.getInstance(this)
            .enqueueUniqueWork(
                "gps_sender",
                ExistingWorkPolicy.REPLACE,
                request
            )

    }

    private fun iniciarForeground() {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

            val channel =
                NotificationChannel(
                    CHANNEL_ID,
                    "Ubicación",
                    NotificationManager.IMPORTANCE_LOW
                )

            channel.setShowBadge(false)

            val manager =
                getSystemService(
                    NotificationManager::class.java
                )

            manager.createNotificationChannel(channel)

        }

        val notification: Notification =
            NotificationCompat.Builder(
                this,
                CHANNEL_ID
            )
                .setContentTitle("Pidelo Fácil")
                .setContentText("Compartiendo ubicación")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setOngoing(true)
                .setCategory(NotificationCompat.CATEGORY_SERVICE)
                .build()

        startForeground(
            NOTIFICATION_ID,
            notification
        )

    }

    override fun onTaskRemoved(rootIntent: Intent?) {


        super.onTaskRemoved(rootIntent)

    }

    override fun onDestroy() {

        gpsActivo = false

        fusedLocationClient.removeLocationUpdates(
            callback
        )
        WorkManager.getInstance(this)
            .cancelUniqueWork("gps_sender")

        serviceScope.cancel()

        super.onDestroy()

    }

    override fun onBind(
        intent: Intent?
    ): IBinder? {

        return null

    }
}