import android.content.Context
import android.app.Application

/**
 * Application class used to expose the app context for the NativeAdFactory.
 */
class MyApplication : Application() {
    companion object {
        lateinit var appContext: Context
    }

    override fun onCreate() {
        super.onCreate()
        appContext = applicationContext
    }
}
