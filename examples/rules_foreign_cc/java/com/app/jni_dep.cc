// Copyright 2023 The Bazel Authors. All rights reserved.
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

#include <vector>
#include "zstd.h"
#include "java/com/app/jni_dep.h"

std::string get_string() {
  std::vector<char> input_buffer = {'H', 'e', 'l', 'l', 'o', ',', ' ', 'W', 'o', 'r', 'l', 'd', '!'};
  std::vector<char> compressed_buffer(ZSTD_compressBound(input_buffer.size()));

  // Compress the input buffer into the compressed buffer
  size_t compressed_size = ZSTD_compress(compressed_buffer.data(), compressed_buffer.size(),
      input_buffer.data(), input_buffer.size(), 1);

  std::vector<char> decompressed_buffer(input_buffer.size());
  size_t decompressed_size = ZSTD_decompress(decompressed_buffer.data(), decompressed_buffer.size(),
      compressed_buffer.data(), compressed_size);

  return std::string(decompressed_buffer.data(), decompressed_size);
}
