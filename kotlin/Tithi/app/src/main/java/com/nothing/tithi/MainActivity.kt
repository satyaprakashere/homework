package com.nothing.tithi

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // A simple activity to show that the app is installed.
        // In a real app, this could be the configuration screen.
        setContentView(R.layout.activity_main)
    }
}
