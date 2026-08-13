package com.techub.pidelofacil.pidelofacil_moto

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

class GpsRepository(context: Context) :
    SQLiteOpenHelper(
        context,
        "gps.db",
        null,
        1
    ) {

    override fun onCreate(db: SQLiteDatabase) {

        db.execSQL(
            """
            CREATE TABLE ubicaciones(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                usuario_id TEXT,
                lat REAL,
                lng REAL,
                fecha INTEGER,
                enviado INTEGER DEFAULT 0
            )
            """.trimIndent()
        )

    }

    override fun onUpgrade(
        db: SQLiteDatabase,
        oldVersion: Int,
        newVersion: Int
    ) {
    }

    fun insertarUbicacion(
        usuario:String,
        lat:Double,
        lng:Double,
        fecha:Long
    ){

        val db = writableDatabase

        val values = ContentValues()

        values.put("usuario_id",usuario)
        values.put("lat",lat)
        values.put("lng",lng)
        values.put("fecha",fecha)

        db.insert(
            "ubicaciones",
            null,
            values
        )

    }

    data class Ubicacion(

        val id:Int,
        val usuario:String,
        val lat:Double,
        val lng:Double,
        val fecha:Long

    )

    fun obtenerPendientes():MutableList<Ubicacion>{

        val lista = mutableListOf<Ubicacion>()

        val db = readableDatabase

        val cursor = db.rawQuery(

            """
            SELECT *
            FROM ubicaciones
            WHERE enviado=0
            ORDER BY id
            LIMIT 100
            """,
            null

        )

        while(cursor.moveToNext()){

            lista.add(

                Ubicacion(

                    cursor.getInt(0),

                    cursor.getString(1),

                    cursor.getDouble(2),

                    cursor.getDouble(3),

                    cursor.getLong(4)

                )

            )

        }

        cursor.close()

        return lista

    }

    fun marcarEnviado(id:Int){

        val db = writableDatabase

        val values = ContentValues()

        values.put("enviado",1)

        db.update(

            "ubicaciones",

            values,

            "id=?",

            arrayOf(id.toString())

        )

    }


fun marcarEnviados(ids: List<Int>) {

    if (ids.isEmpty()) return

    val db = writableDatabase

    val values = ContentValues()
    values.put("enviado", 1)

    val placeholders = ids.joinToString(",") {
        "?"
    }

    db.update(
        "ubicaciones",
        values,
        "id IN ($placeholders)",
        ids.map {
            it.toString()
        }.toTypedArray()
    )
}
    fun borrarEnviados() {

        val db = writableDatabase

        db.delete(
            "ubicaciones",
            "enviado=1",
            null
        )

    }


}