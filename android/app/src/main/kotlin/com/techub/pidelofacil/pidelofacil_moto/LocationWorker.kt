package com.techub.pidelofacil.pidelofacil_moto

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.net.HttpURLConnection
import java.net.URL

class LocationWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    companion object {
        private const val TAG = "GPS_WORKER"
        private const val PREFS = "gps_service"

    }
    private val appContext = context.applicationContext


    private val prefs = appContext.getSharedPreferences(
        PREFS,
        Context.MODE_PRIVATE
    )



    private val repository = GpsRepository(context)

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {

        try {

            val lista = repository.obtenerPendientes()

            if (lista.isEmpty())
                return@withContext Result.success()

            val enviados = enviarLote(lista)

            if (enviados) {

                repository.marcarEnviados(
                    lista.map { it.id }
                )
                repository.borrarEnviados()
                return@withContext Result.success()

            }

            Result.retry()

        } catch (e: Exception) {

            Log.e(
                TAG,
                e.message ?: ""
            )

            Result.retry()

        }

    }


    private fun enviarLote(
        lista: List<GpsRepository.Ubicacion>
    ): Boolean {

        return try {


            val url = URL(
                "https://pidexa.online/api/save-position"
            )



            val conexion =
                url.openConnection() as HttpURLConnection


            conexion.requestMethod = "POST"

            conexion.connectTimeout = 15000
            conexion.readTimeout = 15000


            conexion.setRequestProperty(
                "Content-Type",
                "application/json"
            )

            val token = prefs.getString(
                "token",
                null
            )

            if (token != null) {

                conexion.setRequestProperty(
                    "Authorization",
                    "Bearer $token"
                )

            }


            conexion.doOutput = true


            val json =
                construirJson(lista)


            conexion.outputStream.use { output ->

                output.write(
                    json.toByteArray(
                        Charsets.UTF_8
                    )
                )

            }


            val codigo =
                conexion.responseCode




            val respuesta =
                conexion.inputStream.bufferedReader()
                    .readText()




            conexion.disconnect()


            codigo == HttpURLConnection.HTTP_OK


        } catch (e: Exception) {


            Log.e(
                TAG,
                "ERROR WORKER: ${e.message}",
                e
            )


            false

        }

    }
    private fun construirJson(
        lista: List<GpsRepository.Ubicacion>
    ): String {

        val sb = StringBuilder()

        sb.append("{")

        sb.append("\"usuario_id\":\"")
        sb.append(lista.first().usuario)
        sb.append("\",")

        sb.append("\"ubicaciones\":[")

        lista.forEachIndexed { index, gps ->

            sb.append("{")

            sb.append("\"lat\":")
            sb.append(gps.lat)

            sb.append(",")

            sb.append("\"lng\":")
            sb.append(gps.lng)

            sb.append(",")

            sb.append("\"fecha\":")
            sb.append(gps.fecha)

            sb.append("}")

            if (index < lista.size - 1)
                sb.append(",")

        }

        sb.append("]}")

        return sb.toString()

    }
}