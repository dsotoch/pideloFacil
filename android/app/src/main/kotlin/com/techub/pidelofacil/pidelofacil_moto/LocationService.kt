package com.techub.pidelofacil.pidelofacil_moto

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import java.net.HttpURLConnection
import java.net.URL


class LocationService : Service() {


    private var userId: String? = null


    private lateinit var fusedLocationClient: FusedLocationProviderClient


    private val serviceScope =
        CoroutineScope(
            SupervisorJob() + Dispatchers.IO
        )



    private val locationRequest =
        LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            10000
        )
            .setMinUpdateDistanceMeters(10f)
            .build()



    private val callback =
        object : LocationCallback() {

            override fun onLocationResult(
                result: LocationResult
            ) {

                result.locations.forEach { location ->

                    enviarUbicacion(
                        location.latitude,
                        location.longitude
                    )

                }

            }
        }




    override fun onCreate() {
        super.onCreate()


        fusedLocationClient =
            LocationServices
                .getFusedLocationProviderClient(this)


        iniciarForeground()

    }



    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {


        userId =
            intent?.getStringExtra("user_id")


        Log.d(
            "GPS",
            "Servicio iniciado usuario: $userId"
        )


        iniciarGPS()


        return START_STICKY
    }




    private fun iniciarForeground(){


        val channelId = "gps_channel"


        if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O){

            val channel =
                NotificationChannel(
                    channelId,
                    "GPS activo",
                    NotificationManager.IMPORTANCE_LOW
                )


            val manager =
                getSystemService(
                    NotificationManager::class.java
                )


            manager.createNotificationChannel(
                channel
            )

        }



        val notification =
            NotificationCompat.Builder(
                this,
                channelId
            )
                .setContentTitle(
                    "Pidelo Fácil"
                )
                .setContentText(
                    "Compartiendo ubicación"
                )
                .setSmallIcon(
                    R.mipmap.ic_launcher
                )
                .build()



        startForeground(
            100,
            notification
        )

    }




    private fun iniciarGPS(){


        try {


            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                callback,
                Looper.getMainLooper()
            )


        }catch(e:SecurityException){

            Log.e(
                "GPS",
                "Sin permisos GPS: ${e.message}"
            )

        }

    }





    private fun enviarUbicacion(
        lat: Double,
        lng: Double
    ){


        val id =
            userId ?: return



        Log.d(
            "GPS",
            "$id -> $lat,$lng"
        )



        serviceScope.launch {


            try {


                val url =
                    URL(
                        "https://tudominio.com/api/guardar-ubicacion"
                    )



                val conexion =
                    url.openConnection()
                            as HttpURLConnection



                conexion.requestMethod =
                    "POST"



                conexion.setRequestProperty(
                    "Content-Type",
                    "application/json"
                )



                conexion.doOutput = true



                val json =
                    """
                    {
                        "usuario_id":"$id",
                        "latitud":$lat,
                        "longitud":$lng
                    }
                    """.trimIndent()



                conexion.outputStream.use { output ->

                    output.write(
                        json.toByteArray(
                            Charsets.UTF_8
                        )
                    )

                }



                val codigo =
                    conexion.responseCode



                if(codigo == HttpURLConnection.HTTP_OK){

                    Log.d(
                        "GPS",
                        "Ubicación enviada"
                    )


                }else{


                    Log.e(
                        "GPS",
                        "HTTP ERROR: $codigo"
                    )

                }



                conexion.disconnect()



            }catch(e:Exception){


                Log.e(
                    "GPS",
                    "Error enviando GPS: ${e.message}"
                )


            }

        }

    }





    override fun onDestroy() {


        serviceScope.cancel()


        fusedLocationClient
            .removeLocationUpdates(
                callback
            )


        Log.d(
            "GPS",
            "Servicio detenido"
        )


        super.onDestroy()

    }




    override fun onBind(
        intent: Intent?
    ): IBinder? {

        return null

    }

}