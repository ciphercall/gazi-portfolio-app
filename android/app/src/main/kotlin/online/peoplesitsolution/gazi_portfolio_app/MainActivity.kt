package online.peoplesitsolution.gazi_portfolio_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var apkInstaller: ApkInstallerChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        apkInstaller = ApkInstallerChannel(this).also { it.register(flutterEngine) }
    }
}