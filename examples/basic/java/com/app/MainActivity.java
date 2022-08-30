package com.app;

import android.app.Activity;
import android.os.Bundle;
import android.widget.Button;
import android.widget.TextView;
import android.view.View;
import android.util.Log;

public class MainActivity extends Activity {

  @Override
  public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.main_layout);

    System.loadLibrary("app");

    int valueFromNative = Jni.getValue(2);

    ((TextView) findViewById(R.id.text_from_native))
        .setText("Result from JNI: " + valueFromNative);
  }
}
