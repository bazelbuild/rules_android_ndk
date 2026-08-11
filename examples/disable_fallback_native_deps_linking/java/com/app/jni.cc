// Copyright 2022 The Bazel Authors. All rights reserved.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//    http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <jni.h>
#include <string>

#include "java/com/app/jni_dep.h"

extern "C" JNIEXPORT int JNICALL
Java_com_app_Jni_getValue(JNIEnv *env, jclass clazz, jint a) {
  return calculate((int)a, 2);
}
