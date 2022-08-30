#include <jni.h>
#include <string>

#include "java/com/app/jni_dep.h"

extern "C" JNIEXPORT int JNICALL
Java_com_app_Jni_getValue(JNIEnv *env, jclass clazz, jint a) {
  return calculate((int)a, 2);
}
