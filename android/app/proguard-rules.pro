# Fix #2: SQLCipher requiere esta regla en release mode para evitar que R8/ProGuard
# ofusque las clases nativas de net.sqlcipher y rompa el cifrado en producción.
-keep class net.sqlcipher.** { *; }
-keep class net.sqlcipher.database.** { *; }
